---
title: docker镜像的制作

tags:
- docker
  
categories:
- Learn
  
date: 2017-09-24 18:31:13
comments: false
visible: yes
sticky: 0
---

# docker镜像
docker镜像是一个特殊的静<a id="3.1"></a>态文件. 通过dockerfile, 可以构建一个docker镜像, 其提供了容器运行时需要的文件, 包含一些运行时的配置. docker镜像的内容是不会改变的, 容器所有的操作, 本质上都是在docker镜像的只读层上的可写层的操作.
本文是在学习dockerfile编写时的心路历程.

<!--more-->

# docker file
类似于makefile, dockerfile可以指导docker构建一个镜像.

# dockerfile的常用命令
## FROM
FROM命令指定了该镜像的基础镜像.

## RUN
.

## COPY
.

# dockerfile的构建
我们采用一个示例dockerfile, 来构建一个镜像试试.
构建过程如下:
![](/media/15062698462780.jpg)

可以看出:

我们首先是需要把文件给docker daemon给传输过去的. 从这里我们可以清楚的看出, 使用的docker命令其实相当于只是一个client, 实际的build操作, 是在daemon里面进行的, 这个daemon可以是本机的, 也可以是远程的. 那么哪些文件需要传输呢? 
我们利用的基础镜像是nginx, 所以step1的

## dockerfile的构建上下文
我们刚刚执行的命令是`docker build -t nginx:v3 .`, 最后一个参数, 其实就是`上下文`, 也就是需要传输给daemon的文件夹.

# 参考
* [Docker —— 从入门到实践](https://yeasy.gitbooks.io/docker_practice/)

