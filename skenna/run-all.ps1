param(
    [string]$ApiBaseUrl = $(if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://127.0.0.1:8000" })
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendPath = Join-Path $root "frontend"
$backendPath = Join-Path $root "skenna_backend"
$pythonExe = Join-Path $root ".venv\Scripts\python.exe"
$pubCachePath = Join-Path $root ".pub-cache"

$env:PUB_CACHE = $pubCachePath

if (-not (Test-Path $pubCachePath)) {
    New-Item -ItemType Directory -Path $pubCachePath | Out-Null
}

if (-not (Test-Path $pythonExe)) {
    Write-Error "Python environment not found at $pythonExe. Run: python -m venv .venv"
    exit 1
}

Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Set-Location '$backendPath'; & '$pythonExe' -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
)

Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Set-Location '$frontendPath'; `$env:PUB_CACHE='$pubCachePath'; flutter run --dart-define=API_BASE_URL=$ApiBaseUrl"
)



Write-Host "Started backend and frontend."
Write-Host "Backend:  http://127.0.0.1:8000"
Write-Host "Frontend: flutter run in a separate window"