import os
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium_flutter_finder.flutter_finder import FlutterFinder

# Path APK debug hasil build dengan test_driver/app.dart
base_dir = os.path.dirname(os.path.abspath(__file__))
apk_path = os.path.join(base_dir, "build", "app", "outputs", "flutter-apk", "app-debug.apk")

options = UiAutomator2Options()
options.platform_name = "Android"
options.device_name = "emulator-5554"  # Sesuaikan jika ID device berbeda pada `adb devices`
options.app = apk_path
options.app_package = "id.canadev.laporkita"  # Application ID resmi LaporKita
options.app_activity = ".MainActivity"
options.set_capability("automationName", "Flutter")

print("🚀 Menghubungkan ke Appium Server di http://127.0.0.1:4723...")
print(f"📦 Memuat APK: {apk_path}")

driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
finder = FlutterFinder()

try:
    print("⏳ Menunggu widget formulir login dimuat...")
    email_field = finder.by_value_key("login_identifier_field")
    password_field = finder.by_value_key("login_password_field")
    submit_button = finder.by_value_key("login_submit_button")

    # Tunggu widget muncul sebelum interaksi
    driver.execute_script("flutter:waitFor", email_field, 10000)
    
    print("⌨️ Memasukkan nomor HP / email...")
    driver.find_element("flutter", email_field).send_keys("warga@example.com")
    
    print("⌨️ Memasukkan password...")
    driver.find_element("flutter", password_field).send_keys("password123")
    
    print("👆 Menekan tombol Login...")
    driver.find_element("flutter", submit_button).click()

    time.sleep(3)
    print("✅ Interaksi test login berhasil dikirim ke aplikasi!")

except Exception as e:
    print(f"❌ Test gagal: {e}")
    raise

finally:
    driver.quit()
    print("🏁 Sesi Appium selesai ditutup.")
