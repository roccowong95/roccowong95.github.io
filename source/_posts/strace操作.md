---
title: strace操作
tags:
- Linux
- 运维
---

# 简介
`strace`命令可以查看系统调用和信号等等信息.

<!--more-->

# 常用选项和参数
- `-p`: 追踪指定进程, 需要带上`-f`选项来追踪所有的子进程
- `-c`: 进行统计, 输出统计结果
- `-d`: 输出一些关于strace本身的信息, 输出到stderr上
- `-f`: 跟踪因为fork产生的子进程, `-F`可以追踪由vfork产生的子进程, 但是vfork不怎么用了
- `-ff`: 如果使用了`-o`选项, 那么会将跟踪结果输出到对应的`filename.pid`里面
- `-i`: 输出系统调用的入口指针位置
- `-t, -tt, -ttt`: 在每一行加上时间信息, 精度不同, 后面两个是微秒级
- `-T`: 显示每一个系统调用花费的时间
- `-e`: 根据后面的表达式进行筛选
    - 规则是`-e [qualifier=][!]value1[,value2]...`
    - `qualifier`有trace, abbrev, verbose, raw, signal, read, write, 默认是trace
- `-o`: 选择输出位置
- `-a`: 选择返回值的输出位置, 默认是第40列
- `-s`: 指定输出字符串的最大长度, 默认是32, 文件名一直全部输出
- `-u`: 以username的UID和GID执行被跟踪的命令

# 参考
[strace(1) - Linux man page][1]

[1]:http://linux.die.net/man/1/strace


