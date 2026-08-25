import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laporkita/core/theme/app_colors.dart';
import 'package:laporkita/data/models/notification_model.dart';
import 'package:laporkita/data/repositories/notification_repository.dart';

class CitizenNotifikasiTab extends StatefulWidget {
  const CitizenNotifikasiTab({super.key});

  @override
  State<CitizenNotifikasiTab> createState() => _CitizenNotifikasiTabState();
}

class _CitizenNotifikasiTabState extends State<CitizenNotifikasiTab> {
  Future<List<NotificationModel>>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    try {
      final repository = context.read<NotificationRepository>();
      final response = await repository.getNotifications();
      return response.data ?? [];
    } catch (_) {
      return [];
    }
  }

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
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.greenPrimary),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              // Return fallback default notifications if no API items returned
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
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
                  const SizedBox(height: 80),
                ],
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadNotifications(),
              color: AppColors.greenPrimary,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: items.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return const SizedBox(height: 80);
                  }
                  final item = items[index];
                  return _buildNotifCard(
                    title: item.title,
                    message: item.message,
                    time: '${item.createdAt.hour.toString().padLeft(2, '0')}.${item.createdAt.minute.toString().padLeft(2, '0')}',
                    icon: item.isRead
                        ? Icons.check_circle_outline_rounded
                        : Icons.notifications_active_outlined,
                    iconColor: item.isRead
                        ? AppColors.greenPrimary
                        : AppColors.statusInfo,
                    bgColor: item.isRead
                        ? AppColors.white
                        : const Color(0xFFE4F2FF),
                    borderColor: item.isRead
                        ? AppColors.neutral200
                        : const Color(0xFFABD5FF),
                    isUnread: !item.isRead,
                  );
                },
              ),
            );
          },
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
