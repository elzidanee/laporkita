import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom bar saat navigasi aktif (Figma 462:126 & 471:1467).
class NavigationActiveBottomBar extends StatelessWidget {
  final String durationText;
  final String distanceEtaText;
  final VoidCallback onClose;
  final VoidCallback onRoutesToggle;

  const NavigationActiveBottomBar({
    super.key,
    required this.durationText,
    required this.distanceEtaText,
    required this.onClose,
    required this.onRoutesToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Batal / Keluar Navigasi (X)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neutral300, width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.neutral900,
                  size: 26,
                ),
              ),
            ),
          ),

          // Informasi Utama: Durasi Besar & Jarak - ETA
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                distanceEtaText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),

          // Tombol Pilihan Alternatif / Rute (Forked Arrow)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neutral300, width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRoutesToggle,
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: AppColors.neutral900,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
