---
title: pthread
tags:
- Linux
- C/C++
---

# 参考
[知乎][1]
[Linux线程编程之信号处理][2]

---

# mutex
## 用法
- 如果mutex已经上锁了, 那么调用的线程将会阻塞到互斥量被解锁. 
- 如果使用`pthread_mutex_trylock`来尝试, 就好像是无阻塞那样, 如果可以锁那就锁住了, 如果不能锁那就会返回EBUSY.
- 如果一个线程试图对同一个互斥量加锁两次, 那么会陷入死锁. 除非mutex开启了`PTHREAD_MUTEX_RECURSIVE`, 则可以嵌套锁, 这种情况下, 锁了多少次就要解锁多少次.
- attr有以下几种
    - PTHREAD_MUTEX_NORMAL
    - PTHREAD_MUTEX_ERRORCHECK
    - PTHREAD_MUTEX_RECURSIVE
    - PTHREAD_MUTEX_DEFAULT
## 示例
- demo1.c
    ```
    #include <stdio.h>
    ```

---

# condition

---

# rwlock

---

# spinlock

---

# 信号
## 介绍
- 内核也为线程维护未决信号队列.
- 线程可以独立的屏蔽不同的信号.
- 在某个进程内创建线程时, 线程将会继承主线程的信号掩码, 但是新线程的未决信号队列会被清空, 以防一个信号被多个线程处理.
    - 由这一点我们可以知道, 在创建线程之前可以用pthread_sigmask来设置线程的信号掩码, 来确保该掩码被所有线程继承. 防止在某个线程中忘记屏蔽其他线程需要的信号.
- 信号处理函数显然是进程内所有线程共享的.
- 如果某个信号的默认动作是停止或者终止, 那么不管信号发往哪个线程, 整个进程都会停止.
- 线程库并不是异步信号安全的, 因此在信号处理函数中不应该使用线程库函数(pthreads).
## 屏蔽信号
### 函数原型
```
#include <signal.h>
int
pthread_sigmask(int how, const sigset_t \*restrict set,
    sigset_t \*restrict oset);
/*************************
 如果oset非空, 那么将会保存线程当前的信号掩码
 如果set非空, 那么函数将会根据how来修改线程掩码
 how的取值见下
 SIG_BLOCK      将set里面的信号加入当前线程的信号掩码(进行屏蔽)
 SIG_UNBLOCK    从当前信号掩码中移除set里面的信号
 SIG_SETMASK    将当前线程的掩码设为set指向的信号集

 和sigprocmask的关系: 
 sigprocmask函数在多线程的条件下未定义
 pthread_sigmask失败时返回errno, sigprocmask则返回-1并且设置errno
 *************************/
```
## 等待信号
### 函数原型
```
#include <signal.h>
int
sigwait(const sigset_t \*restrict sigset, int \*restrict signop);
/*************************
 阻塞当前线程, 等待sigset信号集. sigwait会解除信号集的阻塞状态, 当接收到了指定信号以后, 再恢复之前的掩码, 在这一点上, 和pthread_cond_wait很像.
 如果已有信号集中的信号阻塞在外面, 那么此次调用无阻塞的返回, 获取一个信号, 并从队列中移除. 否则, 阻塞直到信号到来.
 sigwaitinfo可以获取的东西更多, 成功时返回信号值并且获取siginfo_t结构, 失败时设置errno并且返回-1. 此外, 如果产生了等待信号集之外的信号, 该信号的处理函数可以中断sigwaitinfo, 导致它失败返回并且设置EINTR.
 如果有多个线程等待同一个信号, 那么一个信号的到来只能导致一个线程返回.
 如果信号被sigaction安装的handler捕获, 而又有线程在等待这个信号, 那么只可能在一个地方被处理, 操作系统实现可让sigwait返回, 也可激活handler.
 *************************/
```
## 发送信号
### 函数原型
```
#include <signal.h>
int
pthread_kill(pthread_t thread, int signo);
/*************************
 将signo信号异步发送至thread线程, 成功时候返回0, 错误时返回errno(ESRCH指定线程不存在, EINVAL指定信号无效或者不支持).
 如果signo==0, 那么可以用来检查指定线程是不是存在, 和kill的用法类似.
 
 注意
 这样的存在性测试并不是原子的, 返回结果时, 被测进程可能已经结束了.
 线程号只有在同一个进程内是唯一的, 使用其他进程内的线程号的行为未定义.
 仅在thread指定线程退出但是未被join时, 才能期望必然返回ESRCH错误.
 *************************/
```
---

# 其他问题
## 为什么我在使用condition的时候, 需要配合mutex使用?
- 看[知乎][1]
- 一般在等待wait操作的之前, 都需要先获取一个锁, 来避免竞态条件.

```
/*************************
 *************************/
```



[1]:http://www.zhihu.com/question/24116967
[2]:http://www.cnblogs.com/clover-toeic/p/4126594.html


