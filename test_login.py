import os
import sys
import time

# Pastikan console Windows mendukung karakter UTF-8
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from appium import webdriver
from appium.options.common.base import AppiumOptions
from appium_flutter_finder.flutter_finder import FlutterFinder

base_dir = os.path.dirname(os.path.abspath(__file__))
apk_path = os.path.join(base_dir, "build", "app", "outputs", "flutter-apk", "app-debug.apk")

caps = {
    "platformName": "Android",
    "appium:automationName": "Flutter",
    "appium:deviceName": "emulator-5554",
    "appium:app": apk_path,
    "appium:appPackage": "id.canadev.laporkita",
    "appium:appActivity": ".MainActivity",
    "appium:noReset": False,
    "appium:newCommandTimeout": 300,
}

options = AppiumOptions()
options.load_capabilities(caps)

print("[1/5] Menghubungkan ke Appium Server di http://127.0.0.1:4723...")
print(f"[2/5] Memasang dan memuat APK di Emulator: {apk_path}")

driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
finder = FlutterFinder()

try:
    # Beri jeda 5 detik agar Flutter selesai runApp() dan animasi SplashScreen (3 detik) selesai
    print("[3/5] Menunggu Flutter runApp() dan animasi SplashScreen selesai...")
    time.sleep(5)

    # Di GetStartedScreen, cari tombol "Login"
    print(" -> Mencari dan mengklik tombol 'Login' di halaman Get Started...")
    get_started_login_btn = finder.by_value_key("get_started_login_button")
    driver.execute_script("flutter:waitFor", get_started_login_btn, 10000)
    driver.find_element("flutter", get_started_login_btn).click()
    print(" -> Berhasil masuk ke LoginScreen!")

    time.sleep(2)

    # Sekarang di LoginScreen, temukan formulir menggunakan Key
    print("[4/5] Menunggu formulir login dimuat di LoginScreen...")
    email_field = finder.by_value_key("login_identifier_field")
    password_field = finder.by_value_key("login_password_field")
    submit_button = finder.by_value_key("login_submit_button")

    driver.execute_script("flutter:waitFor", email_field, 10000)
    
    print(" -> Mengisi field email/identitas: 'warga@example.com'...")
    driver.find_element("flutter", email_field).send_keys("warga@example.com")
    
    print(" -> Mengisi field password: 'password123'...")
    driver.find_element("flutter", password_field).send_keys("password123")
    
    print(" -> Mengklik tombol Login...")
    driver.find_element("flutter", submit_button).click()

    time.sleep(3)
    print("[5/5] [BERHASIL] Seluruh alur Login berhasil diuji secara otomatis via Appium Flutter Driver!")

except Exception as e:
    print(f"[GAGAL] Terjadi error: {e}")
    raise

finally:
    driver.quit()
    print("[SELESAI] Sesi Appium ditutup.")
