import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_camera_screen.dart';
import 'operator_update_progress_screen.dart';
import 'operator_foto_sesudah_screen.dart';

class OperatorFotoSebelumScreen extends StatefulWidget {
  final ReportModel report;
  final VoidCallback? onStatusUpdated;

  const OperatorFotoSebelumScreen({
    super.key,
    required this.report,
    this.onStatusUpdated,
  });

  @override
  State<OperatorFotoSebelumScreen> createState() =>
      _OperatorFotoSebelumScreenState();
}

class _OperatorFotoSebelumScreenState extends State<OperatorFotoSebelumScreen> {
  late ReportModel _currentReport;
  String _selectedStatus = 'Sebelum Dikerjakan';
  String? _capturedImagePath;

  final List<String> _statusList = [
    'Sebelum Dikerjakan',
    'Sedang Dikerjakan',
    'Selesai Dikerjakan',
  ];

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  void _onStatusDropdownChanged(String? newValue) {
    if (newValue == null || newValue == _selectedStatus) return;

    if (newValue == 'Sedang Dikerjakan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OperatorUpdateProgressScreen(
            report: _currentReport,
            onStatusUpdated: widget.onStatusUpdated,
          ),
        ),
      );
    } else if (newValue == 'Selesai Dikerjakan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OperatorFotoSesudahScreen(
            report: _currentReport,
            onStatusUpdated: widget.onStatusUpdated,
          ),
        ),
      );
    } else {
      setState(() => _selectedStatus = newValue);
    }
  }

  Future<void> _openCamera() async {
    final repo = context.read<ReportRepository>();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OperatorCameraScreen(
          report: _currentReport,
          title: 'Foto Sebelum Perbaikan',
        ),
      ),
    );

    if (result != null && result['imagePath'] != null) {
      final imgPath = result['imagePath'] as String;
      setState(() {
        _capturedImagePath = imgPath;
      });

      // Update report status to in_progress upon capturing initial repair photo
      try {
        final updated = await repo.updateReportStatus(
          _currentReport.id,
          ReportStatus.inProgress.apiValue,
          notes: 'Petugas mengambil foto sebelum perbaikan dan memulai pengerjaan.',
          existingReport: _currentReport,
        );
        _currentReport = updated;
        widget.onStatusUpdated?.call();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1D9C51),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Foto sebelum perbaikan berhasil diambil! Melanjutkan ke Update Progress...',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );

        // Move to Update Progress screen with initial photo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorUpdateProgressScreen(
              report: _currentReport,
              initialPhotoPath: imgPath,
              onStatusUpdated: widget.onStatusUpdated,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Foto sebelum perbaikan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Mini Report Summary Card (Node 671:1093)
              _buildMiniReportCard(),
              const SizedBox(height: 20),

              // 2. Progress Saat Ini (*dapat diubah) Card (Node 673:1667)
              _buildProgressDropdownCard(),
              const SizedBox(height: 22),

              // 3. Section Title: "Foto yang di unggah pelapor"
              Text(
                'Foto yang di unggah pelapor',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Hero Image with Telemetry Watermark Overlay (Node 666:15)
              _buildReporterPhotoWithWatermark(),
              const SizedBox(height: 16),

              // 5. Deskripsi
              _buildDescriptionSection(),
              const SizedBox(height: 20),

              // 6. Validation Card (Node 668:706)
              _buildValidationCard(),
              const SizedBox(height: 24),

              // 7. Button "Ambil Foto" (Node 668:768)
              _buildCaptureButton(),
              const SizedBox(height: 20),

              // 8. Rekomendasi Card (Node 669:787)
              _buildRecommendationCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Mini Report Summary Card (Node 671:1093) ───────────────────────────
  Widget _buildMiniReportCard() {
    final priorityText = _currentReport.priorityLabel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with watermark badge
          _buildThumbnailWatermark(),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentReport.categoryName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _currentReport.addressText ?? 'Jl. Ahmad Yani no. 15',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _currentReport.formattedReportCode,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D9C51),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Priority badge & chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  priorityText,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFC60D05),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black54,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailWatermark() {
    return Container(
      width: 119,
      height: 83,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBEC4BD), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildReportImage(),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A54B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'LaporKita',
                        style: GoogleFonts.poppins(
                          fontSize: 5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _currentReport.formattedReportCode,
                      style: GoogleFonts.poppins(fontSize: 4.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportImage() {
    if (_capturedImagePath != null && File(_capturedImagePath!).existsSync()) {
      return Image.file(
        File(_capturedImagePath!),
        fit: BoxFit.cover,
      );
    }

    final url = _currentReport.primaryPhotoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      } else if (File(url).existsSync()) {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      }
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
      ),
    );
  }

  // ── 2. Progress Saat Ini (*dapat diubah) Card (Node 673:1667) ─────────────
  Widget _buildProgressDropdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                'Progress Saat Ini',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '*dapat diubah',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF8F8F8F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black87,
                  size: 22,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                items: _statusList.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: _onStatusDropdownChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Hero Image with Telemetry Watermark (Node 666:15) ───────────────────
  Widget _buildReporterPhotoWithWatermark() {
    return Container(
      width: double.infinity,
      height: 204,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBEC4BD), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildReportImage(),
            ),

            // Authentic telemetry watermark overlay
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A54B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF62D26D), width: 0.4),
                      ),
                      child: Text(
                        'LaporKita',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentReport.formattedReportCode,
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          _currentReport.addressText ?? 'Jl. Ahmad Yani No.15 Malang',
                          style: GoogleFonts.poppins(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          'Kamis, 12 Mei 2026 | 10.30 WIB',
                          style: GoogleFonts.poppins(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.report_problem_outlined, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          _currentReport.categoryName,
                          style: GoogleFonts.poppins(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentReport.latitude.toStringAsFixed(6)}, ${_currentReport.longitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
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
    );
  }

  // ── 5. Deskripsi ─────────────────────────────────────────────────────────
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi :',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: Colors.black,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _currentReport.description?.isNotEmpty == true
              ? _currentReport.description!
              : 'Jalan sudah tidak layak karena banyak retakan dan lubang disepanjang jalan.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── 6. Validation Card (Node 668:706) ─────────────────────────────────────
  Widget _buildValidationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildValidationRow('Foto Valid', 'Valid'),
          const SizedBox(height: 12),
          _buildValidationRow('GPS Valid', 'Valid'),
          const SizedBox(height: 12),
          _buildValidationRow('Timestamp Valid', 'Valid'),
        ],
      ),
    );
  }

  Widget _buildValidationRow(String title, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1D9C51),
                size: 22,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D9C51),
          ),
        ),
      ],
    );
  }

  // ── 7. Button "Ambil Foto" (Node 668:768) ─────────────────────────────────
  Widget _buildCaptureButton() {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D9C51),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFC9E1BF), width: 0.5),
          ),
        ),
        onPressed: _openCamera,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Ambil Foto',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 8. Rekomendasi Card (Node 669:787) ────────────────────────────────────
  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFFF2AE01),
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF2AE01),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pastikan foto jelas ( tidak blur ) dan ambil sudut dari titik lokasi yang sama',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF515151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
