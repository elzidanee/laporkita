# AI Agent Instructions — Integrasi Frontend (Flutter) ke Backend LaporKita

> Dokumen ini ditujukan sebagai instruksi kerja untuk AI coding agent (mis. Claude Code) yang akan mengerjakan integrasi API di repo frontend `elzidanee/laporkita`. Sebelum mulai coding, **WAJIB** lakukan langkah verifikasi di Bagian 0 — jangan asumsikan endpoint/field tanpa verifikasi, karena sebagian struktur di bawah masih berstatus asumsi dari desain awal (PRD/ERD), belum tentu 100% sama dengan implementasi aktual backend.

---

## 0. WAJIB DILAKUKAN SEBELUM CODING (Verification Step)

AI agent harus melakukan ini sebagai langkah pertama, sebelum menulis satu baris kode API pun:

1. Buka `{{baseUrl}}/api/docs` (Swagger UI) dari backend yang sedang berjalan.
2. Ambil daftar endpoint aktual, method, request schema, dan response schema — **ini sumber kebenaran utama**, bukan bagian 3 di dokumen ini.
3. Jika Swagger tidak tersedia/kosong, baca langsung source code backend: folder `src/modules/*/[nama].controller.ts` untuk path & method, dan `*.dto.ts` untuk field yang valid.
4. Bandingkan hasilnya dengan Bagian 3 di dokumen ini. Jika berbeda, **ikuti hasil verifikasi aktual**, dan catat perbedaannya di komentar kode/PR description.
5. Baru setelah itu lanjut ke implementasi model, repository, dan UI.

**Jangan generate kode yang memanggil endpoint yang belum diverifikasi ada di backend.**

---

## 1. Base URL & Environment

| Environment | Base URL |
|---|---|
| Tunnel dev saat ini (Cloudflare Tunnel) | `https://drops-gamecube-journalist-soa.trycloudflare.com` |
| Prefix API global | `/api/v1` |
| Base URL lengkap untuk dipakai di Dio client | `https://drops-gamecube-journalist-soa.trycloudflare.com/api/v1` |

**PENTING — sifat URL ini sementara:**
- URL `trycloudflare.com` adalah tunnel gratis yang **berubah setiap kali backend di-restart** (kecuali dikonfigurasi named tunnel). Jangan hardcode URL ini langsung di banyak tempat.
- AI agent harus membuat URL ini **dapat dikonfigurasi**, bukan hardcoded di banyak file:

```dart
// lib/core/config/app_config.dart
class AppConfig {
  // Ganti nilai ini via --dart-define atau file .env, JANGAN hardcode di banyak tempat lain
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://drops-gamecube-journalist-soa.trycloudflare.com/api/v1',
  );
}
```

Jalankan Flutter dengan:
```
flutter run --dart-define=API_BASE_URL=https://drops-gamecube-journalist-soa.trycloudflare.com/api/v1
```

Agar saat URL tunnel berganti, tidak perlu ubah kode — cukup ubah value saat run/build.

---

## 2. Response Envelope (CONFIRMED — hasil observasi nyata dari testing Postman)

Backend mengembalikan struktur konsisten berikut untuk **semua response**, termasuk saat error:

**Success:**
```json
{
  "success": true,
  "data": { /* payload sesuai endpoint */ },
  "error": null
}
```

**Error (confirmed dari 2 kasus nyata saat testing):**
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PHONE_NOT_VERIFIED",
    "message": "Nomor telepon belum diverifikasi. Silakan lakukan verifikasi OTP terlebih dahulu."
  }
}
```

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "NOT_FOUND",
    "message": "Cannot POST /api/v1/api/v1/auth/register"
  }
}
```

**Instruksi untuk AI agent:** buat generic wrapper di Dart yang SELALU mem-parsing struktur `{ success, data, error }` ini di layer paling luar (interceptor Dio atau base repository), sebelum parsing model spesifik dari `data`. Jangan biarkan setiap repository menangani parsing envelope sendiri-sendiri (DRY).

```dart
// lib/core/network/api_response.dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] != null ? ApiError.fromJson(json['error']) : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;
  ApiError({required this.code, required this.message});
  factory ApiError.fromJson(Map<String, dynamic> json) =>
      ApiError(code: json['code'], message: json['message']);
}
```

**Known error codes (confirmed):**
| Code | Arti | Aksi UI yang disarankan |
|---|---|---|
| `NOT_FOUND` | Route salah / resource tidak ada | Bug developer — jangan tampilkan raw ke user, log saja |
| `PHONE_NOT_VERIFIED` | User belum verifikasi OTP | Redirect ke layar Verifikasi OTP, bukan tampilkan error mentah |

Tambahkan kode error lain ke tabel ini begitu ditemukan saat development (mis. `VALIDATION_ERROR`, `UNAUTHORIZED`, `DUPLICATE_ENTRY`, dll) — AI agent WAJIB update dokumen ini setiap menemukan kode baru.

---

## 3. Alur Autentikasi (CONFIRMED sebagian, endpoint OTP masih perlu verifikasi ulang)

### 3.1 Yang sudah confirmed
- Register **tidak langsung** membuat akun aktif — perlu verifikasi OTP dulu.
- Login akan ditolak dengan `PHONE_NOT_VERIFIED` jika OTP belum diverifikasi.
- Prefix path adalah `/api/v1/...` (bukan double `/api/v1/api/v1/...`).

### 3.2 Yang PERLU diverifikasi ulang oleh AI agent via Swagger (belum confirmed)
- Path pasti endpoint verify-OTP (kandidat: `/auth/verify-otp`, `/auth/otp/verify`, `/auth/verify`).
- Field body yang diminta (`phoneNumber` vs `phone`, `otp` vs `code`).
- Apakah setelah verify-otp langsung dapat token (auto-login), atau harus panggil `/auth/login` terpisah.
- Format request `/auth/login` (pakai `phoneNumber`+`password`, atau `email`+`password`, atau keduanya opsional).
- Endpoint refresh token (`/auth/refresh` kemungkinan besar, tapi konfirmasi dulu).

### 3.3 Alur yang harus diimplementasikan di Flutter (urutan wajib)

```
[Register Screen]
   → POST /auth/register (phoneNumber, password, fullName, ...)
   → response: 202/201, akun belum aktif
   → navigate ke [OTP Screen]

[OTP Screen]
   → user input 4 digit dari SMS (atau log server saat dev)
   → POST {endpoint verify-otp} (phoneNumber, otp)
   → JIKA response berisi accessToken/refreshToken → simpan token, langsung ke [Home]
   → JIKA tidak berisi token → navigate ke [Login Screen]

[Login Screen]
   → POST /auth/login (phoneNumber, password)
   → JIKA error PHONE_NOT_VERIFIED → tampilkan pesan jelas + tombol "Verifikasi Sekarang" → balik ke [OTP Screen]
   → JIKA sukses → simpan accessToken (secure storage) + refreshToken → ke [Home]
```

**Instruksi khusus untuk AI agent:** Implementasikan penanganan `PHONE_NOT_VERIFIED` di layer UI Login sebagai **kasus khusus** (bukan generic error toast) — arahkan user ke OTP screen otomatis dengan nomor HP yang sama, jangan biarkan user stuck di layar error.

---

## 4. Daftar Modul/Endpoint yang Diharapkan Ada (ASUMSI dari desain awal — WAJIB diverifikasi satu-satu via Swagger sebelum implementasi)

> ⚠️ Bagian ini adalah referensi dari PRD/ERD yang kita susun sebelumnya, BUKAN hasil scan langsung ke backend. Gunakan sebagai checklist untuk dicocokkan ke Swagger, bukan sebagai kontrak final.

| Modul | Endpoint dugaan | Method | Auth diperlukan? |
|---|---|---|---|
| Auth | `/auth/register` | POST | Tidak |
| Auth | `/auth/verify-otp` *(perlu konfirmasi nama pasti)* | POST | Tidak |
| Auth | `/auth/login` | POST | Tidak |
| Auth | `/auth/refresh` | POST | Refresh token |
| Categories | `/categories` | GET | Tidak |
| Agencies | `/agencies` | GET | Tidak |
| Reports | `/reports` | GET, POST | POST perlu auth |
| Reports | `/reports/:id` | GET, PATCH | PATCH perlu auth (operator) |
| Reports | `/reports/:id/support` | POST | Ya |
| Reports | `/reports/:id/comments` | GET, POST | POST perlu auth |
| Reports | `/reports/:id/validate` | POST | Ya (citizen validation) |
| Route Alert | `/route-alerts/check` | POST | Kemungkinan ya |
| Policy Simulator | `/policy-simulator` | POST | Ya (role operator/policy_maker) |
| Notifications | `/notifications` | GET | Ya |

**Instruksi untuk AI agent:** untuk setiap baris di tabel ini, tandai status di komentar kode saat diimplementasikan:
```dart
// STATUS: VERIFIED via Swagger 2026-08-23
// atau
// STATUS: NOT YET VERIFIED — implemented based on assumption, needs testing
```

---

## 5. Business Rules yang Harus Diikuti di Sisi Frontend

(Diambil dari dokumen Rules yang sudah disepakati sebelumnya — tetap berlaku selama tidak bertentangan dengan hasil verifikasi Swagger.)

1. **Status laporan** mengikuti state machine tetap:
   `pending_verification → verified/rejected → assigned → in_progress → completed → resolved/disputed`
   UI tidak boleh menampilkan tombol aksi yang melompati urutan ini (mis. tombol "Selesai" tidak muncul kalau status masih `pending_verification`).

2. **Submit laporan bersifat asynchronous.** Response awal POST `/reports` kemungkinan `202 Accepted` dengan status `pending_verification` — bukan hasil verifikasi final. UI harus:
   - Tampilkan status "Menunggu Verifikasi" segera setelah submit.
   - Lakukan polling `GET /reports/:id` secara berkala (misal setiap 5–10 detik selama beberapa menit) ATAU dengarkan push notification, untuk update status begitu AI Verification selesai di background.
   - Jangan blocking UI menunggu hasil verifikasi secara sinkron.

3. **1 user hanya bisa dukung 1x per laporan** — tombol "Dukung" harus disable/berubah state setelah user memberi dukungan (idealnya validasi state ini datang dari field response, misal `isSupportedByMe: true`, bukan cuma disimpan lokal di device).

4. **Draft laporan offline:** jika submit gagal karena tidak ada koneksi, simpan draft laporan (foto + metadata) secara lokal (Hive/SQLite), dan sync otomatis saat online kembali.

5. **Warna & style UI** wajib mengacu ke Design System yang sudah dibuat (palet `#FFFFFF`, `#206C57`, `#1D9C51`, `#B9D19E` + turunan warna status) — jangan hardcode hex baru di widget.

---

## 6. Struktur Kode Frontend yang Harus Diikuti AI Agent

Ikuti struktur Clean Architecture yang sudah disepakati di dokumen Architecture:

```
lib/
├── core/
│   ├── config/app_config.dart       # baseUrl, env
│   ├── network/
│   │   ├── dio_client.dart           # instance Dio + interceptor auth & refresh token
│   │   ├── api_response.dart         # wrapper envelope (lihat Bagian 2)
│   │   └── api_exception.dart        # mapping ApiError → exception yang readable
│   └── theme/                        # design tokens (warna, tipografi)
├── data/
│   ├── models/                       # DTO per entity (Report, User, Category, dll)
│   ├── datasources/remote/           # 1 file per modul (auth_remote_ds.dart, report_remote_ds.dart, dll)
│   └── repositories/                 # implementasi repository, panggil datasource
├── domain/
│   ├── entities/
│   └── usecases/
└── presentation/
    ├── auth/ (register, otp, login)
    ├── citizen/ (home, camera, map, report_detail, profile)
    └── command_center/ (dashboard, report_management, policy_simulator)
```

**Aturan wajib untuk AI agent saat generate kode:**
- Widget **tidak boleh** memanggil Dio langsung — selalu lewat repository → usecase → provider/state notifier.
- Setiap model wajib punya `fromJson`/`toJson` yang match persis dengan field aktual dari Swagger (bukan field asumsi dari ERD).
- Interceptor Dio wajib menangani: (a) menyisipkan `Authorization: Bearer <token>` otomatis, (b) auto-refresh token saat dapat 401, (c) mapping response error envelope ke exception yang bisa ditangkap UI.

---

## 7. Checklist Implementasi Bertahap (urutan yang harus diikuti AI agent)

1. [ ] Verifikasi seluruh endpoint via Swagger (Bagian 0) — update Bagian 4 dengan status VERIFIED.
2. [ ] Implementasi `AppConfig`, `DioClient`, `ApiResponse`, `ApiException`.
3. [ ] Implementasi modul Auth lengkap (register, verify-otp, login, refresh, secure token storage).
4. [ ] Test manual alur auth di aplikasi (bukan cuma Postman) — pastikan redirect `PHONE_NOT_VERIFIED` bekerja.
5. [ ] Implementasi Categories & Agencies (GET sederhana, tanpa auth) — sebagai sanity check koneksi API setelah auth beres.
6. [ ] Implementasi Reports: list, detail, submit (dengan async status handling & polling).
7. [ ] Implementasi fitur interaktif: support, comments, citizen validation.
8. [ ] Implementasi modul Command Center (khusus role operator/policy_maker).
9. [ ] Implementasi Route Alert & Policy Simulator (fitur fase lanjutan).
10. [ ] Review akhir: pastikan semua warna/komponen sesuai Design System, semua state loading/error/empty tertangani di setiap layar.

---

## 8. Catatan Tambahan untuk AI Agent

- Jangan pernah generate kode yang mengasumsikan field response tanpa tanda `VERIFIED` di Bagian 4.
- Jika Swagger tidak mencantumkan contoh response yang jelas, lakukan 1x call manual (via Postman/curl) dan simpan contoh response asli sebagai komentar di atas model Dart terkait, agar developer lain tahu sumbernya.
- Setiap kali menemukan ketidaksesuaian antara dokumen ini dan implementasi aktual backend, **update dokumen ini juga** — jangan biarkan dokumen basi sementara kode berubah.