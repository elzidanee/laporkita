import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum NavigationBannerState {
  turnByTurn,
  hazardApproaching,
  hazardPassed,
}

/// Banner atas saat navigasi aktif (Figma 462:126, 464:837, 471:1467).
class NavigationActiveTopBanner extends StatelessWidget {
  final NavigationBannerState state;
  final String distanceText;
  final String primaryText;
  final String secondaryText;
  final IconData maneuverIcon;
  final VoidCallback? onMicTap;

  const NavigationActiveTopBanner({
    super.key,
    required this.state,
    required this.distanceText,
    required this.primaryText,
    required this.secondaryText,
    this.maneuverIcon = Icons.turn_left_rounded,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      margin: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.greenPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kolom Ikon & Jarak
          if (state == NavigationBannerState.hazardApproaching) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppColors.statusPending,
                size: 38,
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  maneuverIcon,
                  color: AppColors.white,
                  size: 32,
                ),
                const SizedBox(height: 2),
                Text(
                  distanceText,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
          ],

          // Informasi Arah / Peringatan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primaryText,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: state == NavigationBannerState.hazardApproaching ? 20 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  secondaryText,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Tombol Mic / Suara (pada state turn-by-turn)
          if (state == NavigationBannerState.turnByTurn) ...[
            const SizedBox(width: 8),
            Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onMicTap,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.mic_rounded,
                    color: AppColors.statusInfo,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
