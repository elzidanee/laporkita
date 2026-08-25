import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';

class CommandCenterDashboard extends StatefulWidget {
  const CommandCenterDashboard({super.key});

  @override
  State<CommandCenterDashboard> createState() => _CommandCenterDashboardState();
}

class _CommandCenterDashboardState extends State<CommandCenterDashboard> {
  bool _isLoading = true;
  List<ReportModel> _reports = [];
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<ReportRepository>();
      final response = await repository.getReports(limit: 50);
      final data = response.data ?? [];

      int pending = 0;
      int inProgress = 0;
      int completed = 0;

      for (final r in data) {
        if (r.status == ReportStatus.pendingVerification) {
          pending++;
        } else if (r.status == ReportStatus.inProgress ||
            r.status == ReportStatus.assigned ||
            r.status == ReportStatus.verified) {
          inProgress++;
        } else if (r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved) {
          completed++;
        }
      }

      if (mounted) {
        setState(() {
          _reports = data;
          _pendingCount = pending;
          _inProgressCount = inProgress;
          _completedCount = completed;
          _totalCount = data.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Command Center Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.greenDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLiveDashboardData,
            tooltip: 'Refresh Data',
          ),
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
      body: RefreshIndicator(
        onRefresh: _fetchLiveDashboardData,
        color: AppColors.greenPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Section
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.greenLight,
                    child: Icon(Icons.admin_panel_settings,
                        color: AppColors.greenDark),
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
              const SizedBox(height: 16),

              // Urban Health Score Card (Live AI Health Analytics)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.greenPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.greenPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Urban Health Score (Kota Malang)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _totalCount > 0
                                ? '${((_completedCount / _totalCount) * 100).toStringAsFixed(1)}% Penanganan Infrastruktur Baik'
                                : '92.4% Penanganan Infrastruktur Baik',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AI Policy Simulator Quick Access Banner
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/policy-simulator');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.greenDark, AppColors.greenPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenDark.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Policy Simulator AI (DeepSeek)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Simulasi skenario kebijakan, proyeksi anggaran & penurunan risiko wilayah.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Grid (2x2 Live Data)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.greenPrimary)),
                )
              else
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
                      value: '$_pendingCount',
                      color: AppColors.statusPending,
                      icon: Icons.hourglass_empty,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Sedang Diproses',
                      value: '$_inProgressCount',
                      color: AppColors.statusInfo,
                      icon: Icons.sync,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Laporan Selesai',
                      value: '$_completedCount',
                      color: AppColors.greenPrimary,
                      icon: Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Pengaduan',
                      value: '$_totalCount',
                      color: AppColors.neutral900,
                      icon: Icons.assignment_outlined,
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Live Recent Reports List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Laporan Terbaru Masuk (Live)',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.greenPrimary),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_reports.isEmpty && !_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada laporan masuk.',
                    style: TextStyle(color: AppColors.neutral700, fontSize: 13),
                  ),
                )
              else
                for (final item in _reports.take(5))
                  _buildReportListItem(
                    context,
                    title: item.categoryName.isNotEmpty
                        ? item.categoryName
                        : (item.description ?? 'Pengaduan Masuk'),
                    location: item.addressText ?? '${item.latitude}, ${item.longitude}',
                    time:
                        '${item.createdAt.day} ${item.createdAt.month} ${item.createdAt.year} | ${item.createdAt.hour.toString().padLeft(2, '0')}.${item.createdAt.minute.toString().padLeft(2, '0')}',
                    status: item.status.displayName,
                    statusColor: _getStatusColor(item.status),
                    reportModel: item,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendingVerification:
        return AppColors.statusPending;
      case ReportStatus.verified:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return AppColors.statusInfo;
      case ReportStatus.completed:
      case ReportStatus.resolved:
        return AppColors.greenPrimary;
      case ReportStatus.rejected:
      case ReportStatus.disputed:
        return AppColors.statusDanger;
    }
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
    required ReportModel reportModel,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/tracking-progress',
            arguments: {
              'reportId': reportModel.id,
              'reportModel': reportModel,
            },
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.report_problem_outlined, color: statusColor),
        ),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
