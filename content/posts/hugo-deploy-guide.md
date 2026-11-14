---
title: 从零把博客部署上线：Hugo + 极简主题 + GitHub Pages
date: 2026-11-13
draft: false
categories: ["技术"]
tags: ["Hugo", "GitHub Pages", "教程"]
summary: 从 PowerShell 环境检查开始，一步步把 Hugo 博客推到 GitHub Pages。全程网页点击，不装额外命令行工具，主题配置的坑和真实踩过的报错都记在里面。
---

这篇文章记录本站从空目录到上线的完整过程。环境是 Windows + PowerShell 7（命令名 `pwsh`，不是系统自带的那个）。

在目前状态下，其实自己手搓一个博客其实是一件很简单的事情，只需要向dsh许个愿就行了，但是肯定不如自己做浪费时间：-）。

## 一、先把环境备齐

四样东西，缺一样都不行：

| 工具 | 版本要求 | 用途 |
| --- | --- | --- |
| PowerShell | **7+**，命令名 `pwsh` | 执行所有命令 |
| Git | 任意较新版本 | 版本管理、推送 |
| Node.js | ≥ 18（建议 22 LTS） | 只用于生成搜索索引 |
| Hugo | ≥ 0.158，**extended** 版 | 生成静态站 |

顺序建议就按上面这个来：PowerShell 是载体，Git 决定代码能不能推上去，Node 和 Hugo 分别负责搜索索引和构建。

### 装 PowerShell 7

Windows 自带的那个叫 **Windows PowerShell 5.1**，命令是 `powershell`（或 `powershell.exe`），**不要用它**。有三个实际影响：

- **不支持 `&&` 串联命令**，`npm run build && npm run search` 这类写法直接报语法错
- **默认只开 TLS 1.0/1.1**，用 `Invoke-WebRequest` 从 GitHub 下载东西会失败
- **输出编码是 GBK**，Hugo 的中文日志、`git log` 里的中文提交信息容易变成乱码

新版的命令是 **`pwsh`**，和 5.1 可以共存，装了不冲突。先用这条判断：

```powershell
pwsh -v
```

- 输出 `PowerShell 7.x.x` → 已装好，直接用
- 提示 `pwsh : 无法将"pwsh"项识别为 cmdlet...` → 没装

装：

```powershell
winget install --id Microsoft.PowerShell --source winget
```

winget 不通就去 `github.com/PowerShell/PowerShell/releases` 下 `PowerShell-<版本>-win-x64.msi`，双击安装。

装完**重开终端**，再执行一次 `pwsh -v` 确认。之后所有命令都在 `pwsh` 里跑。

VS Code 里顺手把默认终端换过来，否则你每次按 `` Ctrl + ` `` 打开的仍然是 5.1：

1. `Ctrl + Shift + P`
2. 输入 `Terminal: Select Default Profile`
3. 选 **PowerShell 7**，不是 **Windows PowerShell**

### 装 Git

```powershell
winget install --id Git.Git -e --source winget
```

或者去 `git-scm.com/download/win` 下安装包。安装过程中有个 PATH 选项，要选 **Git from the command line and also from 3rd-party software**，否则终端里敲 `git` 会提示找不到命令。

装完重开终端验证：

```powershell
git --version
```

然后**必须**配一下提交身份，否则第一次 `git commit` 会直接报 `Author identity unknown`：

```powershell
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

不想暴露真实邮箱的话，用 GitHub 提供的匿名地址 `<ID>+<用户名>@users.noreply.github.com`。其中 ID 在 GitHub 的 **Settings → Emails** 页面能看到。用它提交，记录照样算在你账号名下。

### 装 Node.js

只有生成搜索索引用得上，不需要写任何前端代码。

```powershell
winget install --id OpenJS.NodeJS.LTS -e --source winget
```

装的是 LTS 版，验证：

```powershell
node -v
npm -v
```

两个都输出版本号就行。需要同时维护多个 Node 版本可以上 `nvm-windows`，这个项目用不到。

国内网络如果 `npm install` 慢，可以换镜像（可选，Hugo 构建本身不依赖 npm 源）：

```powershell
npm config set registry https://registry.npmmirror.com
```

### 装 Hugo

winget 最省事：

```powershell
winget install Hugo.Hugo.Extended
```

如果 winget 卡住或者公司网络限制了商店，就直接下便携版：

```powershell
# 到 github.com/gohugoio/hugo/releases 找 hugo_extended_<版本>_windows-amd64.zip
# 解压后把 hugo.exe 放到一个固定目录，比如 D:\hugo\hugo.exe
D:\hugo\hugo.exe version
```

然后把目录加进用户 PATH（改完要**重开终端**才生效）：

```powershell
$bin = "D:\hugo"
$p = [Environment]::GetEnvironmentVariable("Path", "User")
if ($p -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$($p.TrimEnd(';'));$bin", "User")
}
```

### 最后验一遍

在 `pwsh` 里依次执行，四条都有输出就说明环境齐了：

```powershell
pwsh -v
git --version
node -v
hugo version
```

`hugo version` 的输出里必须带 `+extended`：

```
hugo v0.169.0-1da10fc44701c566b1669cdb2d12638f155138bd+extended windows/amd64
```

没有 `+extended` 的部分图片处理（webp 封面等）会失败，主题也可能报错。装了普通版就重装 extended 版。


## 二、建站

```powershell
hugo new site my-blog
cd my-blog
git init
```

Hugo 会生成 `archetypes/ content/ layouts/ static/ themes/ hugo.yaml` 这一套骨架。`hugo.yaml` 一开始长这样：

```yaml
baseURL: https://example.org/
locale: en-us
title: My New Hugo Project

theme:jijian
```

注意最后一行——**这是错的**。YAML 里键值之间必须有空格，`theme:jijian` 会被解析成一个叫 `theme:jijian` 的键，等于没设主题。我第一次就是这么翻车的，症状是整站渲染成没有任何样式的裸 HTML，而且不报错。

正确写法是 `theme: jijian`。

### 装主题

本站用的是[极简 jijian](https://github.com/hcllmsx/hugo-jijian)，基于 PaperMod 二次开发，中文排版和搜索做得比较细。用 git submodule 装：

```powershell
git submodule add https://github.com/hcllmsx/hugo-jijian.git themes/jijian
```

用 submodule 的好处是主题更新可以直接 `git submodule update --remote`；代价是**克隆仓库时必须带 `--recursive`**，否则 `themes/jijian` 是个空目录，构建直接失败。CI 里也要显式开启（后面会写）。

## 三、配置：几个必须改对的地方

完整的 `hugo.yaml` 比较长，这里只列容易出错的几处。

### locale 和分页

```yaml
locale: zh-cn
defaultContentLanguage: zh-cn
hasCJKLanguage: true

# 新版分页配置，旧的 paginate 键已废弃
pagination:
  pagerSize: 10
```

`languageCode` 已经被 Hugo 弃用，改用 `locale`。分页也从顶层的 `paginate: 10` 改成了 `pagination.pagerSize`，写旧的虽然还能跑但会有警告。

### 菜单

```yaml
menus:
  main:
    - identifier: posts
      name: 文章
      url: /posts/
      weight: 10
    - identifier: archives
      name: 时光轴
      url: /archives/
      weight: 20
```

这里有个隐性约束：主题会在菜单里做 `site.GetPage .KeyName`，靠 `identifier` 反查真实页面。**`identifier` 必须能对应到已存在的页面**，否则模板取值拿到 nil，构建会报错。所以 `/archives/` 这种菜单项，必须真的建一个 `content/archives.md`。

### PWA manifest 的后缀坑

主题带了 `layouts/index.manifest.json`，但默认情况下这个文件永远生成不出来，构建日志里会提示：

```
WARN found no layout file for "manifest" for kind "home"
```

原因是 Hugo 内置的 `application/manifest+json` 媒体类型后缀是 `webmanifest`，而主题模板的文件名是 `.json`，对不上。解决办法是覆盖媒体类型后缀：

```yaml
mediaTypes:
  application/manifest+json:
    suffixes: ["json"]

outputFormats:
  manifest:
    mediaType: application/manifest+json
    baseName: manifest
    isPlainText: true
    rel: manifest

outputs:
  home:
    - HTML
    - RSS
    - manifest
```

### 图标别漏

主题的 `head.html` 里写死了一串默认路径，不补文件就是一排 404：

```
href="/favicon.ico"
href="/favicon-16x16.png"
href="/favicon-32x32.png"
href="/apple-touch-icon.png"
href="/safari-pinned-tab.svg"
```

准备这几个文件扔进 `static/` 就行。没有现成的图标可以用 Python 的 Pillow 画一个，比找图标站快：

```python
from PIL import Image, ImageDraw, ImageFont

for size in (192, 512):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.22), fill=(31, 35, 40, 255))
    font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", int(size * 0.6))
    box = d.textbbox((0, 0), "J", font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((size - w) / 2 - box[0], (size - h) / 2 - box[1]), "J", font=font, fill=(245, 245, 245, 255))
    img.save(f"static/icon-{size}.png")
```

## 四、写文章

先把固定页面建好，主题靠 `layout` 字段区分渲染方式：

`content/archives.md`：

```yaml
---
title: 时光轴
layout: archives
---
```

`content/search.md`：

```yaml
---
title: 搜索
layout: search
placeholder: 输入关键词，回车搜索
---
```

这里**千不要把 YAML 的冒号打成中文全角冒号**。我一开始写的是 `title：时光轴`，构建不报错，但页面标题是空的——因为全角冒号让整行变成了一个普通字符串，不是键值对。

正文用骨架命令生成：

```powershell
hugo new content posts/my-first-post.md
```

默认 `draft: true`，本地加 `-D` 能看到，正式构建自动忽略。Front Matter 常用字段：

```yaml
---
title: 标题
date: 2026-11-13
draft: false
categories: ["技术"]
tags: ["Hugo", "教程"]
summary: 列表页摘要，不写则自动截取
pin: 1          # 置顶，正整数，越小越靠前
ShowToc: true   # 是否显示目录
cover:
  image: cover.webp
  alt: 封面
---
```

图片直接放在文章同目录（Page Bundle），正文用相对路径引用，主题会自动做灯箱和尺寸处理。

## 五、搜索：索引不在 hugo server 里

这是最容易误解的一点。主题的搜索用 Pagefind，它是**构建后的产物**——需要先有静态 HTML，才能扫描建索引。而 `hugo server` 是在内存里渲染的，`public/` 目录里什么都没有，所以本地预览时点搜索框必然是搜不到东西的，这不是配置错了。

正确流程是构建完再跑索引：

```powershell
hugo --gc --minify
node themes/jijian/scripts/pf-prep.cjs
npx pagefind --site _temp/pf-site --output-path public/pagefind
```

中间那个 `pf-prep.cjs` 是主题内置的中文修复脚本。原因是 Pagefind 建索引时按「相邻两字」切分，查询时按整词切分，两本词典不一致，导致「二维码」这类词索引里有、查询时拆成单字就搜不到（Pagefind 的 issue #987）。脚本会在 HTML 文本里插入零宽空格，让两端对齐。

嫌三条命令麻烦就写进 `package.json`：

```json
{
  "scripts": {
    "dev": "hugo server -D --disableFastRender",
    "build": "hugo --gc --minify",
    "search": "node themes/jijian/scripts/pf-prep.cjs && npx pagefind --site _temp/pf-site --output-path public/pagefind",
    "preview": "npm run build && npm run search && npx -y serve public"
  }
}
```

想验证搜索效果，用 `npm run preview` 起一个静态服务，别用 `hugo server`。

## 六、部署到 GitHub Pages

这一节全部在浏览器里点，除了 `git push` 之外不需要任何命令行工具。

### 先选站点形态

GitHub Pages 有两种地址：

- **用户站点**：仓库名必须叫 `<用户名>.github.io`，地址是 `https://用户名.github.io/`，根路径
- **项目站点**：仓库叫任意名字，地址带子目录 `https://用户名.github.io/仓库名/`

**对本站要选第一种。** 原因是主题的 `baseof.html` 里搜索资源的路径是写死根路径的：

```html
<link href="/pagefind/pagefind-component-ui.css" rel="stylesheet">
```

部署到子目录时，浏览器会去 `https://用户名.github.io/pagefind/...` 找，而实际文件在 `/仓库名/pagefind/...`，搜索样式和脚本全 404。除非改主题模板或者绑自定义域名，否则子路径方案搜索一定是坏的。

### 在网页上建仓库

1. 打开 `https://github.com/new`
2. **Repository name** 填 `<用户名>.github.io`，大小写不影响，但必须和用户名一字不差
3. 选 **Public**（Pages 免费额度只对公开仓库开放）
4. **不要勾** Add a README / .gitignore / license，否则本地首次推送会因为历史不一致被拒
5. 点 **Create repository**

建完页面会给你一段 Git 命令提示，先不用管，后面用得上。

### 准备推送凭据

GitHub 早就不允许用账号密码推送了。三种方式任选其一，都在网页上完成。

**方式一：交给 VS Code（最省事）**

在 VS Code 里打开这个项目，点左侧「源代码管理」图标，点 **Publish Branch**。第一次会弹窗让你登录 GitHub，浏览器里授权一次，之后 VS Code 会把凭据存进 Windows 凭据管理器，以后推送不再问。

**方式二：个人访问令牌（PAT）**

1. 右上角头像 → **Settings** → 左侧最下方 **Developer settings**
2. **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)**
3. Note 随便写，Expiration 选个期限（90 天够用）
4. 勾选 **repo** 和 **workflow** 两个权限——少勾 `workflow` 的话，CI 文件会因为权限不足推不上去
5. 生成后**立刻复制**，页面刷新就再也看不到这串字符了

推送时用户名填 GitHub 用户名，密码位置粘贴这串 token。

**方式三：SSH 密钥**

```powershell
ssh-keygen -t ed25519 -C "你的邮箱"
# 一路回车（密码可留空），然后复制公钥
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard
```

网页右上角头像 → **Settings** → **SSH and GPG keys** → **New SSH key** → 粘贴 → **Add SSH key**。

之后远端地址换成 SSH 形式：

```powershell
git remote add origin git@github.com:<用户名>/<用户名>.github.io.git
```

### 推送代码

```powershell
git add -A
git commit -m "初始化 Hugo 站点"
git branch -M main
git remote add origin https://github.com/<用户名>/<用户名>.github.io.git
git push -u origin main
```

需要认证时按上一节选的方式填。成功的话终端会显示 `main -> main`，浏览器刷新仓库就能看到文件。

### 把 Pages 发布源切成 GitHub Actions

默认 Pages 是「从分支发布」，也就是把仓库里的 HTML 原样发出去。我们的仓库里只有 Markdown 和模板，所以必须改成 Actions 构建。

1. 仓库顶部 **Settings**
2. 左侧 **Pages**
3. **Build and deployment** 下的 **Source** 下拉，选 **GitHub Actions**

如果下拉里只有 *Deploy from a branch*、找不到 GitHub Actions，说明仓库里还没有任何工作流文件。先把下一节的 `deploy.yml` 提交推送，再刷新这个页面就会出现。

### 工作流文件

在项目里新建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          submodules: recursive   # 必须，否则主题目录是空的
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: "0.169.0"
          extended: true

      - name: Setup Node
        uses: actions/setup-node@v7
        with:
          node-version: "22"
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Configure Pages
        id: pages
        uses: actions/configure-pages@v6

      - name: Build site
        run: hugo --gc --minify --baseURL "${{ steps.pages.outputs.base_url }}/"

      - name: Build search index
        run: npm run search

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v5
        with:
          path: ./public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

几个细节值得说：

- `submodules: recursive` 别忘了，漏了主题目录为空，构建会报 `found no layout file`
- `baseURL` 用 `configure-pages` 输出的值，不要写死，换域名时不用改代码
- `npm ci` 需要仓库里有 `package-lock.json`，否则会用 `npm install` 得到不确定的依赖版本
- Pagefind 版本固定在 `devDependencies` 里，别用 `npx -y pagefind@latest`，哪天发新版可能行为就变了

### 覆盖已有站点前先备份

如果这个仓库上已经有别的站点（比如早期的 Hexo），强推会把工作区内容整个换掉。**先在网页上打个分支留底**：

1. 仓库首页 → 分支下拉框 → **View all branches**
2. 右上角 **New branch**
3. 名字填 `legacy-hexo`，**Branch from** 选 `main`
4. **Create branch**

这个分支就停在旧站的状态。之后强推 main 只会影响 main：

```powershell
git push -f origin main
```

哪天想看旧站：

```powershell
git fetch origin legacy-hexo
git checkout legacy-hexo
```

### 看构建结果

1. 仓库顶部 **Actions**
2. 左侧选 **Deploy to GitHub Pages**
3. 点最新那条运行记录，能看到 `build` 和 `deploy` 两个 job 的每一步

全绿就说明上线了，点开 `deploy` 页面顶部会显示站点地址。**首次部署后地址生效可能需要 1–2 分钟**，这期间打开是 404 属于正常。

## 七、日常流程

上线之后，每天要做的其实只有三件事：

1. `hugo new content posts/xxx.md` 新建草稿
2. 本地 `hugo server -D` 预览，写完把 `draft` 改成 `false`
3. `git push`，等 Actions 跑完自动上线

搜索索引、构建、发布都由 CI 接管，本地不需要手动跑 `hugo`。

## 八、报错对照表

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 整站无样式，像裸 HTML | `hugo.yaml` 里 `theme:jijian` 少了空格 | 改成 `theme: jijian` |
| 页面标题空白 | Front Matter 用了中文全角冒号 `title：` | 换成半角 `title:` |
| 命令报 `标记"&&"不是此版本中的有效语句分隔符` | 用的是 Windows PowerShell 5.1 | 装 PowerShell 7，改用 `pwsh` |
| `git commit` 报 `Author identity unknown` | 没配提交身份 | `git config --global user.name` 和 `user.email` |
| 终端里 `node` / `npm` 找不到 | 装的是某个软件自带的 Node，没进系统 PATH | 用 winget 装 `OpenJS.NodeJS.LTS` |
| 构建报 `found no layout file for "manifest"` | manifest 媒体类型后缀是 webmanifest | 在 `mediaTypes` 里改成 `json` |
| CI 报主题目录为空 | submodule 没拉取 | checkout 加 `submodules: recursive` |
| 搜索框样式全丢 | 部署在子路径，`/pagefind/` 被解析到根域名 | 改用用户站点或绑自定义域名 |
| 本地预览搜不到内容 | Pagefind 索引是构建产物，`hugo server` 不生成 | 用 `npm run preview` 验证 |
| 菜单报 nil pointer | 菜单 `identifier` 找不到对应页面 | 建好 `content/archives.md` 这类页面 |
| push 报 `Authentication failed` | 还在用账号密码 | 改用 PAT 或 SSH，见「准备推送凭据」 |
| Pages 的 Source 里没有 GitHub Actions | 仓库里还没有工作流文件 | 先推 `deploy.yml`，再刷新 Pages 设置 |
| push 报 `dial tcp ...:443` 超时 | 网络无法直连 github.com | 配代理，见下 |

当然遇到的所有报错或者问题都可以向dsh询问解决，不过要注意的一点是，GitHub那里如果不想自己做做好还是用SSH密钥，不然校园网可能会使得你的端口无法正常使用。

## 附：代理环境下的配置

如果所在网络访问 GitHub 需要代理（我这边就是这样：`api.github.com` 能直连，但 `github.com` 超时），只需要配一处：

```powershell
# 让 git 走本机代理，只影响这个仓库
git config http.proxy http://127.0.0.1:7890
```

浏览器里的网页操作不用单独设，跟着 Clash 之类的系统代理走就行。

哪天关掉代理后推送报 `Failed to connect to 127.0.0.1 port 7890`，重新开代理即可；想彻底去掉这条配置就执行：

```powershell
git config --unset http.proxy
```

到这里整条链路就通了。剩下的时间应该花在写东西上，而不是修构建。
