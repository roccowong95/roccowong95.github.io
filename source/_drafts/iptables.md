---
title: iptables
tags:
  - Linux
  - shell
  - 运维
date: 2016-08-09 19:37:26
---

iptables
<!--more-->

# 参考
- [运维人员20道必会iptables面试题][1]
- [The Beginner’s Guide to iptables, the Linux Firewall][2]
- [linux下iptables讲解][3]

---

# 介绍
- iptables防火墙的规则由几张表构成, 每个表里有几条不同的链. 当包达到指定链时会从第一条开始检查是否需要操作.
- 默认有raw, mangle, nat, filter四张表, 优先级是raw \> mangle \> nat \> filter
	- raw: 对报文设置一个标志, 决定数据包是否被状态跟踪机制处理, 只有OUTPUT和PREROUTING两个链. 可以在这张表中设置规则让数据包不受跟踪处理, 从而避免出现链接跟踪表满的错误.
	- mangle: 主要用于修改数据包的服务类型(TOS), 生存周期(TTL)等, 以实现服务质量(QOS)以及策略路由等应用.五个链都有.
	- nat: 网络地址转换, 端口映射等.有PREROUTING, OUTPUT, POSTROUTING三个链.
	- filter: 主要用于过滤数据包, 有三个链INPUT, OUTPUT, FORWARD.
- 下面是工作流程
	{% asset_img iptables工作流程.png iptables工作流程 %}

# 常用选项
- `service iptables save`: 保存当前规则
- `-n`: 以数字形式显示
- `-L`: 列出所有
- `-v`: 可视化显示
- `-t`: 选择指定表
- `-F`: 临时清除所有规则, 会在重启以后重置
- `-Z`: 将计数器清零
- `-i`: 选择网络设备如eth0
- `-P --policy`: 修改链的默认行为
	- DROP: 会导致超时
	- REJECT: 目的IP不可达
- `-D`: `iptables -D INPUT 1`根据序号删除规则; 也可以在`-D`后面输一模一样的以删除对应的规则
- `-I`: `iptables -I INPUT 2`在指定位置插入规则, 不加数字的话则是在第一个
- `-A`: 在链的最后加条规则
- `-p`: 筛选协议
- `-d`: 目标IP
- `-s`: 起始IP
- `-dport`: 目标端口
- `-sport`: 起始端口
- `-m`: 匹配, 如`iptables -A PREROUTING -t mangle -i eth2 -m mark ! --mark 0xffff -j DROP`
- `!`: 反选. 如`iptables -I INPUT ! -dport 22 -j accept`
- `-N`: 创建一个新的链

# 例子🌰
- 查看当前所有规则
- 禁止来自10.0.0.188 ip地址访问80端口的请求
- 把访问10.0.0.3:80的请求转到172.16.1.17:80
- 实现172.16.1.0/24段所有主机通过124.32.54.26外网IP共享上网
- 如何利用iptables防止syn洪泛攻击?
	```
	iptables -N syn-flood
	iptables -A INPUT -i eth0 -syn -j syn-flood
	iptables -A syn-flood -m limit --limit 5000/s --limit-burst 200 -j RETURN
	iptables -A syn-flood -j DROP
	```
- 写一个脚本解决DOS攻击
	```
	hehe
	```
- 为什么会出现`nf_conntrack: table full, dropping packet`?
	- 因为web服务器接受的连接太多了, iptables对每个连接都进行跟踪处理, 导致连接跟踪表满了.
	- 解决方案
		- 加大ip\_conntrack\_max

			`
			vi /etc/sysctl.conf

			net.ipv4.ip_conntrack_max = 393216
			net.ipv4.netfilter.ip_conntrack_max = 393216
			`

- 降低ip\_conntrack timeout的时间
	```
	vi /etc/sysctl.conf

	net.ipv4.netfilter.ip_conntrack_tcp_timeout_established = 300
	net.ipv4.netfilter.ip_conntrack_tcp_timeout_time_wait = 120
	net.ipv4.netfilter.ip_conntrack_tcp_timeout_close_wait = 60
	net.ipv4.netfilter.ip_conntrack_tcp_timeout_fin_wait = 120
	```



[1]:	http://lx.wxqrcode.com/index.php/post/84.html
[2]:	http://www.howtogeek.com/177621/the-beginners-guide-to-iptables-the-linux-firewall/
[3]:	http://mofansheng.blog.51cto.com/8792265/1635953

