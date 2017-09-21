---
title: Golang学习笔记
date: 2016-09-22 09:48:14
tags:
  - Go
---

学 go 的时候怕记不住的语法啥的
<!--more-->

# 参考链接
- [go-web编程之处理json][1]
- [求教一个Unmarshal JSON的问题][2]
- [JSON处理][3]
- [文件处理][4]
- [Go如何比较时间大小][5]

---

# 流程控制

## 循环

## switch
- 空的 switch 语句可以当做是一个写很长的 if else 的方法


## defer
- defer 把接下来的这句语句推迟到所在函数运行结束时候再运行
- defer 里面的参数是立即生效的, 但是运行是推迟的
- 几个 stack 的 defer 会堆叠在栈里面, 后进先出


# 数据类型
## 参考

## 指针
- 指针通过dot可以直接访问结构体的成员, **而不用->**


## 列表
- 声明: `var a [10]int`
- 初始化: `a := [5]int{2, 3, 5, 7}`, 未初始化的被初始化为默认值


## 切片
- `s := a[3:5]`里面有2个元素, 含左不含右
- 切片用 %T 来看的话, 是`[]int`这种, 而数组是`[size]int`, 大小是固定的
- 切片像引用, 当多个切片是从同一个数组出来的时候, 切片的改动会影响原数组和其他切片
- `s := []int{1, 2, 3}`创建一个切片, 指向一个匿名的数组
- `cap(s []T)`显示切片指向的数组的大小, `len(s []T)`显示切片的大小
- `s = s[2:]`这样的操作会改变capacity, `s = s[:2]`这样的不会, 因为`[2:]`舍弃的是前面的成员, 无法再找回了


## nil
- nil的type是<nil>
- 一个没有指向任何数组的切片就是一个nil
- nil的len和cap都是0
- `var s = []int`来构造一个nil, `s := []int{}`不行, 虽然它的cap和len也是0


## 接口
- 空接口
    - 作用
    - 用法

---

# 并发

## goroutine

## channel
- channel默认是没有缓冲的
- 所以

---

# 其他

- 变量初始化和声明

    ```Go
    //下面这个是不行的
    a, b := 1, 2
    a := 3
    //但是这个是可以的
    a, b := 1, 2
    c, a := 3, 3
    ```


[1]:https://my.oschina.net/lucasz/blog/87442
[2]:http://golangtc.com/t/55f78ddcb09ecc7a4200006f
[3]:https://github.com/astaxie/build-web-application-with-golang/blob/master/zh/07.2.md
[4]:http://www.cnblogs.com/MikeZhang/archive/2012/02/17/fileOperationsGolang.html
[5]:https://fukun.org/archives/03212466.html

