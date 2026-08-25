import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';

class ReportSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const ReportSuccessScreen({super.key, this.reportData});

  @override
  Widget build(BuildContext context) {
    // --- Extract data from arguments ---
    final args = reportData ??
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final isSupportOnly = args?['isSupportOnly'] as bool? ?? true;
    final ReportModel? report = args?['report'] as ReportModel?;

    final String? imagePath = args?['imagePath'] as String? ??
        args?['photoPath'] as String? ??
        report?.directPhotoUrl;

    // Derived values from report model
    final reportCode = report?.reportCode.isNotEmpty == true
        ? report!.reportCode
        : (args?['reportId'] as String? ?? '#LP-2026-002487');
    final title = report?.categoryName ?? (args?['title'] as String? ?? 'Laporan');
    final address = report?.addressText ?? (args?['address'] as String? ?? '-');
    final statusText =
        report?.status.displayName ?? (args?['status'] as String? ?? 'Menunggu Verifikasi');
    final supportCount = report?.supportCount ?? 0;

    final photoUrl = report?.formattedPhotoUrl ?? report?.photoUrl;

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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/citizen',
            (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Green Verified Badge Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.greenPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 56,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Terimakasih!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      isSupportOnly
                          ? 'Anda telah mendukung laporan\nberikut.'
                          : 'Laporan Anda telah berhasil\nterkirim!',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.neutral900,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Report ID Box with Copy Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 28,
                            color: AppColors.neutral900,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ID Laporan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reportCode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 20,
                              color: AppColors.neutral900,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: reportCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('ID Laporan berhasil disalin!'),
                                  backgroundColor: AppColors.greenPrimary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Report Summary Card (real data)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Foto mini
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 80,
                              height: 64,
                              child: () {
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
                                if (isLocalValid && imagePath != null) {
                                  return Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: AppColors.neutral100),
                                  );
                                } else if (photoUrl != null && photoUrl.isNotEmpty) {
                                  return Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: AppColors.neutral100),
                                  );
                                } else {
                                  return Container(
                                    color: AppColors.neutral50,
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: AppColors.greenPrimary,
                                      size: 28,
                                    ),
                                  );
                                }
                              }(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.neutral900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$supportCount Dukungan',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.greenPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceWarning,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.statusWarning,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 20,
                                          color: AppColors.neutral900,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons Column
              Column(
                children: [
                  // Button 1: Lihat Tracking
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/tracking-progress',
                        arguments: {
                          'reportId': report?.id,
                          'reportCode': report?.reportCode,
                          'reportModel': report,
                          'imagePath': imagePath,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenPrimary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 2: Kembali ke Beranda
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/citizen',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neutral900,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.neutral900),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
