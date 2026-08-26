import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laporkita/core/services/notification_service.dart';
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
  bool _isCheckingProximity = false;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService().initialize();
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

  Future<void> _handleTestRouteAlert() async {
    setState(() => _isCheckingProximity = true);
    try {
      final repository = context.read<NotificationRepository>();

      // 1. Subscribe Route Alert dengan token dummy/fcm
      await repository.subscribeRouteAlert(
        deviceToken: 'fcm_device_token_demo_laporkita',
        lastLat: -7.9827,
        lastLng: 112.6304,
      );

      // 2. Trigger check proximity ke backend NestJS
      await repository.checkProximityAlert();

      // 3. Tampilkan Notifikasi Popup Lokal di HP
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '⚠️ Route Alert: Peringatan Area Rute',
        body: 'Terdapat laporan kerusakan jalan di sekitar lokasi rute Anda (Jl. Sawojajar).',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uji coba Route Alert berhasil! Notifikasi dikirim.'),
          backgroundColor: AppColors.greenPrimary,
        ),
      );

      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghubungkan Route Alert ke server: $e'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingProximity = false);
    }
  }

  Future<void> _handleMarkAllRead() async {
    setState(() => _isMarkingAllRead = true);
    try {
      final repository = context.read<NotificationRepository>();
      await repository.markAllAsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai telah dibaca.'),
          backgroundColor: AppColors.greenPrimary,
        ),
      );
      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status notifikasi: $e'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _handleMarkSingleRead(String id) async {
    try {
      final repository = context.read<NotificationRepository>();
      await repository.markAsRead(id);
      _loadNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi & Route Alert',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tandai Semua Dibaca',
            icon: _isMarkingAllRead
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.greenPrimary),
                  )
                : const Icon(Icons.done_all_rounded,
                    color: AppColors.greenPrimary),
            onPressed: _isMarkingAllRead ? null : _handleMarkAllRead,
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadNotifications(),
          color: AppColors.greenPrimary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Banner Uji Coba Route Alert & Push Notif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInfo,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.statusInfo.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.alt_route_rounded,
                            color: AppColors.statusInfo, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Route Alert & FCM Push',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusInfo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Peringatan otomatis saat ada bahaya/kerusakan di sekitar rute jalan Anda.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingProximity ? null : _handleTestRouteAlert,
                        icon: _isCheckingProximity
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.notifications_active, size: 18),
                        label: Text(
                          _isCheckingProximity
                              ? 'Mengecek Proximity...'
                              : 'Uji Coba Route Alert & Notifikasi',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusInfo,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Subheader Daftar Notifikasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Notifikasi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  TextButton(
                    onPressed: _handleMarkAllRead,
                    child: const Text(
                      'Tandai Dibaca',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greenPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // FutureBuilder untuk daftar notifikasi live / fallback
              FutureBuilder<List<NotificationModel>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.greenPrimary,
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    // Tampilan item bawaan
                    return Column(
                      children: [
                        _buildNotifCard(
                          id: 'demo-1',
                          title: 'Perbaikan dimulai',
                          message:
                              'Laporan #LP_2026_002487 sedang dikerjakan oleh petugas.',
                          time: '10.46',
                          icon: Icons.notifications_active_outlined,
                          iconColor: AppColors.statusInfo,
                          bgColor: const Color(0xFFE4F2FF),
                          borderColor: const Color(0xFFABD5FF),
                          isUnread: true,
                        ),
                        const SizedBox(height: 12),
                        _buildNotifCard(
                          id: 'demo-2',
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
                          id: 'demo-3',
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
                          id: 'demo-4',
                          title: 'Permintaan informasi tambahan',
                          message:
                              'Mohon lengkapi informasi pada laporan #LP_2026_002328',
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

                  return Column(
                    children: [
                      for (final item in items) ...[
                        _buildNotifCard(
                          id: item.id,
                          title: item.title,
                          message: item.message,
                          time:
                              '${item.createdAt.hour.toString().padLeft(2, '0')}.${item.createdAt.minute.toString().padLeft(2, '0')}',
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
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard({
    required String id,
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool isUnread,
  }) {
    return GestureDetector(
      onTap: () => _handleMarkSingleRead(id),
      child: Container(
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
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.w600,
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
      ),
    );
  }
}
