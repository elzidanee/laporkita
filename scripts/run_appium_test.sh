#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=================================================="
echo "🚀 LAPORKITA APPIUM AUTOMATION RUNNER"
echo "=================================================="

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH:$HOME/.local/bin"

# 1. Cek Device / Simulator
echo "[1/4] Memeriksa Android Device atau iOS Simulator yang aktif..."
IOS_BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep "(Booted)" | head -n 1)
ANDROID_DEVICES=$(adb devices 2>/dev/null | grep -v "List of devices" | grep "device$" | awk '{print $1}')

if [ -n "$IOS_BOOTED" ]; then
  echo "    📱 Terdeteksi iOS Simulator Booted: $IOS_BOOTED"
elif [ -n "$ANDROID_DEVICES" ]; then
  echo "    🤖 Terdeteksi Android Device: $ANDROID_DEVICES"
else
  echo "⚠️  PERINGATAN: Tidak ada Android device maupun iOS simulator yang aktif."
fi

# 2. Cek Appium Server
echo "[2/4] Memeriksa status Appium Server (http://127.0.0.1:4723)..."
STARTED_APPIUM=0
if ! curl -s http://127.0.0.1:4723/status > /dev/null 2>&1; then
  echo "    Appium server belum berjalan. Memulai Appium server di background..."
  appium --address 127.0.0.1 --port 4723 > /tmp/appium_server.log 2>&1 &
  APPIUM_PID=$!
  STARTED_APPIUM=1
  
  # Tunggu server siap
  for i in {1..10}; do
    if curl -s http://127.0.0.1:4723/status | grep -q '"ready":true'; then
      echo "    Appium server berhasil dimulai (PID: $APPIUM_PID)!"
      break
    fi
    sleep 1
  done
else
  echo "    Appium server sudah aktif di port 4723."
fi

# 3. Jalankan Test
echo "[3/4] Menjalankan Automation Test..."
if [ -f ".venv/bin/python3" ]; then
  .venv/bin/python3 test_driver/appium_regression_test.py
else
  python3 test_driver/appium_regression_test.py
fi

# 4. Cleanup jika tadi kita yang menyalakan appium server di script ini
if [ "$STARTED_APPIUM" -eq 1 ] && [ -n "$APPIUM_PID" ]; then
  echo "[4/4] Menghentikan background Appium server (PID: $APPIUM_PID)..."
  kill "$APPIUM_PID" 2>/dev/null || true
fi

echo "=================================================="
echo "Selesai!"
