import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  bool _isLoading = true;
  List<ReportModel> _reports = [];
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _manualReviewCount = 0;

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

      int inProgress = 0;
      int completed = 0;
      int manualReview = 0;

      for (final r in data) {
        if (r.needsManualReview) {
          manualReview++;
        }
        if (r.status == ReportStatus.inProgress ||
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
          _inProgressCount = inProgress;
          _completedCount = completed;
          _manualReviewCount = manualReview;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUpdateStatusModal(ReportModel report) {
    ReportStatus newStatus = report.status;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Update Status: ${report.reportCode}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report.categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenPrimary,
                    ),
                  ),
                  Text(
                    report.addressText ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.neutral700),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Pilih Status Baru Penanganan:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReportStatus>(
                    initialValue: const [
                      ReportStatus.pendingVerification,
                      ReportStatus.verified,
                      ReportStatus.assigned,
                      ReportStatus.inProgress,
                      ReportStatus.completed,
                      ReportStatus.resolved,
                      ReportStatus.rejected,
                      ReportStatus.disputed,
                    ].contains(newStatus)
                        ? newStatus
                        : ReportStatus.inProgress,
                    items: ReportStatus.values.map((s) {
                      return DropdownMenuItem<ReportStatus>(
                        value: s,
                        child: Text(s.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => newStatus = val);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Status ${report.reportCode} berhasil diupdate!'),
                          backgroundColor: AppColors.greenPrimary,
                        ),
                      );
                      _fetchLiveDashboardData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Simpan Perubahan Penanganan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Dashboard Operator Dinas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Panel Penanganan Tugas & Task Force Lapangan',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD97706), // Amber theme for Field Ops
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLiveDashboardData,
            tooltip: 'Refresh Task Queue',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97706)),
            )
          : RefreshIndicator(
              onRefresh: _fetchLiveDashboardData,
              color: const Color(0xFFD97706),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Operator Header Alert Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF2AE01)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.engineering_rounded,
                              color: Color(0xFFF2AE01), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Panel Task Force Dinas (PUPR / Dishub)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Terdapat $_manualReviewCount laporan membutuhkan manual review & tindakan operator.',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.neutral700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Counter Grid untuk Operator
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Antrian Review',
                            value: '$_manualReviewCount',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.statusDanger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Sedang Diperbaiki',
                            value: '$_inProgressCount',
                            icon: Icons.build_circle_outlined,
                            color: const Color(0xFFF2AE01),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Selesai Dikerjakan',
                            value: '$_completedCount',
                            icon: Icons.task_alt_rounded,
                            color: AppColors.greenPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Antrian Penanganan Lapangan',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tap Tombol Update',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildOperatorTaskListView(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorTaskListView() {
    if (_reports.isEmpty) {
      return const Center(child: Text('Belum ada penanganan tugas baru.'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reports.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = _reports[index];
        return Card(
          elevation: 1.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: r.needsManualReview
                  ? AppColors.statusDanger.withValues(alpha: 0.15)
                  : AppColors.greenPrimary.withValues(alpha: 0.15),
              child: Icon(
                r.needsManualReview
                    ? Icons.priority_high_rounded
                    : Icons.build_rounded,
                color: r.needsManualReview
                    ? AppColors.statusDanger
                    : AppColors.greenPrimary,
                size: 20,
              ),
            ),
            title: Text(
              '${r.reportCode} — ${r.categoryName}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${r.addressText ?? ''}\nStatus: ${r.status.displayName}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: ElevatedButton(
              onPressed: () => _showUpdateStatusModal(r),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Update', style: TextStyle(fontSize: 11)),
            ),
          ),
        );
      },
    );
  }
}
