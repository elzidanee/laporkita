import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';

class SimilarReportScreen extends StatelessWidget {
  const SimilarReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final List<ReportModel>? similarReports =
        args?['similarReports'] as List<ReportModel>?;

    final String categoryArg = (args?['category'] as String?) ?? 'Laporan Fasilitas';
    final String locationArg = (args?['location'] as String?) ?? 'Malang';
    final String timestampArg = (args?['timestamp'] as String?) ?? 'Baru saja';

    String reportTitle = categoryArg;
    String reportAddress = locationArg;
    String reportDate = timestampArg;
    String supportsText = '0 Dukungan';
    String statusText = 'Menunggu Verifikasi';
    String? photoUrl;

    if (similarReports != null && similarReports.isNotEmpty) {
      final report = similarReports.first;
      reportTitle = report.categoryName;
      reportAddress = report.addressText ?? locationArg;
      reportDate =
          '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}';
      supportsText = '${report.supportCount} Dukungan';
      statusText = report.status.displayName;
      photoUrl = report.formattedPhotoUrl ?? report.photoUrl;
    }

    // Mengutamakan foto terbaru yang baru saja diambil/diinputkan oleh user
    final String? userPhotoPath = args?['imagePath'] as String? ??
        args?['photoPath'] as String? ??
        args?['directPhotoUrl'] as String? ??
        args?['photoUrl'] as String?;

    bool isLocalValid = false;
    if (userPhotoPath != null &&
        userPhotoPath.isNotEmpty &&
        !userPhotoPath.startsWith('http')) {
      try {
        isLocalValid = File(userPhotoPath).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    Widget cardImageWidget;
    if (isLocalValid && userPhotoPath != null) {
      cardImageWidget = Image.file(
        File(userPhotoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.amber.shade100,
          child: const Icon(
            Icons.alt_route_rounded,
            color: Color(0xFFE68A00),
            size: 32,
          ),
        ),
      );
    } else if (userPhotoPath != null &&
        userPhotoPath.isNotEmpty &&
        userPhotoPath.startsWith('http')) {
      cardImageWidget = Image.network(
        userPhotoPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.amber.shade100,
          child: const Icon(
            Icons.alt_route_rounded,
            color: Color(0xFFE68A00),
            size: 32,
          ),
        ),
      );
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      cardImageWidget = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.amber.shade100,
          child: const Icon(
            Icons.alt_route_rounded,
            color: Color(0xFFE68A00),
            size: 32,
          ),
        ),
      );
    } else {
      cardImageWidget = Container(
        color: Colors.amber.shade100,
        child: const Icon(
          Icons.alt_route_rounded,
          color: Color(0xFFE68A00),
          size: 32,
        ),
      );
    }

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
          'Deteksi laporan serupa',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. AI Warning Alert Box (Yellow Background)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE599)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5A623),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'AI menemukan laporan serupa disekitar lokasi anda',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Untuk menghindari laporan ganda, silahkan tinjau laporan berikut.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Section Header
                    const Text(
                      'Laporan Paling mirip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Similar Report Card Item
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 80,
                              height: 64,
                              child: cardImageWidget,
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
                                        reportTitle,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.neutral900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      reportDate,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reportAddress,
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
                                      supportsText,
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
                                            color: const Color(0xFFFFF8E6),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFE68A00),
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
                    const SizedBox(height: 16),

                    // 4. Similarity Percentage Progress Bar Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Tingkat kesamaan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              Text(
                                '90%',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE68A00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              value: 0.90,
                              minHeight: 8,
                              backgroundColor: AppColors.neutral100,
                              color: Color(0xFFE68A00),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Perhitungan berdasarkan lokasi, foto, dan kategori kerusakan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Bottom Action Button: Lanjut
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/report-confirmation',
                    arguments: args,
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
                  'Lanjut',
                  style: TextStyle(
                    fontSize: 16,
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
}
