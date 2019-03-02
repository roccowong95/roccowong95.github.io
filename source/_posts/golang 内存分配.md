---
category: Digest
created: '2019-02-18T16:35:41.596Z'
description: golang内存分配的简单实现方式学习.
modified: '2019-03-02T19:38:41.782Z'
tags:
- golang
- memory
title: golang 内存分配
---



# 内存划分

span, bitmap, arena. go程序在启动时, 便会申请巨大的空间, 因此go程序的虚拟内存都很大.

## arena

用于实际分配内存. 512GB

## bitmap

该区域用两个bit来描述arena区域的一个指针大小的区域. 因此大小是`512GB/8B*2bit/8bit/B=16GB`. 其存储方式比较特别, 需要注意. 两个bit分别用来表示是否需要继续扫描以及是否包含指针.

![](https://ws2.sinaimg.cn/large/006tKfTcly1g0b1wb8f56j30ii0c7dg4.jpg)

![](https://ws2.sinaimg.cn/large/006tKfTcly1g0b1xn1amnj30ox04pmxa.jpg)

## span

span区域存储的是指向mspan对象的指针, 用于表示arena中的某一页(8KB)属于哪个span.
因此span区的大小是`512GB/8KB*8B=512MB`.

管理span的数据结构叫做mcentral, 而每个goroutine又有自己的mcentral中部分span的缓存, 叫做mcache. 由于mcache是goroutine独立的, 因此对于mcache的操作是无需加锁的.

```go
type mcache struct {
	alloc [67*2]*mspan // 按class分组的mspan列表
}

type mcentral struct {
	lock      mutex     //互斥锁
	spanclass spanClass // span class ID
	nonempty  mSpanList // non-empty 指还有空闲块的span列表
	empty     mSpanList // 指没有空闲块的span列表

	nmalloc uint64      // 已累计分配的对象个数
}
```

mcache中存在`67*2`个span, 是class数量的两倍, 分别存放内部有指针和没有指针的对象. 而每个mcentral对象只负责管理一个class的span. 所有mcentral的集合存放于mheap数据结构中.


```go
type mheap struct {
	lock      mutex

	spans []*mspan

	bitmap        uintptr 	//指向bitmap首地址，bitmap是从高地址向低地址增长的

	arena_start uintptr		//指示arena区首地址
	arena_used  uintptr		//指示arena区已使用地址位置

	central [67*2]struct {
		mcentral mcentral
		pad      [sys.CacheLineSize - unsafe.Sizeof(mcentral{})%sys.CacheLineSize]byte
	}
}
```

* 申请堆内存时, 会首先从mcache中看对应的class下是否有空闲.
* 如果mcache中没有空闲, 则从mcentral中申请span, 放入mcache中.
* 否则从mheap中申请一个span, 放入mcentral, 再放入mcache.
* 读取空闲的地址并且返回.

# 什么时候从heap分配对象

* 返回对象的指针.
* 传递了对象的指针到其他的函数.
* 在闭包中使用了对象, 并需要修改.
* 使用了new.

决定是否使用堆来分配对象, 叫做逃逸分析(src/cmd/compile/gc/esc.go).

# 逃逸分析

# 参考

* [Go 内存管理 - 恋恋美食的个人空间 - 开源中国][1]
* [Escape Analysis in Go][2]
* [Golang源码探索(三) GC的实现原理 - q303248153 - 博客园][3]
* [Go Memory Management - Povilas Versockas][4]

[1]:https://my.oschina.net/renhc/blog/2236782?spm=a2c4e.11153940.blogcont652551.13.3e3f2219ZdhTmm
[2]:https://scvalex.net/posts/29/
[3]:http://www.cnblogs.com/zkweb/p/7880099.html
[4]:https://povilasv.me/go-memory-management/