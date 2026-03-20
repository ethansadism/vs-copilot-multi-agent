---
title: github-trending-ui
type: note
permalink: multi-agent-system/frontend/github-trending-ui
tags:
- frontend
- mta_demo3
- github-trending
- dashboard
---

# GitHub Trending UI

mta_demo3 GitHub Trending Dashboard 前端實現。

## Observations

- project :: mta_demo3
- framework :: Flask + Jinja2 + Vanilla JS
- theme :: GitHub 深色主題（背景 #0d1117）
- layout :: CSS Grid，桌面 3 欄 / 平板 2 欄 / 手機 1 欄
- filter :: 語言篩選下拉，JavaScript 即時過濾，不需後端
- badge_color :: djb2 hash 從語言名稱生成 HSL 色相，同語言永遠同色
- template_engine :: Jinja2（repos list + last_updated 傳入）
- refresh_action :: POST /refresh，點擊後有 loading 狀態
- empty_state :: repos 空時顯示提示文字
- stats_highlight :: stars_today 用金色漸層 badge 突顯

## Design Decisions

- lang_badge_hue :: djb2 hash mod 360 → HSL 色彩（bg 透明度 45%，文字 L=75%）
- rank_badge :: 絕對定位於卡片右上角
- hover_effect :: translateY(-3px) + 頂部漸層光條（opacity 0→1）
- sticky_header :: position: sticky top:0 z-index 100
- format_number :: 使用 Jinja2 filter `format_number`（需後端實現），若無 fallback 為 raw int

## Relations

- part_of [[Dashboard Design System]]
- relates_to [[Component Library]]
