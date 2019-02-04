---
title: C和socket
tags: [Linux,C/C++]
category: [digest]
description: ''
---

# 参考
- APUE
- Unix网络编程
- [C/C++ socket编程教程][1]
- [TCP与UDP的不同接包处理方式][2]

---

# socket的数据传输
## 数据的读写(TCP)
- read/write和recv/send函数都只是操作socket的缓冲区, 不管具体的发送和接收.
- socket由四元组唯一标示, 每个socket都有单独的缓冲区
- 阻塞情况下的发送
    - 如果需要发送的数据小于缓冲区剩余可用空间, 那么会直接写入缓冲区
    - 如果大于可用空间但小于最大缓冲空间, 则会阻塞直到缓冲区有这么多空间
    - 如果大于最大缓冲空间, 则会分批写入, 和管道类似, 此时不是原子的
    - 所有数据都被写入后, 写入函数才会返回(send/write)
    - 如果TCP协议正在占用缓冲区, 那么将会阻塞直到TCP协议释放缓冲
- 阻塞情况下的读取
    - 如果缓冲没有数据, 那么将会阻塞
    - 如果要读取的数据小于缓冲区当前的数据, 则会立刻返回, 但剩余数据会积压
    - 如果大于, 则会阻塞, 直到读满指定数量.

<!--more-->

## socket属性
- 可以通过`getsockopt`来获取

    ```
    #include <sys/socket.h>
    int
    getsockopt(int socket, int level, int option_name,
        void *restrict option_value, socklen_t *restrict option_len);
    ```

---

# socket的断开
- socket的断开我们可以用`close`或`shutdown`来完成
    - `close(int sockfd)`
    - `shutdown(int sockfd, int how)`
- `shutdown`的第二个参数`how`可以指定关闭全双工socket的某一个
    - `SHUT_RD`
    - `SHUT_WR`
    - `SHUT_RDWR`

---

# 相关的问题
- udp socket, 发送两次数据, 100字节, 200字节, 接收方试着接收1000字节, recvfrom的返回值?
- 上面的udp换成tcp呢?
- 如果链路的MTU是1500, 使用udp发送2000, 如果试着接收3000字节, 会收到多少字节
- 如果上面的500字节丢失了怎么办?
- 什么是TCP的粘包?
    - 这是个流协议.
    - 数据是无边界的, 如果没有规定边界字符的话, 会导致不同的数据积压.
- 为什么TCP最后有一个TIME_WAIT阶段?
    - 在最后一次发送了ACK报文后, 并没有确保这个ACK报文能够送达
    - 因此需要TIME_WAIT来确保另一端收到了ACK, 如果他没有收到ACK, 那么会再发送第二个FIN报文
    - 那么这个TIME_WAIT需要多长时间呢
    - 我们知道, 网络中的数据包是有生存时间的, 即MSL, 也就是说最坏情况下的往返时间是2MSL, 因此如果2MSL内没有收到第二次FIN, 就说明对面服务器已经收到ACK报文.


[1]:http://c.biancheng.net/cpp/socket/
[2]:http://www.cnblogs.com/thankgoodness/articles/3146069.html


