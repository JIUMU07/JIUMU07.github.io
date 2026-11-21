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

$t0 = Get-Date

Write-Host "[1/4] 编译..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) { Fail "编译失败，未发布" }

Write-Host "[2/4] 生成搜索索引..." -ForegroundColor Cyan
npm run search
if ($LASTEXITCODE -ne 0) { Fail "搜索索引生成失败，未发布" }

$tar = Join-Path $env:TEMP ("blog-public-{0}.tar.gz" -f $PID)
try {
    Write-Host "[3/4] 打包并上传..." -ForegroundColor Cyan
    tar -czf $tar -C (Join-Path $Root "public") .
    if ($LASTEXITCODE -ne 0) { Fail "打包失败，未发布" }
    $mb = [math]::Round((Get-Item $tar).Length / 1MB, 2)
    Write-Host ("      包大小 {0} MB" -f $mb)

    # -4 强制 IPv4：默认会先尝试 IPv6，跨境链路上会白等十几秒
    scp -q -4 -o ConnectTimeout=15 $tar "seoul:/tmp/blog-public.tar.gz"
    if ($LASTEXITCODE -ne 0) { Fail "上传失败，未发布" }

    Write-Host "[4/4] 服务器解包 + 原子替换..." -ForegroundColor Cyan
    $remote = @"
set -e
rm -rf /opt/novelsite/blog/_stage
mkdir -p /opt/novelsite/blog/_stage
tar -xzf /tmp/blog-public.tar.gz -C /opt/novelsite/blog/_stage
rsync -a --delete /opt/novelsite/blog/_stage/ /opt/novelsite/blog/public/
rm -rf /opt/novelsite/blog/_stage /tmp/blog-public.tar.gz
"@
    # PowerShell 的 here-string 是 CRLF，直接喂给 bash 会把 \r 当成命令的一部分
    $remote = $remote -replace "`r", ""
    $remote | ssh -4 -o ConnectTimeout=15 seoul "bash -s"
    if ($LASTEXITCODE -ne 0) { Fail "服务器解包/替换失败，请检查 /opt/novelsite/blog" }
}
finally {
    if (Test-Path $tar) { Remove-Item $tar -Force -ErrorAction SilentlyContinue }
}

$sec = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
Write-Host ("完成：https://huangth.xyz/ （耗时 {0}s）" -f $sec) -ForegroundColor Green
Write-Host "提醒：记得 git 提交并推送本次改动，保持 GitHub 备份同步" -ForegroundColor Yellow
