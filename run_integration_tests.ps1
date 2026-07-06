$CHROMEDRIVER_DIR = "chromedriver"

function Find-ChromeDriver {
    # 1. Search locally in the chromedriver directory
    if (Test-Path $CHROMEDRIVER_DIR) {
        $localBin = Get-ChildItem -Path $CHROMEDRIVER_DIR -Filter "chromedriver.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($localBin) {
            return $localBin.FullName
        }
    }
    
    # 2. Check if available globally in PATH
    $globalBin = Get-Command "chromedriver" -ErrorAction SilentlyContinue
    if ($globalBin) {
        return "chromedriver"
    }
    
    return $null
}

$CHROMEDRIVER_BIN = Find-ChromeDriver

if (-not $CHROMEDRIVER_BIN) {
    Write-Host "❌ ChromeDriver not found!" -ForegroundColor Red
    Write-Host "Please install ChromeDriver and add it to your PATH, or run:"
    Write-Host "  npx @puppeteer/browsers install chromedriver@stable"
    Write-Host "to install it locally in the project directory."
    exit 1
}

Write-Host "✅ ChromeDriver found at: $CHROMEDRIVER_BIN"

$statusUrl = "http://localhost:9515/status"
$running = $false
try {
    $response = Invoke-RestMethod -Uri $statusUrl -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response) { $running = $true }
} catch {}

$CHROMEDRIVER_PROCESS = $null

if (-not $running) {
    Write-Host "🚀 Starting ChromeDriver..."
    $CHROMEDRIVER_PROCESS = Start-Process -FilePath $CHROMEDRIVER_BIN -ArgumentList "--port=9515" -PassThru -NoNewWindow
    Start-Sleep -Seconds 2
    Write-Host "   ChromeDriver started (PID: $($CHROMEDRIVER_PROCESS.Id))"
} else {
    Write-Host "✅ ChromeDriver is already running on port 9515."
}

Write-Host "🧪 Running web integration tests..."
puro flutter drive `
  --driver=test_driver/integration_test.dart `
  --target=test/vdoninja_sdk_web_test.dart `
  -d chrome `
  --web-browser-flag="--use-fake-ui-for-media-stream" `
  --web-browser-flag="--use-fake-device-for-media-stream" `
  --web-browser-flag="--autoplay-policy=no-user-gesture-required"

$TEST_EXIT = $LASTEXITCODE

if ($CHROMEDRIVER_PROCESS) {
    Write-Host "🛑 Stopping ChromeDriver (PID: $($CHROMEDRIVER_PROCESS.Id))..."
    Stop-Process -Id $CHROMEDRIVER_PROCESS.Id -Force -ErrorAction SilentlyContinue
}

exit $TEST_EXIT
