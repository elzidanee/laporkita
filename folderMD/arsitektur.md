lib/
├── main.dart
├── core/
│   ├── network/        # Dio client, interceptors (auth token, retry)
│   ├── theme/           # Design tokens (warna, tipografi dari Design System)
│   ├── constants/
│   └── utils/
├── data/
│   ├── models/           # DTO (Report, User, Category, dll)
│   ├── repositories/     # Implementasi repository (panggil API)
│   └── datasources/      # remote (REST), local (cache/draft offline)
├── domain/
│   ├── entities/
│   └── usecases/         # business logic sisi client (mis. validasi form sebelum submit)
├── presentation/
│   ├── citizen/
│   │   ├── home/
│   │   ├── camera/        # Citizen Vision + integrasi TFLite
│   │   ├── map/
│   │   ├── report_detail/
│   │   └── profile/
│   ├── command_center/
│   │   ├── dashboard/
│   │   ├── report_management/
│   │   └── policy_simulator/
│   └── shared_widgets/    # ReportCard, StatusBadge, RadialProgress, dll
└── ai/
    └── tflite_service.dart  # wrapper inference on-device



2.2 Pola Arsitektur
Clean Architecture (presentation → domain → data) agar business logic tidak bergantung langsung pada implementasi API.
State Management: Riverpod/Bloc (per fitur) — rekomendasi Riverpod untuk skalabilitas & testability.
Offline-first parsial: Draft laporan disimpan lokal (Hive/SQLite) saat tidak ada koneksi, auto-sync saat online.
Role-based routing: Setelah login, role dari JWT menentukan initial route (Citizen App vs Command Center).
2.3 On-Device AI Flow
Camera Stream → Frame Preprocessing → TFLite Interpreter (YOLOv11)
→ Bounding Box + Label + Confidence → Overlay UI (real-time)
→ (saat shutter ditekan) → Freeze frame + hasil deteksi terakhir
→ dikirim sebagai HINT ke backend (bukan keputusan final)

Prinsip penting: deteksi on-device bersifat assistive (mempercepat UX 3-tap), keputusan final validitas tetap di AI Verification Service backend agar konsisten & tidak mudah dimanipulasi client.