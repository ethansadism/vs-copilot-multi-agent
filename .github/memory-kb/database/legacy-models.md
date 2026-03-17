---
title: legacy-models
type: note
permalink: multi-agent-system/database/legacy-models
---

# Legacy Data Models

mta_demo 的原始資料模型。

## MTA_Demo_Posts Table

- model_name :: MTA_Demo_Posts
- version :: 1.1
- description :: SQLite table for storing Hacker News posts
- project :: mta_demo

### Fields
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | Integer PK | 主鍵 |
| title | Text | 標題 |
| url | Text UNIQUE | URL |
| published_at | Text | 發布時間 |
| crawled_at | Text | 爬取時間（ISO） |

- index :: url

## WebsiteData Table

- model_name :: WebsiteData
- version :: 1.0
- description :: 存儲爬蟲收集的網站數據
- project :: mta_demo

### Fields
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | Integer PK | 主鍵 |
| source_url | String | 來源 URL |
| title | String | 頁面標題 |
| content | Text | 頁面內容 |
| crawled_at | DateTime | 爬蟲時間 |

- index :: source_url, crawled_at

## Relations

- part_of [[Project Overview]]
- data_from [[Hacker News Crawler]]