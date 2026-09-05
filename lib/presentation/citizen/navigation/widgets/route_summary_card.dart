import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/route_model.dart';

/// Kartu ringkasan rute yang menampilkan jarak tempuh dan estimasi waktu.
class RouteSummaryCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback? onReset;

  const RouteSummaryCard({
    super.key,
    required this.route,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Judul dan Tombol Reset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSuccess,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_rounded,
                      color: AppColors.greenPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Informasi Rute',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900,
                    ),
                  ),
                ],
              ),
              if (onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.neutral700,
                  ),
                  label: const Text(
                    'Ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),

          // Baris Statistik: Jarak & Estimasi Waktu
          Row(
            children: [
              // Kolom Jarak
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.straighten_rounded,
                        color: AppColors.greenPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jarak Tempuh',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            route.distanceKm,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Garis pemisah vertikal
              Container(
                width: 1,
                height: 38,
                color: AppColors.borderLight,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),

              // Kolom Estimasi Waktu
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.greenPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimasi Waktu',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            route.durationMinutes,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
