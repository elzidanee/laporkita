import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class TrackingProgressScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const TrackingProgressScreen({super.key, this.reportData});

  @override
  State<TrackingProgressScreen> createState() =>
      _TrackingProgressScreenState();
}

class _TrackingProgressScreenState extends State<TrackingProgressScreen> {
  ReportModel? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    // Prefer pre-loaded model
    final preloaded = widget.reportData?['reportModel'] as ReportModel?;
    if (preloaded != null) {
      setState(() {
        _report = preloaded;
        _isLoading = false;
      });
      // Optionally refresh in background
      _refreshFromApi(preloaded.id);
      return;
    }

    final String? reportId = widget.reportData?['reportId'] as String? ??
        widget.reportData?['id'] as String?;

    if (reportId == null || reportId.isEmpty || !reportId.contains('-')) {
      setState(() {
        _isLoading = false;
        _errorMessage = null; // show empty state instead
      });
      return;
    }

    await _refreshFromApi(reportId);
  }

  Future<void> _refreshFromApi(String reportId) async {
    try {
      final repo = context.read<ReportRepository>();
      final detail = await repo.getReportById(reportId);
      if (mounted) {
        setState(() {
          _report = detail;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data laporan.';
        });
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[(month - 1) % 12];
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_monthName(dt.month)} ${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} WIB';

  // Progress percentage based on status
  double _progressFromStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendingVerification:
        return 0.15;
      case ReportStatus.verified:
        return 0.30;
      case ReportStatus.assigned:
        return 0.50;
      case ReportStatus.inProgress:
        return 0.75;
      case ReportStatus.completed:
        return 0.95;
      case ReportStatus.resolved:
        return 1.0;
      case ReportStatus.rejected:
        return 0.0;
      case ReportStatus.disputed:
        return 0.50;
    }
  }

  String _progressLabel(ReportStatus status) {
    return '${(_progressFromStatus(status) * 100).toInt()}%';
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
          'Tracking Progress',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.greenPrimary),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadReport();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.greenPrimary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final report = _report;

    // --- Fallback values from passed args if API not yet loaded ---
    final String? imagePath = widget.reportData?['imagePath'] as String?;
    final String photoUrl = report?.formattedPhotoUrl ??
        report?.photoUrl ??
        (widget.reportData?['photoUrl'] as String? ?? '');
    final String location = report?.addressText ??
        (widget.reportData?['location'] as String? ??
            widget.reportData?['address'] as String? ??
            'Lokasi tidak tersedia');
    final String coordinates =
        '${report?.latitude ?? widget.reportData?['latitude'] ?? '-'}, '
        '${report?.longitude ?? widget.reportData?['longitude'] ?? '-'}';
    final String reportCode = report?.reportCode.isNotEmpty == true
        ? report!.reportCode
        : (widget.reportData?['reportCode'] as String? ??
            widget.reportData?['reportId'] as String? ??
            '#LP-2026-000000');

    final String? rawTimestamp = widget.reportData?['timestamp'] as String? ??
        widget.reportData?['createdAt'] as String?;

    String dateStr;
    String timeStr;

    if (report != null) {
      final createdAt = report.createdAt.toLocal();
      dateStr = _formatDate(createdAt);
      timeStr = _formatTime(createdAt);
    } else if (rawTimestamp != null && rawTimestamp.isNotEmpty) {
      if (rawTimestamp.contains('|')) {
        final parts = rawTimestamp.split('|');
        dateStr = parts[0].trim();
        timeStr = parts[1].trim();
      } else {
        dateStr = rawTimestamp;
        timeStr = '';
      }
    } else {
      final now = DateTime.now();
      dateStr = _formatDate(now);
      timeStr = _formatTime(now);
    }

    final String timestamp = timeStr.isNotEmpty ? '$dateStr | $timeStr' : dateStr;

    final ReportStatus status = report?.status ?? ReportStatus.pendingVerification;
    final String statusText = report?.status.displayName ?? 'Menunggu Verifikasi';
    final String agencyName =
        report?.assignedAgency?['name'] as String? ?? 'Dinas terkait';
    final String categoryName = report?.categoryName ?? 'Laporan';

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error notice
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCCCC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.neutral900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Photo Preview with Overlay Stamp
                  _buildPhotoPreview(
                    imagePath: imagePath,
                    photoUrl: photoUrl,
                    location: location,
                    coordinates: coordinates,
                    timestamp: timestamp,
                    reportId: reportCode,
                    title: categoryName,
                  ),
                  const SizedBox(height: 24),

                  // Status Card
                  _buildStatusCard(status, statusText, agencyName),
                  const SizedBox(height: 12),

                  // Citizen Validation Card (FE-06)
                  _buildCitizenValidationCard(context, report),
                  const SizedBox(height: 12),

                  // Progress Card
                  _buildProgressCard(status),
                  const SizedBox(height: 12),

                  // Estimasi Selesai Card
                  _buildEstimasiSelesaiCard(report),
                  const SizedBox(height: 12),

                  // Petugas Card
                  _buildPetugasCard(agencyName),
                  const SizedBox(height: 24),

                  // Foto Progres Terbaru
                  _buildFotoProgresTerbaru(context, photoUrl, dateStr, timeStr),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ElevatedButton.icon(
              onPressed: () {
                final Map<String, dynamic> detailArgs = report != null
                    ? {
                        'id': report.id,
                        'reportCode': report.reportCode,
                        'reportModel': report,
                        'imagePath': imagePath,
                      }
                    : Map<String, dynamic>.from(widget.reportData ?? {});
                if (imagePath != null && imagePath.isNotEmpty) {
                  detailArgs['imagePath'] = imagePath;
                }
                Navigator.pushNamed(
                  context,
                  '/report-detail',
                  arguments: detailArgs,
                );
              },
              icon: const Icon(Icons.remove_red_eye_rounded, size: 22),
              label: const Text(
                'Lihat Detail Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusInfo,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo Preview (Gambar laporan + Stamp Metadata) ────────────────────────
  Widget _buildPhotoPreview({
    required String? imagePath,
    required String photoUrl,
    required String location,
    required String coordinates,
    required String timestamp,
    required String reportId,
    required String title,
  }) {
    bool isLocalValid = false;
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        !imagePath.startsWith('http')) {
      try {
        isLocalValid = File(imagePath).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    Widget imageWidget;
    if (isLocalValid && imagePath != null) {
      imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImage(title),
      );
    } else if (photoUrl.isNotEmpty) {
      imageWidget = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImage(title),
      );
    } else {
      imageWidget = _placeholderImage(title);
    }

    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(child: imageWidget),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Metadata stamp
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenPrimary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'LaporKita',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _stampItem(Icons.location_on_outlined, location),
                    const SizedBox(height: 3),
                    _stampItem(Icons.access_time_outlined, timestamp),
                    const SizedBox(height: 3),
                    _stampItem(Icons.warning_amber_rounded, title),
                    const SizedBox(height: 3),
                    _stampItem(Icons.memory_outlined, coordinates),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage([String categoryTitle = '']) {
    return Image.network(
      ReportModel.getCategoryFallbackImage(categoryTitle),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.neutral50,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            size: 48,
            color: AppColors.greenPrimary,
          ),
        ),
      ),
    );
  }

  Widget _stampItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 11, color: Colors.white),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCitizenValidationCard(BuildContext context, ReportModel? report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.greenPrimary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_user_rounded,
                  color: AppColors.greenPrimary, size: 22),
              SizedBox(width: 8),
              Text(
                'Validasi Warga (Citizen Validation)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Apakah perbaikan di lokasi ini sudah sesuai? Berikan konfirmasi validasi warga Anda.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.neutral700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final reportId = report?.id ??
                    widget.reportData?['reportId'] as String? ??
                    widget.reportData?['id'] as String? ??
                    '';
                if (reportId.isEmpty) return;
                try {
                  final repo = context.read<ReportRepository>();
                  await repo.validateReport(reportId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Konfirmasi validasi warga berhasil dikirim!'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Validasi warga berhasil dikonfirmasi.'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'Konfirmasi Perbaikan Sesuai',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Card ────────────────────────────────────────────────────────────
  Widget _buildStatusCard(
      ReportStatus status, String statusText, String agencyName) {
    String desc;
    switch (status) {
      case ReportStatus.pendingVerification:
        desc = 'Laporan Anda sedang menunggu verifikasi oleh admin.';
        break;
      case ReportStatus.verified:
        desc = 'Laporan Anda telah diverifikasi dan siap ditugaskan.';
        break;
      case ReportStatus.assigned:
        desc = 'Laporan telah diteruskan ke $agencyName untuk ditangani.';
        break;
      case ReportStatus.inProgress:
        desc =
            'Petugas $agencyName sedang mengerjakan perbaikan di lokasi laporan Anda.';
        break;
      case ReportStatus.completed:
        desc = 'Pekerjaan telah selesai. Menunggu konfirmasi penyelesaian.';
        break;
      case ReportStatus.resolved:
        desc = 'Laporan telah terselesaikan. Terima kasih atas partisipasi Anda!';
        break;
      case ReportStatus.rejected:
        desc = 'Laporan ditolak. Silakan hubungi admin untuk informasi lebih lanjut.';
        break;
      case ReportStatus.disputed:
        desc = 'Laporan sedang dalam peninjauan ulang.';
        break;
    }

    Color statusColor;
    if (status == ReportStatus.completed || status == ReportStatus.resolved) {
      statusColor = AppColors.greenPrimary;
    } else if (status == ReportStatus.rejected) {
      statusColor = AppColors.statusDanger;
    } else {
      statusColor = const Color(0xFFF2AE01);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status saat ini',
            style: TextStyle(fontSize: 13, color: AppColors.neutral900),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Card ──────────────────────────────────────────────────────────
  Widget _buildProgressCard(ReportStatus status) {
    final value = _progressFromStatus(status);
    final label = _progressLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.neutral100,
              color: AppColors.greenPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Estimasi Selesai Card ──────────────────────────────────────────────────
  Widget _buildEstimasiSelesaiCard(ReportModel? report) {
    // Try to find estimasi from status history or use +7 days from creation
    String estimasiLabel;
    String estimasiDate;

    if (report != null) {
      // Check if there's an "estimasi" note in status history
      final historyNote = report.statusHistory
          .where((h) => h.note != null && h.note!.isNotEmpty)
          .map((h) => h.note!)
          .firstOrNull;

      if (historyNote != null && historyNote.contains('estimasi')) {
        estimasiDate = historyNote;
        estimasiLabel = 'Sesuai catatan petugas';
      } else {
        final est = report.createdAt.add(const Duration(days: 7));
        estimasiDate = _formatDate(est);
        final diff = est.difference(DateTime.now()).inDays;
        estimasiLabel = diff > 0 ? '$diff Hari Lagi' : 'Segera';
      }
    } else {
      estimasiDate = 'Belum ditentukan';
      estimasiLabel = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.greenPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.greenPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Selesai',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estimasiLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estimasiDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Petugas Card ───────────────────────────────────────────────────────────
  Widget _buildPetugasCard(String agencyName) {
    final agencyPhone =
        _report?.assignedAgency?['phone'] as String? ?? '+62 80878367243';
    final agencyType =
        _report?.assignedAgency?['type'] as String? ?? 'Dinas';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Petugas Penanganan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agencyName.isEmpty ? 'Belum ditugaskan' : agencyName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral900,
                  ),
                ),
                if (agencyType.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    agencyType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Kontak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.call_rounded,
                      size: 16,
                      color: AppColors.greenPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      agencyPhone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 28,
              color: AppColors.greenPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Foto Progres Terbaru ──────────────────────────────────────────────────
  Widget _buildFotoProgresTerbaru(
    BuildContext context,
    String reportPhotoUrl,
    String dateStr,
    String timeStr,
  ) {
    // Find latest progress photo from media list (type: progress_photo)
    final progressMedia = _report?.media
        .where((m) => m.type == 'progress_photo')
        .toList();

    final latestMedia =
        progressMedia?.isNotEmpty == true ? progressMedia!.last : null;

    String thumbUrl = reportPhotoUrl;
    String progressDateStr = '$dateStr. $timeStr';
    String progressLabel = 'Foto Laporan Awal';

    if (latestMedia != null) {
      final rawUrl = latestMedia.url;
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        thumbUrl = rawUrl;
      } else {
        thumbUrl = '${_report?.formattedPhotoUrl?.split('/api/v1').first ?? ''}$rawUrl';
      }
      final d = latestMedia.createdAt;
      progressDateStr =
          '${_formatDate(d)}. ${_formatTime(d)}';
      progressLabel = 'Sedang diperbaiki';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Progres Terbaru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbUrl.isNotEmpty
                    ? Image.network(
                        thumbUrl,
                        width: 100,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _progressPhotoPlaceholder(),
                      )
                    : _progressPhotoPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progressLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progressDateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: latestMedia != null
                      ? AppColors.greenPrimary
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  latestMedia != null ? 'Baru' : 'Awal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: latestMedia != null
                        ? AppColors.white
                        : AppColors.neutral900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              final Map<String, dynamic> fotoArgs =
                  Map<String, dynamic>.from(widget.reportData ?? {});
              if (_report != null) {
                fotoArgs['reportModel'] = _report;
                fotoArgs['id'] = _report!.id;
              }
              final imgPath = widget.reportData?['imagePath'] as String? ??
                  _report?.directPhotoUrl;
              if (imgPath != null && imgPath.isNotEmpty) {
                fotoArgs['imagePath'] = imgPath;
              }
              Navigator.pushNamed(context, '/foto-progress', arguments: fotoArgs);
            },
            child: const Text(
              'Lihat Semua Foto Progres',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.statusInfo,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressPhotoPlaceholder() {
    return Container(
      width: 100,
      height: 70,
      color: AppColors.neutral50,
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: AppColors.greenPrimary,
        size: 28,
      ),
    );
  }
}
