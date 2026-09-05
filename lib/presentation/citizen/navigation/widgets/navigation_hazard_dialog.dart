import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal peringatan kedekatan jalan rusak (Figma 464:837).
class NavigationHazardDialog extends StatelessWidget {
  final String title;
  final String distanceRemaining;
  final String streetName;
  final String severityLevel;
  final VoidCallback onViewDetail;
  final VoidCallback onDismiss;

  const NavigationHazardDialog({
    super.key,
    this.title = 'Jalan Berlubang',
    this.distanceRemaining = '10 meter lagi',
    this.streetName = 'Jl. Soekarno Hatta',
    this.severityLevel = 'Sedang',
    required this.onViewDetail,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon Segitiga Kuning & Tombol Tutup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppColors.statusPending,
                size: 38,
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, color: AppColors.neutral500),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Judul Bahaya
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),

          // Jarak Tersisa
          Text(
            distanceRemaining,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 16),

          // Nama Jalan
          Text(
            streetName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),

          // Tingkat Keparahan
          Text(
            'Tingkat : $severityLevel',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.statusPending,
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Lihat Detail
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onViewDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Lihat Detail',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
