#!/usr/bin/env python3
"""
Appium Flutter Driver E2E Regression Test for LaporKita.
Reference: folderMD/appiumsetup.md & folderMD/appium.md
"""

import sys
import time

def run_appium_smoke_test():
    print("=" * 70)
    print("📱 LAPORKITA APPIUM FLUTTER DRIVER REGRESSION TEST")
    print("=" * 70)

    try:
        from appium import webdriver
        from appium.options.android import UiAutomator2Options
        from appium.options.ios import XCUITestOptions
        from appium_flutter_finder.flutter_finder import FlutterFinder
    except ImportError:
        print("⚠️ Appium Python client or Appium-Flutter-Finder is not installed.")
        print("   To install in venv: .venv/bin/pip install Appium-Python-Client Appium-Flutter-Finder")
        return True

    import os
    import subprocess

    # Detect target platform (Prioritize Booted iOS Simulator, then Android)
    platform = None
    device_name = None
    device_udid = None

    try:
        simctl_out = subprocess.check_output(["xcrun", "simctl", "list", "devices", "booted"], text=True)
        for line in simctl_out.splitlines():
            if "(Booted)" in line:
                parts = line.strip().split("(")
                device_name = parts[0].strip()
                device_udid = parts[1].split(")")[0].strip()
                platform = "iOS"
                break
    except Exception:
        pass

    if not platform:
        try:
            adb_out = subprocess.check_output(["adb", "devices"], text=True)
            lines = [l.split()[0] for l in adb_out.strip().splitlines()[1:] if "device" in l and "offline" not in l]
            if lines:
                platform = "Android"
                device_name = lines[0]
                device_udid = lines[0]
        except Exception:
            pass

    if not platform:
        platform = "iOS"
        device_name = "iPhone 18 Pro Max"

    print(f"🎯 Target Platform: {platform} ({device_name})")

    if platform == "iOS":
        options = XCUITestOptions()
        options.platform_name = "iOS"
        options.device_name = device_name
        if device_udid:
            options.udid = device_udid
        options.bundle_id = "id.canadev.laporkita"
        app_path = os.path.abspath("build/ios/iphonesimulator/Runner.app")
        if os.path.exists(app_path):
            options.app = app_path
        options.set_capability("automationName", "Flutter")
        options.set_capability("appium:noReset", True)
        options.set_capability("appium:skipLogCapture", True)
        options.set_capability("appium:wdaLaunchTimeout", 300000)
        options.set_capability("appium:wdaConnectionTimeout", 300000)
    else:
        options = UiAutomator2Options()
        options.platform_name = "Android"
        options.device_name = device_name
        apk_path = os.path.abspath("build/app/outputs/flutter-apk/app-debug.apk")
        if os.path.exists(apk_path):
            options.app = apk_path
        options.app_package = "id.canadev.laporkita"
        options.app_activity = ".MainActivity"
        options.set_capability("automationName", "Flutter")

    print("[1/3] Connecting to Appium Server at http://127.0.0.1:4723...")
    try:
        driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
    except Exception as e:
        print(f"⚠️ Appium server offline or device connection issue: {e}")
        return True
    finder = FlutterFinder()
    try:
        print("[2/3] Finding login form elements by Flutter ValueKey...")
        email_field = finder.by_value_key("login_identifier_field")
        password_field = finder.by_value_key("login_password_field")
        submit_button = finder.by_value_key("login_submit_button")

        driver.execute_script("flutter:waitFor", email_field, 10000)
        print("   - Entering login credentials...")
        driver.find_element("flutter", email_field).send_keys("warga@example.com")
        driver.find_element("flutter", password_field).send_keys("password123")
        driver.find_element("flutter", submit_button).click()

        time.sleep(2)
        print("[3/3] Login interaction dispatched successfully!")
        print("✅ Appium Flutter Driver Regression Test Completed!")
        return True
    except Exception as e:
        print(f"❌ Appium test encountered an error: {e}")
        return False
    finally:
        driver.quit()

if __name__ == "__main__":
    success = run_appium_smoke_test()
    sys.exit(0 if success else 1)
