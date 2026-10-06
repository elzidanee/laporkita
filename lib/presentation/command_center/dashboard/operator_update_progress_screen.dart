import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import 'operator_camera_screen.dart';
import 'operator_foto_sebelum_screen.dart';
import 'operator_foto_sesudah_screen.dart';

class OperatorUpdateProgressScreen extends StatefulWidget {
  final ReportModel report;
  final String? initialPhotoPath;
  final VoidCallback? onStatusUpdated;

  const OperatorUpdateProgressScreen({
    super.key,
    required this.report,
    this.initialPhotoPath,
    this.onStatusUpdated,
  });

  @override
  State<OperatorUpdateProgressScreen> createState() =>
      _OperatorUpdateProgressScreenState();
}

class _OperatorUpdateProgressScreenState
    extends State<OperatorUpdateProgressScreen> {
  late ReportModel _currentReport;
  String _selectedStatus = 'Sedang Dikerjakan';
  double _progressPercentage = 78.0;
  final TextEditingController _descController = TextEditingController();
  final List<String> _progressPhotos = [];
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
    final repo = context.read<ReportRepository>();
    final savedPct = repo.getProgressPercentage(_currentReport.id) ??
        repo.getProgressPercentage(_currentReport.reportCode);
    if (savedPct != null) {
      _progressPercentage = savedPct;
    } else if (_currentReport.progressPercentage != null) {
      _progressPercentage = _currentReport.progressPercentage!;
    } else {
      _progressPercentage = (_currentReport.currentProgress * 100).clamp(0.0, 100.0);
      if (_progressPercentage == 0 && _currentReport.status == ReportStatus.inProgress) {
        _progressPercentage = 50.0;
      }
    }
    if (_currentReport.status == ReportStatus.completed || _currentReport.status == ReportStatus.resolved) {
      _selectedStatus = 'Selesai Dikerjakan';
    } else if (_currentReport.status == ReportStatus.inProgress) {
      _selectedStatus = 'Sedang Dikerjakan';
    }
    _descController.text = '';
    if (widget.initialPhotoPath != null) {
      _progressPhotos.add(widget.initialPhotoPath!);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
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

  Future<void> _takePhotoWithCamera() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OperatorCameraScreen(
          report: _currentReport,
          title: 'Foto Update Progres',
        ),
      ),
    );

    if (result != null && result['imagePath'] != null) {
      setState(() {
        _progressPhotos.add(result['imagePath'] as String);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _progressPhotos.add(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _progressPhotos.removeAt(index);
    });
  }

  Future<void> _saveProgress() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final repo = context.read<ReportRepository>();
      final notifRepo = context.read<NotificationRepository>();
      final isCompleted = _progressPercentage >= 100 || _selectedStatus == 'Selesai Dikerjakan';
      final targetStatus = isCompleted ? ReportStatus.completed : ReportStatus.inProgress;

      // 1. Simpan persentase progres ke repository (memori & persistent storage)
      await repo.saveProgressPercentage(_currentReport.id, _progressPercentage);

      // Cek apakah status benar-benar berubah.
      // Backend menolak transisi ke status yang sama (in_progress → in_progress).
      final statusWillChange = targetStatus != _currentReport.status;

      final progressTag = '[PROGRESS: ${_progressPercentage.toInt()}%]';
      final noteText = _descController.text.trim().isNotEmpty
          ? '${_descController.text.trim()} $progressTag'
          : 'Progress pengerjaan: ${_progressPercentage.toInt()}% $progressTag';

      if (statusWillChange) {
        final updated = await repo.updateReportStatus(
          _currentReport.id,
          targetStatus.apiValue,
          notes: noteText,
          existingReport: _currentReport,
        );
        _currentReport = updated.copyWith(progressPercentage: _progressPercentage);
      } else {
        // Status sudah in_progress, backend melarang update status yang sama.
        // Simpan catatan persentase progres operator via endpoint komentar
        try {
          await repo.addComment(_currentReport.id, noteText);
        } catch (commentErr) {
          debugPrint('warning [UpdateProgress] Gagal simpan komentar progress: $commentErr');
        }
      }

      // Upload foto progress via media endpoint
      // PENTING: type HARUS 'progress_photo' agar tampil di tracking screen citizen
      for (final photoPath in _progressPhotos) {
        if (!photoPath.startsWith('http') && File(photoPath).existsSync()) {
          try {
            await repo.uploadReportMedia(
              reportId: _currentReport.id,
              filePath: photoPath,
              type: 'progress_photo',
            );
          } catch (photoErr) {
            debugPrint('warning [UpdateProgress] Gagal upload foto: $photoErr');
          }
        }
      }

      // Re-fetch report agar _currentReport memiliki daftar media dan histori terbaru
      try {
        final fresh = await repo.getReportById(_currentReport.id);
        _currentReport = fresh.copyWith(progressPercentage: _progressPercentage);
      } catch (_) {
        _currentReport = _currentReport.copyWith(progressPercentage: _progressPercentage);
      }

      // Jika status berubah, repo.updateReportStatus sudah memicu notifikasi otomatis.
      // Hanya jika status TIDAK berubah (murni pembaruan progres operator), pemicu notifikasi progres dipanggil.
      try {
        if (!statusWillChange) {
          await notifRepo.addProgressUpdateNotification(
            reportCode: _currentReport.reportCode,
            percentage: _progressPercentage.toInt(),
            reportId: _currentReport.id,
            note: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
          );
        }
      } catch (_) {}

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
                    isCompleted
                        ? 'Pengerjaan selesai! Progress ${_progressPercentage.toInt()}%.'
                        : 'Progress (${_progressPercentage.toInt()}%) berhasil disimpan!',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );

        if (isCompleted) {
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
          Navigator.pop(context, _currentReport);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Gagal menyimpan progress: $errorMsg'),
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
          'Update Progress',
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
              // 1. Mini Report Summary Card (Node 671:1048)
              _buildMiniReportCard(),
              const SizedBox(height: 20),

              // 2. Progress Saat Ini Card (Node 671:1136)
              _buildProgressDropdownCard(),
              const SizedBox(height: 16),

              // 3. Progress Card (Node 671:1149)
              _buildProgressGaugeCard(),
              const SizedBox(height: 16),

              // 4. Deskripsi Progres Card (Node 671:1157)
              _buildDeskripsiCard(),
              const SizedBox(height: 22),

              // 5. Upload Progres Terbaru Section (Node 671:1181)
              _buildUploadSection(),
              const SizedBox(height: 16),

              // 6. Uploaded photos list with delete buttons (Node 671:1200)
              _buildUploadedPhotosRow(),
              const SizedBox(height: 32),

              // 7. Simpan Progress Button (Node 672:1232)
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Mini Report Card ───────────────────────────────────────────────────
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
          // Thumbnail
          Container(
            width: 119,
            height: 83,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBEC4BD), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildReportImage(),
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

  Widget _buildReportImage() {
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

  // ── 2. Progress Saat Ini Card ─────────────────────────────────────────────
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

  // ── 3. Progress Gauge Card (Node 671:1149) ────────────────────────────────
  Widget _buildProgressGaugeCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '${_progressPercentage.toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF42A54B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Progress Slider / Bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 7,
              activeTrackColor: const Color(0xFF42A54B),
              inactiveTrackColor: const Color(0xFFD9D9D9),
              thumbColor: const Color(0xFF1D9C51),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _progressPercentage,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (val) {
                setState(() => _progressPercentage = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Deskripsi Progres Card (Node 671:1157) ─────────────────────────────
  Widget _buildDeskripsiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          const Icon(
            Icons.assignment_outlined,
            color: Colors.black87,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Deskripsi Progres',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '*opsional',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF8F8F8F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        maxLength: 200,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Pengerjaan pengaspalan tahap pertama sudah selesai. Sedang persiapan untuk tahap kedua.',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: Colors.black54,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      Text(
                        '${_descController.text.length}/200',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFFBBBBBB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Upload Progres Terbaru Section (Node 671:1181) ──────────────────────
  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Progres Terbaru',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Button 1: Ambil Foto (Green tint)
            Expanded(
              child: GestureDetector(
                onTap: _takePhotoWithCamera,
                child: Container(
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFFDF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1D9C51), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF1D9C51),
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ambil Foto',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D9C51),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Button 2: Pilih dari galeri (Blue tint)
            Expanded(
              child: GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1976D2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF1976D2),
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pilih dari galeri',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 6. Uploaded photos list with delete button (Node 671:1200) ────────────
  Widget _buildUploadedPhotosRow() {
    if (_progressPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            'Belum ada foto progres yang diunggah',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _progressPhotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final path = _progressPhotos[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 145,
                height: 101,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8F8F8F), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: File(path).existsSync()
                      ? Image.file(File(path), fit: BoxFit.cover)
                      : Image.network(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackImage(),
                        ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel,
                      color: Color(0xFFC60D05),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 7. Simpan Progress Button (Node 672:1232) ─────────────────────────────
  Widget _buildSaveButton() {
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
        onPressed: _isSaving ? null : _saveProgress,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Simpan Progress',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
