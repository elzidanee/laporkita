import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RouteOptionItem {
  final int index;
  final String title;
  final String riskTitle;
  final String durationKm;
  final String warningCountText;
  final Color riskColor;
  final int warnings;

  const RouteOptionItem({
    required this.index,
    required this.title,
    required this.riskTitle,
    required this.durationKm,
    required this.warningCountText,
    required this.riskColor,
    required this.warnings,
  });
}

/// Bottom Sheet daftar rute (Figma 454:2 & 471:4186).
class NavigationRouteSheet extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectRoute;
  final bool showRiskBadges;

  const NavigationRouteSheet({
    super.key,
    required this.selectedIndex,
    required this.onSelectRoute,
    this.showRiskBadges = true,
  });

  static const List<RouteOptionItem> defaultRoutes = [
    RouteOptionItem(
      index: 0,
      title: 'Rute Tercepat',
      riskTitle: 'Rute awal (ada resiko)',
      durationKm: '12 mnt - 4,6 km',
      warningCountText: '2 peringatan',
      riskColor: AppColors.statusDanger,
      warnings: 2,
    ),
    RouteOptionItem(
      index: 1,
      title: 'Rute Alternatif',
      riskTitle: 'Rute Alternatif 1 (lebih aman)',
      durationKm: '14 mnt - 5,1 km',
      warningCountText: '0 peringatan',
      riskColor: AppColors.greenPrimary,
      warnings: 0,
    ),
    RouteOptionItem(
      index: 2,
      title: 'Hindari Jalan Rusak',
      riskTitle: 'Hindari Alternatif 2',
      durationKm: '15 mnt - 5,6 km',
      warningCountText: '1 peringatan',
      riskColor: AppColors.statusPending,
      warnings: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 54,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Daftar 3 Kartu Rute
          ...defaultRoutes.map((route) {
            final isSelected = selectedIndex == route.index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelectRoute(route.index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.greenPrimary : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.greenPrimary.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ikon Kiri: Mobil atau Segitiga Resiko
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (showRiskBadges
                                  ? route.riskColor.withValues(alpha: 0.1)
                                  : AppColors.surfaceSuccess)
                              : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: showRiskBadges
                            ? Icon(
                                Icons.warning_rounded,
                                color: route.riskColor,
                                size: 28,
                              )
                            : const Icon(
                                Icons.directions_car_rounded,
                                color: AppColors.neutral900,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 14),

                      // Deskripsi Rute & Waktu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              showRiskBadges ? route.riskTitle : route.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              showRiskBadges
                                  ? '${route.durationKm} - ${route.warningCountText}'
                                  : route.durationKm,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.neutral700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Radio check indicator
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.greenPrimary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
