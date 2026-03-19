---
title: github-trending-crawler
type: note
permalink: multi-agent-system/crawler/github-trending-crawler
tags:
- github
- trending
- crawler
- mta_demo3
---

# GitHub Trending Crawler

mta_demo3 的 GitHub Trending 爬蟲實現經驗。

## Observations

- project :: mta_demo3
- file :: mta_demo3/github_crawler.py
- target_url :: https://github.com/trending
- method :: requests + BeautifulSoup4（靜態頁面，不需要 JS 渲染）
- tested_date :: 2026-03-17
- result :: 成功爬取 12 筆 repo

## CSS Selectors（截至 2026-03）

- container :: article.Box-row（fallback: article）
- repo_link :: h2 a[href]（格式 /author/repo）
- description :: p.col-9（fallback: p）
- language :: span[itemprop="programmingLanguage"]
- total_stars :: a.Link--muted（第 1 個）
- forks :: a.Link--muted（第 2 個）
- stars_today :: span 內文含 "stars today/week/month"，regex `([\d,]+)\s+stars`

## Known Issues

- github_trending_count :: GitHub 有時回傳 12 筆而非 25 筆，屬正常行為
- stars_today_selector :: 需 regex 擷取，不能直接取文字節點

## Error Handling

- retry_strategy :: 指數退避，最多 3 次（1s → 2s → 4s + jitter）
- ip_block_fallback :: 爬取失敗時回傳 10 筆 DEMO_DATA（PROXY-001）
- empty_parse_fallback :: 解析結果為空時也回傳 DEMO_DATA

## Relations

- relates_to [[Crawler Best Practices]]
- relates_to [[Proxy IP Block Solution]]
- part_of [[Project Overview]]

## Report File

- report_path :: .github/reports/crawler-report.md（已附加至現有報告）
