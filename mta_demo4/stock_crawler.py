"""
美股即時報價爬蟲

使用 yfinance 取得美股即時報價，搭配 Redis 快取（TTL 30s）與 Pub/Sub 通知。
支援美股交易時段判斷（US Eastern Time 09:30~16:00）與 watchlist 閾值警報。
"""

import json
import time
import logging
import threading
from datetime import datetime
from typing import Callable, Optional

import redis
import yfinance as yf

try:
    from zoneinfo import ZoneInfo
except ImportError:  # Python < 3.9 fallback
    from backports.zoneinfo import ZoneInfo

logger = logging.getLogger(__name__)

# ── 美股交易時間（US Eastern Time）──────────────────────────────────────────
MARKET_TZ = ZoneInfo("America/New_York")
MARKET_OPEN_H, MARKET_OPEN_M = 9, 30
MARKET_CLOSE_H, MARKET_CLOSE_M = 16, 0

# ── Redis 設定 ───────────────────────────────────────────────────────────────
CACHE_PREFIX = "stock:"
CACHE_TTL = 30          # 快取有效秒數
PUBSUB_UPDATES = "stock_updates"
PUBSUB_ALERTS = "stock_alerts"

# ── 輪詢設定 ─────────────────────────────────────────────────────────────────
DEFAULT_POLL_INTERVAL = 15  # 秒


# ── 輔助函式 ─────────────────────────────────────────────────────────────────

def _safe_float(value, default: float = 0.0) -> float:
    """安全轉換為浮點數，無效值回傳預設值"""
    if value is None:
        return default
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def _safe_int(value, default: int = 0) -> int:
    """安全轉換為整數，無效值回傳預設值"""
    if value is None:
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def _parse_ticker_info(symbol: str, info: dict) -> dict:
    """
    將 yfinance info dict 解析為標準報價格式。

    change_amount / change_percent 由 price 與 prev_close 直接計算，
    避免不同 yfinance 版本對 regularMarketChangePercent 單位不一致的問題。
    """
    price = _safe_float(info.get("currentPrice") or info.get("regularMarketPrice"))
    prev_close = _safe_float(info.get("regularMarketPreviousClose"))

    if prev_close:
        change_amount = price - prev_close
        change_percent = round((change_amount / prev_close) * 100, 2)
    else:
        change_amount = _safe_float(info.get("regularMarketChange", 0))
        change_percent = 0.0

    name = info.get("shortName") or info.get("longName") or symbol

    return {
        "symbol": symbol.upper(),
        "name": name,
        "price": price,
        "change_amount": round(change_amount, 4),
        "change_percent": change_percent,
        "volume": _safe_int(info.get("regularMarketVolume")),
        "prev_close": prev_close,
        "market_cap": _safe_int(info.get("marketCap")),
        "updated_at": datetime.now(MARKET_TZ).isoformat(),
    }


# ── 主類別 ───────────────────────────────────────────────────────────────────

class USStockCrawler:
    """美股即時報價爬蟲，搭配 Redis 快取與 Pub/Sub 通知"""

    def __init__(self, redis_host: str = "localhost", redis_port: int = 6379):
        self._redis = redis.Redis(
            host=redis_host,
            port=redis_port,
            decode_responses=True,
        )
        self._polling = False
        self._poll_thread: Optional[threading.Thread] = None
        logger.info("USStockCrawler 初始化完成（Redis: %s:%s）", redis_host, redis_port)

    # ── 公開 API ──────────────────────────────────────────────────────────────

    def is_market_open(self) -> bool:
        """
        判斷美股是否在交易時段。
        US Eastern Time 09:30 ~ 16:00，週一至週五。
        """
        now = datetime.now(MARKET_TZ)
        if now.weekday() >= 5:  # 週六=5, 週日=6
            return False
        open_time = now.replace(
            hour=MARKET_OPEN_H, minute=MARKET_OPEN_M, second=0, microsecond=0
        )
        close_time = now.replace(
            hour=MARKET_CLOSE_H, minute=MARKET_CLOSE_M, second=0, microsecond=0
        )
        return open_time <= now < close_time

    def fetch_quotes(self, symbols: list[str]) -> list[dict]:
        """
        批次取得報價。

        查詢流程：
          1. 先查 Redis cache（key: stock:{SYMBOL}）
          2. cache hit → 直接回傳（不呼叫 yfinance）
          3. cache miss → 批次呼叫 yfinance，寫入 cache，發布 stock_updates
        """
        results: list[dict] = []
        miss_symbols: list[str] = []

        for symbol in symbols:
            cached = self._get_from_cache(symbol)
            if cached is not None:
                results.append(cached)
                logger.debug("Cache hit: %s", symbol)
            else:
                miss_symbols.append(symbol.upper())

        if miss_symbols:
            fresh = self._fetch_from_yfinance(miss_symbols)
            for quote in fresh:
                self._cache_quote(quote)
                self._publish_update(quote)
            results.extend(fresh)

        return results

    def check_alerts(self, quotes: list[dict], watchlist: list[dict]) -> list[dict]:
        """
        比對報價與 watchlist 閾值，回傳所有觸發的 alerts，
        並透過 Redis Pub/Sub channel `stock_alerts` 發布。

        watchlist 格式：
            [{"symbol": "AAPL", "threshold": 5.0}, ...]

        回傳 alert dict 格式：
            {
                "symbol": "AAPL",
                "name": "Apple Inc.",
                "alert_type": "price_change",
                "message": "...",
                "trigger_value": 6.2,
                "threshold": 5.0,
            }
        """
        threshold_map = {
            w["symbol"].upper(): float(w["threshold"]) for w in watchlist
        }
        triggered: list[dict] = []

        for quote in quotes:
            symbol = quote["symbol"]
            threshold = threshold_map.get(symbol)
            if threshold is None:
                continue

            change_pct = quote.get("change_percent", 0.0)
            if abs(change_pct) >= threshold:
                direction = "上漲" if change_pct >= 0 else "下跌"
                alert = {
                    "symbol": symbol,
                    "name": quote.get("name", symbol),
                    "alert_type": "price_change",
                    "message": (
                        f"{quote.get('name', symbol)} ({symbol}) {direction} "
                        f"{abs(change_pct):.2f}%，超過門檻 {threshold:.1f}%"
                    ),
                    "trigger_value": round(change_pct, 2),
                    "threshold": threshold,
                }
                triggered.append(alert)
                self._publish_alert(alert)
                logger.info(
                    "Alert 觸發：%s change_percent=%.2f%% threshold=%.1f%%",
                    symbol, change_pct, threshold,
                )

        return triggered

    def start_polling(
        self,
        get_watchlist_fn: Callable[[], list[dict]],
        on_update_fn: Callable[[list[dict]], None],
        on_alert_fn: Callable[[list[dict]], None],
        interval: int = DEFAULT_POLL_INTERVAL,
    ) -> None:
        """
        啟動背景輪詢（只在美股開盤時段自動執行）。
        非交易時段呼叫不會報錯，但自動跳過每輪查詢。

        :param get_watchlist_fn: 每輪呼叫以取得最新 watchlist，格式同 check_alerts
        :param on_update_fn:     收到新報價時的回調，接收 list[dict]
        :param on_alert_fn:      觸發 alert 時的回調，接收 list[dict]
        :param interval:         輪詢間隔（秒），預設 15
        """
        if self._polling:
            logger.warning("輪詢已在執行中，忽略重複啟動請求")
            return
        self._polling = True
        self._poll_thread = threading.Thread(
            target=self._poll_loop,
            args=(get_watchlist_fn, on_update_fn, on_alert_fn, interval),
            daemon=True,
            name="USStockCrawler-Polling",
        )
        self._poll_thread.start()
        logger.info("背景輪詢已啟動（間隔 %ds）", interval)

    def stop_polling(self) -> None:
        """停止背景輪詢，等待執行緒結束（最多 5 秒）"""
        self._polling = False
        if self._poll_thread and self._poll_thread.is_alive():
            self._poll_thread.join(timeout=5)
        logger.info("背景輪詢已停止")

    # ── 內部方法 ──────────────────────────────────────────────────────────────

    def _get_from_cache(self, symbol: str) -> Optional[dict]:
        """從 Redis 讀取快取，回傳 dict 或 None（cache miss）"""
        key = f"{CACHE_PREFIX}{symbol.upper()}"
        try:
            raw = self._redis.get(key)
            if raw:
                return json.loads(raw)
        except (redis.RedisError, json.JSONDecodeError) as e:
            logger.warning("讀取 Redis cache 失敗（%s）：%s", key, e)
        return None

    def _cache_quote(self, quote: dict) -> None:
        """將報價寫入 Redis cache（TTL: CACHE_TTL 秒）"""
        key = f"{CACHE_PREFIX}{quote['symbol']}"
        try:
            self._redis.setex(key, CACHE_TTL, json.dumps(quote))
        except redis.RedisError as e:
            logger.error("寫入 Redis cache 失敗（%s）：%s", key, e)

    def _publish_update(self, quote: dict) -> None:
        """透過 Redis Pub/Sub channel `stock_updates` 發布新報價"""
        try:
            self._redis.publish(PUBSUB_UPDATES, json.dumps(quote))
        except redis.RedisError as e:
            logger.error("發布 stock_updates 失敗：%s", e)

    def _publish_alert(self, alert: dict) -> None:
        """透過 Redis Pub/Sub channel `stock_alerts` 發布警報"""
        try:
            self._redis.publish(PUBSUB_ALERTS, json.dumps(alert))
        except redis.RedisError as e:
            logger.error("發布 stock_alerts 失敗：%s", e)

    def _fetch_from_yfinance(self, symbols: list[str]) -> list[dict]:
        """
        使用 yfinance 逐一取得報價。

        yfinance 的 .info 屬性每次呼叫皆為獨立 HTTP 請求，
        Redis cache（TTL 30s）是控制請求頻率的主要機制。
        每個 symbol 間加入 0.2s 延遲以降低 rate limit 風險。
        """
        results: list[dict] = []
        for i, symbol in enumerate(symbols):
            if i > 0:
                time.sleep(0.2)  # 輕量 rate limit 保護
            try:
                ticker = yf.Ticker(symbol)
                info = ticker.info
                if not info or info.get("quoteType") is None:
                    logger.warning("yfinance 無法取得 %s 的有效資料", symbol)
                    continue
                quote = _parse_ticker_info(symbol, info)
                results.append(quote)
                logger.debug("yfinance fetch OK: %s @ %.2f", symbol, quote["price"])
            except Exception as e:
                logger.error("yfinance 查詢 %s 失敗：%s", symbol, e)
        return results

    def _poll_loop(
        self,
        get_watchlist_fn: Callable,
        on_update_fn: Callable,
        on_alert_fn: Callable,
        interval: int,
    ) -> None:
        """輪詢主迴圈，非交易時段自動跳過"""
        while self._polling:
            if not self.is_market_open():
                logger.debug("非交易時段，跳過本次輪詢")
                time.sleep(interval)
                continue

            try:
                watchlist = get_watchlist_fn()
                if not watchlist:
                    logger.debug("watchlist 為空，跳過本次輪詢")
                else:
                    symbols = [w["symbol"] for w in watchlist]
                    quotes = self.fetch_quotes(symbols)
                    if quotes:
                        on_update_fn(quotes)
                        alerts = self.check_alerts(quotes, watchlist)
                        if alerts:
                            on_alert_fn(alerts)
            except Exception as e:
                logger.error("輪詢迴圈發生錯誤：%s", e)

            time.sleep(interval)
