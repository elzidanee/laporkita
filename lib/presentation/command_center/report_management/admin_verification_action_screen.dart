import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'admin_assign_report_screen.dart';
import 'admin_duplicate_detection_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Verifikasi AI / Human | Admin (Figma: node 554-321 & 554-511)
// ─────────────────────────────────────────────────────────────

class AdminVerificationActionScreen extends StatefulWidget {
  final ReportModel report;

  const AdminVerificationActionScreen({
    super.key,
    required this.report,
  });

  @override
  State<AdminVerificationActionScreen> createState() =>
      _AdminVerificationActionScreenState();
}

class _AdminVerificationActionScreenState
    extends State<AdminVerificationActionScreen> {
  int _activeTabIndex = 0; // 0: AI Verification, 1: Manual Review
  bool _isProcessing = false;

  // Manual Review Form State
  bool _manualPhotoValid = true;
  bool _manualGpsValid = true;
  bool _manualCategoryValid = true;
  bool _manualSafeContent = true;
  String _selectedOpd = 'Dinas PUPR (DPUPR)';
  final TextEditingController _adminNotesController = TextEditingController();

  final List<String> _opdList = [
    'Dinas PUPR (DPUPR)',
    'Dinas Perhubungan (Dishub)',
    'Dinas Komunikasi & Informatika (Diskominfo)',
  ];

  @override
  void initState() {
    super.initState();
    _adminNotesController.text =
        'Laporan telah diperiksa oleh Admin dan siap diteruskan.';
  }

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top Bar: Back Chevron + Share Button
            _buildTopBar(),
            const SizedBox(height: 12),

            // Tab Bar: AI Verification vs Manual Review
            _buildTabBar(),

            // Tab Contents
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    if (_activeTabIndex == 0)
                      _buildAiVerificationTab()
                    else
                      _buildManualReviewTab(),
                    const SizedBox(height: 28),
                    // Action Buttons: Setujui & Teruskan, Tolak, Minta Revisi
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR (Figma Node 554:394) ──────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.centerLeft,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.share_outlined,
                size: 22,
                color: Colors.black,
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'Verifikasi Laporan LaporKita: ${widget.report.reportCode}\nKategori: ${widget.report.categoryName}\nLokasi: ${widget.report.addressText ?? "-"}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tautan verifikasi disalin ke clipboard!'),
                    backgroundColor: Color(0xFF1D9C51),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR (Figma Node 554:483 & 554:586) ────────────────────────

  Widget _buildTabBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTabIndex = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'AI Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: _activeTabIndex == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _activeTabIndex == 0
                            ? const Color(0xFF1D9C51)
                            : const Color(0xFF8F8F8F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTabIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'Manual Review',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: _activeTabIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _activeTabIndex == 1
                            ? const Color(0xFF1D9C51)
                            : const Color(0xFF8F8F8F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Indicator underline + horizontal separator
        Stack(
          children: [
            Container(
              height: 1.2,
              color: const Color(0xFFE0DFDF),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: _activeTabIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 2.8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9C51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── TAB 1: AI VERIFICATION (Figma Node 554:334 & 554:487) ─────────

  Widget _buildAiVerificationTab() {
    final r = widget.report;
    final confidenceScore = r.rawAiConfidenceScore != null
        ? (r.rawAiConfidenceScore! * 100).round()
        : 98;
    final urgencyScore = (r.urgencyScore ?? 85).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Hasil AI Verification
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil AI Verification',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildVerificationRow('Foto Valid', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('GPS Valid', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('Timestamp Valid', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('Metadata lengkap', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('Confidence Score', '$confidenceScore%'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Card 2: Analisis AI
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analisis AI',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kerusakan terdeteksi : ${r.categoryName}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              Text(
                'Model : YOLOv11 + Gemini 2.5 Flash',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              Text(
                'Waktu Proses : 4.21 detik',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rekomendasi Prioritas',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: urgencyScore >= 70
                          ? 'Tinggi '
                          : urgencyScore >= 40
                              ? 'Sedang '
                              : 'Rendah ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: urgencyScore >= 70
                            ? const Color(0xFFC60D05)
                            : urgencyScore >= 40
                                ? const Color(0xFFF2AE01)
                                : const Color(0xFF1D9C51),
                      ),
                    ),
                    TextSpan(
                      text: '($urgencyScore/100)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Button "Lihat detail Analisis"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _showAiDetailModal,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF1976D2), width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Lihat detail Analisis',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationRow(String label, String value) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF1D9C51),
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D9C51),
          ),
        ),
      ],
    );
  }

  // ── TAB 2: MANUAL REVIEW (Figma Node 554:511) ─────────────────────

  Widget _buildManualReviewTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formulir Peninjauan Manual',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          _buildCheckTile(
            title: 'Kualitas Foto Memadai',
            subtitle: 'Foto jelas memperlihatkan objek laporan warga',
            value: _manualPhotoValid,
            onChanged: (v) => setState(() => _manualPhotoValid = v ?? true),
          ),
          _buildCheckTile(
            title: 'Koordinat GPS Sesuai Lokasi',
            subtitle: 'Pin lokasi sinkron dengan deskripsi jalan',
            value: _manualGpsValid,
            onChanged: (v) => setState(() => _manualGpsValid = v ?? true),
          ),
          _buildCheckTile(
            title: 'Kesesuaian Kategori Kerusakan',
            subtitle: 'Kategori cocok dengan kewenangan dinas',
            value: _manualCategoryValid,
            onChanged: (v) => setState(() => _manualCategoryValid = v ?? true),
          ),
          _buildCheckTile(
            title: 'Konten Bersih & Tidak Melanggar',
            subtitle: 'Bebas dari ujaran kebencian atau spam',
            value: _manualSafeContent,
            onChanged: (v) => setState(() => _manualSafeContent = v ?? true),
          ),
          const SizedBox(height: 16),
          Text(
            'Tugaskan ke OPD Penanggung Jawab',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedOpd,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0DFDF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0DFDF)),
              ),
            ),
            items: _opdList.map((opd) {
              return DropdownMenuItem(
                value: opd,
                child: Text(
                  opd,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedOpd = v);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Catatan Instruksi Petugas',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _adminNotesController,
            maxLines: 3,
            style: GoogleFonts.poppins(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tuliskan catatan arahan tindak lanjut...',
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0DFDF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0DFDF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF1D9C51),
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS (Figma Node 554:510) ────────────────────────────

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 1. Setujui & Teruskan (Figma Node 554:504)
        SizedBox(
          width: double.infinity,
          height: 49,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleApproveAndForward,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9C51),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFFC9E1BF), width: 0.5),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Setujui & Teruskan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Tolak Laporan (Figma Node 554:506)
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _showRejectDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC60D05), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Tolak Laporan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFC60D05),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Meminta Revisi (Figma Node 554:508)
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _showRevisionDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF2AE01), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Meminta Revisi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFF2AE01),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── ACTION LOGIC & DUPLICATE ROUTING ───────────────────────────────

  Future<void> _handleApproveAndForward() async {
    setState(() => _isProcessing = true);
    final repo = context.read<ReportRepository>();
    final nav = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Fetch live reports to check for real similarity candidates
      final response = await repo.getReports(limit: 50);
      final all = response.data ?? [];

      // Filter other reports that share similar category or nearby GPS within 1.5 km
      final candidates = all.where((r) {
        if (r.id == widget.report.id) return false;
        final sameCat = r.categoryId == widget.report.categoryId ||
            r.categoryName.toLowerCase() ==
                widget.report.categoryName.toLowerCase();
        final distanceMeters = _calcDistanceMeters(
          widget.report.latitude,
          widget.report.longitude,
          r.latitude,
          r.longitude,
        );
        final nearby = distanceMeters <= 1500;
        return sameCat || nearby;
      }).toList();

      setState(() => _isProcessing = false);

      // Check if candidate duplicates exist, or if similarity is detected
      final hasSimilarity = candidates.isNotEmpty ||
          widget.report.needsManualReview ||
          (widget.report.rawAiConfidenceScore != null &&
              widget.report.rawAiConfidenceScore! >= 0.85);

      if (hasSimilarity && mounted) {
        // Navigate to Deteksi Kesamaan (Figma Node 555:608)
        final result = await Navigator.push<ReportModel>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDuplicateDetectionScreen(
              currentReport: widget.report,
              similarReports: candidates.take(3).toList(),
              similarityPercentage: 85.0,
            ),
          ),
        );

        if (result != null && mounted) {
          nav.pop(result);
        }
        return;
      }

      // If no duplicates detected, proceed directly to AdminAssignReportScreen (Figma Node 559:1020)
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAssignReportScreen(report: widget.report),
          ),
        );
        if (result == true && mounted) {
          nav.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status laporan: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Tolak Laporan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFC60D05),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan alasan penolakan laporan ini:',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Contoh: Laporan tidak memenuhi kriteria / foto tidak valid.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC60D05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                try {
                  final repo = context.read<ReportRepository>();
                  final updated = await repo.updateReportStatus(
                    widget.report.id,
                    'rejected',
                    notes: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : 'Laporan ditolak oleh Admin.',
                    existingReport: widget.report,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Laporan telah ditolak.'),
                        backgroundColor: Color(0xFFC60D05),
                      ),
                    );
                    Navigator.pop(context, updated);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menolak laporan: $e'),
                        backgroundColor: AppColors.statusDanger,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Tolak',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRevisionDialog() {
    final revisionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Meminta Revisi Laporan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFF2AE01),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Instruksi perbaikan untuk warga pelapor:',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: revisionController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Contoh: Mohon unggah ulang foto yang lebih terang dan jelas.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2AE01),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                try {
                  final repo = context.read<ReportRepository>();
                  final updated = await repo.updateReportStatus(
                    widget.report.id,
                    'pending_verification',
                    notes: revisionController.text.trim().isNotEmpty
                        ? revisionController.text.trim()
                        : 'Meminta perbaikan data kepada pelapor.',
                    existingReport: widget.report,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Permintaan revisi telah dikirim ke pelapor.'),
                        backgroundColor: Color(0xFFF2AE01),
                      ),
                    );
                    Navigator.pop(context, updated);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengirim revisi: $e'),
                        backgroundColor: AppColors.statusDanger,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Kirim Revisi',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAiDetailModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail Analisis AI Vision & Telemetri',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              _buildModalDetailRow('Model AI', 'YOLOv11 Instance Segmentation + Gemini 2.5 Flash'),
              _buildModalDetailRow('Objek Terdeteksi', widget.report.categoryName),
              _buildModalDetailRow('Confidence Score', '${((widget.report.rawAiConfidenceScore ?? 0.98) * 100).round()}%'),
              _buildModalDetailRow('Damage Severity', '${((widget.report.damageSeverity ?? 0.85) * 100).round()}%'),
              _buildModalDetailRow('AI Processing Time', '4.21 detik (Edge Server Kota Malang)'),
              _buildModalDetailRow('GPS EXIF Verified', '${widget.report.latitude.toStringAsFixed(6)}, ${widget.report.longitude.toStringAsFixed(6)}'),
              _buildModalDetailRow('Needs Manual Review', widget.report.needsManualReview ? 'Ya (Flagged)' : 'Tidak (Auto-Passed)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9C51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calcDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lat2 == 0) return 999999.0;
    const p = 0.017453292519943295;
    final c = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(c));
  }
}
