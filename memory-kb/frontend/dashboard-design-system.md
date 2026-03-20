---
title: dashboard-design-system
type: note
permalink: multi-agent-system/frontend/dashboard-design-system
---

# Dashboard Design System

前端設計系統規範。

## Design System v1.1

- name :: Dashboard Design System v1.1
- patterns :: Flask + Vanilla JS implementation, Polling via setInterval(30s) for data updates

## Color Palette

- primary :: #007ACC
- accent :: #FF6B6B
- background :: #1E1E1E（深色主題）
- dark_theme :: #1a1a2e（mta_demo2）
- text :: #FFFFFF
- stock_up :: 紅色（台股紅漲）
- stock_down :: 綠色（台股綠跌）

## Typography

- heading_font :: Segoe UI
- body_font :: Segoe UI
- base_size :: 14px

## Layout

- responsive :: CSS Grid + Flexbox
- mobile_support :: 響應式設計（桌面 + 手機）
- accessibility :: 符合 WCAG 2.1 AA 標準

## Relations

- used_by [[Frontend Engineer]]
- part_of [[Project Overview]]
- relates_to [[Stock Monitoring UI]]