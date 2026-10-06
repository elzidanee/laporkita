import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_report_detail_screen.dart';

class OperatorNotifikasiScreen extends StatefulWidget {
  const OperatorNotifikasiScreen({super.key});

  @override
  State<OperatorNotifikasiScreen> createState() => _OperatorNotifikasiScreenState();
}

class _OperatorNotifikasiScreenState extends State<OperatorNotifikasiScreen> {
  bool _isLoading = true;
  List<ReportModel> _operatorReports = [];
  final Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _fetchOperatorNotifications();
  }

  Future<void> _fetchOperatorNotifications() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getReports(limit: 50);
      final list = res.data ?? [];

      // Filter laporan yang relevan bagi operator (assigned, in_progress, completed, disputed)
      final relevant = list.where((r) =>
          r.status == ReportStatus.assigned ||
          r.status == ReportStatus.inProgress ||
          r.status == ReportStatus.completed ||
          r.status == ReportStatus.disputed ||
          r.status == ReportStatus.verified).toList();

      relevant.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (mounted) {
        setState(() {
          _operatorReports = relevant;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} m lalu';
    } else if (diff.inHours < 24) {
      final h = dt.toLocal().hour.toString().padLeft(2, '0');
      final m = dt.toLocal().minute.toString().padLeft(2, '0');
      return '$h.$m WIB';
    } else if (diff.inDays <= 1) {
      return 'Kemarin';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.greenPrimary))
            : RefreshIndicator(
                onRefresh: _fetchOperatorNotifications,
                color: AppColors.greenPrimary,
                child: _operatorReports.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada notifikasi tugas baru',
                                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        itemCount: _operatorReports.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = _operatorReports[index];
                          final id = 'op-notif-${r.id}-${r.status.apiValue}';
                          final isUnread = !_readIds.contains(id);

                          IconData iconData;
                          Color iconColor;
                          String title;
                          String subtitle = r.formattedReportCode;

                          switch (r.status) {
                            case ReportStatus.assigned:
                              iconData = Icons.assignment_outlined;
                              iconColor = const Color(0xFFF2AE01);
                              title = 'Tugas Baru Diterima';
                              subtitle = 'Laporan ${r.formattedReportCode} telah ditugaskan ke dinas Anda.';
                              break;
                            case ReportStatus.inProgress:
                              iconData = Icons.build_outlined;
                              iconColor = const Color(0xFF1976D2);
                              title = 'Pekerjaan Sedang Berlangsung';
                              subtitle = 'Laporan ${r.formattedReportCode} sedang dalam penanganan.';
                              break;
                            case ReportStatus.completed:
                              iconData = Icons.check_circle_outline_rounded;
                              iconColor = const Color(0xFF1D9C51);
                              title = 'Menunggu Validasi Warga';
                              subtitle = 'Perbaikan ${r.formattedReportCode} tuntas, menunggu konfirmasi warga.';
                              break;
                            case ReportStatus.disputed:
                              iconData = Icons.error_outline_rounded;
                              iconColor = const Color(0xFFEF4444);
                              title = 'Perbaikan Perlu Ditinjau Ulang';
                              subtitle = 'Warga mengajukan sanggahan pada ${r.formattedReportCode}.';
                              break;
                            default:
                              iconData = Icons.info_outline_rounded;
                              iconColor = const Color(0xFF1976D2);
                              title = 'Status Laporan Diperbarui';
                              break;
                          }

                          return _buildNotificationCard(
                            icon: iconData,
                            iconColor: iconColor,
                            title: title,
                            subtitle: subtitle,
                            time: _formatRelativeTime(r.updatedAt),
                            isHighlighted: isUnread && index == 0,
                            onTap: () {
                              setState(() => _readIds.add(id));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OperatorReportDetailScreen(
                                    report: r,
                                    onStatusUpdated: _fetchOperatorNotifications,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFE8F4FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? const Color(0xFFB5DCFB) : const Color(0xFFE0DFDF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
