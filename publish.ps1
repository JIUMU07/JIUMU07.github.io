# 一键发布：本地编译（含搜索索引）+ 直接同步到服务器
# 在 VS Code 里 Ctrl+Shift+B 触发；或终端执行 .\publish.ps1
# 全程约 10 秒，不经过 GitHub Actions
$ErrorActionPreference = "Stop"

npm run build
if ($LASTEXITCODE -ne 0) { Write-Host "编译失败，未发布" -ForegroundColor Red; exit 1 }

npm run search
if ($LASTEXITCODE -ne 0) { Write-Host "搜索索引生成失败，未发布" -ForegroundColor Red; exit 1 }

Write-Host "编译与索引完成，同步到服务器..."
ssh root@8.136.3.4 "rm -rf /opt/novelsite/blog/public/*"
scp -r -q public/* root@8.136.3.4:/opt/novelsite/blog/public/

Write-Host "已发布: http://8.136.3.4/" -ForegroundColor Green
Write-Host "提醒: 记得 git 提交推送本次改动，保持 GitHub 备份同步" -ForegroundColor Yellow
