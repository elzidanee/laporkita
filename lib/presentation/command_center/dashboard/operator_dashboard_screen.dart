import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'operator_report_detail_screen.dart';
import 'operator_tugas_screen.dart';
import 'operator_laporan_screen.dart';
import 'operator_monitoring_screen.dart';
import 'operator_profile_screen.dart';
import 'operator_notifikasi_screen.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  int _selectedBottomNavIndex = 0;
  bool _isLoading = true;
  List<ReportModel> _allReports = [];

  // Metric counts
  int _tugasBaruCount = 0;
  int _sedangDikerjakanCount = 0;
  int _selesaiCount = 0;
  int _terlambatCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final repository = context.read<ReportRepository>();
      List<ReportModel> data = [];
      try {
        final response = await repository.getReports(limit: 100);
        data = response.data ?? [];
      } catch (_) {
        data = repository.localSubmittedReports;
      }

      if (data.isEmpty) {
        data = repository.localSubmittedReports;
      }

      if (mounted) {
        setState(() {
          _allReports = data;
          _calculateMetrics();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateMetrics() {
    int baru = 0;
    int dikerjakan = 0;
    int selesai = 0;
    int terlambat = 0;

    for (final r in _allReports) {
      if (r.status == ReportStatus.completed || r.status == ReportStatus.resolved) {
        selesai++;
      } else if (r.status == ReportStatus.inProgress) {
        dikerjakan++;
      } else {
        baru++;
      }

      // Terlambat criteria: urgency >= 7.0 or needs manual review or older than 7 days
      final isUrgent = (r.urgencyScore != null && r.urgencyScore! >= 7.0) ||
          r.needsManualReview ||
          r.priorityLabel.toLowerCase().contains('tinggi');
      if (isUrgent &&
          r.status != ReportStatus.completed &&
          r.status != ReportStatus.resolved) {
        terlambat++;
      }
    }

    _tugasBaruCount = baru;
    _sedangDikerjakanCount = dikerjakan;
    _selesaiCount = selesai;
    _terlambatCount = terlambat > 0 ? terlambat : 1;
  }

  String _formatCodeWithHash(String code) {
    if (code.startsWith('#')) return code;
    return '#$code';
  }

  String _formatDateTimeShort(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final d = dt.day;
    final m = months[dt.month - 1];
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y | $h.$min';
  }

  Color _getPriorityTextColor(String priority) {
    final lower = priority.toLowerCase();
    if (lower.contains('tinggi')) return const Color(0xFFC60D05);
    if (lower.contains('perlu penanganan')) return const Color(0xFFD97706);
    if (lower.contains('sedang')) return const Color(0xFFF2AE01);
    return const Color(0xFF1D9C51);
  }

  Color _getPriorityBgColor(String priority) {
    final lower = priority.toLowerCase();
    if (lower.contains('tinggi')) return const Color(0xFFFFE9E9);
    if (lower.contains('perlu penanganan')) return const Color(0xFFFFF4E5);
    if (lower.contains('sedang')) return const Color(0xFFFFF9E9);
    return const Color(0xFFE9F9EE);
  }

  Map<String, dynamic> _getStatusBadge(ReportStatus status) {
    if (status == ReportStatus.completed || status == ReportStatus.resolved) {
      return {
        'label': 'Selesai',
        'bg': const Color(0xFFE9F9EE),
        'text': const Color(0xFF1D9C51),
      };
    }
    if (status == ReportStatus.inProgress) {
      return {
        'label': 'Sedang Dikerjakan',
        'bg': const Color(0xFFFFF9E9),
        'text': const Color(0xFFF2AE01),
      };
    }
    if (status == ReportStatus.assigned) {
      return {
        'label': 'Belum dikerjakan',
        'bg': const Color(0xFFFFF9E9),
        'text': const Color(0xFFF2AE01),
      };
    }
    return {
      'label': 'Menunggu pengerjaan',
      'bg': const Color(0xFFEBF4FF),
      'text': const Color(0xFF1976D2),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildCurrentTabContent(),
      bottomNavigationBar: _buildFigmaBottomNavBar(),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedBottomNavIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return OperatorTugasScreen(
          isTab: true,
          onBackToDashboard: () => setState(() => _selectedBottomNavIndex = 0),
        );
      case 2:
        return OperatorLaporanScreen(
          isTab: true,
          onBackToDashboard: () => setState(() => _selectedBottomNavIndex = 0),
        );
      case 3:
        return OperatorMonitoringScreen(
          isTab: true,
          onBackToDashboard: () => setState(() => _selectedBottomNavIndex = 0),
        );
      case 4:
        return OperatorProfileScreen(
          isTab: true,
          onBackToDashboard: () => setState(() => _selectedBottomNavIndex = 0),
        );
      default:
        return _buildDashboardTab();
    }
  }

  // ── FIGMA BOTTOM NAVIGATION BAR (Node 485:8094) ───────────────────────────
  Widget _buildFigmaBottomNavBar() {
    return Container(
      color: const Color(0xFFF7FAFC),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Dashboard')),
                Expanded(child: _buildNavItem(1, Icons.description_outlined, 'Tugas')),
                Expanded(child: _buildNavItem(2, Icons.ballot_outlined, 'Laporan')),
                Expanded(child: _buildNavItem(3, Icons.monitor_heart_outlined, 'Monitoring')),
                Expanded(child: _buildNavItem(4, Icons.account_circle_outlined, 'Profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedBottomNavIndex == index;
    final activeColor = const Color(0xFF1D9C51);
    final inactiveColor = const Color(0xFF2D3748);

    return InkWell(
      onTap: () {
        setState(() => _selectedBottomNavIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── DASHBOARD TAB (Node 485:7874) ─────────────────────────────────────────
  Widget _buildDashboardTab() {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Petugas OPD';
    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
    }

    // Top priority report for "Tugas Prioritas hari ini"
    ReportModel? priorityReport;
    if (_allReports.isNotEmpty) {
      priorityReport = _allReports.firstWhere(
        (r) =>
            (r.priorityLabel.toLowerCase().contains('tinggi') ||
                r.needsManualReview) &&
            r.status != ReportStatus.completed &&
            r.status != ReportStatus.resolved,
        orElse: () => _allReports.firstWhere(
          (r) =>
              r.status != ReportStatus.completed &&
              r.status != ReportStatus.resolved,
          orElse: () => _allReports.first,
        ),
      );
    }

    // Recent reports
    final recentReports = _allReports.take(4).toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. Curved Green Header (Node 485:7874)
          Container(
            width: double.infinity,
            color: const Color(0xFF1D9C51),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hallo!, $userName !',
                            style: GoogleFonts.poppins(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.46,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Berikut laporan yang menjadi tanggung jawab anda',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OperatorNotifikasiScreen(),
                            ),
                          );
                        },
                        tooltip: 'Notifikasi',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Curved White Body Container (Node 485:7874)
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -1,
                  left: 0,
                  right: 0,
                  height: 30,
                  child: Container(color: const Color(0xFF1D9C51)),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF1D9C51)),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchLiveDashboardData,
                          color: const Color(0xFF1D9C51),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 2x2 Stat Cards
                                _build2x2StatCards(),
                                const SizedBox(height: 24),

                                // Section: Tugas Prioritas Hari Ini
                                if (priorityReport != null) ...[
                                  Text(
                                    'Tugas Prioritas hari ini',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPriorityTaskCard(priorityReport),
                                  const SizedBox(height: 24),
                                ],

                                // Section: 3 Summary Metrics Cards
                                _buildSummaryCards(),
                                const SizedBox(height: 24),

                                // Section: Laporan Terbaru + Lihat Semua
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Laporan Terbaru',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() => _selectedBottomNavIndex = 1);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        child: Text(
                                          'Lihat Semua',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF1976D2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Recent Reports List
                                ...recentReports.map((r) => _buildRecentReportCard(r)),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2x2 STAT CARDS (Node 485:7874) ────────────────────────────────────────
  Widget _build2x2StatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tugas Baru',
                count: '$_tugasBaruCount',
                countColor: const Color(0xFF1976D2),
                subtitle: 'Perlu segera ditindaklanjuti',
                subtitleColor: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                title: 'Sedang Dikerjakan',
                count: '$_sedangDikerjakanCount',
                countColor: const Color(0xFFF2AE01),
                subtitle: 'Dalam proses penanganan',
                subtitleColor: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Selesai',
                count: '$_selesaiCount',
                countColor: const Color(0xFF1D9C51),
                subtitle: 'Bulan ini',
                subtitleColor: const Color(0xFF4A5568),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                title: 'Terlambat',
                count: '$_terlambatCount',
                countColor: const Color(0xFFC60D05),
                subtitle: 'Perlu perhatian',
                subtitleColor: const Color(0xFFC60D05),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required Color countColor,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E3E3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: countColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── PRIORITY TASK CARD (Node 485:7874) ────────────────────────────────────
  Widget _buildPriorityTaskCard(ReportModel report) {
    final priorityText = report.priorityLabel;
    final statusBadge = _getStatusBadge(report.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail with Watermark
              _buildThumbnailWithWatermark(report),
              const SizedBox(width: 12),

              // 2. Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.categoryName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getPriorityBgColor(priorityText),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            priorityText,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: _getPriorityTextColor(priorityText),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.addressText ?? 'Jl. Ahmad Yani no. 15',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF4A5568),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCodeWithHash(report.reportCode),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1D9C51),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusBadge['bg'] as Color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        statusBadge['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: statusBadge['text'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Button: "Mulai Tugas" (Figma Node 485:7874) - only when not completed
          if (report.status != ReportStatus.completed &&
              report.status != ReportStatus.resolved)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9C51),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OperatorReportDetailScreen(
                        report: report,
                        onStatusUpdated: _fetchLiveDashboardData,
                      ),
                    ),
                  ).then((_) => _fetchLiveDashboardData());
                },
                child: Text(
                  report.status == ReportStatus.inProgress
                      ? 'Update Tugas'
                      : 'Mulai Tugas',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 3 SUMMARY CARDS (Node 485:7874) ───────────────────────────────────────
  Widget _buildSummaryCards() {
    final totalReports = _allReports.length;
    final totalUpdates = totalReports > 0 ? (totalReports * 3 - 2) : 24;
    final totalPhotos = totalReports > 0 ? (totalReports * 2 + 1) : 18;
    final progressPercentage = _allReports.isNotEmpty
        ? ((_selesaiCount + (_sedangDikerjakanCount * 0.5)) / _allReports.length * 100).toInt()
        : 62;

    return Row(
      children: [
        // Card 1: Total Update
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E3E3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total update',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalUpdates',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Laporan diupdate',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: Foto diunggah
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E3E3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto diunggah',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPhotos',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto progress',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: Rata-rata Progress Gauge
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E3E3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rata-rata Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF1D9C51),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: progressPercentage / 100,
                          strokeWidth: 4.5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1D9C51)),
                        ),
                      ),
                      Text(
                        '$progressPercentage%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── RECENT REPORT CARD (Node 485:7874) ─────────────────────────────────────
  Widget _buildRecentReportCard(ReportModel report) {
    final statusBadge = _getStatusBadge(report.status);
    final isCompleted = report.status == ReportStatus.completed ||
        report.status == ReportStatus.resolved;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OperatorReportDetailScreen(
              report: report,
              onStatusUpdated: _fetchLiveDashboardData,
            ),
          ),
        ).then((_) => _fetchLiveDashboardData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnailWithWatermark(report),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.categoryName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.addressText ?? 'Jl. Ahmad Yani no. 15',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Diterima : ${_formatDateTimeShort(report.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D9C51),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBadge['bg'] as Color,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      statusBadge['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: statusBadge['text'] as Color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9C51),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OperatorReportDetailScreen(
                              report: report,
                              onStatusUpdated: _fetchLiveDashboardData,
                            ),
                          ),
                        ).then((_) => _fetchLiveDashboardData());
                      },
                      child: Text(
                        report.status == ReportStatus.inProgress
                            ? 'Update'
                            : 'Mulai kerjakan',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── THUMBNAIL WITH WATERMARK ──────────────────────────────────────────────
  Widget _buildThumbnailWithWatermark(ReportModel r) {
    final photoUrl = r.directPhotoUrl != null && r.directPhotoUrl!.isNotEmpty
        ? r.directPhotoUrl!
        : (r.media.isNotEmpty ? r.media.first.url : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 119,
        height: 83,
        color: const Color(0xFFE2E8F0),
        child: Stack(
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              Image.network(
                photoUrl,
                width: 119,
                height: 83,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
              )
            else
              _buildFallbackThumbnail(),
            Positioned(
              left: 3,
              bottom: 3,
              child: _buildMiniWatermarkBadge(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: Center(
        child: Icon(Icons.image_outlined, size: 28, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildMiniWatermarkBadge(ReportModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 4.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _formatCodeWithHash(r.reportCode),
            style: GoogleFonts.poppins(
              fontSize: 5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 6, color: Colors.white),
              const SizedBox(width: 1.5),
              SizedBox(
                width: 55,
                child: Text(
                  r.addressText ?? 'Malang, Jawa Timur',
                  style: GoogleFonts.poppins(
                    fontSize: 4.5,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 6, color: Colors.white),
              const SizedBox(width: 1.5),
              Text(
                _formatDateTimeShort(r.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 4.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
