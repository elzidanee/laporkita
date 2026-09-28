import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/report_model.dart';

class OperatorCameraScreen extends StatefulWidget {
  final ReportModel? report;
  final String title;

  const OperatorCameraScreen({
    super.key,
    this.report,
    this.title = 'Kamera Geotagging',
  });

  @override
  State<OperatorCameraScreen> createState() => _OperatorCameraScreenState();
}

class _OperatorCameraScreenState extends State<OperatorCameraScreen>
    with TickerProviderStateMixin {
  // ── Camera State ─────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  String? _cameraError;

  // ── GPS & Location State ─────────────────────────────────────────────────
  bool _isLoadingLocation = true;
  String _locationText = 'Melacak lokasi...';
  String _coordinatesText = '-6.382728, 107.734682';
  String _timestamp = '';

  // ── Shutter pulse animation & Timer ──────────────────────────────────────
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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
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
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _timestamp =
            '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year} | $h.$m WIB';
      });
    }
  }

  Future<void> _initAll() async {
    await _initCamera();
    await _initLocation();
  }

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
        _isFrontCamera = description.lensDirection == CameraLensDirection.front;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Gagal membuka kamera: $e');
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() {
              _locationText = widget.report?.addressText ?? 'Jl. Ahmad Yani No.15 Malang';
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final lat = pos.latitude.toStringAsFixed(6);
      final lng = pos.longitude.toStringAsFixed(6);
      String address = widget.report?.addressText ?? '$lat, $lng';

      try {
        final geocoder = Geocoding();
        final marks = await geocoder.placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
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
          _locationText = widget.report?.addressText ?? 'Jl. Ahmad Yani No.15 Malang';
          _coordinatesText = widget.report != null
              ? '${widget.report!.latitude.toStringAsFixed(6)}, ${widget.report!.longitude.toStringAsFixed(6)}'
              : '-6.382728, 107.734682';
          _isLoadingLocation = false;
        });
      }
    }
  }

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

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraReady) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _takePhoto() async {
    if (_controller == null ||
        !_isCameraReady ||
        _isCapturing ||
        _controller!.value.isTakingPicture) {
      return;
    }

    _updateTimestamp();
    setState(() => _isCapturing = true);

    try {
      final xfile = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, {
          'imagePath': xfile.path,
          'coordinates': _coordinatesText,
          'location': _locationText,
          'timestamp': _timestamp,
        });
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

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        Navigator.pop(context, {
          'imagePath': picked.path,
          'coordinates': _coordinatesText,
          'location': _locationText,
          'timestamp': _timestamp,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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
          // ── 1. Live Camera Preview ───────────────────────────────────────
          Positioned.fill(child: _buildCameraLayer()),

          // ── 2. Top Bar ───────────────────────────────────────────────────
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCircleButton(
                      icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      iconColor: _isFlashOn ? const Color(0xFFFFD700) : Colors.white,
                      onTap: _toggleFlash,
                    ),
                    const SizedBox(width: 8),
                    _buildCircleButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: _flipCamera,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 3. Authentic Telemetry Watermark Badge (Bottom-Left) ─────────
          Positioned(
            bottom: bottom + 120,
            left: 20,
            right: 20,
            child: _buildWatermarkBadge(),
          ),

          // ── 4. Bottom Controls: Shutter & Gallery ─────────────────────────
          Positioned(
            bottom: bottom + 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery picker
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Shutter button with glowing pulse animation
                ScaleTransition(
                  scale: _pulseAnim,
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: const Color(0xFF1D9C51),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1D9C51).withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                    ),
                  ),
                ),

                // Simulated / placeholder capture button if camera is broken
                GestureDetector(
                  onTap: _isCameraReady ? _takePhoto : _pickFromGallery,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 26,
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

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_cameraError != null) {
      return Container(
        color: const Color(0xFF121212),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(
              'Pratinjau Kamera Tidak Tersedia',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan tombol galeri di bawah untuk memilih foto bukti.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9C51),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: Text(
                'Pilih dari Galeri',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onPressed: _pickFromGallery,
            ),
          ],
        ),
      );
    }

    if (!_isCameraReady || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1D9C51)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? constraints.maxWidth,
              height: _controller!.value.previewSize?.width ?? constraints.maxHeight,
              child: CameraPreview(_controller!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatermarkBadge() {
    final reportCode = widget.report != null
        ? widget.report!.formattedReportCode
        : '#LP_2026_002487';
    final categoryName = widget.report?.categoryName ?? 'Jalan Rusak';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9C51).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LaporKita',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reportCode,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _locationText,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoadingLocation) ...[
                const SizedBox(width: 6),
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _timestamp,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.report_problem_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  categoryName,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _coordinatesText,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
