---
title: 内存杂烩
date: 2019-02-04 15:41:55
tags: [Linux]
category: [digest]
description: 内存相关内容.
---

# x86架构下的分段机制

![](https://ws3.sinaimg.cn/large/006tNbRwly1fy49et602cj302n0ajt8h.jpg)

* 代码段(text): 存放可执行指令. 出于安全原因, 代码段只读.
* 数据段(data): 已初始化的变量和全局变量.
* BSS端(block started by symbol): 未初始化变量, 全是0.
* 栈(stack): 函数调用栈, 上下文, 参数, 返回值.
* 堆(heap): 可以由进程动态分配.

# 内存寻址过程

![](https://ws2.sinaimg.cn/large/006tNbRwly1fy3ckwaxf8j30qc0k4q4o.jpg)

当一条指令需要访问内存时, 会由逻辑地址-> 线性地址(虚拟地址)-> 物理内存地址, 最终得到真正需要读取的内存地址.

## 三类地址
### 逻辑地址
逻辑地址由段选择码(segment selector)和偏移量(offset)组成.
![](https://ws3.sinaimg.cn/large/006tNbRwly1fy3ecqix4uj30ma0a2wfh.jpg)

### 线性地址
虚拟地址是进程视角的内存地址.

### 物理地址
实际上真正需要读取的内存的地址.

## 几个寄存器
下面几个寄存器用来存放段选择码. 都是16位. 15-3(index)存放 GDT 或者 LDT 表中的下标. 2(TI)存放 GDT 还是 LDT. 1-0(RPL)存放权限信息, linux 下只有0和3, 分别是内核级和用户级.
* CS: 保存 code segment selector.
* SS: 保存 stack segment selector.
* DS: 保存 data segment selector.
* ES, FS, GS: 随便用.

下面两个用于快速寻找段描述符表.
* GDTR: 存放 GDT 表的位置和大小.
* LDTR: 存放 LDT 表的位置和大小.

## 几个表
每个段都由8字节的段描述符来表示. 段描述符存放在 GDT(Global Descriptor Table) 或者 LDT(Local Descriptor Table) 中. 顾名思义, 一般只有一个 GDT 表, 而每个进程可以有自己的 LDT 表.
GDT,LDT 表的位置和大小, 存放在GDTR,LDTR 寄存器里.

## 逻辑地址->线性地址(段机制)

![](https://ws1.sinaimg.cn/large/006tNbRwly1fy4hveyb98j30ni0dqwfn.jpg)

1. 根据指令性质, 决定去读哪个段寄存器(CS, ES, DS, FS, GS, SS)中的段选择码.
2. 根据选择码中的TI确定需要去哪张表(GDT, LDT)找段描述符, 以及去读哪个寄存器(GDTR, LDTR).
2. 找到地址描述符, 
    * 根据信息判断是否越界.
    * 判断是否越权.
4. 描述符中的 base addr+指令中的 offset, 得到线性地址.

![](https://ws1.sinaimg.cn/large/006tNbRwly1fy4hlkzp7mj30se0fgab8.jpg)

如上图所示, linux 中只使用了代码段和数据段, 再往下深究可以发现, 代码段和数据段的起始线性地址都是0x00000000, 段限都是0xfffffff(4GB), 这样逻辑地址在计算后会得到与之相同的线性(虚拟)地址, 实际上就是偏移(offset). 具体的分析可以看上面的[Linux_Memory_Address_Mapping.pdf](http://www.ilinuxkernel.com/files/Linux_Memory_Address_Mapping.pdf).

早期的 x86 架构下, offset 不足以直接表述内存, 所以采用了分段, 现代处理器的 offset 达到了32位, 已经足够覆盖4GB的内存空间了, 分段就没什么必要了.

## 线性地址->物理地址(页机制)

![](https://ws4.sinaimg.cn/large/006tNbRwly1fy4l978dwvj30ve0ieq4n.jpg)
上面的 cr3寄存器, 保存在每个进程的mm_struct 数据结构中.
线性地址是连续的, 实际上并不是. 分页机制使得内存分配更为灵活, 并且允许进程的线性地址空间比物理内存大.
32位的情况下, 我们的进程虚拟内存空间最大就4GB, 所以32位机器的物理内存如果再大的话, 也没啥用了(启用 PAE 扩展的情况下, 可以使物理总线达到36根, 从而能够允许进程访问64GB 的虚拟内存. [PAE可以看这里][4]).
但64位的情况下, 虚拟内存空间有2^64这么大, 物理内存就很难跟上了, 我们必须分页. 分页又带来一个问题, 我们需要保存每个页的实际位置, 这个信息在64位情况下也非常大. 如果我们只有一级页表, 物理内存甚至放不下. 所以需要多级页表, 最终使得最高层的页表足够小, 这样我们总能通过最高层页表一级一级找到需要的数据(数据和页表都可能被 swap 出去).


# 内存管理

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fy53m82cicj30e20900sp.jpg)

## numa

uma 架构下, 所有 cpu 访问内存走的是一组总线, 这样很容易导致瓶颈发生.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fy4y1pyc1cj30nj0dyq3j.jpg)

numa架构下, 处理器与几个内存相关联, 组成 node, node又进一步分为若干 zone. node 内部的访问很快, node 之间的访问会慢一些, 这样整体提高了吞吐量, 但也会带来一些问题, 可能会导致内存在不同的 node 间分布不均. 见[这里][16].

![](https://ws1.sinaimg.cn/large/006tNbRwly1fy4z1egistj308b0bh3yf.jpg)

每个 node 有一个 kswapd 进程, 来管理内存页的回收.

* 当 pages_free<pages_min时, 申请内存的进程需要等待内存回收(同步回收).
* 当 pages_min<pages_free<pages_low时, kswapd被唤醒, 开始进行异步回收.
* 当 pages_free>pages_high时, kswapd 被关闭.

## /proc/meminfo

* memfree: 尚未使用的内存.
* memavailable: **估计值**. 会用 memfree 加上预估的, 可以回收的内存. 如 cached, slab.
* buffers 表示块设备(block device)所占用的缓存页，包括：直接读写块设备、以及文件系统元数据(metadata)比如SuperBlock所使用的缓存页；
* cached: 表示普通文件数据所占用的缓存页([file-backed pages][18]).
* swap cache: 匿名页的缓存. 进程的内存页分两种, 一个与文件对应的内存页, 一个是匿名内存页, 如 malloc 调用申请的. 与文件对应的内存页(mmap将文件映射进内存)在 pageout 和 pagein 的时候, 直接操作文件, 但匿名内存页没有文件对应, 需要写进交换区, 在 pageout 和 pagein 时, 会写入 swap cache.

## 伙伴算法

![](https://ws1.sinaimg.cn/large/006tNbRwly1fy4m1av5y4j319g0sqdko.jpg)
这样的算法能够实现物理内存的分配, 但也带来了内部碎片问题.

## slab
slab 机制能够为内核较小较频繁的内存申请提供方便. 当 slab 为较小的内存申请分配内存并且用完归还时, 他并不直接返回, 而是缓存起来, 等待下次小量内存申请使用, 这样避免了频繁的物理内存分配与回收.

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fy4x8l2aiqj30cv02jaaa.jpg)

# [内存分配参数(/proc/sys/vm)][7]

* vm.zone_reclaim_mode:
    * 0: 当内存不足时, 会去其他 node 分配.
* vm.dirty_writeback_centisecs: bdi 周期性的检查脏页并写回.
* vm.dirty_background_ratio, vm.dirty_background_bytes(两者互斥, 把另一个设置成0): 当脏数据占（MemFree + Cached - Mapped）的总比例超过这个数值的时候, bdi 会开始写回脏数据(background).
* vm.dirty_ratio, vm.dirty_bytes(互斥): 造成超过这个比例的进程会阻塞, 把脏数据写出去. 跑 io 不大的进程时, 小 DBR, 大 DR, 会更好些. 当高频写同一个文件时, 可以把 DBR 调大一些, 不让冗余写落到磁盘.
* vm.dirty_expire_centisecs: 最长处于 cache 状态多久.

`cat /proc/vmstat | egrep "dirty|writeback"`这样可以查看脏数据相关信息.

# 问题
* GDT 表存在哪里?
    * 内存中. 其具体的位置写在 GDTR 寄存器里.
* 为什么要用分级分页方式?
    * 假设只有一层页表. 我们
    * [这里][12]有个问题: 考虑一个64位机器, 4KB 页, 4GB 物理内存.


# 参考
[内存观点][1]
[深入理解Linux内存管理-之-目录导航 - AderStep - CSDN博客][2]
[Go Memory Management - Povilas Versockas][3]
[Linux_Memory_Address_Mapping.pdf][4]
[cpu - What is the Global Descriptor Table memory type? - Electrical Engineering Stack Exchange][5]
[X86 Assembly/Global Descriptor Table - Wikibooks, open books for an open world][6]
[Deep dive into linux memory management | TechTalks][7]
[Linux Kernel: Memory Addressing – Hungys.blog() – Medium][8]
[Understanding memory information on Linux systems - Linux Audit][10]
[memory - Why do the data and code segments completely overlap in Linux? - Unix & Linux Stack Exchange][11]
[linux kernel - Why using hierarchical page tables? - Stack Overflow][12]
[memory management - Multi-level page tables Hierarchical paging - Stack Overflow][13]
[linux kernel - Why using hierarchical page tables? - Stack Overflow][14]
[NUMA架构的CPU -- 你真的用好了么？ • cenalulu's Tech Blog][15]
[The MySQL “swap insanity” problem and the effects of the NUMA architecture – Jeremy Cole][16]
[/proc/meminfo之谜 | Linux Performance][17]
[linux - What are memory mapped page and anonymous page? - Stack Overflow][18]
[linux - How do pdflush, kjournald, swapd, etc interoperate? - Unix & Linux Stack Exchange][19]
[linux pagecache bdi writeback 机制 - qqqqqq999999的专栏 - CSDN博客][20]
[linux - Difference between vm.dirty_ratio and vm.dirty_background_ratio? - Stack Overflow][21]


[1]: http://www.kerneltravel.net/journal/v/mem.htm
[2]: https://blog.csdn.net/gatieme/article/details/52384965
[3]:https://povilasv.me/go-memory-management/
[4]:http://www.ilinuxkernel.com/files/Linux_Memory_Address_Mapping.pdf
[5]:https://electronics.stackexchange.com/questions/94924/what-is-the-global-descriptor-table-memory-type
[6]:https://en.wikibooks.org/wiki/X86_Assembly/Global_Descriptor_Table
[7]:http://balodeamit.blogspot.com/2015/11/deep-dive-into-linux-memory-management.html
[8]:https://medium.com/hungys-blog/linux-kernel-memory-addressing-a0d304283af3
[10]:https://linux-audit.com/understanding-memory-information-on-linux-systems/
[11]:https://unix.stackexchange.com/questions/109651/why-do-the-data-and-code-segments-completely-overlap-in-linux
[12]:https://stackoverflow.com/questions/9834542/why-using-hierarchical-page-tables
[13]:https://stackoverflow.com/questions/11671527/multi-level-page-tables-hierarchical-paging
[14]:https://stackoverflow.com/questions/9834542/why-using-hierarchical-page-tables
[15]:http://cenalulu.github.io/linux/numa/
[16]:https://blog.jcole.us/2010/09/28/mysql-swap-insanity-and-the-numa-architecture/
[17]:http://linuxperf.com/?p=142
[18]:https://stackoverflow.com/questions/13024087/what-are-memory-mapped-page-and-anonymous-page
[19]:https://unix.stackexchange.com/questions/76970/how-do-pdflush-kjournald-swapd-etc-interoperate
[20]:https://blog.csdn.net/qqqqqq999999/article/details/77481899
[21]:https://stackoverflow.com/questions/27900221/difference-between-vm-dirty-ratio-and-vm-dirty-background-ratio/27902157

