---
title: 'Scrapy:第一个工程'
date: 2016-08-06 17:15:17
tags:
- scrapy
- python
- 爬虫
---

scrapy
<!--more-->

# 参考
[Scrapy Tutorial][1]

---

# 创建工程
```
scrapy startproject tutorial
```

创建完了以后有如下的目录

``` 
.
├── scrapy.cfg
└── tutorial
    ├── __init__.py
    ├── items.py
    ├── pipelines.py
    ├── settings.py
    └── spiders
        └── __init__.py
```

# 定义item
item是抓取来的数据的容器, 可以通过定义一个scrapy.Item的子类来声明

```
# tutorial/items.py
import scrapy
class DmozItem(scrapy.Item):
    # define the fields for your item here like:
    title = scrapy.Field()
    link = scrapy.Field()
    desc = scrapy.Field()
```

# 定义spider
代码如下

```
# tutorial/spiders/dmoz_spider.py
import scrapy

class DmozSpider(scrapy.Spider):
    name = "dmoz"
    allowed_domains = ["dmoz.org"]
    start_urls = [
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
    ]

    def parse(self, response):
        filename = response.url.split("/")[-2] + '.html'
        with open(filename, 'wb') as f:
            f.write(response.body)
```
- name: 是爬虫的唯一标识
- start\_urls: 爬虫的起始url们, 接下来的url都是从起始url弄出来的
- parse(): 上面的起始url们被下载完了以后的默认回调方法. 下载得到的`Responde object`会被作为参数传入. `parse()`会以`Item`形式返回抓取的数据, 并且获取更多的Url

# 开始运行
- 回到顶层tutorial目录, 执行
	```
	scrapy crawl dmoz
	```
- 可以看到当前目录下多了`Books.html`和`Resources.html`
- 对于`start_urls`里面的每一个URL, scrapy都创建一个`scrapy.Request`对象. 下载回来的会构成`scrapy.http.Response`对象, 调用回调方法`parse()`

# 获取Items

## Selector
scrapy利用基于css或者Xpath的selector来从html中获取需要的内容.

### 几个xpath的例子
- `/html/head/title`
	选择`<html>`标签里面的`<title>`元素
- `/html/head/title/text()`
	选择上述`<title>`元素里的文字
- `//td`
	选择所有的`<td>`元素
- `//div[@class="mine"]`
	选择所有含有`class="mine"`属性的`<div>`元素

### selector有以下几个基本方法
- `xpath()`
	返回由参数xpath选择的selector列表
- `css()`
	返回由参数css选择的selector列表
- `extract()`
	返回该selector选中的元素的unicode编码的字符串, 其实就是去掉里面的标签
- `re()`
	返回被参数正则表达式捕获的字符串列表

### 用内置shell来试一试selector
- 首先启动
	```
	scrapy shell "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/"
	```
- 接下来就进入了scrapy内置的shell, 返回的response内的selector属性即是整个页面的selector, 因此可以使用`response.selector.xpath()`, 但也可以用快捷方式, `response.xpath()`

### 利用selector来从response中获取需要的信息
- 修改代码

	```
	# tutorial/spiders/dmoz_spider.py
	import scrapy

	class DmozSpider(scrapy.Spider):
	    name = "dmoz"
	    allowed_domains = ["dmoz.org"]
	    start_urls = [
	        "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
	        "http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
	    ]

	    def parse(self, response):
	        for sel in response.xpath('//ul/li'):
	            title = sel.xpath('a/text()').extract()
	            link = sel.xpath('a/@href').extract()
	            desc = sel.xpath('text()').extract()
	            print title, link, desc
	```
- 这时运行`scrapy crawl dmoz`就可以看到效果了

### 接下来将数据写入Item里
- 再改一下代码

	```
	import scrapy
	from tutorial.items import DmozItem

	class DmozSpider(scrapy.Spider):
	    name = "dmoz"
	    allowed_domains = ["dmoz.org"]
	    start_urls = [
	        "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
	        "http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
	    ]

	    def parse(self, response):
	        for sel in response.xpath('//ul/li'):
	            item = DmozItem()
	            item['title'] = sel.xpath('a/text()').extract()
	            item['link'] = sel.xpath('a/@href').extract()
	            item['desc'] = sel.xpath('text()').extract()
	            yield item
	```
- 接下来再运行爬虫的时候就会yield出item来了

### 存储Item
- 最简单的方法就是存进json里

	```
	scrapy crawl dmoz -o items.json
	```


[1]:	http://doc.scrapy.org/en/latest/intro/tutorial.html

