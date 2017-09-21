---
title: gdb复习
tags:
  - Linux
  - C/C++
  - gdb
date: 2016-08-10 09:41:18
---

复习 gdb 的一些常用调试操作
<!--more-->


# 参考
- Linux C 编程一站式学习

---

# 开始
- 在gcc编译时一定要用`-g`选项才可以用gdb进行调试
- `list <line_number>/<function_name>`可以查看指定行号开始或者函数的代码
- 注意在调试过程中可以调用函数

# 调试过程
## 单步调试
- `n(next)`: 一句一句执行, 不会进入调用的函数
- `s(step)`: 会进入调用的函数等
- `bt(backtrace)`: 查看调用栈
    - `br full`: 查看完整的栈
- `f <frame number>`: 选择栈
- `i locals`: 显示当前栈的局部变量
- `finish`: 执行直到当前函数运行完成
- `until <line_number>`: 直到
- `set var=n`: 直接设置变量的值

## 断点/观察点
- `display/undisplay <variable>`: 每次停下来的时候都会显示指定的变量/取消显示
- `b(break) <line_number>/<function_name>`: 设置断点
    - `b if sum != 0`: 设置条件断点
- `d(delete) <id>`: 删除断点, 无参数表示删除所有断点
- `clear <line_number>`: 删除指定行的断点
- `c`: 运行到断点, 连续执行
- `i breakpoints`: 显示断点相关信息
- `enable/disable <id>`: 启用/禁用断点
- `r`: 从头开始连续执行
- `x/FMT <add>/<var>`: 以指定格式显示一个位置的值
    - FMT由数字, 格式字符, size字符标识, 如7xb, 8ow
    - size字符表示一次显示多大的区间
        - b: 字节
        - h: 半字
        - w: 字
        - g: 大字😂(giant, 8字节)
    - 格式字符表明将该值读取为什么东西
        - o: 8进制
        - x: 16进制
        - d: 小数
        - u: 无符号整数
        - t: 2进制
        - f: 浮点
        - a: 地址
        - i: 指令
        - c: 字符
        - s: 字符串
        - z: 16进制, 左边加0填充
- `watch <var>`: 观察一个变量, 当它变了的时候gdb会中断, 如`watch input[5]`
- `i watchpoints`: 显示所有观察点相关信息

## 其他
- `layout`: 分割界面, 可以一边看代码一边调试
- `layout src`: 显示源代码窗口
- `layout asm`: 显示反汇编代码窗口
- `layout regs`: 显示代码和寄存器窗口
- `set follow-fork-mode child/parent`: 设置遇到多进程时的行为


