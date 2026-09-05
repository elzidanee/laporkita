import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';

/// Layar Pemilihan Pengambilan Foto Validasi — Presisi Sesuai Figma (Node 230:849)
class ValidasiLaporanScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const ValidasiLaporanScreen({super.key, this.reportData});

  @override
  State<ValidasiLaporanScreen> createState() => _ValidasiLaporanScreenState();
}

class _ValidasiLaporanScreenState extends State<ValidasiLaporanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  ReportModel? get _reportModel =>
      widget.reportData?['reportModel'] as ReportModel?;

  String get _reportCode =>
      _reportModel?.reportCode ??
      widget.reportData?['reportCode'] as String? ??
      widget.reportData?['id'] as String? ??
      '#LP-2026-002267';

  String get _title =>
      _reportModel?.categoryName ??
      widget.reportData?['title'] as String? ??
      'Kursi tidak layak';

  String get _address =>
      _reportModel?.addressText ??
      widget.reportData?['address'] as String? ??
      'Jl. simpang ibrahim';

  int get _supportCount =>
      _reportModel?.supportCount ??
      widget.reportData?['supports'] as int? ??
      129;

  String? get _photoUrl =>
      _reportModel?.formattedPhotoUrl ??
      _reportModel?.photoUrl ??
      widget.reportData?['photoUrl'] as String?;

  String? get _imagePath =>
      widget.reportData?['imagePath'] as String? ??
      _reportModel?.directPhotoUrl;

  Future<void> _handlePickFromGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final forwardData = Map<String, dynamic>.from(widget.reportData ?? {});
        forwardData['imagePath'] = pickedFile.path;
        forwardData['capturedPhotoPath'] = pickedFile.path;
        forwardData['reportCode'] = _reportCode;
        forwardData['title'] = _title;
        forwardData['address'] = _address;
        forwardData['supports'] = _supportCount;
        forwardData['photoUrl'] = _photoUrl;

        Navigator.pushNamed(
          context,
          '/beri-validasi',
          arguments: forwardData,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto dari galeri: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _handleOpenCamera() {
    final forwardData = Map<String, dynamic>.from(widget.reportData ?? {});
    forwardData['reportCode'] = _reportCode;
    forwardData['title'] = _title;
    forwardData['address'] = _address;
    forwardData['supports'] = _supportCount;
    forwardData['photoUrl'] = _photoUrl;
    forwardData['imagePath'] = _imagePath;

    Navigator.pushNamed(
      context,
      '/camera-validasi',
      arguments: forwardData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.neutral900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Validasi Perbaikan',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.neutral900,
              size: 22,
            ),
            onPressed: () {
              final code = _reportCode;
              if (code.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: 'Validasi LaporKita: $code'));
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan validasi berhasil disalin!'),
                  backgroundColor: AppColors.greenPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Informasi Laporan (Figma node 230:1038)
            const Text(
              'Informasi Laporan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 12),

            // 2. Report Information Card (Figma node 230:986)
            _buildReportInfoCard(),
            const SizedBox(height: 24),

            // 3. Section Title & Subtitle (Figma node 230:1041)
            const Text(
              'Ambil foto kondisi terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Foto ini akan digunakan untuk validasi perbaikan.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 20),

            // 4. Option 1: Green Dashed Camera Card (Figma node 230:1047)
            Center(
              child: _buildDashedCameraCard(),
            ),
            const SizedBox(height: 22),

            // 5. Divider Text "Atau masuk dengan" (Figma node 230:1068)
            const Center(
              child: Text(
                'Atau masuk dengan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8F8F8F),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Option 2: Gallery Button Card (Figma node 230:1069)
            Center(
              child: _buildGalleryButtonCard(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Report Information Card with Camera Metadata Overlay (Figma node 230:986) ──
  Widget _buildReportInfoCard() {
    bool isLocalValid = false;
    if (_imagePath != null &&
        _imagePath!.isNotEmpty &&
        !_imagePath!.startsWith('http')) {
      try {
        isLocalValid = File(_imagePath!).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    Widget imgWidget;
    if (isLocalValid && _imagePath != null) {
      imgWidget = Image.file(
        File(_imagePath!),
        fit: BoxFit.cover,
      );
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      imgWidget = Image.network(
        _photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.greenLight,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColors.greenPrimary,
              size: 32,
            ),
          ),
        ),
      );
    } else {
      imgWidget = Container(
        color: AppColors.greenLight,
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: AppColors.greenPrimary,
            size: 32,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 129,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Image Thumbnail (164.5px x 112px)
          Container(
            width: 154,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBEC4BD), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imgWidget,
                  // Camera stamp overlay
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.greenPrimary.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LaporKita',
                              style: TextStyle(
                                fontSize: 6.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _reportCode,
                            style: const TextStyle(
                              fontSize: 6.5,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 7, color: Colors.white),
                              const SizedBox(width: 1),
                              SizedBox(
                                width: 85,
                                child: Text(
                                  _address,
                                  style: const TextStyle(
                                    fontSize: 6,
                                    color: Colors.white,
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _reportCode,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _address,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_supportCount Dukungan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Option 1: Green Dashed Camera Card (Figma node 230:1047) ───────────────
  Widget _buildDashedCameraCard() {
    return GestureDetector(
      onTap: _handleOpenCamera,
      child: Container(
        width: 308,
        height: 167,
        decoration: BoxDecoration(
          color: const Color(0xFFD2FFD6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.greenPrimary,
            width: 1.8,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.camera_alt_rounded,
              size: 52,
              color: AppColors.greenPrimary,
            ),
            SizedBox(height: 8),
            Text(
              'Ambil Foto',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.greenPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Gunakan camera',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF515151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Option 2: Gallery Button Card (Figma node 230:1069) ────────────────────
  Widget _buildGalleryButtonCard() {
    return GestureDetector(
      onTap: _isPicking ? null : _handlePickFromGallery,
      child: Container(
        width: 309,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF515151), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isPicking)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.greenPrimary,
                ),
              )
            else
              const Icon(
                Icons.photo_library_outlined,
                size: 28,
                color: Color(0xFF515151),
              ),
            const SizedBox(width: 14),
            const Text(
              'Pilih dari Galeri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF515151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
