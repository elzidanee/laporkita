import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class FotoProgressScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const FotoProgressScreen({super.key, this.reportData});

  @override
  State<FotoProgressScreen> createState() => _FotoProgressScreenState();
}

class _FotoProgressScreenState extends State<FotoProgressScreen> {
  ReportModel? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final preloaded = widget.reportData?['reportModel'] as ReportModel?;
    if (preloaded != null) {
      setState(() {
        _report = preloaded;
        _isLoading = false;
      });
      _refreshFromApi(preloaded.id);
      return;
    }

    final reportId = widget.reportData?['reportId'] as String? ??
        widget.reportData?['id'] as String?;

    if (reportId == null || reportId.isEmpty || !reportId.contains('-')) {
      setState(() => _isLoading = false);
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
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';

  double _progressFromStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendingVerification: return 0.15;
      case ReportStatus.verified: return 0.30;
      case ReportStatus.assigned: return 0.50;
      case ReportStatus.inProgress: return 0.75;
      case ReportStatus.completed: return 0.95;
      case ReportStatus.resolved: return 1.0;
      case ReportStatus.rejected: return 0.0;
      case ReportStatus.disputed: return 0.50;
    }
  }

  String _buildAbsoluteUrl(String rawUrl) {
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    try {
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final host =
          '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      return rawUrl.startsWith('/') ? '$host$rawUrl' : '$host/$rawUrl';
    } catch (_) {
      return rawUrl;
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
          'Foto Progress',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.greenPrimary),
            onPressed: () {
              final id = _report?.id ??
                  widget.reportData?['reportId'] as String? ??
                  widget.reportData?['id'] as String?;
              if (id != null) {
                setState(() => _isLoading = true);
                _refreshFromApi(id);
              }
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
    final status = report?.status ?? ReportStatus.pendingVerification;
    final progressValue = _progressFromStatus(status);
    final progressLabel = '${(progressValue * 100).toInt()}%';

    // Estimasi Selesai
    String estimasiLabel = '-';
    String estimasiDate = 'Belum ditentukan';
    if (report != null) {
      final est = report.createdAt.add(const Duration(days: 7));
      estimasiDate = _formatDate(est);
      final diff = est.difference(DateTime.now()).inDays;
      estimasiLabel = diff > 0 ? '$diff Hari Lagi' : 'Segera';
    }

    // Kumpulkan semua media foto
    final List<ReportMediaModel> allMedia = report?.media ?? [];
    final List<ReportMediaModel> progressMedia = allMedia
        .where((m) => m.type == 'progress_photo')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final List<ReportMediaModel> initialMedia =
        allMedia.where((m) => m.type == 'initial_photo').toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estimasi Selesai Card
            _buildEstimasiSelesaiCard(estimasiLabel, estimasiDate),
            const SizedBox(height: 12),

            // Progress Card
            _buildProgressCard(progressLabel, progressValue),
            const SizedBox(height: 24),

            // Timeline Title
            const Text(
              'Timeline foto progres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 12),

            // Foto progress dari backend (progress_photo type)
            if (progressMedia.isNotEmpty) ...[
              ...progressMedia.asMap().entries.map((entry) {
                final idx = entry.key;
                final media = entry.value;
                final dt = media.createdAt;
                final dateStr = _formatDate(dt);
                final timeStr = _formatTime(dt);
                final pct =
                    (progressValue * 100 - idx * 12).clamp(0.0, 100.0).toInt();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTimelineItem(
                    date: '$dateStr | $timeStr',
                    progressText: 'Progres $pct%',
                    description: 'Foto progres penanganan laporan',
                    imageUrl: _buildAbsoluteUrl(media.url),
                    isNew: idx == 0,
                  ),
                );
              }),
            ],

            // Foto awal laporan sebagai item terakhir timeline
            if (initialMedia.isNotEmpty) ...[
              ...initialMedia.map((media) {
                final dt = media.createdAt;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTimelineItem(
                    date: '${_formatDate(dt)} | ${_formatTime(dt)}',
                    progressText: 'Foto Awal Laporan',
                    description: 'Foto saat laporan pertama kali dibuat',
                    imageUrl: _buildAbsoluteUrl(media.url),
                    isNew: false,
                  ),
                );
              }),
            ],

            // Jika tidak ada media sama sekali, tampilkan foto laporan utama sebagai fallback
            if (progressMedia.isEmpty && initialMedia.isEmpty && report != null)
              _buildTimelineItem(
                date: '${_formatDate(report.createdAt)} | ${_formatTime(report.createdAt)}',
                progressText: 'Foto Awal Laporan',
                description: 'Foto saat laporan pertama kali dibuat',
                imageUrl: report.formattedPhotoUrl ??
                    report.photoUrl ??
                    '',
                isNew: false,
              ),

            // Empty state jika benar-benar tidak ada foto
            if (report == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0DFDF)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 48, color: AppColors.neutral500),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada foto progres',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimasiSelesaiCard(String label, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
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
                  style: TextStyle(fontSize: 13, color: AppColors.neutral900),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.neutral900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
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

  Widget _buildTimelineItem({
    required String date,
    required String progressText,
    required String description,
    required String imageUrl,
    required bool isNew,
  }) {
    Widget imgWidget;
    if (imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http') &&
        File(imageUrl).existsSync()) {
      imgWidget = Image.file(
        File(imageUrl),
        width: 100,
        height: 80,
        fit: BoxFit.cover,
      );
    } else if (imageUrl.isNotEmpty) {
      imgWidget = Image.network(
        imageUrl,
        width: 100,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _photoPlaceholder(),
      );
    } else {
      imgWidget = _photoPlaceholder();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
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
            child: imgWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progressText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Baru',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder([String categoryName = '']) {
    return Image.network(
      ReportModel.getCategoryFallbackImage(categoryName),
      width: 100,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 100,
        height: 80,
        color: const Color(0xFFF0F4F8),
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.greenPrimary,
          size: 28,
        ),
      ),
    );
  }
}
