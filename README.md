# 今天也要好好吃饭

就暮的个人博客，线上地址 https://jiumu07.github.io/ ，基于 [Hugo](https://gohugo.io/) + [极简 jijian](https://github.com/hcllmsx/hugo-jijian) 主题。

## 环境要求

| 工具 | 版本 | 说明 |
| --- | --- | --- |
| PowerShell | **7+**（命令 `pwsh`） | 系统自带的 5.1 不支持 `&&`，TLS 和中文编码也有问题 |
| Git | 任意较新版本 | 推送代码，需先配 `user.name` / `user.email` |
| Node.js | ≥ 18（建议 22 LTS） | 仅用于生成 Pagefind 搜索索引 |
| Hugo | ≥ 0.158.0，**extended** 版 | 主题要求；extended 才能处理 webp 封面 |

检查一下（在 `pwsh` 里执行）：

```bash
pwsh -v          # 应输出 PowerShell 7.x
git --version
node -v
hugo version     # 输出里应带 +extended
```

首次搭建时各工具的详细安装步骤（含 PATH 设置、Git 身份配置）见文章 `content/posts/hugo-deploy-guide.md` 第一节。

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

> **两个常见坑**：
> 1. 手动敲 `hugo server` 时，终端的工作目录必须是项目根目录（`D:\hugo-blog\JIUMU07`）。在别的目录执行不会报错，但会起一个**空站点**，打开就是 `Page Not Found`。用 VS Code 的任务不受影响，任务固定在项目根目录执行。
> 2. 1313 端口被占用时，Hugo 不会失败，而是自动换一个随机端口（如 `51180`）。所以看到端口和你预期的不一样，先看终端输出里 Hugo 实际打印的地址，并确认是不是已经有一个在运行的了。

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

线上地址：**https://jiumu07.github.io/**
仓库：`JIUMU07/JIUMU07.github.io`（用户站点，根路径，无子目录）

### 自动部署

推送到 `main` 即自动构建发布，流程在 `.github/workflows/deploy.yml`：

1. checkout（含主题 submodule）→ 装 Hugo 0.169.0 extended → 装 Node 20
2. `npm ci` → `hugo --gc --minify --baseURL <Pages 地址>` → `npm run search`
3. 上传 `public/` 并用 `actions/deploy-pages` 发布

Pages 的发布源是 **GitHub Actions**（不是 branch）。改动发布方式需在仓库 Settings → Pages 里切换。

### 历史版本

2025 年 7 月那版 Hexo 站点（标题「今天也要好好吃饭」，Hexo 7.3.0）完整保留在 `legacy-hexo` 分支，需要时：

```bash
git fetch origin legacy-hexo
git checkout legacy-hexo
```

### 网络前提（校园网 / 无代理）

这台机器在校园网下，`github.com` 的 DNS 被解析到 `20.6.7.17`，该 IP 被拦，直连必然超时；同时没有可用的本地代理（Clash Verge 装了但不在校园网里开）。

解决办法是**把域名固定到一个可用 IP**，用 git 的 `http.curloptResolve`，不需要代理也不需要改 hosts：

```powershell
git config http.curloptResolve "github.com:443:20.200.245.247"
```

本仓库已经这样配好，`git push` / VS Code 里点同步都能直接通。

某个 IP 哪天不通了就换一个。候选 IP 和测试方法：

```powershell
$ips = "140.82.112.4","140.82.114.4","140.82.116.4","20.200.245.247","20.205.243.166","20.27.177.113"
foreach ($ip in $ips) {
    $code = & curl.exe -s -o NUL -w "%{http_code}" --resolve "github.com:443:$ip" -m 6 https://github.com
    "$ip -> $code"
}
```

挑返回 200 的那个写回配置即可。若所有 IP 都不通，说明当次校园网把 GitHub 整体拦了，只能等网络恢复或换网络。
