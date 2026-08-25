# Laporan QA — Frontend
## LaporKita Mobile App (Flutter)

**Repo:** `elzidanee/laporkita` (branch master)
**Tanggal:** 23 Agustus 2026
**Metodologi:** Static code review menyeluruh — struktur proyek, kualitas kode, konsistensi desain, cakupan pengujian, dan kontrak integrasi API.

---

## 1. Ringkasan Eksekutif

Frontend LaporKita dibangun dengan Flutter + BLoC, mengikuti struktur Clean Architecture yang direncanakan (`core/`, `data/`, `presentation/`). Modul inti citizen (Auth, Reports) terintegrasi dengan benar ke backend — nama field, path endpoint, dan format request/response sudah presisi. Namun ditemukan sejumlah kesenjangan pada kualitas kode (nol cakupan pengujian nyata, file widget berukuran sangat besar) dan konsistensi desain (warna hardcode tersebar meski token warna resmi sudah tersedia), serta beberapa fitur inti dari PRD yang belum terhubung ke API sama sekali.

### Scorecard

| Area | Status |
|---|---|
| Modul Auth (register, OTP, login, refresh) | ✅ PASS |
| Modul Reports (submit, list, detail) | ✅ PASS |
| Integrasi AI Service | 🔴 BLOCKER |
| Cakupan pengujian otomatis | 🔴 BLOCKER |
| Citizen Validation & Route Alert | 🟠 MAJOR GAP |
| Ukuran file widget | 🟠 MAJOR |
| Konsistensi warna/token desain | 🟠 MAJOR |

---

## 2. Temuan — Kualitas Kode & Struktur

### 🔴 FE-01 — Cakupan Pengujian Otomatis Nol Persen (Test Rusak)
**Severity:** Blocker

Folder `test/` hanya berisi `widget_test.dart` bawaan template default Flutter (uji "Counter increments smoke test"). Test ini mengecek keberadaan teks "0" dan tombol `+` — sisa dari starter project `flutter create`, sama sekali tidak relevan dengan aplikasi LaporKita.

**Dampak:** Jika `flutter test` dijalankan, test ini kemungkinan besar akan **GAGAL** karena `MyApp` sekarang me-render alur splash/get-started, bukan counter app — artinya repo saat ini meninggalkan test yang rusak, bukan sekadar "belum ada test". Tidak ada satupun unit test atau widget test untuk BLoC (`AuthBloc`, `ReportBloc`, `CategoryBloc`), model parsing (`ReportModel.fromJson`), atau alur kritikal (submit laporan, auto-refresh token).

**Rekomendasi:** Hapus/ganti `widget_test.dart` dengan smoke test yang sesuai aplikasi nyata. Prioritaskan unit test untuk `DioClient` (parsing envelope, auto-refresh token) dan `ReportModel`/`AuthTokenModel` (`fromJson`) karena keduanya adalah titik kegagalan paling kritis jika backend mengubah format response.

---

### 🟠 FE-02 — File Widget Berukuran Sangat Besar (Melanggar Aturan Proyek Sendiri)
**Severity:** Major

Dokumen Rules.md proyek ini menyatakan *"Widget besar dipecah menjadi widget kecil reusable — hindari 1 file widget >300 baris."* Pada praktiknya, **14 dari 19 file screen** melebihi 300 baris, dengan dua di antaranya sangat ekstrem:

| File | Baris |
|---|---|
| `citizen_home_screen.dart` | 1.984 |
| `report_detail_screen.dart` | 1.506 |
| `tracking_progress_screen.dart` | 967 |
| `ai_verification_screen.dart` | 740 |
| `new_report_form_screen.dart` | 687 |

**Dampak:** File sebesar ini menyulitkan maintenance, meningkatkan risiko merge conflict saat kerja tim, dan mempersulit reuse komponen antar layar (mis. status badge, card laporan kemungkinan besar didefinisikan ulang di banyak tempat alih-alih dari `shared_widgets/`).

**Rekomendasi:** Refactor bertahap — pecah section besar (header, list item, bottom sheet) menjadi widget terpisah di `presentation/shared_widgets/` atau folder `widgets/` lokal per fitur.

---

### 🟠 FE-03 — Warna Hardcode Tersebar Meski Token Resmi Sudah Ada
**Severity:** Major

`lib/core/theme/app_colors.dart` sudah didefinisikan dengan benar dan **cocok 100%** dengan Design System yang dirancang (`greenPrimary #1D9C51`, `greenDark #206C57`, dst). Namun ditemukan **190 pemakaian `Color(0xFF...)` hardcode** tersebar di berbagai file widget, alih-alih memanggil `AppColors.xxx`.

Yang lebih mengkhawatirkan: sebagian warna hardcode ini **tidak identik** dengan token resmi untuk makna semantik yang sama — misalnya ditemukan `0xFFE53935`, `0xFFFF3D00`, dan `0xFFE68A00` dipakai bergantian untuk indikasi "urgent/danger", padahal token resmi `AppColors.statusDanger` sudah didefinisikan sebagai `0xFFD64545`. Demikian juga `0xFF2B82C4` dipakai berdampingan dengan token `statusInfo` (`0xFF3B82C4`) — mirip tapi tidak sama persis.

**Dampak:** Warna badge status/ikon bisa terlihat sedikit berbeda-beda di layar yang berbeda untuk makna yang sama, merusak konsistensi visual brand yang sudah dirancang rapi di Design System.

**Rekomendasi:** Audit seluruh 190 titik pemakaian, ganti dengan referensi `AppColors`. Jika memang dibutuhkan varian warna baru, tambahkan sebagai token resmi baru di `app_colors.dart`, jangan hardcode ad-hoc di widget.

---

### 🟡 FE-04 — Dependency untuk Fitur Offline & Push Notification Belum Ada
**Severity:** Minor

`pubspec.yaml` tidak mencantumkan package local storage (`hive`, `sqflite`, dsb) maupun push notification (`firebase_messaging`). Rules.md §1.4 proyek mensyaratkan draft laporan tersimpan lokal saat offline, dan PRD menjanjikan fitur Route Alert berbasis push notification kontekstual.

**Dampak:** Ini bukan bug — ini konfirmasi bahwa kapabilitas teknis untuk kedua fitur tersebut **belum ada fondasinya sama sekali** di level dependency, bukan cuma belum diimplementasi di layer UI.

**Rekomendasi:** Jika kedua fitur ini masuk prioritas fase berikutnya, tambahkan dependency terkait di awal sprint supaya estimasi waktu development lebih akurat.

---

## 3. Temuan — Integrasi API

### 🔴 FE-05 — Panggilan Langsung ke AI Service Tanpa Header Otentikasi
**Severity:** Blocker

`ai_service_datasource.dart` memanggil `POST /v1/verify` dan `POST /v1/predict-risk` **langsung ke AI Service** (bukan melalui backend), tetapi tidak pernah menyertakan header `X-API-Key` yang diwajibkan AI Service (`verify_internal_api_key` di `app/core/security.py`, aktif jika `INTERNAL_API_KEY` terisi).

**Dampak:** Fitur *AI Verification Screen* dan prediksi risiko berpotensi gagal total dengan HTTP 401 di lingkungan production jika proteksi API key AI Service diaktifkan sesuai rekomendasi keamanan standar.

**Rekomendasi:** Jangan tanam shared secret di client mobile. Arahkan panggilan ini melalui backend (proxy), atau buat skema otentikasi berbasis token user (JWT) khusus untuk endpoint AI yang diakses client — bukan internal API key yang sama dengan yang dipakai backend.

---

### 🟠 FE-06 — Fitur Inti PRD Belum Terhubung ke Endpoint yang Tersedia
**Severity:** Major

Hasil pemindaian seluruh path API yang benar-benar dipanggil di kode (`grep` seluruh `lib/`) dibandingkan endpoint yang tersedia di backend:

| Fitur | Endpoint Backend Tersedia | Dipanggil di Frontend? |
|---|---|---|
| Citizen Validation | `POST /reports/:id/validate` | **Tidak** |
| Update Profil | `PATCH /users/me` | **Tidak** |
| Riwayat Poin Kontribusi | `GET /users/me/points` | **Tidak** (datasource ada, tidak dipanggil dari UI manapun) |
| Upload Foto Progress/Selesai | `POST /reports/:id/media` | **Tidak** |
| Route Alert (subscribe/check) | `POST /route-alerts/*` | **Tidak** |
| Notifikasi | `GET /notifications` dkk | **Tidak** |
| Policy Simulator | `POST /policy-simulations` | **Tidak** |
| Daftar Instansi | `GET /agencies` | **Tidak** |
| Transisi Status (operator) | `PATCH /reports/:id/status` | **Tidak** |

**Dampak:** Layar `tracking_progress_screen.dart` dan `foto_progress_screen.dart` **hanya menampilkan** data (read-only via `getReportById`) — tombol/aksi aktif seperti "konfirmasi laporan selesai" belum benar-benar terhubung ke backend, walau secara visual sudah ada teks status terkait.

**Rekomendasi:** Prioritaskan Citizen Validation lebih dulu (nilai jual utama produk), baru Route Alert. Sisanya (Policy Simulator, Notifications, transisi status operator) wajar didokumentasikan sebagai scope Command Center fase 2.

---

### 🟡 FE-07 — Fallback Foto Dummy Saat Path Foto Tidak Valid
**Severity:** Minor

`report_remote_datasource.dart` mengirim byte JPEG 1×1 piksel palsu sebagai fallback saat `photoPath` kosong/tidak valid, agar validasi *"file wajib ada"* di backend tetap lolos — alih-alih memblokir submit dengan pesan error yang jelas ke pengguna.

**Rekomendasi:** Validasi di level UI — nonaktifkan tombol submit jika tidak ada foto valid, jangan kirim data dummy ke server produksi.

---

## 4. Hal yang Sudah Baik (Confirmed PASS)

### ✅ Struktur Proyek
Folder `core/`, `data/`, `presentation/` konsisten dengan Clean Architecture yang direncanakan di Architecture.md. Pemisahan `datasources/remote`, `models`, `repositories` jelas dan mudah ditelusuri.

### ✅ Integrasi Modul Auth
Seluruh field request (`register`, `verify-otp`, `login`, `refresh`) cocok 100% dengan DTO backend. Auto-refresh token saat 401 diimplementasikan dengan benar di `DioClient`, termasuk retry request asli setelah token baru didapat.

### ✅ Integrasi Modul Reports (Core Flow)
Field submit laporan, query parameter list laporan, dan enum status (8 nilai) seluruhnya cocok persis dengan backend. Response `202 Accepted` untuk submit laporan ditangani dengan benar sebagai proses asynchronous, tidak diasumsikan sebagai hasil final.

### ✅ Role-Based Routing
Redirect otomatis ke `/citizen` atau `/command-center` berdasarkan `user.role` sudah diimplementasikan konsisten di tiga entry point (splash screen, login, OTP screen).

### ✅ State Management & Navigasi
`MultiBlocProvider`/`MultiRepositoryProvider` disusun rapi di `main.dart`. Transisi antar halaman memakai `PageRouteBuilder` custom dengan animasi slide+fade yang halus dan berbeda gaya untuk alur auth (modal-style) vs alur utama.

---

## 5. Ringkasan Prioritas

| Prioritas | ID | Temuan |
|---|---|---|
| 1 (Blocker) | FE-05 | AI Service dipanggil tanpa autentikasi yang benar |
| 2 (Blocker) | FE-01 | Nol test coverage nyata + test bawaan yang rusak |
| 3 (Tinggi) | FE-06 | Citizen Validation & Route Alert belum terhubung API |
| 4 (Sedang) | FE-02 | File widget terlalu besar, melanggar Rules.md sendiri |
| 5 (Sedang) | FE-03 | Warna hardcode tidak konsisten dengan token resmi |
| 6 (Rendah) | FE-04, FE-07 | Dependency offline/push belum ada, fallback foto dummy |

---

## 6. Batasan Laporan

Review ini bersifat static code analysis — tidak mencakup pengujian UI manual di perangkat asli, tidak menjalankan `flutter test`/`flutter analyze` secara langsung (environment tidak memiliki Flutter SDK), dan tidak mengukur performa runtime aplikasi.