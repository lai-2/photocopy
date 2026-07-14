# ===========================================
# Update Vietnam Time
# ===========================================

# Tự chạy lại bằng quyền Administrator nếu cần
$currentUser = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}

Clear-Host

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Update Vietnam System Time"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Đặt múi giờ Việt Nam
try {
    Set-TimeZone -Id "SE Asia Standard Time"
    Write-Host "[OK] Time zone: Vietnam (UTC+7)" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Cannot set time zone." -ForegroundColor Red
}

# Đảm bảo Windows Time Service luôn tự khởi động
Set-Service w32time -StartupType Automatic

# Khởi động service nếu chưa chạy
if ((Get-Service w32time).Status -ne "Running") {
    Start-Service w32time
}

Write-Host "[OK] Windows Time service is running." -ForegroundColor Green

# Cấu hình NTP
Write-Host ""
Write-Host "Configuring NTP servers..."

w32tm /config `
    /manualpeerlist:"time.google.com,0x8 time.cloudflare.com,0x8 pool.ntp.org,0x8" `
    /syncfromflags:manual `
    /reliable:no `
    /update | Out-Null

# Khởi động lại dịch vụ để áp dụng cấu hình
Restart-Service w32time

# Đồng bộ thời gian
Write-Host ""
Write-Host "Synchronizing time..."

$resyncOutput = w32tm /resync /force 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Time synchronized successfully." -ForegroundColor Green
} else {
    Write-Host "[WARNING] Time synchronization failed." -ForegroundColor Yellow
    $resyncOutput | ForEach-Object { Write-Host $_ }
}

Write-Host ""
Write-Host "------------------------------------------"
Write-Host "Current Time:"
Get-Date
Write-Host "------------------------------------------"

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Read-Host "Press Enter to exit"