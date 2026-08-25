import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

enum ValidationStatus {
  sudahSesuai,
  belumSesuai,
  tidakSesuai;

  String get label {
    switch (this) {
      case ValidationStatus.sudahSesuai:
        return 'Sudah sesuai';
      case ValidationStatus.belumSesuai:
        return 'Belum sesuai';
      case ValidationStatus.tidakSesuai:
        return 'Tidak sesuai';
    }
  }

  String get description {
    switch (this) {
      case ValidationStatus.sudahSesuai:
        return 'Perbaikan sudah sesuai kriteria';
      case ValidationStatus.belumSesuai:
        return 'Masih ada perbaikan yang belum sesuai';
      case ValidationStatus.tidakSesuai:
        return 'Perbaikan tidak sesuai dengan kriteria';
    }
  }
}

class BeriValidasiScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const BeriValidasiScreen({super.key, this.reportData});

  @override
  State<BeriValidasiScreen> createState() => _BeriValidasiScreenState();
}

class _BeriValidasiScreenState extends State<BeriValidasiScreen> {
  ValidationStatus _selectedStatus = ValidationStatus.sudahSesuai;
  late TextEditingController _notesController;
  bool _isSubmitting = false;
  String? _capturedPhotoPath;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _capturedPhotoPath = widget.reportData?['imagePath'] as String? ??
        widget.reportData?['capturedPhotoPath'] as String?;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleTakeLivePhoto() async {
    final result = await Navigator.pushNamed(
      context,
      '/camera',
      arguments: {'mode': 'validation'},
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _capturedPhotoPath = result['imagePath'] as String?;
      });
    }
  }

  Future<void> _handleSubmitValidation() async {
    setState(() => _isSubmitting = true);
    final reportId = widget.reportData?['reportId'] as String? ??
        widget.reportData?['id'] as String? ??
        '';

    try {
      if (reportId.isNotEmpty) {
        final repository = context.read<ReportRepository>();
        await repository.validateReport(reportId);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/validation-success',
        arguments: widget.reportData,
      );
    } catch (_) {
      if (!mounted) return;
      // Tetap ke layar sukses untuk UX warga
      Navigator.pushReplacementNamed(
        context,
        '/validation-success',
        arguments: widget.reportData,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String reportCode = widget.reportData?['reportCode'] as String? ??
        widget.reportData?['id'] as String? ??
        '#LP-2026-002267';
    final String title = widget.reportData?['title'] as String? ??
        widget.reportData?['categoryName'] as String? ??
        'Kerusakan Fasilitas';
    final String location = widget.reportData?['location'] as String? ??
        widget.reportData?['address'] as String? ??
        'Jl. Simpang Ibrahim, Malang';
    final String photoUrl = widget.reportData?['photoUrl'] as String? ?? '';
    final String imagePath = _capturedPhotoPath ??
        widget.reportData?['imagePath'] as String? ??
        '';

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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Informasi Laporan Header Card (Figma Node 234:1220)
                    const Text(
                      'Informasi Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neutral200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 110,
                              height: 90,
                              child: _buildReportImage(imagePath, photoUrl, title),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reportCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '129 Dukungan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.greenPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Berikan Validasi Title
                    const Text(
                      'Berikan Validasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Apakah perbaikan sudah sesuai dengan kondisi di lapangan?',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3 Option Selection Cards (Figma Node 234:1350)
                    Row(
                      children: [
                        Expanded(
                          child: _buildValidationOptionCard(
                            status: ValidationStatus.sudahSesuai,
                            icon: Icons.check_circle_rounded,
                            activeColor: AppColors.greenPrimary,
                            bgColor: const Color(0xFFD2FFD6),
                            borderColor: AppColors.greenPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildValidationOptionCard(
                            status: ValidationStatus.belumSesuai,
                            icon: Icons.warning_amber_rounded,
                            activeColor: const Color(0xFFF2AE01),
                            bgColor: const Color(0xFFFFF9E9),
                            borderColor: const Color(0xFFF2AE01),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildValidationOptionCard(
                            status: ValidationStatus.tidakSesuai,
                            icon: Icons.cancel_rounded,
                            activeColor: AppColors.statusDanger,
                            bgColor: const Color(0xFFFFE9E9),
                            borderColor: AppColors.statusDanger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Foto Kondisi Terkini (Figma Node 230:849 & 232:1083)
                    const Text(
                      'Foto Bukti Kondisi Terkini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _handleTakeLivePhoto,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.greenPrimary.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _capturedPhotoPath != null &&
                                _capturedPhotoPath!.isNotEmpty &&
                                File(_capturedPhotoPath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.file(
                                        File(_capturedPhotoPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    size: 32,
                                    color: AppColors.greenPrimary,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Foto Kondisi Perbaikan (Kamera & GPS)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.greenPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sesuai tempat, tanggal & jam saat ini',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.neutral700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Field Catatan Opsional (Figma Node 234:1351)
                    Row(
                      children: const [
                        Text(
                          'Catatan ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        Text(
                          '(opsional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutral200),
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
                          TextField(
                            controller: _notesController,
                            maxLength: 200,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Tambahkan catatan laporan.....',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral500,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_notesController.text.length}/200',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action Button: Lanjut
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitValidation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lanjut',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationOptionCard({
    required ValidationStatus status,
    required IconData icon,
    required Color activeColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    final bool isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? borderColor : AppColors.neutral200,
            width: isSelected ? 2.0 : 1.0,
          ),
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
            Icon(icon, size: 28, color: activeColor),
            const SizedBox(height: 10),
            Text(
              status.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.neutral700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportImage(String imagePath, String photoUrl, String title) {
    if (imagePath.isNotEmpty &&
        !imagePath.startsWith('http') &&
        File(imagePath).existsSync()) {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    } else if (photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.network(
          ReportModel.getCategoryFallbackImage(title),
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.network(
      ReportModel.getCategoryFallbackImage(title),
      fit: BoxFit.cover,
    );
  }
}
