param(
    [string]$Stamp = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Fail($msg) {
    Write-Host $msg -ForegroundColor Red
    exit 1
}

$remote = @"
set -e
cd /opt/novelsite/blog
if [ -z "$Stamp" ]; then
    SRC=`$(ls -1dt releases/* | head -1)
else
    SRC="releases/$Stamp"
fi
test -d "`$SRC"
rsync -a --delete "`$SRC/" public/
echo "rolled_back=`$SRC"
"@
$remote = $remote -replace "`r", ""
$remote | ssh -4 -o ConnectTimeout=15 seoul "bash -s"
if ($LASTEXITCODE -ne 0) { Fail "回滚失败，请检查 /opt/novelsite/blog/releases" }

Write-Host "回滚完成，烟测..." -ForegroundColor Cyan
foreach ($u in @("https://huangth.xyz/", "https://huangth.xyz/pagefind/pagefind-component-ui.js")) {
    try {
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
        if ($r.StatusCode -ne 200) { Fail ("烟测失败: " + $u + " -> " + $r.StatusCode) }
        Write-Host ("OK " + $u) -ForegroundColor Green
    } catch {
        Fail ("烟测失败: " + $u + " -> " + $_.Exception.Message)
    }
}
