import 'package:flutter/material.dart';
import 'package:laporkita/core/theme/app_colors.dart';

class CitizenNotifikasiTab extends StatelessWidget {
  const CitizenNotifikasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Card 1: Perbaikan dimulai (Blue Container)
            _buildNotifCard(
              title: 'Perbaikan dimulai',
              message: 'Laporan #LP_2026_002487 sedang dikerjakan oleh petugas.',
              time: '10.46',
              icon: Icons.notifications_active_outlined,
              iconColor: AppColors.statusInfo,
              bgColor: const Color(0xFFE4F2FF),
              borderColor: const Color(0xFFABD5FF),
              isUnread: true,
            ),
            const SizedBox(height: 12),

            // Card 2: Laporan anda diverifikasi
            _buildNotifCard(
              title: 'Laporan anda diverifikasi',
              message: 'Laporan #LP_2026_002487 telah diverifikasi.',
              time: '07.23',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.greenPrimary,
              bgColor: AppColors.white,
              borderColor: AppColors.neutral200,
              isUnread: false,
            ),
            const SizedBox(height: 12),

            // Card 3: Perbaikan selesai
            _buildNotifCard(
              title: 'Perbaikan selesai',
              message: 'Laporan #LP_2026_002328 telah selesai diperbaiki',
              time: 'Kemarin',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.greenPrimary,
              bgColor: AppColors.white,
              borderColor: AppColors.neutral200,
              isUnread: false,
            ),
            const SizedBox(height: 12),

            // Card 4: Permintaan informasi tambahan
            _buildNotifCard(
              title: 'Permintaan informasi tambahan',
              message: 'Mohon lengkapi informasi pada laporan #LP_2026_002328',
              time: '3 hari lalu',
              icon: Icons.error_outline_rounded,
              iconColor: AppColors.statusWarning,
              bgColor: AppColors.white,
              borderColor: AppColors.neutral200,
              isUnread: false,
            ),
            const SizedBox(height: 80), // Padding for floating navbar
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
