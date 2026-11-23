# 一键发布：本地编译（含搜索索引）+ 打包单文件上传 + 服务器原子替换
# 在 VS Code 里 Alt+B / Ctrl+Shift+B 触发；或终端执行 .\publish.ps1
# 说明：public/ 文件多但每个很小，逐个 scp 会被"每文件一次往返"拖到几分钟，
#       打包成 tar.gz 后只传一个文件，通常 10~20 秒完成。
$ErrorActionPreference = "Stop"
# 统一 UTF-8 输出，避免中文乱码；必须用「不带 BOM」的 UTF8，
# 否则通过管道喂给远端 bash 时会在开头多出一个 BOM（报 ﻿set: command not found）
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Fail($msg) {
    Write-Host $msg -ForegroundColor Red
    exit 1
}

$hugoVersion = ((hugo version) -join " ")
if ($hugoVersion -notmatch 'v0\.169\.0') {
    Fail ("Hugo 版本不匹配，需要 v0.169.0 extended，当前: " + $hugoVersion)
}

# 加密文章功能已禁用：主题的 single.html 会把密码明文写进 HTML，
# 且 encrypt.js 未接入构建。发布前直接拦截，避免误发。
$locked = Get-ChildItem (Join-Path $Root "content") -Recurse -File -Filter *.md |
    Select-String -Pattern '^\s*(mima|password|protected)\s*:'
if ($locked) {
    Write-Host "encrypted articles are disabled; found:" -ForegroundColor Red
    $locked | ForEach-Object { Write-Host ("  " + $_.Path) -ForegroundColor Red }
    exit 1
}

$t0 = Get-Date

Write-Host "[1/5] 编译..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) { Fail "编译失败，未发布" }

Write-Host "[2/5] 生成搜索索引..." -ForegroundColor Cyan
npm run search
if ($LASTEXITCODE -ne 0) { Fail "搜索索引生成失败，未发布" }

$tar = Join-Path $env:TEMP ("blog-public-{0}.tar.gz" -f $PID)
try {
    Write-Host "[3/5] 打包并上传..." -ForegroundColor Cyan
    tar -czf $tar -C (Join-Path $Root "public") .
    if ($LASTEXITCODE -ne 0) { Fail "打包失败，未发布" }
    $mb = [math]::Round((Get-Item $tar).Length / 1MB, 2)
    Write-Host ("      包大小 {0} MB" -f $mb)

    # -4 强制 IPv4：默认会先尝试 IPv6，跨境链路上会白等十几秒
    scp -q -4 -o ConnectTimeout=15 $tar "seoul:/tmp/blog-public.tar.gz"
    if ($LASTEXITCODE -ne 0) { Fail "上传失败，未发布" }

    Write-Host "[4/5] 服务器解包 + 原子替换..." -ForegroundColor Cyan
    $remote = @"
set -e
cd /opt/novelsite/blog
STAMP=`$(date +%Y%m%d-%H%M%S)
mkdir -p releases
if [ -d public ]; then cp -a public "releases/`$STAMP"; fi
ls -1dt releases/* | tail -n +6 | xargs -r rm -rf
rm -rf _stage
mkdir -p _stage
tar -xzf /tmp/blog-public.tar.gz -C _stage
rsync -a --delete _stage/ public/
rm -rf _stage /tmp/blog-public.tar.gz
echo "release=`$STAMP"
"@
    # PowerShell 的 here-string 是 CRLF，直接喂给 bash 会把 \r 当成命令的一部分
    $remote = $remote -replace "`r", ""
    $remote | ssh -4 -o ConnectTimeout=15 seoul "bash -s"
    if ($LASTEXITCODE -ne 0) { Fail "服务器解包/替换失败，请检查 /opt/novelsite/blog" }

    Write-Host "[5/5] 烟测..." -ForegroundColor Cyan
    $checks = @(
        "https://huangth.xyz/",
        "https://huangth.xyz/index.xml",
        "https://huangth.xyz/pagefind/pagefind-component-ui.js"
    )
    foreach ($u in $checks) {
        try {
            $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
            if ($r.StatusCode -ne 200) { Fail ("烟测失败: " + $u + " -> " + $r.StatusCode) }
            Write-Host ("      OK " + $u) -ForegroundColor Green
        } catch {
            Fail ("烟测失败: " + $u + " -> " + $_.Exception.Message)
        }
    }
}
finally {
    if (Test-Path $tar) { Remove-Item $tar -Force -ErrorAction SilentlyContinue }
}

$sec = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
Write-Host ("完成：https://huangth.xyz/ （耗时 {0}s）" -f $sec) -ForegroundColor Green
Write-Host "提醒：记得 git 提交并推送本次改动，保持 GitHub 备份同步" -ForegroundColor Yellow
