# Panduan Setup Appium — `appium-flutter-driver` (Mode Debug/Profile)

**Target:** Testing cepat selama development menggunakan `appium-flutter-driver` — bicara langsung ke widget tree Flutter, tidak perlu menambahkan `Semantics label` manual ke tiap widget seperti jalur UiAutomator2.

> ⚠️ **Catatan jujur sebelum mulai:** `appium-flutter-driver` adalah driver **komunitas**, bukan driver resmi Appium inti (beda dengan `UiAutomator2`/`XCUITest`). Update-nya tidak secepat Appium utama, dan kadang ada masalah kompatibilitas dengan versi Flutter/Appium terbaru. Kalau nanti kamu mentok error aneh yang sulit di-debug, itu wajar — cek dulu [issue tracker resminya](https://github.com/appium-userland/appium-flutter-driver/issues) sebelum menghabiskan banyak waktu debugging sendiri.

---

## 1. Perbedaan Utama dari Jalur UiAutomator2

| | UiAutomator2 (sebelumnya) | appium-flutter-driver (ini) |
|---|---|---|
| Build APK | Release biasa | **Debug/profile khusus** dengan driver extension aktif |
| Cara cari elemen | `Semantics label` manual di tiap widget | `Key` Flutter (kalau sudah ada di kode) atau teks langsung |
| Setup kode Flutter | Tambah `Semantics` di widget | Tambah 1 file entrypoint test + 1 dependency |
| Appium automationName | `UiAutomator2` | `Flutter` |

---

## 2. Install Driver

```bash
appium driver install --source=npm appium-flutter-driver
```

Verifikasi:
```bash
appium driver list --installed
```

---

## 3. Siapkan Project Flutter untuk Mode Testing

### 3.1 Tambahkan dependency
Di `pubspec.yaml`, bagian `dev_dependencies`:
```yaml
dev_dependencies:
  flutter_driver:
    sdk: flutter
```

### 3.2 Buat entrypoint khusus testing
Buat file baru: `test_driver/app.dart`
```dart
import 'package:flutter_driver/driver_extension.dart';
import 'package:laporkita/main.dart' as app;

void main() {
  // Aktifkan Flutter Driver extension SEBELUM app jalan,
  // supaya Appium bisa "bicara" ke widget tree lewat Dart VM.
  enableFlutterDriverExtension();
  app.main();
}
```
> Sesuaikan `package:laporkita/main.dart` dengan nama package di `pubspec.yaml` kamu (cek baris `name:` paling atas file itu).

### 3.3 Cek widget `Key` yang sudah ada (atau tambahkan)
`appium-flutter-driver` paling stabil kalau mencari elemen lewat `Key`, bukan teks (teks bisa berubah-ubah/duplikat). Cek apakah widget penting sudah punya `Key`:
```dart
ElevatedButton(
  key: const Key('login_submit_button'),   // ← tambahkan kalau belum ada
  onPressed: _handleLogin,
  child: const Text('Masuk'),
),

TextFormField(
  key: const Key('login_email_field'),
  controller: _emailController,
),
```
Kalau widget-widget penting sudah lazim diberi `Key` di proyek Flutter kamu (banyak tim memang sudah terbiasa pakai `Key` untuk widget testing internal Flutter), kamu mungkin **tidak perlu menambah apapun** — tinggal pakai yang sudah ada.

---

## 4. Build APK Debug dengan Driver Extension Aktif

```bash
flutter build apk --debug -t test_driver/app.dart
```
Hasil APK: `build/app/outputs/flutter-apk/app-debug.apk`

> Perhatikan flag `-t test_driver/app.dart` — ini yang memberitahu Flutter untuk pakai entrypoint testing (dengan driver extension aktif), bukan `lib/main.dart` biasa.

---

## 5. Install Package Finder untuk Python

```bash
pip install Appium-Python-Client Appium-Flutter-Finder
```

`Appium-Flutter-Finder` menyediakan helper untuk bikin selector sesuai cara Flutter menemukan widget (`by_value_key`, `by_text`, `by_type`, `by_semantics_label`), beda dari selector `UiSelector` Android biasa.

---

## 6. Desired Capabilities

```json
{
  "platformName": "Android",
  "appium:automationName": "Flutter",
  "appium:deviceName": "emulator-5554",
  "appium:app": "/path/lengkap/ke/app-debug.apk",
  "appium:appPackage": "com.laporkita.app",
  "appium:appActivity": ".MainActivity"
}
```
Perhatikan `automationName` sekarang **`Flutter`**, bukan `UiAutomator2`.

---

## 7. Contoh Test Script (Python)

```python
# test_login_flutter_driver.py
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium_flutter_finder.flutter_finder import FlutterFinder
import time

options = UiAutomator2Options()
options.platform_name = "Android"
options.device_name = "emulator-5554"
options.app = "/path/lengkap/ke/app-debug.apk"
options.app_package = "com.laporkita.app"
options.app_activity = ".MainActivity"
# automationName "Flutter" di-set lewat capability tambahan:
options.set_capability("automationName", "Flutter")

driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
finder = FlutterFinder()

try:
    # Cari widget berdasarkan Key — paling stabil
    email_field = finder.by_value_key("login_email_field")
    password_field = finder.by_value_key("login_password_field")
    submit_button = finder.by_value_key("login_submit_button")

    driver.execute_script("flutter:waitFor", email_field)
    driver.find_element("flutter", email_field).send_keys("warga@example.com")
    driver.find_element("flutter", password_field).send_keys("password123")
    driver.find_element("flutter", submit_button).click()

    time.sleep(3)

    # Verifikasi berhasil masuk ke Home — cari berdasarkan teks yang muncul di Home
    home_text = finder.by_text("Ayo jaga kota kita bersama!")  # sesuaikan teks asli
    driver.execute_script("flutter:waitFor", home_text, 5000)
    print("✅ Test login BERHASIL")

except Exception as e:
    print(f"❌ Test login GAGAL: {e}")
    raise

finally:
    driver.quit()
```

**Perbedaan penting dari script UiAutomator2 sebelumnya:**
- Pakai `finder.by_value_key(...)` bukan `UiSelector().description(...)`
- `driver.execute_script("flutter:waitFor", ...)` dipakai untuk menunggu widget muncul — lebih andal daripada `time.sleep()` biasa karena benar-benar menunggu widget tree siap, bukan cuma tebak-tebakan durasi.
- `driver.find_element("flutter", finder_object)` — strategi locator `"flutter"` adalah strategi khusus yang disediakan driver ini.

---

## 8. Test Regresi FE-09 (Pesan Sukses Palsu) — Versi Flutter Driver

```python
# Simulasi kondisi gagal: matikan jaringan sebelum klik tombol validasi
import subprocess
subprocess.run(["adb", "shell", "svc", "wifi", "disable"])
subprocess.run(["adb", "shell", "svc", "data", "disable"])

validate_button = finder.by_value_key("tracking_validate_button")
driver.find_element("flutter", validate_button).click()
time.sleep(2)

# Assert: harus muncul pesan GAGAL, bukan pesan "berhasil"
error_snackbar = finder.by_text_containing("Gagal")
try:
    driver.execute_script("flutter:waitFor", error_snackbar, 5000)
    print("✅ FE-09 tidak regresi — pesan error muncul dengan benar")
except Exception:
    raise AssertionError("❌ FE-09 REGRESI — tidak ada pesan error saat aksi gagal!")

# Jangan lupa nyalakan lagi jaringannya setelah test
subprocess.run(["adb", "shell", "svc", "wifi", "enable"])
subprocess.run(["adb", "shell", "svc", "data", "enable"])
```
*(Perlu tambahkan `Key('tracking_validate_button')` ke tombol konfirmasi di `tracking_progress_screen.dart` kalau belum ada.)*

---

## 9. Troubleshooting Khusus Driver Ini

| Masalah | Penyebab Umum | Solusi |
|---|---|---|
| `Flutter Driver extension not found` | Lupa flag `-t test_driver/app.dart` saat build, atau lupa panggil `enableFlutterDriverExtension()` | Cek ulang Bagian 3.2 & 4 |
| Session gagal start, error soal port | Flutter Driver pakai port terpisah (biasanya 8888 via `adb forward`) yang kadang bentrok | Jalankan `adb forward tcp:8888 tcp:8888` manual sebelum start session kalau error |
| `by_value_key` tidak ketemu elemen | Widget belum punya `Key`, atau App belum selesai loading saat dicari | Pastikan `Key` sudah ditambahkan & build ulang; tambahkan `flutter:waitFor` sebelum interaksi |
| Works di lokal tapi gagal di CI/CD | Driver komunitas ini kadang tidak stabil di environment headless | Pertimbangkan jalankan di real device/emulator dengan GPU rendering aktif, bukan headless murni |

---

## 10. Kapan Beralih ke Jalur UiAutomator2 (Panduan Sebelumnya)

Simpan panduan `GUIDE_Appium_Testing_LaporKita.md` (UiAutomator2) juga — pakai itu nanti saat:
- Development sudah stabil dan mau testing final sebelum submit kompetisi (lebih dekat ke kondisi real production).
- `appium-flutter-driver` mentok masalah kompatibilitas yang tidak kunjung selesai.

Kedua pendekatan **tidak saling menggantikan** — wajar kalau tim pakai `appium-flutter-driver` untuk iterasi cepat sehari-hari, lalu jalankan sekali lagi dengan UiAutomator2 + APK release sebagai gerbang terakhir sebelum rilis/submit.