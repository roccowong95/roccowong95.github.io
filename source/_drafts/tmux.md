---
title: tmux
date: 2016-09-28 13:23:21
tags:
  - Linux
---

tmux的配置和使用相关的东西
<!--more-->

# 配置文件
- `~/.tmux.conf`

# 基础配置
- 设置tmux通用键
    - `unbind ^b`
    - `set -g prefix ^k`
- 配置窗口从1开始排序
    - `set -g base-index 1`

# 其他功能

### 窗口和面板操作
- `select-pane -[UDLR]`
- `resize-pane -[UDLR] xx`
- `split-window -[hv]`
- `resize-pane -Z`可以最大化或者恢复原样


### 其他
- d detach
- t big clock
- ? help


