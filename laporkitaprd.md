# Product Requirements Document (PRD) — Frontend
## LaporKita: City Intelligence Platform untuk Kota yang Lebih Responsif

**Versi:** 1.0
**Tanggal:** 21 Agustus 2026
**Tim:** Saya Akan Lawan — SMK Telkom Malang
**Ruang Lingkup Dokumen:** Sisi Frontend (Mobile App) — akan disambungkan ke Backend (NestJS), Database (PostgreSQL/Supabase), dan layanan AI (YOLOv11, XGBoost, Gemini) pada tahap berikutnya.

---

## 1. Latar Belakang & Tujuan Produk

LaporKita adalah platform pelaporan fasilitas umum berbasis AI dengan konsep **"From Report to Resolve"**. Frontend berperan sebagai titik interaksi utama bagi dua kelompok pengguna:

- **Warga (B2C)** — melapor kerusakan fasilitas umum dan memantau progresnya.
- **Operator Pemerintah (B2G)** — memantau, memverifikasi, dan menindaklanjuti laporan melalui dashboard Command Center.

**Tujuan PRD ini:**
1. Mendefinisikan seluruh kebutuhan fungsional dan non-fungsional frontend secara independen dari implementasi backend.
2. Menstandarkan kontrak data (data contract) yang diharapkan frontend dari API, agar backend dapat dikembangkan paralel.
3. Menjadi acuan desain UI/UX dan arsitektur teknis frontend.

---

## 2. Sasaran Pengguna & Persona

| Persona | Deskripsi | Kebutuhan Utama |
|---|---|---|
| **Warga Pelapor** (Kalandra, 24 th) | Warga Kota Malang, pengguna smartphone harian | Melapor cepat (3-tap), tahu status laporannya |
| **Warga Pemantau** | Warga yang tidak melapor tapi ingin tahu kondisi kota/rute | Melihat peta kerusakan, dapat notifikasi rute |
| **Operator Command Center** | Staf DPUPR/Dishub/Diskominfo | Melihat prioritas, memverifikasi, menugaskan penanganan |
| **Pengambil Kebijakan** | Kepala Dinas/Pemkot | Melihat tren, menjalankan simulasi kebijakan |

---

## 3. Ruang Lingkup (Scope)

### 3.1 Termasuk (In-Scope)
- Aplikasi mobile Android (Flutter) dengan **2 mode akses**: Citizen App (B2C) dan Command Center App/Dashboard (B2G) — dapat berupa 1 codebase dengan role-based UI atau 2 modul terpisah dalam 1 app.
- 5 layar inti sesuai mock-up: Dashboard Command Center, Peta Interaktif, Kamera Laporan (Citizen Vision), Detail Laporan, Konfirmasi Laporan.
- Integrasi UI dengan Google Maps SDK (tampilan peta & pin).
- Integrasi UI dengan kamera perangkat + on-device inference (TensorFlow Lite/YOLOv11) untuk real-time object detection di layar kamera.
- State management, navigasi, dan komponen UI reusable (card, radial progress, heatmap/zona warna, timeline status).

### 3.2 Tidak Termasuk (Out-of-Scope untuk fase frontend ini)
- Logika backend (verifikasi AI server-side, prediksi XGBoost, orkestrasi Gemini).
- Skema database & migrasi.
- Autentikasi/otorisasi tingkat server (frontend hanya mengonsumsi token yang diterbitkan backend).
- Infrastruktur deployment/DevOps.

---

## 4. Informasi Arsitektur (Information Architecture)

```
LaporKita App
├── Auth Flow (Login/Register/OTP) — bergantung pada endpoint backend
├── B2C — Citizen Vision
│   ├── Beranda (ringkasan laporan saya, kategori, laporan terdekat)
│   ├── Kamera Laporan (Citizen Vision — 3-tap flow)
│   ├── Peta Interaktif (Urban Emotion Map)
│   ├── Detail Laporan (timeline, dukungan, komentar)
│   ├── Konfirmasi Laporan (setelah submit)
│   ├── Profil & Poin Kontribusi
│   └── Notifikasi Route Alert
└── B2G — Command Center
    ├── Dashboard (Urban Health Score, Prioritas Prediksi Harian)
    ├── Peta & Daftar Laporan (filter: Belum Diproses/Diproses/Selesai)
    ├── Detail Laporan (aksi: verifikasi, tugaskan, update status)
    └── Policy Simulator (input prompt → hasil simulasi AI)
```

---

## 5. Kebutuhan Fungsional per Layar

### 5.1 Layar: Beranda / Dashboard Command Center (Gambar 4)
**User story:** Sebagai operator, saya ingin melihat kondisi kota secara ringkas agar bisa mengambil keputusan cepat.

| Elemen UI | Kebutuhan |
|---|---|
| Urban Health Score | Widget radial progress (skor 0–100) + status teks ("Sehat & Terkendali") |
| Ringkasan angka | 3 kartu: Laporan Saya, Sedang Diproses, Laporan Selesai |
| Kategori | Grid ikon kategori (Routes, Trotoar, Lalu Lintas, Fasilitas Umum) — tap → filter laporan |
| Laporan Terdekat | List card (foto, judul, tanggal, alamat, jumlah dukungan, badge status) |
| Search bar | Cari laporan/kategori/lokasi |

**Data yang dibutuhkan dari API:** `GET /health-score`, `GET /reports?filter=nearby`, `GET /reports/summary`

### 5.2 Layar: Peta Interaktif / Urban Emotion Map (Gambar 5)
**User story:** Sebagai warga/operator, saya ingin melihat sebaran laporan dalam bentuk peta berzona agar mudah memahami area bermasalah.

| Elemen UI | Kebutuhan |
|---|---|
| Peta (Google Maps SDK) | Render zona warna (merah/kuning/hijau) berdasarkan data tingkat "stres" lingkungan dari backend |
| Pin laporan | Marker dengan warna sesuai kategori/status |
| Bottom sheet preview | Card ringkas saat pin di-tap (foto, judul, alamat, status) |
| Filter tab | Semua / Belum Diproses / Diproses / Selesai |
| List laporan (scrollable) | Sinkron dengan peta di atasnya |

**Data yang dibutuhkan:** `GET /map/zones`, `GET /reports?bbox=...&status=...`

### 5.3 Layar: Kamera Laporan / Citizen Vision (Gambar 6)
**User story:** Sebagai warga, saya ingin melapor cukup dengan 3 sentuhan tanpa mengetik detail manual.

| Elemen UI | Kebutuhan |
|---|---|
| Live camera preview | Akses kamera native |
| On-device detection overlay | Label + confidence score real-time (mis. "Tumpukan Sampah 92%") via TFLite model yang di-bundle di app |
| Status indikator | GPS Aktif, AI Ready, GPS Connected, Internet Ok |
| Info otomatis | Lokasi (reverse geocoding ditangani backend/Maps API), timestamp, kategori terdeteksi |
| Tombol shutter | 1 tap potret → 1 tap kirim (total memenuhi 3-tap rule) |

**Data yang dikirim ke API saat submit:** foto (multipart), lat/long, timestamp, kategori hasil deteksi on-device (sebagai hint, akan diverifikasi ulang server-side)
**Endpoint:** `POST /reports`

### 5.4 Layar: Detail Laporan (Gambar 7)
**User story:** Sebagai warga/operator, saya ingin melihat status lengkap satu laporan dan riwayat penanganannya.

| Elemen UI | Kebutuhan |
|---|---|
| Header | ID laporan, kategori, badge status, alamat |
| Foto laporan | Full width image |
| AI Verification checklist | Foto Valid, GPS Valid, Timestamp Valid, Metadata Lengkap + progress bar confidence |
| Statistik | Dukungan, Dilihat, Komentar |
| Tombol aksi (B2C) | Dukung (like/upvote), Komentar |
| Tombol aksi (B2G) | Verifikasi, Teruskan ke Dinas, Update Status |
| Tab: Timeline / Detail / Komentar | Timeline vertikal (Laporan dibuat → Diverifikasi → Diteruskan ke Dinas → Diproses → Estimasi Selesai → Selesai), termasuk foto progres dari petugas |

**Data:** `GET /reports/{id}`, `POST /reports/{id}/support`, `POST /reports/{id}/comments`, `PATCH /reports/{id}/status` (B2G only)

### 5.5 Layar: Konfirmasi Laporan (Gambar 8)
**User story:** Sebagai warga, saya ingin kepastian bahwa laporan saya berhasil terkirim.

| Elemen UI | Kebutuhan |
|---|---|
| Ikon sukses + pesan terima kasih | Feedback visual positif |
| Ringkasan laporan | ID laporan, foto thumbnail, judul, dukungan awal, status |
| Poin kontribusi | Tampilkan penambahan poin sebagai insentif ringan |
| CTA | "Lihat Tracking" → ke Detail Laporan; "Kembali ke Beranda" |

### 5.6 Fitur Tambahan (disebutkan di proposal, perlu UI pendukung)
- **Route Alert / Notifikasi kontekstual:** push notification / in-app banner "Jalan berlubang 10 meter lagi" saat pengguna mendekati titik laporan (butuh izin lokasi background + integrasi geofencing).
- **Policy Simulator (B2G):** form input prompt bebas teks → tampilkan hasil narasi + grafik proyeksi dari Gemini (`POST /policy-simulator`).
- **Citizen Validation:** tombol konfirmasi "Sudah Diperbaiki Sesuai" pada laporan berstatus Selesai.

---

## 6. Panduan UI/UX

| Prinsip | Penerapan |
|---|---|
| Clutter-free & data-storytelling | Komponen berbasis card, radial progress, heatmap/zona warna |
| Palet warna | Dominan gradasi hijau (sustainable) + putih bersih |
| Tipografi | Prioritas keterbacaan tinggi (banyak menampilkan angka/data) |
| 3-tap rule (Citizen App) | Buka kamera → potret → kirim |
| Hierarki dashboard (Command Center) | Urutkan berdasarkan urgensi waktu; Prioritas Prediksi Harian di posisi teratas |
| Aksesibilitas | Kontras warna memadai terutama untuk badge status (merah/kuning/hijau) |

Referensi visual lengkap: [Figma Prototype](https://www.figma.com/design/ltkTxTn0JkruiR1z5GYswU/Lapor-Kita)

---

## 7. Kebutuhan Teknis Frontend

| Aspek | Pilihan Teknologi | Catatan |
|---|---|---|
| Framework | Flutter (Dart) | Lintas platform, fokus rilis awal Android |
| State management | *(perlu ditentukan tim — rekomendasi: Riverpod/Bloc)* | Perlu mendukung offline-first sebagian (draft laporan saat GPS/internet belum siap) |
| On-device AI | TensorFlow Lite (model YOLOv11 hasil konversi) | Model di-bundle dalam app, inference lokal untuk live detection |
| Peta | Google Maps SDK for Flutter | Marker clustering untuk performa saat laporan banyak |
| Networking | REST client (mis. Dio) ke backend NestJS | Perlu retry & caching untuk kondisi jaringan lemah |
| Autentikasi | Simpan token (JWT) hasil login dari backend | Role-based routing: B2C vs B2G |
| Notifikasi | Push notification (FCM) + geofencing lokal | Untuk fitur Route Alert |
| Media | Kompresi gambar sebelum upload | Mengurangi beban jaringan |

---

## 8. Kontrak Data Frontend ↔ Backend (Ringkasan Endpoint yang Diharapkan)

> Frontend dirancang mengasumsikan endpoint berikut tersedia dari backend NestJS. Skema detail (request/response body) perlu difinalisasi bersama tim backend.

| Endpoint (usulan) | Method | Digunakan di Layar |
|---|---|---|
| `/auth/login`, `/auth/register` | POST | Auth Flow |
| `/health-score` | GET | Dashboard Command Center |
| `/reports` | GET/POST | Beranda, Peta, Kamera Laporan |
| `/reports/{id}` | GET/PATCH | Detail Laporan |
| `/reports/{id}/support` | POST | Detail Laporan (Dukung) |
| `/reports/{id}/comments` | GET/POST | Detail Laporan |
| `/reports/{id}/validate` | POST | Citizen Validation |
| `/map/zones` | GET | Peta Interaktif |
| `/policy-simulator` | POST | Policy Simulator (B2G) |
| `/notifications/route-alert` | GET/subscribe | Route Alert |

---

## 9. Kebutuhan Non-Fungsional

- **Performa:** Live camera detection harus tetap responsif (>15 fps) di perangkat mid-range.
- **Ketahanan jaringan:** Form laporan harus bisa disimpan sebagai draft lokal jika koneksi terputus, lalu auto-sync saat online kembali.
- **Keamanan:** Token disimpan secure storage; tidak menyimpan foto sensitif lebih lama dari kebutuhan cache.
- **Skalabilitas UI:** List laporan & peta harus mendukung pagination/lazy-loading untuk ribuan data (mendukung target SOM 15–20 ribu pengguna aktif).
- **Lokalisasi:** UI berbahasa Indonesia sebagai default (sesuai target pilot Kota Malang).

---

## 10. Metrik Keberhasilan Frontend

| Metrik | Target |
|---|---|
| Waktu rata-rata submit laporan | < 30 detik (selaras 3-tap rule) |
| Crash rate | < 1% sesi |
| Load time Dashboard Command Center | < 2 detik pada koneksi 4G |
| Adopsi awal (SOM tahun 1) | 15.000–20.000 pengguna aktif |

---

## 11. Risiko & Pertanyaan Terbuka

- Apakah model TFLite untuk on-device detection cukup ringan untuk perangkat low-end warga umum?
- Bagaimana strategi caching peta (zona warna) agar tidak terlalu sering fetch ulang dari backend?
- Perlu klarifikasi apakah Command Center dirilis sebagai app mobile terpisah atau web dashboard (proposal menyebut mobile Flutter untuk semua, namun beban data B2G biasanya lebih cocok di desktop/web).
- Skema role-based access (B2C vs B2G) di satu app perlu didefinisikan bersama backend agar konsisten dengan sistem auth.

---

## 12. Lampiran

- Mock-up rujukan: Gambar 4 (Dashboard Command Center), Gambar 5 (Peta Interaktif), Gambar 6 (Kamera Laporan), Gambar 7 (Detail Laporan), Gambar 8 (Konfirmasi Laporan) — dari Proposal MAGE 12.
- Link Figma Prototype: https://www.figma.com/design/ltkTxTn0JkruiR1z5GYswU/Lapor-Kita