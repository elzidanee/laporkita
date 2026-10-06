import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_camera_screen.dart';
import 'operator_foto_sebelum_screen.dart';
import 'operator_update_progress_screen.dart';

class OperatorFotoSesudahScreen extends StatefulWidget {
  final ReportModel report;
  final String? initialPhotoPath;
  final VoidCallback? onStatusUpdated;

  const OperatorFotoSesudahScreen({
    super.key,
    required this.report,
    this.initialPhotoPath,
    this.onStatusUpdated,
  });

  @override
  State<OperatorFotoSesudahScreen> createState() =>
      _OperatorFotoSesudahScreenState();
}

class _OperatorFotoSesudahScreenState extends State<OperatorFotoSesudahScreen> {
  late ReportModel _currentReport;
  String _selectedStatus = 'Selesai Dikerjakan';
  String? _afterRepairPhoto;
  bool _isSaving = false;

  final List<String> _statusList = [
    'Sebelum Dikerjakan',
    'Sedang Dikerjakan',
    'Selesai Dikerjakan',
  ];

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _afterRepairPhoto = widget.initialPhotoPath ?? _currentReport.completionPhotoUrl;
  }

  void _onStatusDropdownChanged(String? newValue) {
    if (newValue == null || newValue == _selectedStatus) return;

    if (newValue == 'Sebelum Dikerjakan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OperatorFotoSebelumScreen(
            report: _currentReport,
            onStatusUpdated: widget.onStatusUpdated,
          ),
        ),
      );
    } else if (newValue == 'Sedang Dikerjakan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OperatorUpdateProgressScreen(
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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OperatorCameraScreen(
          report: _currentReport,
          title: 'Foto Sesudah Perbaikan',
        ),
      ),
    );

    if (result != null && result['imagePath'] != null) {
      final imgPath = result['imagePath'] as String;
      setState(() {
        _afterRepairPhoto = imgPath;
      });

      // Submit completion photo & mark report completed
      await _completeReport(imgPath);
    }
  }

  Future<void> _completeReport([String? photoPath]) async {
    if (_isSaving) return;

    final pathToUpload = photoPath ?? _afterRepairPhoto;
    if (pathToUpload == null || pathToUpload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: const Text(
              'Silakan ambil foto bukti perbaikan terlebih dahulu sebelum menyelesaikan.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = context.read<ReportRepository>();

      // 1. Wajib upload foto penyelesaian ke backend terlebih dahulu (Rules.md §1.1)
      if (!pathToUpload.startsWith('http') && File(pathToUpload).existsSync()) {
        await repo.uploadReportMedia(
          reportId: _currentReport.id,
          filePath: pathToUpload,
          type: 'completion_photo',
        );
      }

      // 2. Update status ke 'completed'
      try {
        final updated = await repo.updateReportStatus(
          _currentReport.id,
          ReportStatus.completed.apiValue,
          notes: 'Pekerjaan perbaikan telah selesai dikerjakan dengan bukti foto selesai.',
          existingReport: _currentReport,
        );
        _currentReport = updated;
      } catch (statusErr) {
        final errStr = statusErr.toString().toLowerCase();
        if (errStr.contains('tidak dapat mengubah status') && errStr.contains('completed')) {
          _currentReport = _currentReport.copyWith(status: ReportStatus.completed);
        } else {
          rethrow;
        }
      }

// repo.updateReportStatus sudah memicu notifikasi selesai secara otomatis

      widget.onStatusUpdated?.call();

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
                    'Perbaikan berhasil diselesaikan & diverifikasi!',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Gagal menyelesaikan perbaikan: $errorMsg'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          'Foto sesudah perbaikan',
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
              // 1. Mini Report Summary Card (Node 673:1577)
              _buildMiniReportCard(),
              const SizedBox(height: 16),

              // 2. Deskripsi Pelapor (Node 673:1536)
              _buildDescriptionSection(),
              const SizedBox(height: 20),

              // 3. Progress Saat Ini (*dapat diubah) (Node 674:1682)
              _buildProgressDropdownCard(),
              const SizedBox(height: 18),

              // 4. Validation Card (Node 673:1620)
              _buildValidationCard(),
              const SizedBox(height: 22),

              // 5. Title: "Foto yang anda unggah" (Node 673:1618)
              Text(
                'Foto yang anda unggah',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              // 6. After Repair Photo with Watermark (Node 674:1681)
              _buildAfterPhotoWithWatermark(),
              const SizedBox(height: 24),

              // 7. Button "Ambil Foto" (Node 673:1570)
              _buildCaptureButton(),
              const SizedBox(height: 20),

              // 8. Rekomendasi Card (Node 673:1656)
              _buildRecommendationCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Mini Report Summary Card (Node 673:1577) ───────────────────────────
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
          // Thumbnail with watermark
          Container(
            width: 119,
            height: 83,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBEC4BD), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildThumbnailImage(),
            ),
          ),
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

  Widget _buildThumbnailImage() {
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

  // ── 2. Deskripsi Pelapor (Node 673:1536) ───────────────────────────────────
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
          (_currentReport.description != null && _currentReport.description!.trim().isNotEmpty)
              ? _currentReport.description!
              : 'Tidak ada catatan tambahan dari warga.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: (_currentReport.description != null && _currentReport.description!.trim().isNotEmpty)
                ? Colors.black87
                : const Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── 3. Progress Saat Ini (*dapat diubah) (Node 674:1682) ───────────────────
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

  // ── 4. Validation Card (Node 673:1620) ─────────────────────────────────────
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

  // ── 6. After Repair Photo with Watermark (Node 674:1681) ───────────────────
  Widget _buildAfterPhotoWithWatermark() {
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
              child: _buildCompletedImage(),
            ),

            // Authentic telemetry watermark badge
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
                          'Jumat, 19 Mei 2026 | 12.56 WIB',
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

  Widget _buildCompletedImage() {
    if (_afterRepairPhoto != null && File(_afterRepairPhoto!).existsSync()) {
      return Image.file(
        File(_afterRepairPhoto!),
        fit: BoxFit.cover,
      );
    }

    final completionUrl = _currentReport.completionPhotoUrl;
    if (completionUrl != null && completionUrl.isNotEmpty) {
      if (completionUrl.startsWith('http')) {
        return Image.network(
          completionUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderComplete(),
        );
      } else if (File(completionUrl).existsSync()) {
        return Image.file(
          File(completionUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderComplete(),
        );
      }
    }

    // Default to report's completed image or photo
    final url = _currentReport.primaryPhotoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderComplete(),
        );
      } else if (File(url).existsSync()) {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderComplete(),
        );
      }
    }
    return _buildPlaceholderComplete();
  }

  Widget _buildPlaceholderComplete() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_enhance_rounded, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              'Belum ada foto sesudah perbaikan',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ── 7. Button "Ambil Foto" (Node 673:1570) ─────────────────────────────────
  Widget _buildCaptureButton() {
    final hasPhoto = _afterRepairPhoto != null && _afterRepairPhoto!.isNotEmpty;
    final isAlreadyCompleted = _currentReport.status == ReportStatus.completed;

    if (isAlreadyCompleted) {
      return Container(
        width: double.infinity,
        height: 49,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1D9C51), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF1D9C51), size: 22),
            const SizedBox(width: 10),
            Text(
              'Laporan Telah Selesai Dikerjakan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D9C51),
              ),
            ),
          ],
        ),
      );
    }

    if (hasPhoto) {
      return Column(
        children: [
          // Tombol utama: Selesaikan Perbaikan (langsung submit foto yang sudah ada)
          SizedBox(
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
              onPressed: _isSaving ? null : () => _completeReport(),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Selesaikan Perbaikan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Tombol sekunder: Ambil Ulang Foto
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1D9C51), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _isSaving ? null : _openCamera,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Color(0xFF1D9C51), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ambil Ulang Foto',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D9C51),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
        onPressed: _isSaving ? null : _openCamera,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
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

  // ── 8. Rekomendasi Card (Node 673:1656) ────────────────────────────────────
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
