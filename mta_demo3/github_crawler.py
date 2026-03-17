"""
GitHub Trending 爬蟲

爬取 https://github.com/trending 頁面，解析熱門 repository 資訊。
使用 requests + BeautifulSoup4，支援隨機 UA、指數退避重試與 demo data 降級。
"""

import time
import random
import logging
import re
from datetime import datetime, timezone

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

# ── User-Agent 池（至少 5 個不同瀏覽器 UA，避免被 GitHub 識別） ──────────────
UA_POOL = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/121.0.0.0 Safari/537.36",
]

GITHUB_TRENDING_URL = "https://github.com/trending"

# ── Demo data（HTML 結構變動或 IP 被封時的降級資料） ────────────────────────
DEMO_DATA = [
    {
        "author": "microsoft",
        "repo_name": "vscode",
        "full_name": "microsoft/vscode",
        "description": "Visual Studio Code",
        "language": "TypeScript",
        "stars_today": 150,
        "total_stars": 162000,
        "forks": 28000,
        "repo_url": "https://github.com/microsoft/vscode",
        "crawled_at": "",
    },
    {
        "author": "openai",
        "repo_name": "openai-python",
        "full_name": "openai/openai-python",
        "description": "The official Python library for the OpenAI API",
        "language": "Python",
        "stars_today": 120,
        "total_stars": 23000,
        "forks": 3200,
        "repo_url": "https://github.com/openai/openai-python",
        "crawled_at": "",
    },
    {
        "author": "facebook",
        "repo_name": "react",
        "full_name": "facebook/react",
        "description": "The library for web and native user interfaces.",
        "language": "JavaScript",
        "stars_today": 200,
        "total_stars": 222000,
        "forks": 45000,
        "repo_url": "https://github.com/facebook/react",
        "crawled_at": "",
    },
    {
        "author": "google",
        "repo_name": "gemma",
        "full_name": "google/gemma",
        "description": "Gemma is a family of lightweight, state-of-the-art open models.",
        "language": "Python",
        "stars_today": 300,
        "total_stars": 8500,
        "forks": 900,
        "repo_url": "https://github.com/google/gemma",
        "crawled_at": "",
    },
    {
        "author": "rust-lang",
        "repo_name": "rust",
        "full_name": "rust-lang/rust",
        "description": "Empowering everyone to build reliable and efficient software.",
        "language": "Rust",
        "stars_today": 80,
        "total_stars": 94000,
        "forks": 12000,
        "repo_url": "https://github.com/rust-lang/rust",
        "crawled_at": "",
    },
    {
        "author": "torvalds",
        "repo_name": "linux",
        "full_name": "torvalds/linux",
        "description": "Linux kernel source tree",
        "language": "C",
        "stars_today": 60,
        "total_stars": 178000,
        "forks": 52000,
        "repo_url": "https://github.com/torvalds/linux",
        "crawled_at": "",
    },
    {
        "author": "vercel",
        "repo_name": "next.js",
        "full_name": "vercel/next.js",
        "description": "The React Framework",
        "language": "JavaScript",
        "stars_today": 110,
        "total_stars": 121000,
        "forks": 26000,
        "repo_url": "https://github.com/vercel/next.js",
        "crawled_at": "",
    },
    {
        "author": "astral-sh",
        "repo_name": "uv",
        "full_name": "astral-sh/uv",
        "description": "An extremely fast Python package and project manager, written in Rust.",
        "language": "Rust",
        "stars_today": 250,
        "total_stars": 28000,
        "forks": 800,
        "repo_url": "https://github.com/astral-sh/uv",
        "crawled_at": "",
    },
    {
        "author": "golang",
        "repo_name": "go",
        "full_name": "golang/go",
        "description": "The Go programming language",
        "language": "Go",
        "stars_today": 55,
        "total_stars": 122000,
        "forks": 17400,
        "repo_url": "https://github.com/golang/go",
        "crawled_at": "",
    },
    {
        "author": "apache",
        "repo_name": "spark",
        "full_name": "apache/spark",
        "description": "Apache Spark - A unified analytics engine for large-scale data processing.",
        "language": "Scala",
        "stars_today": 40,
        "total_stars": 39000,
        "forks": 27000,
        "repo_url": "https://github.com/apache/spark",
        "crawled_at": "",
    },
]


def _safe_int(text: str, default: int = 0) -> int:
    """移除逗號、空白後轉為整數，失敗回傳預設值。"""
    if not text:
        return default
    cleaned = re.sub(r"[,\s]", "", text.strip())
    try:
        return int(cleaned)
    except (ValueError, TypeError):
        return default


def _now_iso() -> str:
    """回傳目前時間的 ISO 8601 字串（UTC）。"""
    return datetime.now(timezone.utc).isoformat()


def _get_headers() -> dict:
    """隨機選取 UA 組成請求標頭。"""
    return {
        "User-Agent": random.choice(UA_POOL),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
    }


def _fetch_with_retry(url: str, max_retries: int = 3, timeout: int = 15) -> requests.Response:
    """
    以指數退避策略重試 HTTP GET 請求。
    失敗超過 max_retries 次時拋出最後一次的例外。
    """
    last_exc: Exception = RuntimeError("未曾發出請求")
    for attempt in range(max_retries):
        try:
            resp = requests.get(url, headers=_get_headers(), timeout=timeout)
            resp.raise_for_status()
            return resp
        except requests.RequestException as exc:
            last_exc = exc
            wait = (2 ** attempt) + random.uniform(0, 1)  # 1s → 2s → 4s + jitter
            logger.warning("第 %d 次請求失敗（%s），%.1f 秒後重試…", attempt + 1, exc, wait)
            time.sleep(wait)
    raise last_exc


def _parse_trending_html(html: str, base_url: str = "https://github.com") -> list[dict]:
    """
    解析 GitHub Trending HTML，回傳 repo 字典列表。

    GitHub Trending HTML 結構（截至 2026-03）：
      容器：article.Box-row
        repo 連結：h2 a[href]           → /author/repo
        描述：     p.col-9              → 描述文字
        語言：     span[itemprop="programmingLanguage"]
        stars/forks：a.Link--muted（第1個=stars，第2個=forks）
        stars today：span.d-inline-block-count 內最後出現「stars today」的父 span
                     或 f3 class 附近的數字 + "stars today" 文字
    """
    soup = BeautifulSoup(html, "html.parser")
    repos = []
    now = _now_iso()

    # 主要選擇器：article.Box-row；若 GitHub 改版，fallback 到 article
    articles = soup.select("article.Box-row")
    if not articles:
        logger.warning("找不到 article.Box-row，嘗試 fallback 選擇器 article")
        articles = soup.select("article")

    for art in articles:
        try:
            # ── repo 路徑 → author / repo_name ──────────────────────────
            link_tag = art.select_one("h2 a")
            if not link_tag:
                continue
            href = link_tag.get("href", "").strip("/")
            parts = href.split("/")
            if len(parts) < 2:
                continue
            author = parts[0]
            repo_name = parts[1]
            full_name = f"{author}/{repo_name}"
            repo_url = f"{base_url}/{full_name}"

            # ── 描述 ──────────────────────────────────────────────────────
            desc_tag = art.select_one("p.col-9") or art.select_one("p")
            description = desc_tag.get_text(strip=True) if desc_tag else ""

            # ── 程式語言 ──────────────────────────────────────────────────
            lang_tag = art.select_one('span[itemprop="programmingLanguage"]')
            language = lang_tag.get_text(strip=True) if lang_tag else ""

            # ── Total stars / forks（前兩個 a.Link--muted） ───────────────
            muted_links = art.select("a.Link--muted")
            total_stars = _safe_int(muted_links[0].get_text(strip=True)) if len(muted_links) > 0 else 0
            forks = _safe_int(muted_links[1].get_text(strip=True)) if len(muted_links) > 1 else 0

            # ── Stars today ───────────────────────────────────────────────
            stars_today = 0
            # GitHub 通常在 <span class="d-inline-block float-sm-right"> 裡標示
            # 完整文字形如 "150 stars today" 或 "150 stars this week"
            for span in art.select("span"):
                txt = span.get_text(separator=" ", strip=True)
                if "stars" in txt.lower() and ("today" in txt.lower() or "week" in txt.lower() or "month" in txt.lower()):
                    # 擷取第一個數字
                    m = re.search(r"([\d,]+)\s+stars", txt)
                    if m:
                        stars_today = _safe_int(m.group(1))
                        break

            repos.append({
                "author": author,
                "repo_name": repo_name,
                "full_name": full_name,
                "description": description,
                "language": language,
                "stars_today": stars_today,
                "total_stars": total_stars,
                "forks": forks,
                "repo_url": repo_url,
                "crawled_at": now,
            })
        except Exception as exc:
            logger.warning("解析單筆 repo 失敗：%s", exc)
            continue

    return repos


def fetch_trending(language: str = "", since: str = "daily") -> list[dict]:
    """
    爬取 GitHub Trending 頁面。

    Args:
        language: 篩選特定語言（空字串 = 全部）。例如 "python"、"typescript"。
        since:    時間範圍，"daily" | "weekly" | "monthly"，預設 "daily"。

    Returns:
        list[dict]，每筆包含以下欄位：
          author, repo_name, full_name, description, language,
          stars_today, total_stars, forks, repo_url, crawled_at

        若爬取或解析失敗（IP 封鎖等），回傳 DEMO_DATA（含 crawled_at 時間戳）。
    """
    # 建構 URL
    url = GITHUB_TRENDING_URL
    if language:
        url = f"{url}/{language.lower()}"
    params_str = f"?since={since}"
    url = url + params_str

    logger.info("開始爬取 GitHub Trending：%s", url)

    try:
        resp = _fetch_with_retry(url)
        repos = _parse_trending_html(resp.text)

        if not repos:
            logger.warning("解析結果為空，HTML 結構可能已變動，改用 demo data")
            return _demo_with_timestamp()

        logger.info("成功爬取 %d 筆 repo", len(repos))
        return repos

    except Exception as exc:
        # PROXY-001：IP 被封或其他網路錯誤，降級回傳 demo data
        logger.error("爬取失敗（%s），回傳 demo data", exc)
        return _demo_with_timestamp()


def _demo_with_timestamp() -> list[dict]:
    """回傳含當前時間戳的 demo data 副本。"""
    now = _now_iso()
    result = []
    for item in DEMO_DATA:
        entry = dict(item)
        entry["crawled_at"] = now
        result.append(entry)
    return result


# ── 手動測試入口 ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    print("── 爬取 GitHub Trending（daily，全語言）──")
    data = fetch_trending()
    for i, repo in enumerate(data[:5], 1):
        print(
            f"  {i:2}. {repo['full_name']:<40} "
            f"★ {repo['total_stars']:>7,}  "
            f"▲ {repo['stars_today']:>5} today  "
            f"[{repo['language']}]"
        )
    print(f"\n共 {len(data)} 筆，crawled_at = {data[0]['crawled_at']}")
