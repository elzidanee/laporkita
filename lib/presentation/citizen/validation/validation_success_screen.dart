import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Layar Berhasil Kirim Validasi — Presisi Sesuai Figma (Node 234:1368)
class ValidationSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const ValidationSuccessScreen({super.key, this.reportData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // 1. Back button in top-left
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.neutral900,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/citizen',
                      (route) => false,
                    );
                  },
                ),
              ),

              const Spacer(),

              // 2. Center Content: Success Icon (126px) + Title + Subtitle
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large Success Icon (Figma node 234:1440)
                    Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2FFD6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greenPrimary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.greenPrimary,
                          size: 96,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Title: Terimakasih! (Figma node 234:1380)
                    const Text(
                      'Terimakasih!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                        letterSpacing: 0.46,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Description Subtitle (Figma node 234:1381)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Validasi Anda telah berhasil dikirim dan tersimpan di sistem LaporKita untuk memastikan kualitas fasilitas publik di Kota Malang.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF515151),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 3. Bottom Button: Kembali ke Beranda (Figma node 234:1374)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/citizen',
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF565657), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    foregroundColor: AppColors.neutral900,
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
