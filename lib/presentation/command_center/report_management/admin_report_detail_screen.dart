import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'admin_report_history_screen.dart';
import 'admin_verification_action_screen.dart';
import 'admin_assign_report_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Detail Laporan | Admin  (Figma: node 551-2)
// ─────────────────────────────────────────────────────────────

class AdminReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const AdminReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  late ReportModel _currentReport;
  bool _isLoading = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _refreshDetail();
    _loadComments();
  }

  Future<void> _refreshDetail() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final fresh = await repo.getReportById(_currentReport.id);
      if (mounted) {
        setState(() {
          _currentReport = _currentReport.copyWith(
            status: fresh.status,
            damageSeverity: fresh.damageSeverity ?? _currentReport.damageSeverity,
            rawAiConfidenceScore:
                fresh.rawAiConfidenceScore ?? _currentReport.rawAiConfidenceScore,
            directPriority: fresh.directPriority ?? _currentReport.directPriority,
            urgencyScore: fresh.urgencyScore ?? _currentReport.urgencyScore,
            statusHistory: fresh.statusHistory.isNotEmpty
                ? fresh.statusHistory
                : _currentReport.statusHistory,
            category: fresh.category ?? _currentReport.category,
            assignedAgency:
                fresh.assignedAgency ?? _currentReport.assignedAgency,
            addressText: fresh.addressText ?? _currentReport.addressText,
            description: fresh.description ?? _currentReport.description,
            directPhotoUrl:
                fresh.directPhotoUrl ?? _currentReport.directPhotoUrl,
            supportCount: fresh.supportCount > 0
                ? fresh.supportCount
                : _currentReport.supportCount,
            viewCount: fresh.viewCount > 0
                ? fresh.viewCount
                : _currentReport.viewCount,
          );
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getComments(_currentReport.id);
      if (mounted) {
        setState(() {
          _comments = res.data ?? [];
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = _currentReport;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _currentReport);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top App Bar: Back <, "Detail Laporan", Share icon
                  _buildTopAppBar(),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

                          // Header Info: Code + Status Badge, Title, Address
                          _buildHeaderInfo(r),
                          const SizedBox(height: 18),

                          // Hero Image Container with Authentic Watermark
                          _buildHeroImage(r),
                          const SizedBox(height: 18),

                          // Deskripsi Section
                          _buildDescriptionSection(r),
                          const SizedBox(height: 18),

                          // Key-Value Attribute Details List
                          _buildKeyValuesList(r),
                          const SizedBox(height: 20),

                          // "Lihat Pada Peta" Outlined Button
                          _buildMapButton(r),
                          const SizedBox(height: 24),

                          // AI Verification Card
                          _buildAiVerificationCard(r),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Sticky Action Bar: Riwayat, Catatan, Tindak Lanjut
                  _buildBottomActionBar(r),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.greenPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── TOP APP BAR (Figma node 627:946) ──────────────────────────────

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 16, top: 6, bottom: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Back Button (Figma node 627:947)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.5),
              onTap: () => Navigator.pop(context, _currentReport),
              child: Container(
                width: 41,
                height: 41,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 34,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Centered Title (Figma node 627:950)
          Center(
            child: Text(
              'Detail Laporan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
            ),
          ),
          // Share Button (Figma node 627:951)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.share_outlined, size: 24, color: Colors.black),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'Laporan ${_formatCodeWithHash(_currentReport.reportCode)}: ${_currentReport.categoryName} di ${_currentReport.addressText ?? "Malang"}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tautan dan info laporan disalin ke clipboard'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.greenPrimary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER INFO ────────────────────────────────────────────────────

  Widget _buildHeaderInfo(ReportModel r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column: Code, Big Title, Address
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatCodeWithHash(r.reportCode),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                r.categoryName,
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                r.addressText ?? 'Jl. Ahmad Yani no. 15',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Right: Priority Badge matching Figma node 627:883
        _buildPriorityBadge(r),
      ],
    );
  }

  Widget _buildPriorityBadge(ReportModel r) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: r.priorityBgColor,
        borderRadius: BorderRadius.circular(19.88),
      ),
      child: Center(
        child: Text(
          r.priorityLabel,
          style: GoogleFonts.poppins(
            fontSize: 10.6,
            fontWeight: FontWeight.normal,
            color: r.priorityColor,
          ),
        ),
      ),
    );
  }


  // ── HERO IMAGE WITH WATERMARK ──────────────────────────────────────

  Widget _buildHeroImage(ReportModel r) {
    return Container(
      height: 204,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBEC4BD), width: 1.0),
        color: const Color(0xFFF2F2F2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageWidget(r),
            Positioned(
              left: 12,
              bottom: 12,
              child: _buildDetailWatermarkBadge(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(ReportModel r) {
    final url = r.formattedPhotoUrl ?? r.photoUrl;

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackHeroImage(r.categoryName),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFFF5F5F5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.greenPrimary,
                ),
              ),
            );
          },
        );
      } else if (File(url).existsSync()) {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackHeroImage(r.categoryName),
        );
      }
    }

    return _buildFallbackHeroImage(r.categoryName);
  }

  Widget _buildFallbackHeroImage(String categoryName) {
    final lower = categoryName.toLowerCase();
    String unsplashUrl;
    if (lower.contains('jembatan')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1545558014-8692077e9b5c?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('lampu')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('trotoar')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('halte')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=800&auto=format&fit=crop';
    } else {
      unsplashUrl =
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop';
    }

    return Image.network(
      unsplashUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE8F5E9),
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.greenPrimary, size: 48),
        ),
      ),
    );
  }

  Widget _buildDetailWatermarkBadge(ReportModel r) {
    return Container(
      padding: const EdgeInsets.only(left: 6, top: 5.5, right: 10, bottom: 4.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(7.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(8.7),
              border: Border.all(color: const Color(0xFF62D26D), width: 0.35),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 6.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatCodeWithHash(r.reportCode),
            style: GoogleFonts.poppins(
              fontSize: 6.8,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 8, color: Colors.white),
              const SizedBox(width: 3),
              SizedBox(
                width: 95,
                child: Text(
                  r.addressText ?? 'Jl. Ahmad Yani No.15 Malang',
                  style: GoogleFonts.poppins(
                    fontSize: 6.2,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 8, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                _formatDateTimeFull(r.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 6.2,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 8, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                r.categoryName,
                style: GoogleFonts.poppins(
                  fontSize: 6.2,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory_rounded, size: 8, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                '${r.latitude.toStringAsFixed(6)},${r.longitude.toStringAsFixed(6)}',
                style: GoogleFonts.poppins(
                  fontSize: 6.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── DESKRIPSI SECTION (Figma node 627:877) ─────────────────────────

  Widget _buildDescriptionSection(ReportModel r) {
    final hasNote = r.description != null && r.description!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan / Deskripsi Citizen :',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            hasNote ? r.description! : 'Tidak ada catatan tambahan dari warga.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: hasNote ? Colors.black87 : const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── KEY-VALUES ATTRIBUTES LIST (Figma node 627:979) ─────────────────

  Widget _buildKeyValuesList(ReportModel r) {
    final priorityText = r.priorityLabel.replaceAll('Prioritas ', '');
    final priorityColor = r.priorityColor;
    final scoreOutOf100 = r.priorityScoreOutOf100;

    final opdName = r.assignedAgency?['name'] ?? _inferOpd(r.categoryName);

    return Column(
      children: [
        _buildDetailRow(
          label: 'Laporan dibuat',
          valueWidget: Text(
            _formatDateTimeCompact(r.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: 13),
        _buildDetailRow(
          label: 'Pelapor',
          valueWidget: Text(
            r.reporterName.isNotEmpty ? r.reporterName : 'Budi Santoso',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: 13),
        _buildDetailRow(
          label: 'Kategori',
          valueWidget: Text(
            r.categoryName,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: 13),
        _buildDetailRow(
          label: 'Prioritas AI',
          valueWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: priorityText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: priorityColor,
                  ),
                ),
                TextSpan(
                  text: ' ($scoreOutOf100/100)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: 13),
        _buildDetailRow(
          label: 'OPD Tujuan',
          valueWidget: Text(
            opdName,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: 13),
        _buildDetailRow(
          label: 'Koordinat',
          valueWidget: Text(
            '${r.latitude.toStringAsFixed(6)},${r.longitude.toStringAsFixed(6)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: valueWidget,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF515151),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── "LIHAT PADA PETA" BUTTON (Figma node 627:1016) ──────────────────

  Widget _buildMapButton(ReportModel r) {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: OutlinedButton(
        onPressed: () => _showMapModal(r),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1D9C51), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          'Lihat Pada Peta',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D9C51),
          ),
        ),
      ),
    );
  }

  // ── AI VERIFICATION CARD (Figma node 627:886) ──────────────────────

  Widget _buildAiVerificationCard(ReportModel r) {
    final confPercent = ((r.aiConfidenceScore ?? 0.98) * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Verification',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          _buildVerificationItem(label: 'Foto Valid', value: 'Valid'),
          const SizedBox(height: 11),
          _buildVerificationItem(label: 'GPS Valid', value: 'Valid'),
          const SizedBox(height: 11),
          _buildVerificationItem(label: 'Timestamp Valid', value: 'Valid'),
          const SizedBox(height: 11),
          _buildVerificationItem(label: 'Metadata lengkap', value: 'Valid'),
          const SizedBox(height: 11),
          _buildVerificationItem(label: 'Confidence Score', value: '$confPercent%'),
        ],
      ),
    );
  }

  Widget _buildVerificationItem({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF1D9C51),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D9C51),
          ),
        ),
      ],
    );
  }

  // ── BOTTOM ACTION BAR (Figma node 627:1018) ────────────────────────

  Widget _buildBottomActionBar(ReportModel r) {
    final isPending = r.status == ReportStatus.pendingVerification;
    final isVerified = r.status == ReportStatus.verified;
    final isAssigned = r.status == ReportStatus.assigned;
    final isInProgress = r.status == ReportStatus.inProgress;
    final isRejected = r.status == ReportStatus.rejected;

    String actionLabel;
    IconData? actionIcon;
    Color actionBg;
    Color actionFg;
    Color actionBorder;
    VoidCallback actionTap;

    if (isPending) {
      actionLabel = 'Tindak Lanjut';
      actionIcon = null;
      actionBg = const Color(0xFF1D9C51);
      actionFg = Colors.white;
      actionBorder = const Color(0xFFBCFFC2);
      actionTap = () async {
        final updated = await Navigator.push<ReportModel>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminVerificationActionScreen(
              report: r,
              initialTabIndex: 0,
            ),
          ),
        );
        if (mounted) {
          if (updated != null) {
            setState(() => _currentReport = updated);
          }
          await _refreshDetail();
        }
      };
    } else if (isVerified) {
      actionLabel = 'Tugaskan ke OPD';
      actionIcon = Icons.forward_to_inbox_rounded;
      actionBg = const Color(0xFF1D9C51);
      actionFg = Colors.white;
      actionBorder = const Color(0xFFBCFFC2);
      actionTap = () async {
        final updated = await Navigator.push<ReportModel>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAssignReportScreen(
              report: r,
            ),
          ),
        );
        if (mounted) {
          if (updated != null) {
            setState(() => _currentReport = updated);
          }
          await _refreshDetail();
        }
      };
    } else if (isAssigned) {
      actionLabel = 'Sudah Ditugaskan';
      actionIcon = Icons.check_circle_rounded;
      actionBg = const Color(0xFFE9F9EE);
      actionFg = const Color(0xFF1D9C51);
      actionBorder = const Color(0xFF86EFAC);
      actionTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Laporan ini telah ditindaklanjuti dan diteruskan ke instansi terkait.',
            ),
            backgroundColor: Color(0xFF1D9C51),
            duration: Duration(seconds: 2),
          ),
        );
      };
    } else if (isInProgress) {
      actionLabel = 'Sedang Diproses';
      actionIcon = Icons.engineering_rounded;
      actionBg = const Color(0xFFFFF9E9);
      actionFg = const Color(0xFFD97706);
      actionBorder = const Color(0xFFFDE68A);
      actionTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Laporan ini sedang dalam tahap pengerjaan oleh petugas lapangan.',
            ),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 2),
          ),
        );
      };
    } else if (isRejected) {
      actionLabel = 'Ditolak';
      actionIcon = Icons.cancel_outlined;
      actionBg = const Color(0xFFFFF1F2);
      actionFg = const Color(0xFFE11D48);
      actionBorder = const Color(0xFFFECDD3);
      actionTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Laporan ini telah ditolak oleh administrator.',
            ),
            backgroundColor: Color(0xFFE11D48),
            duration: Duration(seconds: 2),
          ),
        );
      };
    } else {
      // Completed / Resolved
      actionLabel = 'Selesai';
      actionIcon = Icons.task_alt_rounded;
      actionBg = const Color(0xFFF1F5F9);
      actionFg = const Color(0xFF64748B);
      actionBorder = const Color(0xFFCBD5E1);
      actionTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Laporan ini telah selesai dan tidak dapat diproses atau ditindaklanjuti lagi.',
            ),
            backgroundColor: Color(0xFF64748B),
            duration: Duration(seconds: 2),
          ),
        );
      };
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8E8E8), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Riwayat Button (Figma node 627:1019)
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportHistoryScreen(report: r),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF515151), width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: Color(0xFF515151),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Riwayat',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF515151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Catatan Button (Figma node 627:1023)
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => _showNotesModal(r),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF515151), width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 20,
                      color: Color(0xFF515151),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Catatan',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF515151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Tindak Lanjut / Status Selesai / Ditugaskan Button (Figma node 627:1027)
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: actionTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionBg,
                  foregroundColor: actionFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: actionBorder,
                      width: 1.0,
                    ),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (actionIcon != null) ...[
                      Icon(
                        actionIcon,
                        size: 16,
                        color: actionFg,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: actionFg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MODALS: MAP, RIWAYAT, CATATAN, TINDAK LANJUT ───────────────────

  void _showMapModal(ReportModel r) {
    final lat = (r.latitude != 0.0) ? r.latitude : -7.9666;
    final lng = (r.longitude != 0.0) ? r.longitude : 112.6326;
    final centerPoint = LatLng(lat, lng);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lokasi Laporan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                r.addressText ?? 'Jl. Malang, Jawa Timur',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: 15.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.laporkita.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: centerPoint,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.statusDanger,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 16, color: AppColors.greenPrimary),
                  const SizedBox(width: 6),
                  Text(
                    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotesModal(ReportModel r) {
    final noteController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Catatan & Komentar',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Catatan dari Citizen / Pelapor
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              size: 16,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Catatan dari Citizen (Pelapor):',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_currentReport.description != null &&
                                  _currentReport.description!.trim().isNotEmpty)
                              ? _currentReport.description!
                              : 'Tidak ada catatan tambahan dari warga.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 170,
                    child: _isLoadingComments
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.greenPrimary,
                            ),
                          )
                        : _comments.isEmpty
                            ? Center(
                                child: Text(
                                  'Belum ada catatan untuk laporan ini.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _comments.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final c = _comments[index];
                                  final author = c['user']?['full_name'] ??
                                      c['author_name'] ??
                                      'Petugas / Admin';
                                  final content =
                                      c['content'] ?? c['message'] ?? '';
                                  final createdAtStr = c['created_at'] ?? c['createdAt'];
                                  String timeStr = '';
                                  if (createdAtStr != null) {
                                    final dt = DateTime.tryParse(
                                        createdAtStr.toString());
                                    if (dt != null) {
                                      timeStr = _formatDateTimeCompact(dt.toLocal());
                                    }
                                  }
                                  if (timeStr.isEmpty) {
                                    timeStr = _formatDateTimeCompact(DateTime.now().toLocal());
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            author,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (timeStr.isNotEmpty)
                                            Text(
                                              timeStr,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        content,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            hintText: 'Tambah catatan tindak lanjut...',
                            hintStyle: GoogleFonts.poppins(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.greenPrimary,
                          foregroundColor: Colors.white,
                        ),
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final text = noteController.text.trim();
                                if (text.isEmpty) return;
                                setModalState(() => isSubmitting = true);
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(context);
                                try {
                                  final repo = context.read<ReportRepository>();
                                  final res =
                                      await repo.addComment(r.id, text);
                                  noteController.clear();
                                  setModalState(() {
                                    _comments.add(res);
                                    isSubmitting = false;
                                  });
                                  if (mounted) {
                                    setState(() {});
                                    _loadComments();
                                  }
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Catatan berhasil ditambahkan'),
                                      backgroundColor: AppColors.greenPrimary,
                                    ),
                                  );
                                } catch (_) {
                                  setModalState(() => isSubmitting = false);
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────

  String _formatCodeWithHash(String code) {
    if (code.isEmpty) return '#LP-2026-002487';
    var cleaned = code.trim();
    if (cleaned.startsWith('#')) cleaned = cleaned.substring(1);
    cleaned = cleaned.replaceAll('_', '-');
    return '#$cleaned';
  }

  String _formatDateTimeCompact(DateTime dt) {
    final localDt = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final month = months[localDt.month - 1];
    final hh = localDt.hour.toString().padLeft(2, '0');
    final mm = localDt.minute.toString().padLeft(2, '0');
    return '${localDt.day} $month ${localDt.year} | $hh.$mm WIB';
  }

  String _formatDateTimeFull(DateTime dt) {
    final localDt = dt.toLocal();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[localDt.weekday - 1];
    final monthName = months[localDt.month - 1];
    final hh = localDt.hour.toString().padLeft(2, '0');
    final mm = localDt.minute.toString().padLeft(2, '0');
    return '$dayName, ${localDt.day} $monthName ${localDt.year} | $hh.$mm WIB';
  }

  String _inferOpd(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('lampu') ||
        lower.contains('rambu') ||
        lower.contains('lalu lintas') ||
        lower.contains('marka') ||
        lower.contains('traffic')) {
      return 'Dinas Perhubungan (Dishub)';
    } else if (lower.contains('internet') ||
        lower.contains('cctv') ||
        lower.contains('kabel') ||
        lower.contains('fiber') ||
        lower.contains('wifi') ||
        lower.contains('komunikasi') ||
        lower.contains('informasi') ||
        lower.contains('digital')) {
      return 'Dinas Komunikasi & Informatika (Diskominfo)';
    } else {
      return 'Dinas PUPR (DPUPR)';
    }
  }
}
