$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "$env:Path;$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:LOCALAPPDATA\Android\Sdk\emulator"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  APPIUM SERVER UNTUK LAPORKITA        " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Yellow
Write-Host "Menjalankan Appium di http://127.0.0.1:4723..." -ForegroundColor White
Write-Host "Biarkan jendela ini tetap terbuka selama testing!" -ForegroundColor Gray
Write-Host "----------------------------------------" -ForegroundColor Cyan

appium
