"""
台股即時監看系統 — 主應用程式
Flask + Flask-SocketIO + APScheduler
"""

import logging
from datetime import datetime

from flask import Flask, jsonify, render_template, request
from flask_socketio import SocketIO
from apscheduler.schedulers.background import BackgroundScheduler

from stock_crawler import StockCrawler
from database import StockDatabase

# ── 日誌設定 ──────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
logger = logging.getLogger(__name__)

# ── Flask & SocketIO 初始化 ──────────────────────────────
app = Flask(__name__)
app.config["SECRET_KEY"] = "twstock-monitor-secret"
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="threading")

# ── Database 初始化 ───────────────────────────────────────
db = StockDatabase()


# ── Callback：收到即時股價列表 ────────────────────────────
def on_stock_data(data_list: list[dict]):
    """當 crawler 獲取新數據時，推送到前端並緩存到 DB。

    data_list: crawler 回傳的股價清單，每筆包含 alerts 欄位。
    """
    for data in data_list:
        # 推送即時股價到前端
        socketio.emit("stock_update", data)
        logger.info("股價更新: %s %s", data.get("stock_id"), data.get("current_price"))

        # 處理通知（crawler 已將 alerts 嵌入每筆數據）
        for alert_msg in data.get("alerts", []):
            alert_type = "VOLUME_SPIKE" if "量能" in alert_msg else (
                "PRICE_SURGE" if "漲" in alert_msg else "PRICE_DROP"
            )
            alert_data = {
                "stock_id": data.get("stock_id"),
                "stock_name": data.get("stock_name"),
                "alert_type": alert_type,
                "message": alert_msg,
                "trigger_value": data.get("change_percent", 0),
                "created_at": data.get("timestamp", ""),
            }
            socketio.emit("alert", alert_data)
            db.save_alert(
                data.get("stock_id", ""),
                data.get("stock_name", ""),
                alert_type,
                alert_msg,
                data.get("change_percent", 0),
            )
            logger.info("通知: %s", alert_msg)

    # 將 crawler 欄位名對應到 DB 欄位（change → change_amount）
    db_records = []
    for d in data_list:
        record = dict(d)
        record["change_amount"] = record.pop("change", 0)
        record["recorded_at"] = record.get("timestamp", "")
        db_records.append(record)
    db.buffer_price_data(db_records)


# ── Crawler 初始化（帶 callback）──────────────────────────
crawler = StockCrawler(callback=on_stock_data)

# ── APScheduler：每 1 小時寫入資料庫 ─────────────────────
scheduler = BackgroundScheduler(daemon=True)
scheduler.add_job(db.flush_to_db, "interval", hours=1, id="flush_job")
scheduler.start()
logger.info("排程已啟動：每 1 小時自動寫入 SQLite")


# ── 頁面路由 ──────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")


# ── REST API ──────────────────────────────────────────────
@app.route("/api/watchlist", methods=["GET"])
def get_watchlist():
    """取得目前監看清單。"""
    watchlist = db.get_watchlist()
    return jsonify(watchlist)


@app.route("/api/watchlist", methods=["POST"])
def add_watchlist():
    """新增監看股票。"""
    body = request.get_json(force=True)
    stock_id = body.get("stock_id", "").strip()
    stock_name = body.get("stock_name", "").strip()
    if not stock_id:
        return jsonify({"error": "stock_id 為必填"}), 400

    result = db.add_to_watchlist(stock_id, stock_name)
    # 通知 crawler 開始抓取新股票
    crawler.add_stock(stock_id)
    return jsonify(result), 201


@app.route("/api/watchlist/<stock_id>", methods=["DELETE"])
def remove_watchlist(stock_id: str):
    """移除監看股票。"""
    db.remove_from_watchlist(stock_id)
    crawler.remove_stock(stock_id)
    return jsonify({"status": "removed", "stock_id": stock_id})


@app.route("/api/alerts", methods=["GET"])
def get_alerts():
    """取得最近通知紀錄。"""
    alerts = db.get_recent_alerts(limit=50)
    return jsonify(alerts)


@app.route("/api/history/<stock_id>", methods=["GET"])
def get_history(stock_id: str):
    """取得今日歷史價格。"""
    history = db.get_today_prices(stock_id)
    return jsonify(history)


# ── SocketIO 事件 ─────────────────────────────────────────
@socketio.on("connect")
def handle_connect():
    logger.info("前端已連線")


@socketio.on("disconnect")
def handle_disconnect():
    logger.info("前端已斷線")


# ── 啟動 ──────────────────────────────────────────────────
if __name__ == "__main__":
    # 從 DB 讀取既有監看清單，交給 crawler
    watchlist = db.get_watchlist()
    for item in watchlist:
        crawler.add_stock(item["stock_id"])

    logger.info("啟動即時台股監看系統，port 5001")
    socketio.run(app, host="0.0.0.0", port=5001, debug=True, use_reloader=False)
