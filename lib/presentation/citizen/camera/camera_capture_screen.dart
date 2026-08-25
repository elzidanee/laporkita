import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with TickerProviderStateMixin {
  // ── Camera State ───────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  String? _cameraError;

  // ── GPS & Location State ───────────────────────────────────────
  bool _isLoadingLocation = true;
  String _locationText = 'Melacak lokasi...';
  String _coordinatesText = '';
  String _timestamp = '';

  // ── Shutter pulse animation & Timer ────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateTimestamp();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimestamp(),
    );
    _initAll();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _updateTimestamp() {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _timestamp =
            '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year} | $h.$m WIB';
      });
    }
  }

  // ── Step 1: Init camera & request GPS permission via geolocator ──
  Future<void> _initAll() async {
    // Camera: Android will prompt automatically via manifest permission
    // Just try to initialize directly
    await _initCamera();

    // Location: use geolocator to request permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Izin lokasi diperlukan';
            _isLoadingLocation = false;
          });
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationText = 'Izin lokasi ditolak permanen';
          _isLoadingLocation = false;
        });
      }
      return;
    }
    _fetchRealLocation();
  }

  // ── Step 2: Init Camera Controller ─────────────────────────────
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'Kamera tidak ditemukan.');
        return;
      }

      final description = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final ctrl = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _isCameraReady = true;
        _isFrontCamera =
            description.lensDirection == CameraLensDirection.front;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Gagal membuka kamera: $e');
      }
    }
  }

  // ── Flip camera front/back ─────────────────────────────────────
  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    await _controller?.dispose();
    setState(() {
      _isCameraReady = false;
      _isFrontCamera = !_isFrontCamera;
    });

    final target = _cameras.firstWhere(
      (c) => _isFrontCamera
          ? c.lensDirection == CameraLensDirection.front
          : c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    final ctrl = CameraController(
      target,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    if (!mounted) {
      ctrl.dispose();
      return;
    }
    setState(() {
      _controller = ctrl;
      _isCameraReady = true;
    });
  }

  // ── Toggle Flash ───────────────────────────────────────────────
  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraReady) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  // ── Step 3: Fetch real GPS + reverse geocode ───────────────────
  Future<void> _fetchRealLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final lat = pos.latitude.toStringAsFixed(6);
      final lng = pos.longitude.toStringAsFixed(6);
      String address = '$lat, $lng';

      try {
        final geocoder = Geocoding();
        final marks = await geocoder.placemarkFromCoordinates(
            pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          final parts = [
            p.street ?? '',
            p.subLocality ?? p.locality ?? '',
            p.subAdministrativeArea ?? p.administrativeArea ?? '',
          ].where((s) => s.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _coordinatesText = '$lat, $lng';
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Tidak dapat mengambil lokasi';
          _isLoadingLocation = false;
        });
      }
    }
  }

  // ── Step 4: Take photo from CameraController ───────────────────
  Future<void> _takePhoto() async {
    if (_controller == null ||
        !_isCameraReady ||
        _isCapturing ||
        _controller!.value.isTakingPicture) {
      return;
    }

    _updateTimestamp(); // lock timestamp at shutter press

    setState(() => _isCapturing = true);

    try {
      final xfile = await _controller!.takePicture();

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/ai-verification',
          arguments: {
            'imagePath': xfile.path,
            'coordinates': _coordinatesText,
            'location': _locationText,
            'timestamp': _timestamp,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. LIVE Camera Preview OR error/loading state ──────────
          Positioned.fill(child: _buildCameraLayer()),

          // ── 2. Vignette gradient overlay ──────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. TOP BAR (back, title, flash, flip, gallery) ─────────
          Positioned(
            top: top + 4,
            left: 4,
            right: 4,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Tangkap gambar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (_isCameraReady)
                          IconButton(
                            icon: Icon(
                              _isFlashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _isFlashOn
                                  ? Colors.yellow
                                  : Colors.white,
                              size: 22,
                            ),
                            onPressed: _toggleFlash,
                          ),
                        if (_cameras.length > 1)
                          IconButton(
                            icon: const Icon(Icons.flip_camera_ios_outlined,
                                color: Colors.white, size: 22),
                            onPressed: _flipCamera,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // GPS pill
                _buildGpsPill(),
              ],
            ),
          ),

          // ── 4. Bottom card + shutter ─────────────────────────────
          Positioned(
            bottom: bottom + 10,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Metadata card
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        icon: Icons.location_on_outlined,
                        color: AppColors.greenPrimary,
                        text: _isLoadingLocation
                            ? 'Melacak lokasi GPS...'
                            : _locationText,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.access_time_outlined,
                        color: AppColors.statusWarning,
                        text: _timestamp.isEmpty
                            ? 'Mendeteksi waktu...'
                            : _timestamp,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.auto_awesome_outlined,
                        color: Colors.deepPurple,
                        text: 'Kategori dideteksi otomatis oleh AI',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statusChip(Icons.psychology_outlined, 'AI Ready'),
                    const SizedBox(width: 6),
                    _statusChip(
                      _isLoadingLocation
                          ? Icons.gps_not_fixed
                          : Icons.gps_fixed,
                      _isLoadingLocation ? 'GPS...' : 'GPS Aktif',
                    ),
                    const SizedBox(width: 6),
                    _statusChip(Icons.wifi_rounded, 'Internet OK'),
                  ],
                ),
                const SizedBox(height: 18),

                // Shutter button
                GestureDetector(
                  onTap: _isCameraReady ? _takePhoto : null,
                  child: ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _isCapturing
                              ? Colors.grey.shade500
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
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

  Widget _buildCameraLayer() {
    if (_cameraError != null) {
      return Container(
        color: const Color(0xFF0D1117),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_outlined,
                    size: 60, color: Colors.white38),
                const SizedBox(height: 16),
                Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white70),
                  label: const Text('Buka Pengaturan HP',
                      style: TextStyle(color: Colors.white70)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Buka Pengaturan HP > Aplikasi > LaporKita > Izin > Kamera'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraReady || _controller == null) {
      return Container(
        color: const Color(0xFF0D1117),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.greenPrimary,
                strokeWidth: 2.5,
              ),
              SizedBox(height: 16),
              Text(
                'Membuka kamera...',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Live camera preview
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildGpsPill() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _isLoadingLocation
            ? Colors.orange.shade700
            : AppColors.greenPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isLoadingLocation ? Icons.gps_not_fixed : Icons.gps_fixed,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            _isLoadingLocation
                ? 'Mencari sinyal GPS...'
                : 'GPS Aktif (${_coordinatesText.split(',').first.trim()})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      {required IconData icon, required Color color, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.greenPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
