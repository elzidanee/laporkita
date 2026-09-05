import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Top bar pemilihan rute (Figma 454:2 & 471:4186).
/// Menampilkan input Lokasi Asal dan Tujuan dengan tombol kembali dan tukar posisi.
class NavigationTopBar extends StatelessWidget {
  final String originText;
  final String destinationText;
  final VoidCallback onBack;
  final VoidCallback onSwap;
  final VoidCallback? onTapOrigin;
  final VoidCallback? onTapDestination;

  const NavigationTopBar({
    super.key,
    required this.originText,
    required this.destinationText,
    required this.onBack,
    required this.onSwap,
    this.onTapOrigin,
    this.onTapDestination,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.statusInfo,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Kolom Input Asal & Tujuan dengan Garis Penghubung
          Expanded(
            child: Stack(
              children: [
                // Garis vertikal penghubung icon
                Positioned(
                  left: 20,
                  top: 24,
                  bottom: 24,
                  child: Container(
                    width: 1.5,
                    color: AppColors.neutral300,
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Input 1: Asal
                    GestureDetector(
                      onTap: onTapOrigin,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.statusInfo,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                originText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input 2: Tujuan
                    GestureDetector(
                      onTap: onTapDestination,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.statusInfo,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                destinationText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Swap / Tukar Posisi
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onSwap,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: AppColors.statusInfo,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
