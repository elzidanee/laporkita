# Laporan QA — Frontend (Re-Review)
## LaporKita Mobile App (Flutter)

**Repo:** `elzidanee/laporkita` (branch master, snapshot terbaru)
**Tanggal:** 23 Agustus 2026
**Jenis laporan:** Re-review — membandingkan kondisi kode saat ini terhadap temuan QA sebelumnya (7 temuan: FE-01 s/d FE-07)
**Metodologi:** Static code review + `diff` struktural terhadap snapshot sebelumnya untuk memverifikasi klaim perbaikan secara langsung ke source code, bukan asumsi.

---

## 1. Ringkasan Eksekutif

Tim telah melakukan iterasi perbaikan yang substansial sejak review sebelumnya: **3 dari 7 temuan resolved penuh**, **4 temuan improved signifikan** (turun tingkat keparahan), dan **tidak ditemukan regresi**. Modul baru ditambahkan untuk Notifications, Policy Simulator, dan Prediction — dan sebagian besar benar-benar terhubung ke UI (bukan cuma kode mati). README juga sudah lengkap.

Catatan penting: dua area masih butuh perhatian sebelum dianggap selesai — **Citizen Validation** sudah ada di layer data tapi **belum ada tombol di UI** yang memanggilnya, dan **Command Center Dashboard masih statis** sepenuhnya.

### Scorecard Perbandingan

| ID | Temuan | Status Sebelumnya | Status Sekarang |
|---|---|---|---|
| FE-01 | Cakupan test | 🔴 Blocker | 🟠 **Improved** → Major |
| FE-02 | File widget raksasa | 🟠 Major | 🟠 **Improved sebagian** → Major |
| FE-03 | Warna hardcode tidak konsisten | 🟠 Major | 🟡 **Improved** → Minor |
| FE-04 | Dependency offline/push belum ada | 🟡 Minor | 🟡 **Tetap** → Minor |
| FE-05 | AI Service tanpa autentikasi | 🔴 Blocker | 🟡 **Resolved** (dengan catatan) → Minor |
| FE-06 | Fitur inti PRD belum terhubung API | 🟠 Major | 🟠 **Improved sebagian** → Major |
| FE-07 | Fallback foto dummy | 🟡 Minor | ✅ **Resolved penuh** |
| FE-08 *(baru)* | README kosong | 🟡 Minor | ✅ **Resolved penuh** |
| — | Command Center Dashboard statis | 🟠 Major | 🟠 **Tetap** → Major |

---

## 2. Temuan yang Sudah Resolved Penuh ✅

### ✅ FE-07 — Fallback Foto Dummy (RESOLVED)
**Sebelumnya:** Mengirim JPEG 1×1 piksel palsu saat foto tidak valid.
**Sekarang:** Diganti dengan `throw ArgumentError(...)` yang eksplisit memblokir submit sebelum request dikirim, dengan pesan jelas ke pengguna: *"Foto laporan tidak valid atau tidak ditemukan..."*. Kode bahkan diberi komentar referensi `// FE-07 fix`. **Verifikasi langsung di `report_remote_datasource.dart` — perbaikan tepat sasaran.**

### ✅ FE-08 — README Kosong (RESOLVED)
Sebelumnya hanya template default (`# laporkita`). Sekarang README lengkap: badge stack teknologi, diagram arsitektur (mermaid), daftar fitur B2C/B2G, tabel kapabilitas AI, struktur direktori, instruksi setup & build, endpoint production. Kualitas dokumentasi sudah baik untuk keperluan demo/handover.

*Catatan kecil:* README mengklaim `flutter analyze: 0 Error, 0 Warning` — klaim ini tidak bisa diverifikasi independen dalam review ini (tidak ada Flutter SDK di environment QA), sebaiknya tim melampirkan output `flutter analyze` aktual sebagai bukti jika diperlukan untuk penilaian kompetisi.

---

## 3. Temuan yang Resolved dengan Catatan 🟡

### 🟡 FE-05 — AI Service Tanpa Autentikasi (RESOLVED, dengan catatan arsitektur)
**Sebelumnya:** Blocker — tidak ada header `X-API-Key` sama sekali.
**Sekarang:** `AppConfig.aiApiKey` mengirim header `X-API-Key` secara otomatis ke setiap request AI Service, nilai key selaras dengan `.env.example` AI Service. **Masalah konektivitas 401 sudah tuntas.**

**Catatan residual (turun jadi Minor, bukan lagi Blocker):** Key tersebut ditanam sebagai `defaultValue` di source code (`lib/core/config/app_config.dart`), yang berarti key ini akan ikut ter-compile ke dalam APK dan bisa diekstrak siapa pun yang men-decompile aplikasi (mis. via `apktool`/`jadx`). Untuk MVP/demo kompetisi ini bukan masalah mendesak, tapi untuk production sesungguhnya, shared secret sebaiknya tidak ditanam permanen di client mobile — pertimbangkan proxy lewat backend atau token per-user untuk fase berikutnya.

---

## 4. Temuan yang Improved (Turun Tingkat Keparahan) 🟠

### 🟠 FE-01 — Cakupan Test (IMPROVED: Blocker → Major)
**Sebelumnya:** Hanya test bawaan counter-app default, kemungkinan besar gagal dijalankan.
**Sekarang:** `test/widget_test.dart` diganti total — 9 test relevan: 2 widget smoke test (`App renders without crashing`, render awal navigasi) + 7 test instansiasi (`AuthBloc`, `ReportBloc`, dan 5 repository termasuk yang baru: `PolicySimulatorRepository`, `PredictionRepository`, `NotificationRepository`).

**Masih kurang:** Seluruh test yang ada bersifat **instansiasi/smoke test** — belum ada assertion terhadap *business logic* nyata (state transition BLoC, parsing `ReportModel.fromJson`, perilaku auto-refresh token di `DioClient`). Ini jauh lebih baik dari sebelumnya (yang malah rusak), tapi belum cukup untuk mencegah regresi logic di masa depan.

**Rekomendasi:** Tambahkan `bloc_test` package untuk menguji state transition BLoC, dan unit test murni untuk `fromJson`/`toJson` model — dua area ini paling sering jadi sumber bug saat backend berubah format response.

### 🟠 FE-02 — File Widget Raksasa (IMPROVED SEBAGIAN)
**Sebelumnya:** `citizen_home_screen.dart` 1.984 baris — file terbesar di proyek.
**Sekarang:** File tersebut sudah **dipecah menjadi struktur tab** (`presentation/citizen/home/tabs/`) — perbaikan struktural yang tepat arahnya. Namun satu di antaranya, `citizen_dashboard_tab.dart`, masih **1.314 baris** — masih jauh di atas batas 300 baris yang ditetapkan Rules.md sendiri. `report_detail_screen.dart` (1.507 baris) **belum tersentuh sama sekali**, tidak berubah dari review sebelumnya.

**Rekomendasi:** Lanjutkan pola pemecahan yang sudah dimulai di citizen_home — terapkan hal serupa ke `citizen_dashboard_tab.dart` dan `report_detail_screen.dart`.

### 🟡 FE-03 — Warna Hardcode Tidak Konsisten (IMPROVED: Major → Minor)
**Sebelumnya:** 190 hardcode `Color(0xFF...)`, beberapa di antaranya menyimpang dari token resmi untuk makna semantik yang sama (dua "merah" berbeda untuk status danger, dst).
**Sekarang:** Jumlah hardcode turun jadi **73** (↓62%). Yang lebih penting: tim menyelesaikan akar masalahnya dengan pendekatan yang tepat — token `AppColors.statusDanger`/`statusInfo` **diperbarui nilainya** agar selaras dengan warna yang paling banyak dipakai di lapangan (bukan sebaliknya memaksa ganti semua widget), plus penambahan token baru (`surfaceDanger`, `surfaceWarning`, `neutral700/400/300/200/50`, dll) untuk varian yang sebelumnya memang belum terdefinisi.

**Sisa 73 hardcode** kebanyakan warna aksen satu-off (ungu `#7B1FA2`, teal `#26A69A`, dsb) yang kemungkinan besar memang butuh nilai baru — bukan duplikasi makna semantik yang membingungkan seperti temuan sebelumnya. Turun ke Minor karena risiko inkonsistensi visualnya jauh berkurang.

### 🟠 FE-06 — Fitur Inti PRD Belum Terhubung API (IMPROVED SEBAGIAN)

Perbandingan status per fitur:

| Fitur | Status Sebelumnya | Status Sekarang |
|---|---|---|
| Notifikasi (inbox) | Tidak ada | ✅ **Terhubung** — `citizen_notifikasi_tab.dart` memanggil `NotificationRepository.getNotifications()` nyata |
| Policy Simulator | Tidak ada | ✅ **Terhubung** — layar baru `policy_simulator_screen.dart` memanggil `getZones()` dan `createSimulation()` nyata |
| Prediksi Risiko Wilayah | Tidak ada | ✅ **Terhubung** — ditampilkan sebagai card prediktif di beranda warga (disebut di README) |
| Citizen Validation | Tidak ada sama sekali | 🟠 **Setengah jalan** — method `validateReport()` sudah ada di datasource & repository (`POST /reports/:id/validate`), tapi **tidak dipanggil dari layar manapun** (dikonfirmasi: nol hasil pencarian `validateReport` di seluruh folder `presentation/`) |
| Route Alert (subscribe/check) | Tidak ada | 🟠 **Setengah jalan** — endpoint sudah ada di `notification_remote_datasource.dart`, tapi juga **tidak dipanggil dari UI manapun** |
| Update Profil (`PATCH /users/me`) | Tidak ada | Belum diverifikasi ada perubahan |

**Catatan penting untuk tim:** Situasi "ada di data layer tapi tidak dipanggil UI" ini berisiko menciptakan kesan palsu bahwa fitur sudah selesai — repository dan datasource-nya sudah siap pakai, tinggal menyambungkan tombol/trigger di layar yang relevan (tombol "Konfirmasi Perbaikan Sesuai" di `tracking_progress_screen.dart` untuk Citizen Validation; toggle langganan di halaman profil/pengaturan untuk Route Alert).

---

## 5. Temuan yang Belum Berubah (Masih Terbuka)

### 🟠 Command Center Dashboard Masih Statis
`dashboard_screen.dart` masih hanya memuat 1 pemanggilan nyata (`AuthLogoutRequested`) — tidak ada pemanggilan repository/data untuk menampilkan Urban Health Score, daftar prioritas laporan, atau ringkasan angka secara live. Satu-satunya progres di sisi Command Center adalah penambahan **Policy Simulator** sebagai layar terpisah yang bisa diakses dari dashboard — tapi dashboard utamanya sendiri belum berubah dari status "tampilan statis" di review sebelumnya.

### 🟡 FE-04 — Dependency Offline & Push Notification Belum Ada (Tetap)
`pubspec.yaml` masih belum mencantumkan `hive`/`sqflite` (offline draft) maupun `firebase_messaging` (push notification untuk Route Alert). Tidak ada perubahan dari review sebelumnya.

---

## 6. Ringkasan Prioritas (Diperbarui)

| Prioritas | Temuan | Status |
|---|---|---|
| 1 (Tinggi) | Command Center Dashboard belum live | Masih terbuka |
| 2 (Tinggi) | Citizen Validation belum ada tombol UI | Data layer siap, tinggal wiring UI |
| 3 (Sedang) | Route Alert belum ada trigger UI | Data layer siap, tinggal wiring UI |
| 4 (Sedang) | `report_detail_screen.dart` & `citizen_dashboard_tab.dart` masih >1.300 baris | Sebagian sudah membaik |
| 5 (Sedang) | Test masih sebatas smoke/instantiation, belum ada assertion logic | Membaik signifikan, lanjutkan |
| 6 (Rendah) | Sisa 73 warna hardcode | Membaik signifikan |
| 7 (Rendah) | Dependency offline/push belum ada | Belum jadi prioritas |
| 8 (Catatan) | API key AI Service ditanam sebagai default di source | Berfungsi baik untuk MVP, revisit untuk production |

---

## 7. Apresiasi — Kualitas Iterasi

Untuk keseimbangan laporan: kecepatan dan ketepatan tim menindaklanjuti temuan sebelumnya patut diapresiasi. Perbaikan FE-07 dan FE-05 dilakukan dengan solusi yang benar secara teknis (bukan sekadar menutupi gejala), dan pendekatan FE-03 (menyelaraskan token ke nilai paling representatif, bukan memaksa migrasi besar-besaran) adalah keputusan pragmatis yang tepat untuk tahap kompetisi. README yang ditulis ulang juga jauh melebihi standar minimum.

---

## 8. Batasan Laporan

Review ini bersifat static code analysis dan differential review terhadap snapshot sebelumnya. Tidak mencakup eksekusi `flutter test`/`flutter analyze` langsung, tidak ada pengujian UI manual di perangkat, dan tidak mengukur performa runtime.