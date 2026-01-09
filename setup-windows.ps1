# Skrypt instalacyjny dla Windows
# Uruchom jako Administrator w PowerShell

Write-Host "=== Instalator narzędzi dla FuckingCalculator ===" -ForegroundColor Green
Write-Host ""

# Sprawdź czy Chocolatey jest zainstalowany
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Instaluję Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Write-Host "Instaluję Node.js..." -ForegroundColor Yellow
choco install nodejs-lts -y

Write-Host "Odświeżam zmienne środowiskowe..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "Instaluję Cordova..." -ForegroundColor Yellow
npm install -g cordova

Write-Host "Instaluję Android Studio..." -ForegroundColor Yellow
Write-Host "UWAGA: Android Studio wymaga ręcznej konfiguracji!" -ForegroundColor Red
Write-Host "Pobierz z: https://developer.android.com/studio" -ForegroundColor Cyan
Write-Host "Podczas instalacji zaznacz:" -ForegroundColor Cyan
Write-Host "  - Android SDK" -ForegroundColor Cyan
Write-Host "  - Android SDK Platform" -ForegroundColor Cyan
Write-Host "  - Android Virtual Device" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== Instalacja Node.js i Cordova zakończona ===" -ForegroundColor Green
Write-Host "Po zainstalowaniu Android Studio uruchom:" -ForegroundColor Yellow
Write-Host "  cd C:\Users\Maacias\FuckingCalculator" -ForegroundColor White
Write-Host "  cordova build android" -ForegroundColor White
