import 'package:flutter/material.dart';
import 'package:laporkita/core/theme/app_colors.dart';

class CitizenLaporTab extends StatelessWidget {
  const CitizenLaporTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 64,
                color: AppColors.greenPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Citizen Vision AI Camera',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ambil foto masalah publik di sekitarmu, AI LaporKita akan mendeteksi otomatis kategori & lokasimu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              icon: const Icon(Icons.camera),
              label: const Text('Buka Kamera Lapor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
