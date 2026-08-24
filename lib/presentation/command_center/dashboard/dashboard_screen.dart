import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';

class CommandCenterDashboard extends StatelessWidget {
  const CommandCenterDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center Dashboard'),
        backgroundColor: AppColors.greenDark, // Distinct header for admin/command center
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                  context, '/get-started', (route) => false);
            },
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.greenLight,
                  child: Icon(Icons.admin_panel_settings, color: AppColors.greenDark),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang, Admin',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Pemerintah Kota LaporKita',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Grid (2x2)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  context,
                  title: 'Menunggu Verifikasi',
                  value: '18',
                  color: AppColors.statusPending,
                  icon: Icons.hourglass_empty,
                ),
                _buildStatCard(
                  context,
                  title: 'Sedang Diproses',
                  value: '42',
                  color: AppColors.statusInfo,
                  icon: Icons.sync,
                ),
                _buildStatCard(
                  context,
                  title: 'Laporan Selesai',
                  value: '143',
                  color: AppColors.greenPrimary,
                  icon: Icons.check_circle_outline,
                ),
                _buildStatCard(
                  context,
                  title: 'Total Pengaduan',
                  value: '203',
                  color: AppColors.neutral900,
                  icon: Icons.assignment_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Reports List
            Text(
              'Laporan Terbaru Masuk',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            _buildReportListItem(
              context,
              title: 'Jalan Berlubang Parah',
              location: 'Kec. Sukolilo, Jl. Toyiban No. 13',
              time: '5 menit yang lalu',
              status: 'Menunggu Verifikasi',
              statusColor: AppColors.statusPending,
            ),
            _buildReportListItem(
              context,
              title: 'Penerangan Jalan Mati',
              location: 'Kec. Gubeng, Jl. Dharmawangsa',
              time: '20 menit yang lalu',
              status: 'Sedang Diproses',
              statusColor: AppColors.statusInfo,
            ),
            _buildReportListItem(
              context,
              title: 'Sampah Menumpuk di Sungai',
              location: 'Kec. Wonokromo, Bantaran Kali Mas',
              time: '1 jam yang lalu',
              status: 'Selesai',
              statusColor: AppColors.greenPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: color,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportListItem(
    BuildContext context, {
    required String title,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.report_problem_outlined, color: statusColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
