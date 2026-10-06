# Setup Step-by-Step — Appium Flutter Driver untuk LaporKita

**Hasil pengecekan kode kamu saat ini:**
| Yang dicek | Status |
|---|---|
| Package name Flutter (`pubspec.yaml`) | `laporkita` |
| Application ID Android (`applicationId`) | `id.canadev.laporkita` ⚠️ beda dari contoh generik sebelumnya |
| MainActivity | `id/canadev/laporkita/MainActivity.kt` → activity class `.MainActivity` |
| Pemakaian `Key(...)` di widget | **0 — belum ada sama sekali** |
| Folder `test_driver/` | **Belum ada** |
| Dependency `flutter_driver` di `pubspec.yaml` | **Belum ada** |

Jadi semua langkah di bawah ini perlu dikerjakan dari nol — saya tunjukkan persis file dan baris kode yang perlu diubah.

---

## Langkah 1 — Install Appium & Driver

```bash
npm install -g appium
appium driver install --source=npm appium-flutter-driver
```

Verifikasi:
```bash
appium driver list --installed
```
Harus muncul `appium-flutter-driver` di daftar.

---

## Langkah 2 — Tambahkan Dependency `flutter_driver`

Buka `pubspec.yaml`, cari bagian `dev_dependencies:` (biasanya dekat `flutter_test`), tambahkan:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_driver:        # ← tambahkan ini
    sdk: flutter          # ← tambahkan ini
```

Jalankan:
```bash
flutter pub get
```

---

## Langkah 3 — Buat Entrypoint Testing

Buat folder baru `test_driver/` di root project (sejajar dengan folder `lib/`), lalu buat file `test_driver/app.dart`:

```dart
import 'package:flutter_driver/driver_extension.dart';
import 'package:laporkita/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
```

---

## Langkah 4 — Tambahkan `Key` ke Widget Login (Target Pertama)

Berdasarkan isi `lib/presentation/citizen/profile/login_screen.dart` kamu saat ini, berikut 3 widget yang perlu diberi `Key` — saya tunjukkan **persis** kode sebelum/sesudah:

### 4.1 Field Email/No. HP (sekitar baris 175)
**Sebelum:**
```dart
TextFormField(
  controller: _identifierController,
  decoration: InputDecoration(
    hintText: 'Masukan email atau nomor HP',
```
**Sesudah (tambahkan `key:`):**
```dart
TextFormField(
  key: const Key('login_identifier_field'),
  controller: _identifierController,
  decoration: InputDecoration(
    hintText: 'Masukan email atau nomor HP',
```

### 4.2 Field Password (sekitar baris 228)
Cari `TextFormField` kedua di file yang sama (untuk password), tambahkan dengan pola yang sama:
```dart
TextFormField(
  key: const Key('login_password_field'),
  controller: _passwordController,
  // ... sisanya tetap sama
```

### 4.3 Tombol Login (sekitar baris 318)
**Sebelum:**
```dart
ElevatedButton(
  onPressed: isLoading ? null : _handleLogin,
  style: ElevatedButton.styleFrom(
```
**Sesudah:**
```dart
ElevatedButton(
  key: const Key('login_submit_button'),
  onPressed: isLoading ? null : _handleLogin,
  style: ElevatedButton.styleFrom(
```

> Lakukan pola yang sama untuk layar lain yang mau ditest nanti (`otp_screen.dart`, halaman submit laporan, dll) — cari widget `TextFormField`/`ElevatedButton`/`GestureDetector` yang relevan, tambahkan `key: const Key('nama_unik')`.

---

## Langkah 5 — Build APK Debug dengan Driver Extension

```bash
flutter build apk --debug -t test_driver/app.dart
```

Hasil APK ada di:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## Langkah 6 — Siapkan Emulator/Device

```bash
# Cek device/emulator terdeteksi
adb devices
```

Kalau pakai emulator dan belum ada yang jalan, buka Android Studio → Device Manager → jalankan salah satu emulator, atau via command line:
```bash
emulator -avd <nama_avd_kamu>
```

---

## Langkah 7 — Jalankan Appium Server

Buka terminal baru (biarkan tetap terbuka selama testing):
```bash
appium
```
Server akan jalan di `http://127.0.0.1:4723` secara default.

---

## Langkah 8 — Install Package Python untuk Test

```bash
pip install Appium-Python-Client Appium-Flutter-Finder
```

---

## Langkah 9 — Tulis & Jalankan Test Pertama

Buat file `test_login.py`:

```python
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium_flutter_finder.flutter_finder import FlutterFinder
import time

options = UiAutomator2Options()
options.platform_name = "Android"
options.device_name = "emulator-5554"  # sesuaikan dengan hasil `adb devices`
options.app = "/path/lengkap/ke/build/app/outputs/flutter-apk/app-debug.apk"
options.app_package = "id.canadev.laporkita"      # ✅ sudah dikoreksi sesuai kode asli
options.app_activity = ".MainActivity"
options.set_capability("automationName", "Flutter")

driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
finder = FlutterFinder()

try:
    email_field = finder.by_value_key("login_identifier_field")
    password_field = finder.by_value_key("login_password_field")
    submit_button = finder.by_value_key("login_submit_button")

    driver.execute_script("flutter:waitFor", email_field, 10000)
    driver.find_element("flutter", email_field).send_keys("warga@example.com")
    driver.find_element("flutter", password_field).send_keys("password123")
    driver.find_element("flutter", submit_button).click()

    time.sleep(3)
    print("✅ Interaksi login berhasil dijalankan, cek manual hasil di layar")

except Exception as e:
    print(f"❌ Test gagal: {e}")
    raise

finally:
    driver.quit()
```

Jalankan:
```bash
python test_login.py
```

---

## Ringkasan Urutan Eksekusi (checklist)

- [ ] 1. `npm install -g appium` + install driver
- [ ] 2. Tambah `flutter_driver` ke `pubspec.yaml` → `flutter pub get`
- [ ] 3. Buat `test_driver/app.dart`
- [ ] 4. Tambah `Key` ke `login_screen.dart` (3 widget: email, password, tombol submit)
- [ ] 5. `flutter build apk --debug -t test_driver/app.dart`
- [ ] 6. Nyalakan emulator, cek `adb devices`
- [ ] 7. Jalankan `appium` di terminal terpisah
- [ ] 8. `pip install Appium-Python-Client Appium-Flutter-Finder`
- [ ] 9. Jalankan `test_login.py`

---

## Catatan Penting

- `appPackage` yang benar adalah **`id.canadev.laporkita`** — kalau di panduan/script lama saya sebelumnya tertulis `com.laporkita.app`, itu salah, abaikan dan pakai nilai yang benar ini.
- Setelah test login ini berhasil jalan, beri tahu saya — saya akan bantu susunkan langkah yang sama persis (dengan referensi baris kode asli) untuk layar OTP dan alur submit laporan.