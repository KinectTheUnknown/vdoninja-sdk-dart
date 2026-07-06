#!/usr/bin/env bash
# Run web integration tests using ChromeDriver.
# Automatically installs and starts ChromeDriver if needed.
# Usage: ./run_integration_tests.sh
set -e

CHROMEDRIVER_DIR="chromedriver"

# Find the chromedriver executable inside the local directory or system PATH
find_chromedriver() {
  # 1. Search locally in the chromedriver directory
  local local_bin
  local_bin=$(find "$CHROMEDRIVER_DIR" -name "chromedriver" -o -name "chromedriver.exe" 2>/dev/null | head -n 1)
  if [ -n "$local_bin" ]; then
    echo "$local_bin"
    return 0
  fi

  # 2. Check if available globally in PATH
  if command -v chromedriver >/dev/null 2>&1; then
    echo "chromedriver"
    return 0
  fi

  return 1
}

# Check for ChromeDriver
if ! CHROMEDRIVER_BIN=$(find_chromedriver); then
  echo "❌ ChromeDriver not found!"
  echo "Please install ChromeDriver and add it to your PATH, or run:"
  echo "  npx @puppeteer/browsers install chromedriver@stable"
  echo "to install it locally in the project directory."
  exit 1
fi
echo "✅ ChromeDriver found at: $CHROMEDRIVER_BIN"

# Start ChromeDriver if not already running
if ! curl -s http://localhost:9515/status > /dev/null 2>&1; then
  echo "🚀 Starting ChromeDriver..."
  "$CHROMEDRIVER_BIN" --port=9515 &
  CHROMEDRIVER_PID=$!
  sleep 2
  echo "   ChromeDriver started (PID: $CHROMEDRIVER_PID)"
else
  echo "✅ ChromeDriver is already running on port 9515."
  CHROMEDRIVER_PID=""
fi

# Run integration tests
echo "🧪 Running web integration tests..."
puro flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=test/vdoninja_sdk_web_test.dart \
  -d chrome \
  --web-browser-flag="--use-fake-ui-for-media-stream" \
  --web-browser-flag="--use-fake-device-for-media-stream" \
  --web-browser-flag="--autoplay-policy=no-user-gesture-required"
TEST_EXIT=$?

# Stop ChromeDriver if we started it
if [ -n "$CHROMEDRIVER_PID" ]; then
  echo "🛑 Stopping ChromeDriver (PID: $CHROMEDRIVER_PID)..."
  kill "$CHROMEDRIVER_PID" 2>/dev/null || true
fi

exit $TEST_EXIT
