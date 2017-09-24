---
title: C和进程控制
tags:
  - Linux
  - C/C++

categories:
  - Learn
date: 2016-08-12 17:21:05
---

进程相关
<!--more-->


# 参考
- LinuxC一站式学习
- [Linux 多进程-1][1]

---


# 进程的几种状态
## R
可执行状态, 进程控制块位于可执行队列中.
## S
可中断睡眠状态, 在等待事件的发生. 事件发生后会进入可执行队列中.
## D
不可中断睡眠状态, 进程不能响应异步信号. 一般用于保护进程不被打断, 很短, 很强.
## T
分为TASK_STOPPED, TASK_TRACED. 暂停或跟踪状态, 在接收到SIGSTOP信号后默认进入该状态. TASK_TRACED状态不能响应SIGCONT信号, 只有通过ptrace才能继续.
## Z
僵尸状态.
## X
很短暂的退出状态.
## and this is a test

---

# 进程的内存大略布局
## 各段说明
- 代码段
- 数据段
- 堆
- 栈
## 大致结构

---

# 环境变量的获取与修改
- 一个进程的高1G空间是内核的, 低3G空间是用户的
- 用户地址空间的最高部分是命令行参数和环境变量, 然后是栈, 栈向低地址生长
- 最低部分是代码段, 然后是初始化的数据, 未初始化的数据, 堆, 堆向高地址生长
- 当我们在shell里面运行程序时, 本质上是fork出来一个子进程然后用exec系统调用来装载一个程序, 对于环境变量, 文件描述符则会继承. 而当我们对该进程的环境变量进行修改时, 不会对其他任何东西产生影响.
- 下面的代码可以获取所有的环境变量, 由于environ没有在任何的头文件里面声明, 所以需要extern修饰
    ```
    #include <stdio.h>

    int main() {
        extern char **environ;
        int i;
        for (i = 0; NULL != environ[i]; i++) {
            printf("%s\n", environ[i]);
        }
        return 0;
    }
    ```
- 可以用`getenv`, `setenv`, `unsetenv`来对环境变量进行操作
    ```
    #include <stdlib.h>

    /*获取指定的环境变量*/
    char *getenv(const char *name);

    /*设定环境变量, 若rewrite非0则覆盖已有, 否则不覆盖*/
    /*设定成功返回0, 失败返回非0*/
    int setenv(const char *name, const char *value, int rewrite);

    /*删除一条环境变量, 即使不存在这个变量也不会报错*/
    void unsetenv(const char *name);
    ```

---

# 进程控制
- 一些主要的进程控制系统调用包括`fork`, `exec`一族, `wait`和`waitpid`, 一个一个来

## fork
- 函数原型
    ```
    #include <unistd.h>
    #include <sys/types.h>
    pid_t fork(void)
    ```
- 栗子
    ```
    #include <unistd.h> //fork
    #include <sys/types.h> //pid_t
    #include <stdio.h> //perror
    #include <stdlib.h> //exit

    int main() {
        pid_t pid  fork();
        char *msg;
        int n;

        if (pid < 0) {
            perror("fork failed");
            exit(1);
        }

        if (0 == pid) {
            msg = "This is child process\n";
            n = 6;
        } else {
            msg = "This is parent process\n";
            n = 3;
        }

        while (n--) {
            printf(msg);
            sleep(1);
        }

        return 0;
    }
    ```
    - 上面的代码在执行的时候, 父进程基本是先运行完的, 我们会发现shell认为父进程执行完了以后就结束了, 于是出现了prompt. 但实际上显然不是的.
    - 正常来讲, 进程在执行的时候, 会默认认为父进程需要查看自己的退出信息以确定是否执行正常, 是否需要额外处理, 因此在结束的时候会留下相关信息, 要是父进程没有查看, 那么虽然进程结束了, 却仍会占用一定的内存空间同时占有PID, 这样的进程成为僵尸进程. 僵尸进程不会占用CPU时间, 但会占用其他资源. 父进程可以通过wait/waitpid系统调用来收集子进程的结束信息.
    - 另一个概念是孤儿进程, 即, 子进程仍在运行, 父进程已经结束, 这样的子进程就是孤儿进程. 孤儿进程会被PID为1的init进程收养, 正常的结束生命, 不会成为僵尸进程.
    - 回到上面的例子, 我们的父进程没有等待子进程完成, 因此提前结束了. 此时如果发生"父进程没有完成, 也没有收集子进程的结束信息", 那么子进程在结束之后就会成为僵尸进程. 我们在下面会实验.
- 注意点
    - 调用失败返回-1
    - 若调用成功, 在父进程内返回fork出的子进程的PID, 在子进程内返回0
    - 父进程需要保存好子进程PID, 因为没什么别的好方法了
    - 子进程可以通过`getpid`获取自己的PID, 通过`getppid`获取父进程的PID
    - 原本的`vfork`可以保证`fork`完了以后立刻`exec`装载另一个程序, 防止白拷贝一次地址空间, 但现在的`fork`已经具备了读时共享写时复制的机制, `vfork`越来越少用了
    - 如果需要在gdb中调试, 可以通过`set follow-fork-mode child/parent`来设置发生`fork`时gdb的行为
    - 内存不足时会失败, 错误为`ENOMEM`
    - 达到系统进程数量上限时也会失败, 错误为`EAGAIN`

---

## wait/waitpid
- 一个进程在结束的时候会释放除了进程描述符(PCB)以外的资源, 一些相关的信息仍然会被保存, 如: 是否正常退出(exit), 如果是收到信号退出则保存哪个信号让它退出, 等等. 这些信息可以被父进程通过wait/waitpid来获取. 之后就会彻底清除这些信息.
- 原型
    ```
    #include <sys/types.h> //pid_t
    #include <sys/wait.h> // wait waitpid

    /*等待任意一个子进程退出*/
    pid_t wait(int *status);

    /**
     * pid的可能取值
     * < -1 等待组id为pid绝对值的任意一个子进程退出
     * = -1 等待任意一个子进程退出
     * = 0 等待组ID相同的任意一个子进程, 如果子进程已经加入了其他的组, 则不等
     * > 0 等待PID对应的子进程
     *
     * option的取值可以有以下的选项构成(0个或多个)
     * WNOHANG      如果没有子进程已经退出, 那么立刻返回而不等待
     * WUNTRACED    
     * WCONTINUED   
     *
     * 保存了status以后, 可以用以下的宏来查看相关信息
     * WIFEXITED(status)
     * WEXITSTATUS(status)
     * WIFSIGNALED(status)
     * WTERMSIG(status)
     * WCOREDUMP(status)
     * WIFSTOPPED(status)
     * WSTOPSIG(status)
     * WIFCONTINUED(status)
     */
    pid_t waitpid(pid_t pid, int *status, int options);
    ```
- 栗子实验
    ```
    #include <sys/types.h> //pid_t
    #include <sys/wait.h> 
    #include <stdio.h> 
    #include <stdlib.h> //exit
    #include <unistd.h> //fork

    int main() {
        pid_t pid = fork();

        if (pid < 0) {
            perror("fork failed");
            exit(1);
        }

        if (0 == pid) {
            int i;
            for (i = 0; i < 3; i++) {
                printf("This is child process\n");
                sleep(1);
            }
            exit(3);
        } else {
            int stat_val;
            waitpid(pid, &stat_val, 0);
            if (WIFEXITED(stat_val))
                printf("child exited with status %d\n", WEXITSTATUS(stat_val));
            else if (WIFSIGNALED(stat_val))
                printf("child terminated abnormally by signal %d\n", WTERMSIG(stat_val));
        }

        return 0;
    }
    ```
    - 正常情况下, 子进程最后会`exit(3)`, 父进程会发现是正常退出
    - 为了触发异常退出, 我们在运行后需要将父进程先挂起(`ctrl+z`), 用ps来查看一下两个进程, 然后将子进程杀掉(`kill -9 <pid>`), 然后再让父进程回到前台运行(`fg %1`), 这时我们就会发现父进程输出了子进程是被哪个信号杀的(9)

---

## exec系列
- 函数原型
    ```
    #include <unistd.h>

    /*如果exec调用成功, 那么装载的程序就开始执行没法返回了*/
    /*否则返回-1*/
    int execl(const char *path, const char *arg, ...);
    int execlp(const char *file, const char *arg, ...);
    int execle(const char *path, const char *arg, ..., char *const envp[]);
    int execv(const char *path, char *const argv[]);
    int execvp(const char *file, char *const argv[]);
    int execve(const char *path, char *const argv[], char *const envp[]);
    ```
    - 很多, 但还是有规律的
    - 如果里面有l, 那么可以直接将参数往后面挂, 但是最后一个需要是NULL, 后面会举例
    - 如果里面有p, 那么会在进程的PATH变量里面搜索程序名, 这也是为什么带p的函数的第一个参数是"file", 不带p的是"path"
    - 如果里面有v, 那么首先应该构造一个指向各个参数的指针数组, 然后将该数组的首地址传入, 数组的最后一个还是需要是NULL, 有点类似main后面的argv
    - 如果里面有e, 那么可以传入一份新的环境变量
- 栗子
    ```
    char *const ps_argv[] = {"ps", "-o", "pid,ppid,comm", NULL};
    char *const ps_envp[] = {"PATH=/bin:/urs/bin", "TERM=console", NULL};

    execl("/bin/ps", "ps", "-o", "pid,ppid,comm", NULL);
    execv("/bin/ps", ps_argv);
    execle("/bin/ps", "ps", "-o", "pid,ppid,comm", NULL, ps_envp);
    execve("/bin/ps", ps_argv, ps_envp);
    execlp("ps", "ps", "-o", "pid,ppid,comm", NULL);
    execvp("ps", ps_argv);
    ```
    - 参数里的第一个, 好像是argv[0], 并不读的, 所以可以随便取
    - 里面只有execve是真正的系统调用, 其他的都是调用它的, 所以除了它都在man 3里面
- 又一个栗子
    ```
    /* upper.c */
    #include <stdio.h>

    int main() {
        int ch;
        while((ch = getchar()) != EOF) {
            putchar(toupper(ch));
        }
        return 0;
    }

    /* wrapper */
    #include <unistd.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <fcntl.h>

    int main(int argc, char *argv[]) {
        if (argc != 2) {
            fputs("usage: wrapper file\n", stderr);
            exit(1);
        }

        int fd = open(argv[1], O_RDONLY);
        if (fd < 0) {
            perror("failed opening file");
            exit(1)
        }

        dup2(fd, STDIN_FILENO);
        close(fd);
        execl("./upper", "upper", NULL);
        perror("exec ./upper";
        exit(1);
    }
    ```
    - upper.c实现了一个一个字符转大写然后输出到stdout
    - wrapper里面修改了自己的stdin, 然后exec了upper, 由于文件描述符的继承, 就实现了重定向

[1]:https://cnbin.github.io/blog/2015/06/24/linux-duo-jin-cheng-1/


