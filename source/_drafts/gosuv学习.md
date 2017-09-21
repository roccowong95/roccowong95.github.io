---
title: gosuv学习
date: 2016-10-03 11:05:59
tags:
  - Golang
---

gosuv学习, 里面涉及很多的包

<!-- more -->

# GOSUV
## 如何在后台运行的

---

# 第三方库
## [github.com/urfave/cli](https://github.com/urfave/cli#installation)
### 简单使用

### Flags
- `help`里面会按照定义顺序排序, 可以用`sort.Sort()`来进行排序
- 如:

    ```
  app.Flags = []cli.Flag {
    cli.StringFlag{
      Name: "lang, l",
      Value: "english",
      Usage: "Language for the greeting",
    },
    cli.StringFlag{
      Name: "config, c",
      Usage: "Load configuration from `FILE`",
    },
  }

  sort.Sort(cli.FlagsByName(app.Flags))
    ```

### Before
- 在before里面已经可以用flag里面的变量了

---

