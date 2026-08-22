import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract passed arguments if any (e.g. {'isSupportOnly': true})
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isSupportOnly = args?['isSupportOnly'] as bool? ?? true;

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

                    // Title: Terimakasih!
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
                              children: const [
                                Text(
                                  'ID Laporan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '#LP_2026_002487',
                                  style: TextStyle(
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ID Laporan berhasil disalin!'),
                                  backgroundColor: AppColors.greenPrimary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Report Summary Card
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
                            child: Container(
                              width: 80,
                              height: 64,
                              color: Colors.amber.shade100,
                              child: const Icon(
                                Icons.alt_route_rounded,
                                color: Color(0xFFE68A00),
                                size: 32,
                              ),
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
                                  children: const [
                                    Text(
                                      'Jalan Rusak',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    Text(
                                      '12 Mei 2026',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Jl. Ahmad Yani no. 15',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '360 Dukungan',
                                      style: TextStyle(
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
                                          child: const Text(
                                            'Sedang Diproses',
                                            style: TextStyle(
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
                  ],
                ),
              ),

              // Action Buttons Column
              Column(
                children: [
                  // Button 1: Lihat Tracking
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tracking-progress');
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
