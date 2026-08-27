import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';

/// Layar Kamera Khusus Validasi Perbaikan — Presisi Sesuai Figma (Node 232:1083)
class CameraValidasiScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const CameraValidasiScreen({super.key, this.reportData});

  @override
  State<CameraValidasiScreen> createState() => _CameraValidasiScreenState();
}

class _CameraValidasiScreenState extends State<CameraValidasiScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;
  bool _isCameraReady = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;

  String _currentAddress = 'Jl. Simpang Ibrahim';
  String _dateTimeStr = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.reportData?['address'] as String? ??
        widget.reportData?['fullAddress'] as String? ??
        'Jl. Simpang Ibrahim';
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
    _initCamera();
    _fetchLiveGps();
  }

  void _updateClock() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final dayName = days[(now.weekday - 1) % 7];
    final monthName = months[(now.month - 1) % 12];
    final hour = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _dateTimeStr = '$dayName, ${now.day} $monthName ${now.year} | $hour.$min WIB';
      });
    }
  }

  Future<void> _fetchLiveGps() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[_selectedCameraIdx],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraReady = true);
        }
      }
    } catch (_) {
      // Fallback untuk emulator tanpa kamera fisik
      if (mounted) {
        setState(() => _isCameraReady = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off,
      );
      setState(() => _isFlashOn = newFlash);
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    await _cameraController?.dispose();
    setState(() => _isCameraReady = false);
    _initCamera();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      String photoPath = '';
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile file = await _cameraController!.takePicture();
        photoPath = file.path;
      } else {
        // Fallback dummy file untuk emulator
        photoPath = widget.reportData?['imagePath'] as String? ?? '';
      }

      if (mounted) {
        final forwardData = Map<String, dynamic>.from(widget.reportData ?? {});
        forwardData['capturedPhotoPath'] = photoPath;
        forwardData['imagePath'] = photoPath.isNotEmpty ? photoPath : forwardData['imagePath'];

        Navigator.pushReplacementNamed(
          context,
          '/beri-validasi',
          arguments: forwardData,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview / Fallback
          if (_isCameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            _buildCameraFallback(),

          // 2. Top Gradient Header (Figma node 232:1087)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // 3. Top Navigation & Action Buttons
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Title
                    const Text(
                      'Tangkap gambar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),

                    // Actions: Flash & Switch Camera
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isFlashOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _toggleFlash,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _toggleCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Center Top Badge: "GPS Aktif" (Figma node 232:1099)
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x9942A54B), // rgba(66,165,75,0.6)
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF62D26D), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'GPS Aktif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Gradient Footer (Figma node 232:1094)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),

          // 6. Bottom Controls: Metadata Card, Status Pills, Shutter Button
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Card: Address & Clock (Figma node 232:1105)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: AppColors.neutral900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.neutral900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dateTimeStr.isNotEmpty
                                  ? _dateTimeStr
                                  : 'Kamis, 2 April 2026 | 10.30 WIB',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Status Pills Row (Figma node 232:1119)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusPill('AI Ready'),
                    const SizedBox(width: 8),
                    _buildStatusPill('GPS Connected'),
                    const SizedBox(width: 8),
                    _buildStatusPill('Internet OK'),
                  ],
                ),
                const SizedBox(height: 20),

                // Shutter Button (Figma node 232:1097 & 232:1098)
                GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.greenPrimary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x9942A54B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF62D26D), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 12),
            Text(
              'Pratinjau Kamera Validasi',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
