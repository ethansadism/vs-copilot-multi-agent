"""
美股即時監聽 Dashboard — 主應用程式
Flask + Flask-SocketIO，整合 USStockDatabase + USStockCrawler
Port: 5003
"""

import logging

from flask import Flask, jsonify, render_template, request
from flask_socketio import SocketIO

from database import USStockDatabase
from stock_crawler import USStockCrawler

# ── 日誌設定 ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
logger = logging.getLogger(__name__)

# ── Flask & SocketIO 初始化 ────────────────────────────────────────────────────
app = Flask(__name__)
app.config["SECRET_KEY"] = "us-stock-monitor-secret"
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="threading")

# ── Database 初始化 ────────────────────────────────────────────────────────────
db = USStockDatabase()

# ── Crawler 初始化（Redis 連線失敗時 graceful fallback）─────────────────────────
try:
    crawler = USStockCrawler()
    logger.info("USStockCrawler 初始化成功")
except Exception as e:
    logger.warning("USStockCrawler 初始化失敗（無 Redis），仍可使用但無快取：%s", e)
    crawler = USStockCrawler.__new__(USStockCrawler)
    crawler._polling = False
    crawler._poll_thread = None


# ── Callback：收到即時報價 ─────────────────────────────────────────────────────
def on_update(quotes: list[dict]):
    """輪詢取得新報價後：儲存至 DB，並透過 SocketIO 推送到前端"""
    if not quotes:
        return
    db.save_prices(quotes)
    socketio.emit("price_update", {"quotes": quotes})
    logger.info("price_update 推送 %d 筆報價", len(quotes))


def on_alert(alerts: list[dict]):
    """Alert 觸發後：儲存至 DB，並透過 SocketIO 推送到前端"""
    for alert in alerts:
        db.save_alert(
            symbol=alert["symbol"],
            name=alert.get("name", ""),
            alert_type=alert.get("alert_type", "price_change"),
            message=alert.get("message", ""),
            trigger_value=alert.get("trigger_value", 0.0),
            threshold=alert.get("threshold", 5.0),
        )
        socketio.emit("alert_triggered", alert)
        logger.info("Alert 推送：%s %s", alert["symbol"], alert.get("message", ""))


# ── 啟動背景輪詢 ───────────────────────────────────────────────────────────────
def _get_watchlist_for_crawler() -> list[dict]:
    """將 DB watchlist 的 alert_threshold_pct 映射為 crawler 期望的 threshold 欄位"""
    return [
        {"symbol": w["symbol"], "threshold": w["alert_threshold_pct"]}
        for w in db.get_watchlist()
    ]


try:
    crawler.start_polling(
        get_watchlist_fn=_get_watchlist_for_crawler,
        on_update_fn=on_update,
        on_alert_fn=on_alert,
        interval=15,
    )
    logger.info("背景輪詢已啟動（interval=15s）")
except Exception as e:
    logger.warning("無法啟動背景輪詢：%s", e)


# ── SocketIO 事件 ──────────────────────────────────────────────────────────────
@socketio.on("request_refresh")
def handle_request_refresh():
    """客戶端手動要求立即刷新報價"""
    logger.info("收到 request_refresh 事件，立即抓取報價")
    watchlist = db.get_watchlist()
    symbols = [w["symbol"] for w in watchlist]
    if not symbols:
        return
    try:
        quotes = crawler.fetch_quotes(symbols)
        alerts = crawler.check_alerts(quotes, _get_watchlist_for_crawler())
        on_update(quotes)
        if alerts:
            on_alert(alerts)
    except Exception as e:
        logger.error("request_refresh 失敗：%s", e)


# ── 頁面路由 ───────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")


# ── REST API ───────────────────────────────────────────────────────────────────
@app.route("/api/watchlist", methods=["GET"])
def get_watchlist():
    """取得監聽清單"""
    return jsonify(db.get_watchlist())


@app.route("/api/watchlist", methods=["POST"])
def add_to_watchlist():
    """新增標的（body: {"symbol": "TSLA", "name": "Tesla Inc.", "threshold": 5.0}）"""
    body = request.get_json(force=True) or {}
    symbol = (body.get("symbol") or "").strip().upper()
    if not symbol:
        return jsonify({"error": "symbol 為必填"}), 400

    name = (body.get("name") or symbol).strip()
    threshold = float(body.get("threshold", 5.0))

    # 先寫入 watchlist，name 後續 crawler fetch 時會自動更新
    db.add_to_watchlist(symbol, name, threshold)
    logger.info("新增監聽標的：%s（門檻 %.1f%%）", symbol, threshold)
    return jsonify({"status": "added", "symbol": symbol}), 201


@app.route("/api/watchlist/<symbol>", methods=["DELETE"])
def remove_from_watchlist(symbol: str):
    """移除標的"""
    db.remove_from_watchlist(symbol.upper())
    logger.info("移除監聽標的：%s", symbol.upper())
    return jsonify({"status": "removed", "symbol": symbol.upper()})


@app.route("/api/watchlist/<symbol>/threshold", methods=["PUT"])
def update_threshold(symbol: str):
    """更新通知門檻（body: {"threshold": 3.0}）"""
    body = request.get_json(force=True) or {}
    threshold = body.get("threshold")
    if threshold is None:
        return jsonify({"error": "threshold 為必填"}), 400
    try:
        threshold = float(threshold)
    except (ValueError, TypeError):
        return jsonify({"error": "threshold 必須為數字"}), 400

    db.update_threshold(symbol.upper(), threshold)
    logger.info("更新門檻：%s → %.1f%%", symbol.upper(), threshold)
    return jsonify({"status": "updated", "symbol": symbol.upper(), "threshold": threshold})


@app.route("/api/quotes", methods=["GET"])
def get_quotes():
    """手動觸發報價抓取，回傳最新報價"""
    watchlist = db.get_watchlist()
    symbols = [w["symbol"] for w in watchlist]
    if not symbols:
        return jsonify({"quotes": [], "count": 0})
    try:
        quotes = crawler.fetch_quotes(symbols)
        alerts = crawler.check_alerts(quotes, _get_watchlist_for_crawler())
        on_update(quotes)
        if alerts:
            on_alert(alerts)
        return jsonify({"quotes": quotes, "count": len(quotes)})
    except Exception as e:
        logger.error("手動抓取報價失敗：%s", e)
        # 即使爬取失敗，仍回傳 DB 中的最新報價
        cached = db.get_latest_prices()
        return jsonify({"quotes": cached, "count": len(cached), "warning": str(e)})


@app.route("/api/alerts", methods=["GET"])
def get_alerts():
    """取得通知歷史（最近 50 筆）"""
    limit = min(int(request.args.get("limit", 50)), 200)
    return jsonify(db.get_alerts(limit=limit))


@app.route("/api/market-status", methods=["GET"])
def market_status():
    """查詢美股是否開盤"""
    try:
        is_open = crawler.is_market_open()
    except Exception:
        is_open = False
    return jsonify({"is_open": is_open})


# ── 啟動 ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5003, debug=True)
