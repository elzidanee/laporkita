import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../citizen/tracking/tracking_progress_screen.dart';

class AdminReportHistoryScreen extends StatefulWidget {
  final ReportModel report;

  const AdminReportHistoryScreen({
    super.key,
    required this.report,
  });

  @override
  State<AdminReportHistoryScreen> createState() =>
      _AdminReportHistoryScreenState();
}

class _AdminReportHistoryScreenState extends State<AdminReportHistoryScreen> {
  static const Color _greenPrimary = Color(0xFF1D9C51);
  static const Color _bluePrimary = Color(0xFF1976D2);
  static const Color _greyDisabled = Color(0xFFBDBDBD);
  static const Color _redDanger = Color(0xFFE53935);

  late ReportModel _report;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _refreshReportDetails();
  }

  Future<void> _refreshReportDetails() async {
    try {
      final repo = context.read<ReportRepository>();
      final fresh = await repo.getReportById(widget.report.id);
      if (mounted) {
        setState(() {
          _report = fresh;
        });
      }
    } catch (_) {}
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final month = months[dt.month - 1];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year} | $hh.$mm';
  }

  String _formatDateOnly(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _getOpdName() {
    final agency = (_report.assignedAgency?['name'] ?? '').toString();
    if (agency.isNotEmpty) return agency;

    final cat = _report.categoryName.toLowerCase();
    if (cat.contains('lampu') ||
        cat.contains('rambu') ||
        cat.contains('lalu lintas') ||
        cat.contains('dishub')) {
      return 'Dinas Perhubungan';
    } else if (cat.contains('internet') ||
        cat.contains('cctv') ||
        cat.contains('kabel') ||
        cat.contains('diskominfo')) {
      return 'Diskominfo';
    }
    return 'Dinas PUPR';
  }

  ReportStatusHistoryModel? _findHistory(ReportStatus status) {
    for (final h in _report.statusHistory) {
      if (h.targetStatus == status) return h;
    }
    return null;
  }

  Widget _buildThumbnail() {
    final photo = _report.formattedPhotoUrl ?? _report.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http')) {
        return Image.network(
          photo,
          width: 104,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackImage(),
        );
      } else {
        try {
          if (File(photo).existsSync()) {
            return Image.file(
              File(photo),
              width: 104,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackImage(),
            );
          }
        } catch (_) {}
      }
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      width: 104,
      height: 64,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.construction_rounded, color: Colors.grey, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opdName = _getOpdName();

    // 1. Dibuat
    final createdTimeStr = _formatDateTime(_report.createdAt);

    // 2. Diverifikasi
    final isVerified = _report.status != ReportStatus.pendingVerification &&
        _report.status != ReportStatus.rejected;
    final verifiedEntry = _findHistory(ReportStatus.verified);
    final verifiedTimeStr = isVerified
        ? _formatDateTime(verifiedEntry?.createdAt ?? _report.updatedAt)
        : '';

    // 3. Diteruskan ke Dinas
    final isAssigned = isVerified &&
        (_report.assignedAgency != null ||
            _report.status == ReportStatus.assigned ||
            _report.status == ReportStatus.inProgress ||
            _report.status == ReportStatus.completed ||
            _report.status == ReportStatus.resolved);
    final assignedEntry = _findHistory(ReportStatus.assigned);
    final assignedTimeStr = isAssigned
        ? _formatDateTime(assignedEntry?.createdAt ?? _report.updatedAt)
        : '';

    // 4. Sedang Diproses
    final isInProgress = _report.status == ReportStatus.inProgress ||
        _report.status == ReportStatus.completed ||
        _report.status == ReportStatus.resolved;
    final inProgressEntry = _findHistory(ReportStatus.inProgress);
    final inProgressTimeStr = isInProgress
        ? _formatDateTime(inProgressEntry?.createdAt ?? _report.updatedAt)
        : '';

    // 5. Estimasi Selesai
    final hasEstimatedDate = _report.estimatedCompletionAt != null;
    final estDateStr = hasEstimatedDate
        ? _formatDateOnly(_report.estimatedCompletionAt!)
        : 'Belum ditentukan dinas';

    // 6. Selesai
    final isCompleted = _report.status == ReportStatus.completed ||
        _report.status == ReportStatus.resolved;
    final completedEntry = _findHistory(ReportStatus.completed) ??
        _findHistory(ReportStatus.resolved);
    final completedTimeStr = isCompleted
        ? _formatDateTime(completedEntry?.createdAt ?? _report.updatedAt)
        : '';

    // Status Ditolak
    final isRejected = _report.status == ReportStatus.rejected;
    final rejectedEntry = _findHistory(ReportStatus.rejected);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 32,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Riwayat Laporan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshReportDetails,
                color: _greenPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // ── STEP 1: Laporan Dibuat ─────────────────────────
                      _buildTimelineStep(
                        iconType: _TimelineIconType.greenCheck,
                        lineType: isRejected
                            ? _TimelineLineType.solidGrey
                            : (isVerified
                                ? _TimelineLineType.solidGreen
                                : _TimelineLineType.solidGrey),
                        title: 'Laporan dibuat',
                        timestamp: createdTimeStr,
                        description:
                            'Laporan ${_report.reportCode} berhasil dibuat oleh masyarakat.',
                      ),

                      // ── STEP REJECTED (Jika Ditolak) ──────────────────
                      if (isRejected) ...[
                        _buildTimelineStep(
                          iconType: _TimelineIconType.redClose,
                          lineType: _TimelineLineType.none,
                          title: 'Laporan Ditolak',
                          timestamp: _formatDateTime(
                              rejectedEntry?.createdAt ?? _report.updatedAt),
                          description: rejectedEntry?.note?.isNotEmpty == true
                              ? 'Alasan: ${rejectedEntry!.note}'
                              : 'Laporan tidak memenuhi kriteria verifikasi admin.',
                        ),
                      ],

                      // ── STEP 2: Diverifikasi Admin ────────────────────
                      if (!isRejected) ...[
                        _buildTimelineStep(
                          iconType: isVerified
                              ? _TimelineIconType.greenCheck
                              : _TimelineIconType.greyCircle,
                          lineType: isAssigned
                              ? _TimelineLineType.solidBlue
                              : _TimelineLineType.solidGrey,
                          title: isVerified
                              ? 'Diverifikasi Admin'
                              : 'Menunggu Verifikasi Admin',
                          timestamp: verifiedTimeStr,
                          description: isVerified
                              ? (verifiedEntry?.note?.isNotEmpty == true
                                  ? verifiedEntry!.note!
                                  : 'Laporan telah diverifikasi dan sesuai ketentuan.')
                              : 'Laporan sedang dalam antrean verifikasi petugas.',
                        ),

                        // ── STEP 3: Diteruskan ke Dinas ───────────────────
                        _buildTimelineStep(
                          iconType: isAssigned
                              ? _TimelineIconType.bluePin
                              : _TimelineIconType.greyCircle,
                          lineType: isInProgress
                              ? _TimelineLineType.solidBlue
                              : _TimelineLineType.solidGrey,
                          title: isAssigned
                              ? 'Diteruskan ke $opdName'
                              : 'Disposisi OPD ($opdName)',
                          timestamp: assignedTimeStr,
                          description: isAssigned
                              ? 'Laporan diteruskan ke $opdName Kota Malang.'
                              : 'Menunggu penugasan resmi ke instansi terkait.',
                        ),

                        // ── STEP 4: Sedang Diproses ───────────────────────
                        _buildTimelineStep(
                          iconType: isInProgress
                              ? _TimelineIconType.bluePin
                              : _TimelineIconType.greyCircle,
                          lineType: isCompleted
                              ? _TimelineLineType.solidGreen
                              : _TimelineLineType.solidGrey,
                          title: 'Sedang Diproses',
                          timestamp: inProgressTimeStr,
                          description: isInProgress
                              ? (inProgressEntry?.note?.isNotEmpty == true
                                  ? inProgressEntry!.note!
                                  : 'Petugas $opdName sedang menangani perbaikan di lokasi.')
                              : 'Menunggu petugas memulai proses pengerjaan.',
                          child: isInProgress
                              ? Container(
                                  margin:
                                      const EdgeInsets.only(top: 10, bottom: 4),
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE0DFDF),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildThumbnail(),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Foto Progres',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                                letterSpacing: 0.25,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              inProgressTimeStr.isNotEmpty
                                                  ? inProgressTimeStr.replaceAll(
                                                      ' | ', '. ')
                                                  : createdTimeStr.replaceAll(
                                                      ' | ', '. '),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF515151),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),

                        // ── STEP 5: Estimasi Selesai ───────────────────────
                        _buildTimelineStep(
                          iconType: isCompleted
                              ? _TimelineIconType.greenCheck
                              : (isInProgress && hasEstimatedDate
                                  ? _TimelineIconType.bluePin
                                  : _TimelineIconType.greyCircle),
                          lineType: isCompleted
                              ? _TimelineLineType.solidGreen
                              : _TimelineLineType.solidGrey,
                          title: 'Estimasi selesai',
                          timestamp: '',
                          description: estDateStr,
                        ),

                        // ── STEP 6: Selesai ────────────────────────────────
                        _buildTimelineStep(
                          iconType: isCompleted
                              ? _TimelineIconType.greenCheck
                              : _TimelineIconType.greyCircle,
                          lineType: _TimelineLineType.none,
                          title: 'Selesai',
                          timestamp: completedTimeStr,
                          description: isCompleted
                              ? (completedEntry?.note?.isNotEmpty == true
                                  ? completedEntry!.note!
                                  : 'Pekerjaan perbaikan telah selesai dikonfirmasi.')
                              : 'Menunggu konfirmasi penyelesaian pekerjaan.',
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── BOTTOM ACTION BUTTON: Lihat Tracking Progress ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 49,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackingProgressScreen(
                          reportData: _report.toJson(),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: _greenPrimary,
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    'Lihat Tracking Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: _greenPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required _TimelineIconType iconType,
    required _TimelineLineType lineType,
    required String title,
    required String timestamp,
    required String description,
    Widget? child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator & Vertical Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _buildIndicatorIcon(iconType),
                if (lineType != _TimelineLineType.none)
                  Expanded(
                    child: Container(
                      width: 2.0,
                      color: lineType == _TimelineLineType.solidGreen
                          ? _greenPrimary
                          : (lineType == _TimelineLineType.solidBlue
                              ? _bluePrimary
                              : const Color(0xFFE0DFDF)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                      height: 1.35,
                    ),
                  ),
                  if (child != null) child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorIcon(_TimelineIconType type) {
    switch (type) {
      case _TimelineIconType.greenCheck:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _greenPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 15,
            color: Colors.white,
          ),
        );
      case _TimelineIconType.bluePin:
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: _bluePrimary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.radio_button_checked_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        );
      case _TimelineIconType.redClose:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _redDanger,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: 15,
            color: Colors.white,
          ),
        );
      case _TimelineIconType.greyCircle:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _greyDisabled,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 15,
            color: Colors.white,
          ),
        );
    }
  }
}

enum _TimelineIconType {
  greenCheck,
  bluePin,
  redClose,
  greyCircle,
}

enum _TimelineLineType {
  solidGreen,
  solidBlue,
  solidGrey,
  none,
}
