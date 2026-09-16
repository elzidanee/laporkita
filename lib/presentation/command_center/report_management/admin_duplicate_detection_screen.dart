import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'admin_assign_report_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Deteksi Kesamaan Laporan | Admin (Figma: node 555-608)
// ─────────────────────────────────────────────────────────────

class AdminDuplicateDetectionScreen extends StatefulWidget {
  final ReportModel currentReport;
  final List<ReportModel> similarReports;
  final double similarityPercentage;

  const AdminDuplicateDetectionScreen({
    super.key,
    required this.currentReport,
    this.similarReports = const [],
    this.similarityPercentage = 85.0,
  });

  @override
  State<AdminDuplicateDetectionScreen> createState() =>
      _AdminDuplicateDetectionScreenState();
}

class _AdminDuplicateDetectionScreenState
    extends State<AdminDuplicateDetectionScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final similarity = widget.similarityPercentage.clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Top Bar: Chevron Back + Title
            _buildTopBar(),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Tingkat Kesamaan Progress
                    _buildSimilarityProgressCard(similarity),
                    const SizedBox(height: 25),

                    // Section Title: Tingkat Kesamaan
                    Text(
                      'Tingkat Kesamaan',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cards List: Current Report & Similar Reports
                    _buildComparisonCard(
                      report: widget.currentReport,
                      badgeText: '${similarity.round()}%',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 14),

                    if (widget.similarReports.isNotEmpty) ...[
                      for (int i = 0; i < widget.similarReports.length; i++) ...[
                        _buildComparisonCard(
                          report: widget.similarReports[i],
                          badgeText: _calculateDistanceText(
                            widget.currentReport,
                            widget.similarReports[i],
                          ),
                          isHighlight: false,
                        ),
                        if (i < widget.similarReports.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ] else ...[
                      // Fallback candidate card representing the detected similarity
                      _buildComparisonCard(
                        report: widget.currentReport.copyWith(
                          reportCode: widget.currentReport.reportCode.isNotEmpty
                              ? '${widget.currentReport.reportCode}_DUP'
                              : '#LP_2026_0027391',
                        ),
                        badgeText: '180m',
                        isHighlight: false,
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Actions: "Apakah laporan ini duplikat?" + Buttons
            _buildBottomDecisionBar(),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR (Figma Node 555:611) ──────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
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
            Expanded(
              child: Text(
                'Deteksi Kesamaan',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  // ── CARD 1: TINGKAT KESAMAAN (Figma Node 557:908) ──────────────────

  Widget _buildSimilarityProgressCard(double similarity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tingkat Kesamaan',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '${similarity.round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D9C51),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: similarity / 100.0,
              minHeight: 6,
              backgroundColor: const Color(0xFFD9D9D9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1D9C51)),
            ),
          ),
        ],
      ),
    );
  }

  // ── COMPARISON CARD (Figma Node 558:925 & 558:969) ─────────────────

  Widget _buildComparisonCard({
    required ReportModel report,
    required String badgeText,
    required bool isHighlight,
  }) {
    return Container(
      height: 97,
      padding: const EdgeInsets.fromLTRB(6, 7, 12, 7),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Thumbnail with Watermark Overlay (Figma 119x83)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 119,
              height: 83,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBEC4BD), width: 1.0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnailImage(report),
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: _buildCameraWatermark(report),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Info (Title, Address, Code)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  report.categoryName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  report.addressText ?? 'Jl. Ahmad Yani no. 15',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  report.reportCode.isNotEmpty
                      ? report.reportCode
                      : '#LP_2026_0024487',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D9C51),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Right Badge (e.g. "85%" or "180m")
          Text(
            badgeText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isHighlight
                  ? const Color(0xFF1D9C51)
                  : const Color(0xFF515151),
            ),
          ),
        ],
      ),
    );
  }

  // ── WATERMARK STAMP (Matching Figma stamp) ─────────────────────────

  Widget _buildCameraWatermark(ReportModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF62D26D), width: 0.3),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 4,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            r.reportCode.isNotEmpty ? r.reportCode : '#LP_2026_002487',
            style: GoogleFonts.poppins(
              fontSize: 3.5,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            maxLines: 1,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 4, color: Colors.white),
              const SizedBox(width: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 45),
                child: Text(
                  r.addressText ?? 'Malang',
                  style: GoogleFonts.poppins(
                    fontSize: 3,
                    fontWeight: FontWeight.w400,
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
    );
  }

  Widget _buildThumbnailImage(ReportModel r) {
    Widget placeholder() => Container(
          color: const Color(0xFFEAEAEA),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 22, color: Color(0xFF9E9E9E)),
          ),
        );

    final localPath = r.directPhotoUrl;
    bool isLocalValid = false;
    if (localPath != null && localPath.isNotEmpty && !localPath.startsWith('http')) {
      try {
        isLocalValid = File(localPath).existsSync();
      } catch (_) {}
    }
    if (isLocalValid && localPath != null) {
      return Image.file(File(localPath), fit: BoxFit.cover, errorBuilder: (c, e, s) => placeholder());
    }

    final photoUrl = r.formattedPhotoUrl ?? r.photoUrl ?? '';
    if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
      return Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => placeholder());
    }

    return Image.network(
      ReportModel.getCategoryFallbackImage(r.categoryName),
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => placeholder(),
    );
  }

  // ── BOTTOM DECISION BAR (Figma Node 558:1016) ──────────────────────

  Widget _buildBottomDecisionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Apakah laporan ini duplikat?',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // 1. Bukan Duplikat Button (Green #1D9C51)
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 49,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleNotDuplicate,
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
                            'Bukan Duplikat',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 2. Duplikat Button (White with Red Border #C60D05)
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 49,
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _handleDuplicate,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC60D05), width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Duplikat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC60D05),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ACTION HANDLERS ────────────────────────────────────────────────

  Future<void> _handleNotDuplicate() async {
    final nav = Navigator.of(context);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAssignReportScreen(
          report: widget.currentReport,
        ),
      ),
    );

    if (result == true && mounted) {
      nav.pop(true);
    }
  }

  Future<void> _handleDuplicate() async {
    setState(() => _isProcessing = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final repo = context.read<ReportRepository>();
      final updated = await repo.updateReportStatus(
        widget.currentReport.id,
        'rejected',
        notes: 'Laporan ditandai sebagai duplikat dari laporan yang sudah terdaftar sebelumnya.',
        existingReport: widget.currentReport,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil ditandai sebagai duplikat.'),
            backgroundColor: Color(0xFFC60D05),
          ),
        );
        nav.pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menandai duplikat: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  String _calculateDistanceText(ReportModel a, ReportModel b) {
    if (a.latitude == 0 || b.latitude == 0) return '180m';
    const p = 0.017453292519943295;
    final c = 0.5 -
        math.cos((b.latitude - a.latitude) * p) / 2 +
        math.cos(a.latitude * p) *
            math.cos(b.latitude * p) *
            (1 - math.cos((b.longitude - a.longitude) * p)) /
            2;
    final meters = (12742000 * math.asin(math.sqrt(c))).round();
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }
}
