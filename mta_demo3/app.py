import logging
import os

from flask import Flask, jsonify, redirect, render_template, request, url_for

from database import get_latest_batch, init_db, save_repos
from github_crawler import fetch_trending

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "trending.db")

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _format_last_updated(repos: list[dict]) -> str:
    if not repos:
        return "No data yet"

    timestamps = [repo.get("crawled_at", "") for repo in repos if repo.get("crawled_at")]
    if not timestamps:
        return "No data yet"

    return max(timestamps)


@app.template_filter("format_number")
def format_number(value):
    try:
        return f"{int(value):,}"
    except (TypeError, ValueError):
        return "0"


@app.route("/", methods=["GET"])
def index():
    repos = get_latest_batch(DB_PATH)
    last_updated = _format_last_updated(repos)
    return render_template("index.html", repos=repos, last_updated=last_updated)


@app.route("/refresh", methods=["POST"])
def refresh():
    try:
        repos = fetch_trending()
        if repos:
            save_repos(repos, DB_PATH)
            logger.info("Refresh completed. Saved %d repos.", len(repos))
        else:
            logger.warning("Refresh completed with empty repo list.")
    except Exception:
        logger.exception("Refresh failed")

    return redirect(url_for("index"))


@app.route("/api/repos", methods=["GET"])
def api_repos():
    repos = get_latest_batch(DB_PATH)
    language = (request.args.get("language") or "").strip()

    if language:
        language_lower = language.lower()
        repos = [
            repo
            for repo in repos
            if (repo.get("language") or "").strip().lower() == language_lower
        ]

    last_updated = _format_last_updated(repos)
    return jsonify({
        "repos": repos,
        "count": len(repos),
        "last_updated": last_updated,
    })


init_db(DB_PATH)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=True)
