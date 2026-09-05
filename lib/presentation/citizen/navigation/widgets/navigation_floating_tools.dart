import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Kolom tombol aksi mengapung di sisi kanan peta (Figma 454:2, 462:126, dll).
class NavigationFloatingTools extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleLayers;
  final VoidCallback onCompass;
  final VoidCallback? onMyLocation;
  final bool isSoundMuted;

  const NavigationFloatingTools({
    super.key,
    required this.onSearch,
    required this.onToggleSound,
    required this.onToggleLayers,
    required this.onCompass,
    this.onMyLocation,
    this.isSoundMuted = false,
  });

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            color: AppColors.neutral900,
            size: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Search
        _buildCircleButton(
          icon: Icons.search_rounded,
          onTap: onSearch,
        ),

        // 2. Sound
        _buildCircleButton(
          icon: isSoundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          onTap: onToggleSound,
        ),

        // 3. Layers
        _buildCircleButton(
          icon: Icons.layers_rounded,
          onTap: onToggleLayers,
        ),

        // 4. Compass
        _buildCircleButton(
          icon: Icons.explore_rounded,
          onTap: onCompass,
        ),

        // 5. My Location (GPS)
        if (onMyLocation != null)
          _buildCircleButton(
            icon: Icons.my_location_rounded,
            onTap: onMyLocation!,
          ),
      ],
    );
  }
}
