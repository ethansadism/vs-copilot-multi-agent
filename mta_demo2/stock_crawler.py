"""
台股即時數據獲取服務

透過 TWSE 公開 API 取得即時個股報價，支援背景輪詢與回調通知。
"""

import time
import threading
import logging
from datetime import datetime, timedelta
from typing import Callable, Optional

import requests
import urllib3

logger = logging.getLogger(__name__)

# 抑制 SSL 未驗證時的警告（僅在 TWSE 憑證異常時的 fallback 用）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# TWSE 即時報價 API 基底 URL
TWSE_API_URL = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp"

# 常見瀏覽器 User-Agent
DEFAULT_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/122.0.0.0 Safari/537.36"
)

# 台股交易時間 (時:分)
MARKET_OPEN = (9, 0)
MARKET_CLOSE = (13, 30)

# 輪詢間隔（秒）
POLL_INTERVAL_MIN = 5
POLL_INTERVAL_MAX = 10

# 通知規則閾值
ALERT_CHANGE_PERCENT = 3.0   # 漲跌幅超過 ±3% 視為大幅波動
ALERT_VOLUME_RATIO = 1.5     # 成交量超過日均量 1.5 倍視為量能放大


def _is_market_open() -> bool:
    """判斷目前是否在台股交易時段 (09:00 ~ 13:30，週一至週五)"""
    now = datetime.now()
    # 週六=5, 週日=6
    if now.weekday() >= 5:
        return False
    market_open = now.replace(hour=MARKET_OPEN[0], minute=MARKET_OPEN[1], second=0, microsecond=0)
    market_close = now.replace(hour=MARKET_CLOSE[0], minute=MARKET_CLOSE[1], second=0, microsecond=0)
    return market_open <= now <= market_close


def _safe_float(value: str, default: float = 0.0) -> float:
    """安全轉換字串為浮點數，無效值回傳預設值"""
    if not value or value == "-":
        return default
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def _safe_int(value: str, default: int = 0) -> int:
    """安全轉換字串為整數"""
    if not value or value == "-":
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def _parse_stock_info(raw: dict) -> Optional[dict]:
    """
    將 TWSE API 回傳的單支股票原始數據解析為標準格式。

    TWSE API 欄位對照：
      c  = 股票代號
      n  = 股票名稱
      z  = 即時成交價
      y  = 昨收
      o  = 開盤價
      h  = 最高價
      l  = 最低價
      v  = 累積成交量（張）
      b  = 最佳五檔買價（以 _ 分隔）
      a  = 最佳五檔賣價（以 _ 分隔）
      t  = 最近成交時間 (HH:MM:SS)
      d  = 日期 (yyyyMMdd)
    """
    try:
        stock_id = raw.get("c", "")
        stock_name = raw.get("n", "").strip()

        current_price = _safe_float(raw.get("z"))
        yesterday_close = _safe_float(raw.get("y"))
        open_price = _safe_float(raw.get("o"))
        high_price = _safe_float(raw.get("h"))
        low_price = _safe_float(raw.get("l"))
        volume = _safe_int(raw.get("v"))

        # 最佳買賣價：取第一檔
        best_bid_str = raw.get("b", "")
        best_ask_str = raw.get("a", "")
        best_bid = _safe_float(best_bid_str.split("_")[0]) if best_bid_str else 0.0
        best_ask = _safe_float(best_ask_str.split("_")[0]) if best_ask_str else 0.0

        # 如果成交價為 0（尚未成交或非交易時間），嘗試用昨收替代以供顯示
        display_price = current_price if current_price > 0 else yesterday_close

        # 計算漲跌與漲跌幅
        change = round(display_price - yesterday_close, 2) if yesterday_close > 0 else 0.0
        change_percent = round((change / yesterday_close) * 100, 2) if yesterday_close > 0 else 0.0

        # 組裝時間戳
        date_str = raw.get("d", "")
        time_str = raw.get("t", "")
        if date_str and time_str:
            timestamp = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]} {time_str}"
        else:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        return {
            "stock_id": stock_id,
            "stock_name": stock_name,
            "current_price": display_price,
            "change": change,
            "change_percent": change_percent,
            "volume": volume,
            "open_price": open_price,
            "high_price": high_price,
            "low_price": low_price,
            "yesterday_close": yesterday_close,
            "timestamp": timestamp,
            "best_bid": best_bid,
            "best_ask": best_ask,
        }
    except Exception as e:
        logger.error("解析股票數據失敗: %s", e)
        return None


def _apply_alerts(data: dict, avg_volumes: dict) -> dict:
    """
    根據通知規則為數據附加告警標記。

    回傳的 data 會多出 "alerts" 欄位（list[str]）。
    """
    alerts: list[str] = []

    # 大幅波動判斷
    if abs(data.get("change_percent", 0)) >= ALERT_CHANGE_PERCENT:
        direction = "漲" if data["change_percent"] > 0 else "跌"
        alerts.append(f"大幅波動：{direction} {abs(data['change_percent']):.2f}%")

    # 量能放大判斷
    stock_id = data.get("stock_id", "")
    avg_vol = avg_volumes.get(stock_id, 0)
    if avg_vol > 0 and data.get("volume", 0) >= avg_vol * ALERT_VOLUME_RATIO:
        ratio = data["volume"] / avg_vol
        alerts.append(f"量能放大：成交量為日均量 {ratio:.1f} 倍")

    data["alerts"] = alerts
    return data


class StockCrawler:
    """台股即時報價爬蟲，支援背景輪詢與回調推播。"""

    def __init__(
        self,
        stock_ids: list[str] | None = None,
        callback: Callable[[list[dict]], None] | None = None,
    ):
        """
        Args:
            stock_ids: 要監看的股票代號列表，預設為 ["2317", "2330"]
            callback:  數據更新時的回調函式，簽名為 callback(data_list)
        """
        self._stock_ids: list[str] = list(stock_ids) if stock_ids else ["2317", "2330"]
        self._callback = callback

        # 最新數據快照 {stock_id: {...}}
        self._latest: dict[str, dict] = {}
        # 日均量參考值 {stock_id: int}，可由外部設定或自動估算
        self._avg_volumes: dict[str, int] = {}

        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
        self._session = requests.Session()
        self._session.headers.update({"User-Agent": DEFAULT_UA})
        # TWSE 憑證在某些 Python 版本會驗證失敗，測試環境先嘗試正常驗證
        self._verify_ssl = True

        # 重試參數
        self._max_retries = 3
        self._retry_delay = 2  # 秒

    # ----- 公開方法 -----

    def start(self) -> None:
        """啟動背景輪詢執行緒"""
        if self._running:
            logger.warning("爬蟲已在執行中")
            return
        self._running = True
        self._thread = threading.Thread(target=self._poll_loop, daemon=True, name="stock-crawler")
        self._thread.start()
        logger.info("台股爬蟲已啟動，監看: %s", self._stock_ids)

    def stop(self) -> None:
        """停止輪詢"""
        self._running = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=15)
        logger.info("台股爬蟲已停止")

    def get_latest_data(self) -> dict[str, dict]:
        """取得所有監看股票的最新數據快照（dict: stock_id -> data）"""
        with self._lock:
            return dict(self._latest)

    def add_stock(self, stock_id: str) -> None:
        """動態加入一支監看股票"""
        with self._lock:
            if stock_id not in self._stock_ids:
                self._stock_ids.append(stock_id)
                logger.info("新增監看股票: %s", stock_id)

    def remove_stock(self, stock_id: str) -> None:
        """動態移除一支監看股票"""
        with self._lock:
            if stock_id in self._stock_ids:
                self._stock_ids.remove(stock_id)
                self._latest.pop(stock_id, None)
                logger.info("移除監看股票: %s", stock_id)

    def set_avg_volume(self, stock_id: str, avg_volume: int) -> None:
        """設定某支股票的日均量，供量能放大告警使用"""
        self._avg_volumes[stock_id] = avg_volume

    def fetch_once(self) -> list[dict]:
        """手動執行一次數據抓取（不依賴背景輪詢），回傳解析後的數據列表"""
        return self._fetch_data()

    # ----- 內部實作 -----

    def _build_query(self) -> str:
        """建構 TWSE API 的 ex_ch 查詢參數"""
        with self._lock:
            ids = list(self._stock_ids)
        return "|".join(f"tse_{sid}.tw" for sid in ids)

    def _fetch_data(self) -> list[dict]:
        """向 TWSE API 發送請求，解析並回傳股票資料列表"""
        ex_ch = self._build_query()
        if not ex_ch:
            return []

        for attempt in range(1, self._max_retries + 1):
            try:
                resp = self._session.get(
                    TWSE_API_URL,
                    params={"ex_ch": ex_ch},
                    timeout=10,
                    verify=self._verify_ssl,
                )
                resp.raise_for_status()
                payload = resp.json()

                raw_list = payload.get("msgArray", [])
                if not raw_list:
                    logger.debug("API 回傳空數據（可能非交易時段）")
                    return []

                results: list[dict] = []
                for raw in raw_list:
                    parsed = _parse_stock_info(raw)
                    if parsed:
                        parsed = _apply_alerts(parsed, self._avg_volumes)
                        results.append(parsed)

                # 更新快照
                with self._lock:
                    for item in results:
                        self._latest[item["stock_id"]] = item

                return results

            except requests.RequestException as e:
                # SSL 驗證失敗時，降級為不驗證（TWSE 為可信來源）
                if self._verify_ssl and "SSL" in str(e):
                    logger.warning("SSL 驗證失敗，降級為不驗證模式（TWSE 可信來源）")
                    self._verify_ssl = False
                    continue
                logger.warning("第 %d 次請求失敗: %s", attempt, e)
                if attempt < self._max_retries:
                    time.sleep(self._retry_delay * attempt)  # 簡易指數退避
                else:
                    logger.error("已達最大重試次數，本輪放棄")

        return []

    def _poll_loop(self) -> None:
        """背景輪詢主迴圈"""
        import random

        logger.info("輪詢執行緒啟動")
        while self._running:
            if _is_market_open():
                data_list = self._fetch_data()
                if data_list and self._callback:
                    try:
                        self._callback(data_list)
                    except Exception as e:
                        logger.error("回調函式執行失敗: %s", e)

                interval = random.uniform(POLL_INTERVAL_MIN, POLL_INTERVAL_MAX)
            else:
                # 非交易時段，降低檢查頻率（每 60 秒看一次是否開盤）
                interval = 60

            # 分段 sleep，以便能快速回應 stop()
            slept = 0.0
            while slept < interval and self._running:
                time.sleep(0.5)
                slept += 0.5

        logger.info("輪詢執行緒結束")


# ---- 快速測試入口 ----
if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    def on_data(data_list: list[dict]):
        for d in data_list:
            alerts_str = " | ".join(d["alerts"]) if d.get("alerts") else ""
            print(
                f"  {d['stock_name']}({d['stock_id']}) "
                f"${d['current_price']}  {d['change']:+.2f} ({d['change_percent']:+.2f}%) "
                f"量:{d['volume']}張  {alerts_str}"
            )

    crawler = StockCrawler(callback=on_data)

    # 不管是否開盤，先手動抓一次看看
    print("=== 手動抓取一次 ===")
    result = crawler.fetch_once()
    if not result:
        print("  （無數據，可能非交易時段）")
    else:
        on_data(result)

    # 如果想測試背景輪詢，取消下面的註解
    # crawler.start()
    # try:
    #     while True:
    #         time.sleep(1)
    # except KeyboardInterrupt:
    #     crawler.stop()
