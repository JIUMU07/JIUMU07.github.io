# JIUMU07

JIUMU 的个人博客，基于 [Hugo](https://gohugo.io/) + [极简 jijian](https://github.com/hcllmsx/hugo-jijian) 主题。

## 环境要求

| 工具 | 版本 | 说明 |
| --- | --- | --- |
| Hugo | ≥ 0.158.0，**extended** 版 | 主题要求；extended 才能处理 webp 封面 |
| Node.js | ≥ 18 | 仅用于生成 Pagefind 搜索索引 |

检查一下：

```bash
hugo version     # 输出里应带 +extended
node -v
```

## 本地开发（VS Code）

1. 用 VS Code 打开本目录（`D:\hugo-blog\JIUMU07`）。
2. 按 `Ctrl + Shift + B` 运行默认构建任务「hugo: 本地预览（含草稿）」，或直接开终端：

   ```bash
   hugo server -D
   ```

3. 浏览器打开 http://localhost:1313/ ，改动会自动热更新。

任务列表在 `.vscode/tasks.json`，用 `Ctrl + Shift + P` → `Tasks: Run Task` 也能调出来：

- **hugo: 本地预览（含草稿）** — `hugo server -D`
- **hugo: 构建到 public** — 生产构建
- **hugo: 构建并生成搜索索引** — 构建 + Pagefind 索引
- **hugo: 带搜索的本地预览** — 构建 + 索引 + 起个静态服务（搜索只有这条链路能用）
- **hugo: 新建文章** — 输入文件名，自动按模板生成草稿

> 需要 `hugo` 在 PATH 中。若终端提示找不到命令，重启一次 VS Code 让新 PATH 生效。

## 写文章

```bash
hugo new content posts/文章文件名.md
```

生成在 `content/posts/` 下，默认 `draft: true`，本地 `-D` 可见，正式构建会被忽略。写完后把 `draft` 改成 `false`。

常用 Front Matter：

| 字段 | 作用 |
| --- | --- |
| `title` | 标题 |
| `date` | 日期，`2026-11-12` |
| `categories` / `tags` | 分类与标签，数组写法 `["技术"]` |
| `summary` | 列表页摘要，不写则自动截取 |
| `pin` | 首页置顶，正整数，越小越靠前 |
| `ShowToc` | 是否显示右侧目录，默认 `true` |
| `cover.image` | 封面图，写与文章同目录的文件名 |
| `draft` | 草稿开关 |

图片放在 `content/posts/文章文件名/` 目录里，正文用相对路径引用，主题会自动做灯箱和尺寸优化。

## 搜索

搜索用 Pagefind，索引不在 `hugo server` 里生成，需要构建后单独跑一次：

```bash
npm run build     # hugo --gc --minify
npm run search    # 生成 public/pagefind
npm run preview   # 构建 + 索引 + 本地起服务看效果
```

想验证搜索效果，用 `npm run preview`，别用 `hugo server`。

## 目录结构

```
content/
  _index.md          首页简介
  about.md           关于页（layout: blank）
  archives.md        时光轴（layout: archives）
  search.md          搜索页（layout: search）
  posts/             文章
archetypes/          新建文章的模板
static/              favicon、图片等静态文件
layouts/_default/    站点级模板覆盖
  archives.html      复制自主题，只改了月份为中文「11月」
themes/jijian/       主题（git submodule，不要直接改）
hugo.yaml            站点配置
```

## 配置说明

全部配置集中在 `hugo.yaml`，几处容易踩的点：

- `theme: jijian` — 冒号后必须有空格，写错整站不生效。
- `locale: zh-cn` — Hugo 新版已弃用 `languageCode`。
- `pagination.pagerSize` — 新版分页配置，旧的 `paginate` 已废弃。
- `mediaTypes` 里把 `application/manifest+json` 的后缀改成 `json`，否则主题的 PWA manifest 模板对不上。
- 菜单项的 `identifier` 必须能对应到真实页面，否则模板取值会报错。

## 部署

目前 `baseURL` 是 `http://localhost:1313/`，只用于本地预览。要上线时改成真实域名（如 `https://example.com/`），再执行 `npm run build && npm run search`，把 `public/` 目录发布到任意静态托管即可。

如果部署在子路径（如 GitHub Pages 的 `https://用户名.github.io/仓库名/`），需把 `baseURL` 写成带结尾斜杠的完整子路径。
