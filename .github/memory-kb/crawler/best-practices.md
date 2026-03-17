---
title: best-practices
type: note
permalink: multi-agent-system/crawler/best-practices
---

# Crawler Best Practices

爬蟲開發的最佳實踐與工具清單。

## Anti-Detection

- user_agent :: 每次請求隨機 User-Agent（維護 UA 池）
- request_delay :: 隨機延遲 1-3 秒（避免固定間隔被偵測）
- rate_limit :: 對同一 domain 限制每分鐘最多 10 次請求
- robots_txt :: 必須遵守 robots.txt 規範

## Error Handling

- retry_strategy :: 指數退避（1s → 2s → 4s → 8s），最多重試 3 次
- fallback :: HTML 結構變動時使用多選擇器 fallback + demo data 降級
- ssl_fallback :: TWSE 等可信來源可 fallback 為 verify=False

## Data Quality

- deduplication :: 用 URL 或唯一 ID 去重
- validation :: 檢查必要欄位非空
- encoding :: 統一使用 UTF-8
- timestamp :: 每筆資料記錄 crawled_at（ISO 格式）

## Session Management

- cookie :: 需要登入的站點使用 Session 管理 + Cookie 持久化
- proxy_rotation :: 每 N 個請求輪換 proxy

## TWSE Specific

- twse_api :: https://mis.twse.com.tw/stock/api/getStockInfo.jsp
- twse_query :: ex_ch=tse_{stock_id}.tw 或 otc_{stock_id}.tw
- twse_ssl :: Python 3.13+ 需要 SSL fallback（見 [[TWSE API SSL Fallback]]）

## Crawled Websites

| 網站 | 用途 | 專案 |
|------|------|------|
| Hacker News | Tech news 爬蟲 | mta_demo |
| TWSE API | 台股即時報價 | mta_demo2 |

## Tools and Libraries

- requests :: HTTP 請求基礎庫
- BeautifulSoup4 :: HTML 解析
- Selenium :: 瀏覽器自動化（JS 渲染）
- Playwright :: 現代 headless browser（推薦）
- rotating-proxy :: Proxy 輪換

## Relations

- used_by [[Crawler Expert]]
- relates_to [[Proxy IP Block Solution]]
- relates_to [[JavaScript Rendering Solution]]
- relates_to [[TWSE API SSL Fallback]]