import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../tracking/tracking_progress_screen.dart';

class CitizenSupportedReportsScreen extends StatefulWidget {
  const CitizenSupportedReportsScreen({super.key});

  @override
  State<CitizenSupportedReportsScreen> createState() =>
      _CitizenSupportedReportsScreenState();
}

class _CitizenSupportedReportsScreenState
    extends State<CitizenSupportedReportsScreen> {
  bool _isLoading = true;
  List<ReportModel> _supportedReports = [];

  @override
  void initState() {
    super.initState();
    _fetchSupportedReports();
  }

  Future<void> _fetchSupportedReports() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      List<ReportModel> all = [];
      try {
        final res = await repo.getReports(limit: 100);
        all = res.data ?? [];
      } catch (_) {
        all = repo.localSubmittedReports;
      }

      if (all.isEmpty) {
        all = repo.localSubmittedReports;
      }

      // Filter laporan yang didukung oleh user
      final supported = all.where((r) {
        return repo.isReportSupported(r.id) ||
            repo.isReportSupported(r.reportCode) ||
            repo.isReportSupported(r.formattedReportCode);
      }).toList();

      if (mounted) {
        setState(() {
          _supportedReports = supported;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildStatusPill(ReportStatus status) {
    Color bg;
    Color text;
    switch (status) {
      case ReportStatus.completed:
      case ReportStatus.resolved:
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF1D9C51);
        break;
      case ReportStatus.inProgress:
      case ReportStatus.assigned:
      case ReportStatus.verified:
        bg = const Color(0xFFFFF9E9);
        text = const Color(0xFFF2AE01);
        break;
      case ReportStatus.rejected:
      case ReportStatus.disputed:
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC60D05);
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        text = const Color(0xFF757575);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildThumbnail(ReportModel report) {
    final photo = report.formattedPhotoUrl ?? report.directPhotoUrl;
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http')) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.neutral400,
          ),
        );
      }
      final file = File(photo);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.neutral400,
          ),
        );
      }
    }
    return const Icon(
      Icons.assignment_outlined,
      color: AppColors.greenPrimary,
      size: 28,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.thumb_up_alt_rounded,
                size: 64,
                color: AppColors.greenPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Dukungan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Anda belum memberikan dukungan pada laporan manapun. Berikan dukungan pada laporan warga sekitar untuk mempercepat penanganan fasilitas umum.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Jelajahi Laporan Sekitar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
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
          'Dukungan Saya',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.greenPrimary))
          : _supportedReports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.greenPrimary,
                  onRefresh: _fetchSupportedReports,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    itemCount: _supportedReports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = _supportedReports[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrackingProgressScreen(
                                reportData: {'reportModel': item},
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.neutral200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenPrimary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.formattedReportCode,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.greenPrimary,
                                      ),
                                    ),
                                  ),
                                  _buildStatusPill(item.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      color: AppColors.neutral100,
                                      child: _buildThumbnail(item),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.categoryName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.neutral900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.addressText ??
                                              'Malang, Jawa Timur',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.neutral500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(item.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.neutral400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.thumb_up_alt_rounded,
                                          size: 14,
                                          color: AppColors.greenPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Didukung oleh Anda (${item.supportCount} total)',
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
