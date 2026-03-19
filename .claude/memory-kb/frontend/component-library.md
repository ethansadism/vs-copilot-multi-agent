---
title: component-library
type: note
permalink: multi-agent-system/frontend/component-library
---

# Component Library

可複用的前端組件清單。

## DataTable

- component :: DataTable
- description :: 通用數據表組件
- features :: Sorting, Filtering, Pagination
- reusable :: true

## StatusCard

- component :: StatusCard
- description :: 系統狀態卡片
- reusable :: true

## StockCard

- component :: StockCard
- description :: 即時股價卡片（漲跌色標、千分位、hover 放大）
- project :: mta_demo2
- reusable :: true

## AlertList

- component :: AlertList
- description :: 即時通知區域（最多 50 筆、自動捲動）
- project :: mta_demo2
- reusable :: true

## WatchlistManager

- component :: WatchlistManager
- description :: 監看清單管理（新增/移除股票標籤）
- project :: mta_demo2
- reusable :: true

## Relations

- used_by [[Frontend Engineer]]
- part_of [[Stock Monitoring UI]]
- styled_by [[Dashboard Design System]]