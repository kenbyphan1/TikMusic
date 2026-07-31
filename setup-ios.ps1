# setup-ios.ps1
# =====================================================================
# Tự động hoá: push source lên GitHub -> GitHub Actions build IPA -> tải về
# -> mở Sideloadly sẵn sàng cài lên iPhone.
#
# CÁCH DÙNG:
#   powershell -ExecutionPolicy Bypass -File .\setup-ios.ps1
#
# Những bước bạn vẫn phải làm một lần (không tự động được):
#   1. Có tài khoản GitHub (tạo miễn phí tại github.com)
#   2. Đăng nhập GitHub khi script mở trình duyệt (lệnh gh auth login)
#   3. Cắm iPhone qua cáp USB + tin tưởng chứng chỉ (xem hướng dẫn cuối)
#   4. Đăng nhập Apple ID bên trong Sideloadly
# =====================================================================
param(
    [string]$RepoName = "TikMusic",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
$ipaPath = Join-Path $env:TEMP "TikMusic.ipa"

Write-Host ""
Write-Host "=== TIKMUSIC - TỰ ĐỘNG BUILD IPA VIA GITHUB ACTIONS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Kiểm tra Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[1/7] Cài đặt Git..." -ForegroundColor Yellow
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent
    $env:Path = "C:\Program Files\Git\cmd;" + $env:Path
}
Write-Host "[1/7] Git: OK ($(git --version))" -ForegroundColor Green

# 2. Kiểm tra GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[2/7] Cài đặt GitHub CLI..." -ForegroundColor Yellow
    winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements --silent
    $env:Path = "C:\Program Files\GitHub CLI;" + $env:Path
}

# 3. Đăng nhập GitHub (một lần)
$auth = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[3/7] Cần đăng nhập GitHub. Trình duyệt sẽ mở ra - hãy đăng nhập." -ForegroundColor Yellow
    gh auth login --hostname github.com --web
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Lỗi: chưa đăng nhập GitHub. Chạy lại script." -ForegroundColor Red
        exit 1
    }
}
Write-Host "[3/7] GitHub: đã đăng nhập ($(gh auth status --active-account))" -ForegroundColor Green

# 4. Tạo repo + push (nếu chưa có)
Set-Location $root
if (-not (Test-Path ".git")) {
    Write-Host "[4/7] Khởi tạo git repo..." -ForegroundColor Yellow
    git init -b $Branch
    git add -A
    git -c user.email="tikmusic@local" -c user.name="TikMusic" commit -m "TikMusic: initial commit"
}

$hasRemote = git remote get-url origin 2>$null
if (-not $hasRemote) {
    Write-Host "[4/7] Tạo repo GitHub '$RepoName'..." -ForegroundColor Yellow
    gh repo create $RepoName --private --source . --remote origin --push
} else {
    Write-Host "[4/7] Push lên GitHub..." -ForegroundColor Yellow
    git add -A
    git -c user.email="tikmusic@local" -c user.name="TikMusic" commit -m "build: chuẩn bị build IPA" 2>$null
    git push -u origin $Branch
}

# 5. Kích hoạt build trên GitHub Actions
Write-Host "[5/7] Kích hoạt workflow build IPA..." -ForegroundColor Yellow
gh workflow run "Build IPA (TikMusic)" --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" 2>$null
$runId = gh run list --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" --workflow "Build IPA (TikMusic)" --limit 1 --json databaseId -q ".[0].databaseId"
Write-Host "    Build ID: $runId" -ForegroundColor Cyan

# 6. Chờ build xong và tải IPA về
Write-Host "[6/7] Chờ GitHub Actions build (máy macOS của GitHub, ~3-8 phút)..." -ForegroundColor Yellow
gh run watch $runId --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" --exit-status
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build thất bại. Xem log: gh run view $runId --log --repo ..." -ForegroundColor Red
    exit 1
}
gh run download $runId --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" --name "TikMusic-ipa" --dir $env:TEMP
$downloaded = Get-ChildItem -Path $env:TEMP -Recurse -Filter "TikMusic.ipa" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $downloaded) {
    Write-Host "Không tìm thấy file IPA đã tải." -ForegroundColor Red
    exit 1
}
Copy-Item $downloaded.FullName $ipaPath -Force
Write-Host "    Đã tải IPA: $ipaPath ($([math]::Round((Get-Item $ipaPath).Length/1MB,1)) MB)" -ForegroundColor Green

# 7. Mở Sideloadly với IPA
Write-Host "[7/7] Mở Sideloadly..." -ForegroundColor Yellow
$sideloadly = @(
    "$env:USERPROFILE\Sideloadly\sideloadly.exe",
    "C:\Program Files\Sideloadly\sideloadly.exe",
    "$env:LOCALAPPDATA\Programs\Sideloadly\sideloadly.exe",
    "$env:USERPROFILE\Desktop\Sideloadly\sideloadly.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($sideloadly) {
    Start-Process $sideloadly -ArgumentList "`"$ipaPath`""
    Write-Host "    Đã mở Sideloadly với file $ipaPath" -ForegroundColor Green
} else {
    Write-Host "Không tìm thấy Sideloadly. Mở file IPA thủ công: $ipaPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== XONG. CÁC BƯỚC CUỐI TRÊN MÁY BẠN ===" -ForegroundColor Green
Write-Host "1. Cắm iPhone qua cáp USB, mở khoá máy, chọn 'Tin cậy máy tính này'." -ForegroundColor White
Write-Host "2. Trong Sideloadly: nhập Apple ID miễn phí của bạn -> Start." -ForegroundColor White
Write-Host "3. Trên iPhone: Cài đặt -> Cài đặt chung -> VPN & Quản lý thiết bị -> Tin tưởng." -ForegroundColor White
Write-Host "4. Mở app, vào Cài đặt -> nhập YouTube API Key (lấy ở console.cloud.google.com)." -ForegroundColor White
Write-Host "Lưu ý: app hết hạn sau 7 ngày - mở lại Sideloadly để ký lại." -ForegroundColor DarkYellow
Write-Host ""
