# Prompt untuk AI Coding Agent — Setup Routing OSRM + Peta Rute (flutter_map)
## Fitur: Navigasi A → B dengan Peringatan Fasilitas Rusak di Sepanjang Rute

> Salin seluruh isi file ini ke awal percakapan dengan AI coding agent (Antigravity) yang bekerja di repo Flutter `laporkita`.

---

## 0. Konteks Proyek (WAJIB dibaca sebelum mulai)

Ini adalah aplikasi Flutter bernama **LaporKita** — platform pelaporan fasilitas umum rusak (jalan berlubang, dll). Struktur proyek mengikuti Clean Architecture:

```
lib/
├── core/
│   ├── config/app_config.dart      # base URL, API key
│   ├── network/dio_client.dart     # Dio instance + interceptor
│   ├── theme/app_colors.dart       # SEMUA warna WAJIB dari sini, jangan hardcode hex baru
│   └── services/notification_service.dart   # sudah ada, untuk local notification
├── data/
│   ├── models/                     # DTO per entity
│   ├── datasources/remote/         # 1 file per modul
│   └── repositories/               # panggil datasource
└── presentation/
    ├── citizen/                    # layar warga
    └── command_center/             # layar operator
```

**Aturan proyek yang WAJIB diikuti (jangan dilanggar):**
1. Widget tidak boleh memanggil `Dio`/HTTP client langsung — selalu lewat `repository` → (opsional `usecase`) → UI.
2. Semua warna pakai `AppColors.xxx` dari `lib/core/theme/app_colors.dart`. Jika butuh warna baru, tambahkan sebagai token baru di file itu — jangan hardcode `Color(0xFF...)` langsung di widget.
3. **Jangan buat file widget baru lebih dari ±400 baris.** Kalau layar kompleks, pecah jadi beberapa widget kecil di subfolder `widgets/` lokal.
4. **Penanganan error harus jujur.** Jika sebuah `try` gagal (exception), blok `catch` HARUS menampilkan pesan gagal yang jelas ke pengguna (warna merah/oranye) — **DILARANG KERAS** menampilkan pesan sukses palsu di blok `catch` (ini adalah bug yang pernah ditemukan di proyek ini sebelumnya, jangan diulangi).
5. Ikuti gaya penamaan yang sudah ada: `snake_case.dart` untuk file, `PascalCase` untuk class, `camelCase` untuk variabel/fungsi.

---

## 1. Tujuan Fitur Ini

Build fitur navigasi A→B: pengguna memilih titik asal dan tujuan di peta, aplikasi menampilkan rute jalan sungguhan (bukan garis lurus) menggunakan **OSRM (Open Source Routing Machine)** — gratis, tanpa API key berbayar — digambar di atas peta **OpenStreetMap** menggunakan package `flutter_map`.

**Scope untuk task ini SAJA (jangan kerjakan lebih dari ini dulu):**
- ✅ Setup pemanggilan OSRM untuk mendapatkan rute antara 2 titik koordinat
- ✅ Menggambar rute (polyline) + marker asal/tujuan di `flutter_map`
- ✅ Menampilkan jarak & estimasi waktu tempuh dari hasil OSRM
- ❌ **BUKAN** scope task ini: alert proximity ke titik laporan rusak (fitur lanjutan setelah ini selesai), live tracking posisi user bergerak, voice guidance/TTS, rerouting otomatis. Jangan implementasikan ini dulu kecuali diminta eksplisit.

---

## 2. Dependency yang Harus Ditambahkan

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  flutter_map: ^7.0.2          # cek versi terbaru saat implementasi
  latlong2: ^0.9.1              # tipe data koordinat untuk flutter_map
  flutter_polyline_points: ^2.1.0   # decode polyline hasil OSRM jadi List<LatLng>
```

Jangan tambahkan dependency lain di luar daftar ini untuk task ini (hindari scope creep). `dio` untuk pemanggilan HTTP **sudah ada** di proyek — pakai `DioClient` yang sudah ada, jangan buat instance Dio baru.

Setelah menambahkan, jalankan:
```
flutter pub get
```

---

## 3. Kontrak API OSRM (Sumber Kebenaran — Pakai Persis Seperti Ini)

**Base URL server demo publik OSRM (gratis, untuk development/demo):**
```
https://router.project-osrm.org
```
> Catatan: ini server demo publik dengan fair-use limit, cukup untuk development & demo kompetisi. Untuk production jangka panjang nanti sebaiknya self-host OSRM sendiri — tapi itu di luar scope task ini.

**Endpoint routing:**
```
GET /route/v1/driving/{lon1},{lat1};{lon2},{lat2}
```

**Query parameters yang WAJIB disertakan:**
| Parameter | Nilai | Keterangan |
|---|---|---|
| `overview` | `full` | Agar geometry rute lengkap, bukan disederhanakan |
| `geometries` | `geojson` | Agar response geometry berupa array koordinat langsung (lebih mudah di-parse ketimbang encoded polyline string) |
| `steps` | `true` | Sertakan instruksi per langkah (untuk fitur turn-by-turn di masa depan, tidak wajib dipakai sekarang tapi sertakan agar tidak perlu request ulang nanti) |

**Contoh request lengkap:**
```
GET https://router.project-osrm.org/route/v1/driving/112.6304,-7.9827;112.6412,-7.9701?overview=full&geometries=geojson&steps=true
```
⚠️ **PENTING:** OSRM pakai format `longitude,latitude` (kebalikan urutan lat/lng yang biasa dipakai `flutter_map`/`Geolocator`). Pastikan urutan ini tidak tertukar saat membangun URL request.

**Contoh response (struktur yang perlu di-parse):**
```json
{
  "code": "Ok",
  "routes": [
    {
      "geometry": {
        "coordinates": [
          [112.6304, -7.9827],
          [112.6310, -7.9820],
          [112.6412, -7.9701]
        ],
        "type": "LineString"
      },
      "distance": 1520.4,
      "duration": 245.8,
      "legs": [
        {
          "steps": [
            {
              "distance": 300.0,
              "duration": 45.0,
              "name": "Jl. Ahmad Yani",
              "maneuver": { "type": "depart" }
            }
          ]
        }
      ]
    }
  ],
  "waypoints": [ ... ]
}
```

**Field penting yang harus diambil:**
- `routes[0].geometry.coordinates` → array `[lon, lat]` — HARUS di-convert ke `List<LatLng(lat, lon)>` untuk `flutter_map` (ingat: urutan dibalik dari `[lon, lat]` menjadi `LatLng(lat, lon)`).
- `routes[0].distance` → jarak total dalam **meter**.
- `routes[0].duration` → estimasi waktu dalam **detik**.

**Kemungkinan error response** (WAJIB ditangani, jangan asumsikan selalu sukses):
```json
{ "code": "NoRoute", "message": "Impossible route between points" }
```
Jika `code` bukan `"Ok"`, tampilkan pesan error yang jelas ke pengguna (lihat Aturan #4 di atas — jangan pura-pura sukses).

---

## 4. Struktur File yang Harus Dibuat

Ikuti pola yang sudah ada di proyek, buat file-file berikut:

```
lib/
├── data/
│   ├── models/
│   │   └── route_model.dart              # model hasil parsing response OSRM
│   ├── datasources/remote/
│   │   └── routing_remote_datasource.dart # panggil OSRM via Dio
│   └── repositories/
│       └── routing_repository.dart        # wrapper datasource, di-inject via RepositoryProvider
└── presentation/
    └── citizen/
        └── navigation/
            ├── route_picker_screen.dart   # UI pilih titik A & B di peta
            └── widgets/
                └── route_summary_card.dart # card kecil menampilkan jarak & estimasi waktu
```

### 4.1 `route_model.dart` — spesifikasi
Buat class `RouteModel` dengan field:
- `List<LatLng> points` (hasil konversi dari `geometry.coordinates`)
- `double distanceMeters`
- `double durationSeconds`
- Getter turunan yang berguna untuk UI: `distanceKm` (format "1.5 km"), `durationMinutes` (format "4 menit")

Buat factory `RouteModel.fromOsrmJson(Map<String, dynamic> json)` yang mem-parsing struktur response OSRM persis seperti kontrak di Bagian 3. Lempar exception yang jelas (custom exception class, misal `RouteNotFoundException`) jika `code` bukan `"Ok"` atau `routes` kosong.

### 4.2 `routing_remote_datasource.dart` — spesifikasi
- Constructor menerima `Dio` instance (gunakan `DioClient` yang sudah ada di proyek — cek bagaimana datasource lain di proyek ini menerima Dio instance, ikuti pola yang sama persis).
- Method `Future<RouteModel> getRoute({required LatLng origin, required LatLng destination})`.
- Base URL OSRM (`https://router.project-osrm.org`) taruh sebagai constant di file ini atau di `AppConfig` — ikuti pola yang sudah ada di proyek untuk base URL lain (`AppConfig.baseUrl`, `AppConfig.aiServiceUrl`), buat entri baru `AppConfig.osrmBaseUrl` agar konsisten dan mudah diganti nanti kalau pindah ke self-hosted.
- Bangun URL manual sesuai kontrak Bagian 3 (perhatikan urutan lon,lat).
- Tangani error jaringan (timeout, no connection) dan error dari OSRM (`code != "Ok"`) dengan exception yang berbeda, agar UI bisa menampilkan pesan yang sesuai konteks.

### 4.3 `routing_repository.dart` — spesifikasi
- Wrapper tipis di atas datasource, mengikuti pola repository lain di proyek ini (lihat `report_repository.dart` sebagai referensi gaya).
- Daftarkan sebagai `RepositoryProvider` baru di `main.dart`, sejajar dengan repository lain yang sudah ada (`ReportRepository`, `NotificationRepository`, dst).

### 4.4 `route_picker_screen.dart` — spesifikasi UI
- Widget `FlutterMap` dengan:
  - `TileLayer` menggunakan tile OpenStreetMap standar: `urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`, dan **WAJIB** menyertakan atribusi `RichAttributionWidget` dengan teks "© OpenStreetMap contributors" (proyek ini sudah punya constant `OSM_ATTRIBUTION` di backend — pakai teks yang sama persis untuk konsistensi).
  - Interaksi: tap pertama di peta = set titik asal (marker warna `AppColors.greenPrimary`), tap kedua = set titik tujuan (marker warna `AppColors.statusDanger`). Tap ketiga reset dan mulai ulang dari titik asal baru.
  - Setelah kedua titik terisi, panggil `RoutingRepository.getRoute()`, tampilkan loading indicator saat menunggu.
  - Gambar hasil rute pakai `PolylineLayer` dengan warna `AppColors.greenPrimary`, ketebalan garis yang jelas terlihat (mis. `strokeWidth: 5`).
  - Setelah rute didapat, tampilkan `RouteSummaryCard` (widget terpisah, lihat 4.5) di bagian bawah layar menampilkan jarak & estimasi waktu.
  - Jika request gagal, tampilkan `SnackBar` warna merah dengan pesan error yang jelas (bukan silent fail, bukan pesan sukses palsu — lihat Aturan #4).
- Tambahkan entry navigasi ke layar ini dari tempat yang masuk akal di aplikasi (misalnya tombol/menu baru di beranda warga) — tanyakan ke saya dulu di mana titik entry yang paling pas kalau tidak yakin, jangan menebak sembarang tempat.

### 4.5 `route_summary_card.dart` — spesifikasi
- Widget kecil (bukan bagian dari file screen, file terpisah sesuai Aturan #3), menampilkan:
  - Ikon jarak + teks jarak (format km, 1 desimal)
  - Ikon waktu + teks estimasi waktu (format menit, dibulatkan)
  - Style mengikuti `AppColors` — card putih dengan sedikit shadow, teks warna `AppColors.neutral900`, aksen `AppColors.greenPrimary`.

---

## 5. Checklist Implementasi (urutan wajib)

1. [ ] Tambahkan dependency di `pubspec.yaml`, jalankan `flutter pub get`.
2. [ ] Tambahkan `AppConfig.osrmBaseUrl` di `app_config.dart`.
3. [ ] Buat `route_model.dart` dengan parsing sesuai kontrak Bagian 3, termasuk exception handling untuk `code != "Ok"`.
4. [ ] Buat `routing_remote_datasource.dart`, pastikan urutan lon/lat di URL benar.
5. [ ] Buat `routing_repository.dart`, daftarkan di `main.dart`.
6. [ ] Buat `route_summary_card.dart` (widget kecil, terpisah).
7. [ ] Buat `route_picker_screen.dart`, sambungkan semua di atas.
8. [ ] Tambahkan entry point navigasi ke layar ini (konfirmasi lokasi entry point ke saya dulu jika ragu).
9. [ ] Test manual: pilih 2 titik di sekitar Kota Malang, pastikan rute tergambar mengikuti jalan asli (bukan garis lurus), jarak & waktu masuk akal.
10. [ ] Test error case: matikan koneksi internet saat request, pastikan muncul pesan error yang jujur (bukan crash, bukan pesan sukses palsu).

---

## 6. Yang TIDAK Boleh Dilakukan di Task Ini

- Jangan implementasikan live tracking posisi user bergerak (`geolocator` position stream) — itu task selanjutnya.
- Jangan implementasikan alert proximity ke titik laporan rusak — itu task selanjutnya, dibangun di atas fondasi ini.
- Jangan tambahkan voice guidance/TTS.
- Jangan ubah/refactor file besar yang sudah ada (`report_detail_screen.dart`, `citizen_dashboard_tab.dart`) sebagai bagian dari task ini, walau file itu memang perlu di-refactor suatu saat — itu di luar scope task ini, jangan dicampur.
- Jangan pindah dari server demo OSRM publik ke self-hosted tanpa diminta — itu keputusan infrastruktur terpisah.

---

## 7. Setelah Selesai

Laporkan ke saya:
1. Konfirmasi seluruh checklist Bagian 5 selesai.
2. File apa saja yang dibuat/diubah (daftar lengkap path).
3. Jika ada penyimpangan dari spesifikasi di atas (misal versi package berbeda, ada kendala teknis), jelaskan alasannya secara eksplisit — jangan diam-diam menyimpang tanpa penjelasan.