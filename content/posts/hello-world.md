---
title: 这个博客的第一篇文章
date: 2026-11-12
draft: false
categories: ["随笔"]
tags: ["Hugo", "开始"]
summary: 站点搭好了，先写一篇占位文章，顺便把主题的几个常用写法记在这里。
---

从一个空目录到能跑起来的博客，中间踩的坑都记在这儿。

## 为什么用 Hugo

静态站点没有数据库、没有后台，写完 Markdown 提交仓库就完事。构建一次通常不到一秒，改完立刻能看到效果，写东西的时候不会被工具打断。

> [!NOTE]
> 主题支持 GitHub 原生风格的提示块，`> [!NOTE]`、`> [!TIP]`、`> [!WARNING]` 都可以直接用。

## 怎么写一篇新文章

在项目根目录执行：

```bash
hugo new content posts/my-new-post.md
```

生成的草稿默认 `draft: true`，本地预览加 `-D` 就能看到，正式构建时会被忽略。

文章开头的 Front Matter 常用字段：

```yaml
---
title: 标题
date: 2026-11-12
draft: false
categories: ["技术"]
tags: ["Hugo", "Markdown"]
summary: 列表页显示的摘要，留空会自动截取正文
pin: 1          # 置顶，正整数，越小越靠前
ShowToc: true   # 是否显示目录
cover:
  image: cover.jpg   # 同目录下的封面图
  alt: 封面
---
```

## 几个小约定

| 字段 | 作用 |
| --- | --- |
| `pin` | 首页置顶，数字越小越前 |
| `summary` | 列表摘要，不写则自动截断 |
| `cover.image` | 封面图，和文章放同一目录即可 |

文章里的图片放在 `posts/文章名/` 目录下，用相对路径引用就行，主题会自动做灯箱和尺寸优化。

> [!TIP]
> 搜索用的是 Pagefind，构建后跑一次索引脚本才能搜到内容，具体命令见项目根目录的 README。

先写到这，接下来慢慢填内容。
