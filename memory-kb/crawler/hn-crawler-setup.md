---
title: hn-crawler-setup
type: note
permalink: multi-agent-system/crawler/hn-crawler-setup
---

# Hacker News Crawler

Hacker News 爬蟲的實現經驗。

## Problem

- problem_id :: MTA-CRAWLER-001
- title :: Hacker News 爬蟲開發
- description :: 建立 HN Top Stories 爬蟲，使用 RSS + API 雙模式
- solution :: requests + BeautifulSoup 抓取 RSS，fallback 為 HN API
- project :: mta_demo

## Implementation Details

- target_url :: https://news.ycombinator.com/rss
- fallback_api :: https://hacker-news.firebaseio.com/v0/
- parser :: BeautifulSoup4
- data_fields :: title, url, published_at
- storage :: SQLite via Database Expert

## Relations

- part_of [[Project Overview]]
- stored_in [[Legacy Data Models]]