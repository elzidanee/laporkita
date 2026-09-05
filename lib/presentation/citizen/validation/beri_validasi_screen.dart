import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../reports/bloc/report_bloc.dart';

enum ValidationOption {
  sudahSesuai,
  belumSesuai,
  tidakSesuai;

  String get title {
    switch (this) {
      case ValidationOption.sudahSesuai:
        return 'Sudah sesuai';
      case ValidationOption.belumSesuai:
        return 'Belum sesuai';
      case ValidationOption.tidakSesuai:
        return 'Tidak sesuai';
    }
  }

  String get description {
    switch (this) {
      case ValidationOption.sudahSesuai:
        return 'Perbaikan sudah sesuai kriteria';
      case ValidationOption.belumSesuai:
        return 'masih ada perbaikan yang belum sesuai';
      case ValidationOption.tidakSesuai:
        return 'Perbaikan tidak sesuai dengan kriteria';
    }
  }
}

/// Layar Pemberian Validasi Status Perbaikan — Presisi Sesuai Figma (Node 234:1214)
class BeriValidasiScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const BeriValidasiScreen({super.key, this.reportData});

  @override
  State<BeriValidasiScreen> createState() => _BeriValidasiScreenState();
}

class _BeriValidasiScreenState extends State<BeriValidasiScreen> {
  ValidationOption _selectedOption = ValidationOption.sudahSesuai;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

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

  String? get _capturedPhotoPath =>
      widget.reportData?['capturedPhotoPath'] as String? ??
      widget.reportData?['imagePath'] as String? ??
      _reportModel?.directPhotoUrl;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final reportId = widget.reportData?['reportId'] as String? ??
        widget.reportData?['id'] as String? ??
        _reportModel?.id ??
        '';

    try {
      if (reportId.isNotEmpty) {
        final repository = context.read<ReportRepository>();
        final isApproved = _selectedOption == ValidationOption.sudahSesuai;
        final notes = _notesController.text.trim();
        await repository.validateReport(
          reportId,
          isApproved: isApproved,
          feedback: notes.isNotEmpty ? notes : _selectedOption.title,
        );
      }

      if (!mounted) return;
      context.read<ReportBloc>().add(const ReportLoadRequested());
      Navigator.pushReplacementNamed(
        context,
        '/validation-success',
        arguments: widget.reportData,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim validasi: $e'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
            // 1. Informasi Laporan Section (Figma node 234:1263)
            const Text(
              'Informasi Laporan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 12),

            // 2. Report Card with Latest Photo (Figma node 234:1220)
            _buildReportInfoCard(),
            const SizedBox(height: 24),

            // 3. Section: Berikan Validasi (Figma node 234:1265)
            const Text(
              'Berikan Validasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Apakah perbaikan sudah sesuai dengan kondisi dilapangan',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 16),

            // 4. 3 Validation Option Cards (Figma node 234:1350)
            _buildOptionCardsRow(),
            const SizedBox(height: 24),

            // 5. Catatan Section (Figma node 234:1351)
            _buildNotesSection(),
            const SizedBox(height: 36),

            // 6. Action Button: Lanjut (Figma node 234:1283)
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Report Info Card (Figma node 234:1220) ────────────────────────────────
  Widget _buildReportInfoCard() {
    bool isLocalValid = false;
    if (_capturedPhotoPath != null &&
        _capturedPhotoPath!.isNotEmpty &&
        !_capturedPhotoPath!.startsWith('http')) {
      try {
        isLocalValid = File(_capturedPhotoPath!).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    Widget imgWidget;
    if (isLocalValid && _capturedPhotoPath != null) {
      imgWidget = Image.file(
        File(_capturedPhotoPath!),
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
          // Left Thumbnail with Camera Metadata Stamp
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

          // Right Info Text
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

  // ── 3 Option Cards Row (Figma node 234:1350) ──────────────────────────────
  Widget _buildOptionCardsRow() {
    return Row(
      children: [
        // 1. Sudah Sesuai (Figma node 234:1301)
        Expanded(
          child: _buildChoiceCard(
            option: ValidationOption.sudahSesuai,
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.greenPrimary,
            selectedBgColor: const Color(0xFFD2FFD6),
            selectedBorderColor: AppColors.greenPrimary,
            textColor: AppColors.greenPrimary,
          ),
        ),
        const SizedBox(width: 10),

        // 2. Belum Sesuai (Figma node 234:1325)
        Expanded(
          child: _buildChoiceCard(
            option: ValidationOption.belumSesuai,
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF2AE01),
            selectedBgColor: const Color(0xFFFFF9E9),
            selectedBorderColor: const Color(0xFFF2AE01),
            textColor: const Color(0xFFF2AE01),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Tidak Sesuai (Figma node 234:1342)
        Expanded(
          child: _buildChoiceCard(
            option: ValidationOption.tidakSesuai,
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFFF3D00),
            selectedBgColor: const Color(0xFFFFE9E9),
            selectedBorderColor: const Color(0xFFFF3D00),
            textColor: const Color(0xFFFF3D00),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required ValidationOption option,
    required IconData icon,
    required Color iconColor,
    required Color selectedBgColor,
    required Color selectedBorderColor,
    required Color textColor,
  }) {
    final isSelected = _selectedOption == option;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedOption = option);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 152,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : AppColors.white,
          borderRadius: BorderRadius.circular(13.5),
          border: Border.all(
            color: isSelected ? selectedBorderColor : const Color(0xFFE0DFDF),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBorderColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: 12),
            Text(
              option.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? textColor : AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              option.description,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF515151),
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Catatan Section (Figma node 234:1351) ──────────────────────────────────
  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Catatan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '(opsional)',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8F8F8F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLength: 200,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12, color: AppColors.neutral900),
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan laporan.....',
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8F8F8F),
              ),
              counterText: '${_notesController.text.length}/200',
              counterStyle: const TextStyle(
                fontSize: 10,
                color: Color(0xFFBBBBBB),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit Button: Lanjut (Figma node 234:1283) ────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFB9D19E)),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
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
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
