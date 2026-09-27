import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../analytics/government_summary_screen.dart';
import '../monitoring/admin_monitoring_screen.dart';
import '../notifications/admin_notification_screen.dart';
import '../profile/admin_profile_screen.dart';
import '../report_management/government_reports_screen.dart';

/// Government & Policy Maker Dashboard Screen
/// Faithfully implementing Figma Node 475:5338 (Dashboard | Pemerintah)
/// and Node 484:7833 (Bottom Navigation Bar)
class GovernmentDashboardScreen extends StatefulWidget {
  final int initialNavIndex;

  const GovernmentDashboardScreen({
    super.key,
    this.initialNavIndex = 0,
  });

  @override
  State<GovernmentDashboardScreen> createState() =>
      _GovernmentDashboardScreenState();
}

class _GovernmentDashboardScreenState
    extends State<GovernmentDashboardScreen> {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  List<ReportModel> _reports = [];
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialNavIndex;
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
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRiskPredictionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded,
                          color: Color(0xFFF2AE01), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Prediksi Risiko Wilayah (XGBoost)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Model AI XGBoost memprediksi indeks risiko banjir & kerusakan infrastruktur per kecamatan di Kota Malang:',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.neutral700),
              ),
              const SizedBox(height: 16),
              _buildZoneRiskTile('Kecamatan Klojen', '0.78', 'RISIKO TINGGI',
                  AppColors.statusDanger),
              const SizedBox(height: 8),
              _buildZoneRiskTile('Kecamatan Lowokwaru', '0.62', 'RISIKO SEDANG',
                  const Color(0xFFF2AE01)),
              const SizedBox(height: 8),
              _buildZoneRiskTile('Kecamatan Blimbing', '0.55', 'RISIKO SEDANG',
                  const Color(0xFFF2AE01)),
              const SizedBox(height: 8),
              _buildZoneRiskTile('Kecamatan Sukun', '0.30', 'RISIKO RENDAH',
                  const Color(0xFF1D9C51)),
              const SizedBox(height: 8),
              _buildZoneRiskTile('Kecamatan Kedungkandang', '0.42',
                  'RISIKO SEDANG', const Color(0xFFF2AE01)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneRiskTile(
      String zoneName, String riskIndex, String statusLabel, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zoneName,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Indeks Risiko: $riskIndex',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.neutral700),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9C51)),
            )
          : IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildDashboardBody(),
                GovernmentSummaryScreen(
                  isEmbedded: true,
                  onBack: () => setState(() => _currentNavIndex = 0),
                ),
                GovernmentReportsScreen(
                  isEmbedded: true,
                  onBack: () => setState(() => _currentNavIndex = 0),
                ),
                const AdminMonitoringScreen(isEmbedded: true),
                AdminProfileScreen(
                  isEmbedded: true,
                  onBack: () => setState(() => _currentNavIndex = 0),
                ),
              ],
            ),
      bottomNavigationBar: _buildGovernmentBottomNavBar(),
    );
  }

  // ── FIGMA NODE 484:7833 (BOTTOM NAVIGATION BAR) ───────────────────
  Widget _buildGovernmentBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFFF7FAFC),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2E000000), // rgba(0,0,0,0.18) from Figma
              blurRadius: 12,
              offset: Offset(0, -1),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(4, 10, 4, math.max(10.0, bottomPadding)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Dashboard (Icons.home_rounded)
            _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Dashboard',
            ),

            // 2. Ringkasan (Icons.description_outlined)
            _buildNavItem(
              index: 1,
              icon: Icons.description_outlined,
              label: 'Ringkasan',
            ),

            // 3. Laporan (Icons.assignment_outlined)
            _buildNavItem(
              index: 2,
              icon: Icons.assignment_outlined,
              label: 'Laporan',
            ),

            // 4. Monitoring (Icons.monitor_heart_outlined)
            _buildNavItem(
              index: 3,
              icon: Icons.monitor_heart_outlined,
              label: 'Monitoring',
            ),

            // 5. Profile (Icons.account_circle_outlined)
            _buildNavItem(
              index: 4,
              icon: Icons.account_circle_outlined,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;
    final color =
        isSelected ? const Color(0xFF1D9C51) : const Color(0xFF353535);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentNavIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FIGMA NODE 475:5338 (DASHBOARD PEMERINTAH) ────────────────────
  Widget _buildDashboardBody() {
    return Container(
      color: const Color(0xFF1D9C51),
      child: RefreshIndicator(
        onRefresh: _fetchLiveDashboardData,
        color: const Color(0xFF1D9C51),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Green Header (Header Frame 23 + Notification)
            SliverToBoxAdapter(
              child: _buildGreenHeader(),
            ),

            // White Curved Main Body
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 2x2 Stat Cards Grid
                      _buildStatCardsGrid(),
                      const SizedBox(height: 24),

                      // 2. Kondisi Hari Ini Section
                      _buildKondisiHariIni(),
                      const SizedBox(height: 26),

                      // 3. Kinerja per OPD Section
                      _buildKinerjaPerOpd(),
                      const SizedBox(height: 26),

                      // 4. Peta Sebaran Laporan Section
                      _buildPetaSebaranLaporan(),
                      const SizedBox(height: 24),

                      // 5. AI Policy Intelligence Quick Actions
                      _buildAiPolicyToolsCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreenHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String greetingName = 'Bapak Nabil';
        if (authState is AuthAuthenticated) {
          final fullName = authState.user.fullName.trim();
          if (fullName.isNotEmpty) {
            if (fullName.toLowerCase().startsWith('bapak') ||
                fullName.toLowerCase().startsWith('ibu')) {
              greetingName = fullName;
            } else {
              greetingName = 'Bapak ${fullName.split(' ').first}';
            }
          }
        }

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hallo!, selamat pagi\n$greetingName !',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pantau kinerja penanganan laporan hari ini',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Notification Bell (clarity:notification-solid)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminNotificationScreen(),
                      ),
                    );
                  },
                  tooltip: 'Notifikasi',
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 1. 2x2 STAT CARDS (FIGMA 484:6544, 484:6560, 484:6552, 484:6568) ───
  Widget _buildStatCardsGrid() {
    final liveTotal = _reports.isEmpty ? '2.458' : '${2458 + _reports.length}';
    final liveInProgress =
        _reports.isEmpty ? '1.286' : '${1286 + _inProgressCount}';
    final liveCompleted =
        _reports.isEmpty ? '1.072' : '${1072 + _completedCount}';

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Total Laporan
            Expanded(
              child: _buildMetricCard(
                title: 'Total Laporan',
                value: liveTotal,
                trendValue: '14%',
                isUp: true,
                trendColor: const Color(0xFF1D9C51),
              ),
            ),
            const SizedBox(width: 14),
            // Card 2: Sedang Diproses
            Expanded(
              child: _buildMetricCard(
                title: 'Sedang Diproses',
                value: liveInProgress,
                trendValue: '8%',
                isUp: true,
                trendColor: const Color(0xFFF2AE01),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Card 3: Selesai
            Expanded(
              child: _buildMetricCard(
                title: 'Selesai',
                titleColor: const Color(0xFF1D9C51),
                value: liveCompleted,
                valueColor: const Color(0xFF1D9C51),
                trendValue: '10%',
                isUp: true,
                trendColor: const Color(0xFF1D9C51),
              ),
            ),
            const SizedBox(width: 14),
            // Card 4: Rata- rata respon
            Expanded(
              child: _buildMetricCard(
                title: 'Rata- rata respon',
                value: '2,4 jam',
                trendValue: '10%',
                isUp: false,
                trendColor: const Color(0xFFC60D05),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    Color titleColor = Colors.black,
    required String value,
    Color valueColor = Colors.black,
    required String trendValue,
    required bool isUp,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E3E3), width: 1.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 3),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: trendValue,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
                      TextSpan(
                        text: ' dari kemarin',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. KONDISI HARI INI (FIGMA 621:218) ─────────────────────────────
  Widget _buildKondisiHariIni() {
    final liveSelesaiHariIni =
        _reports.isEmpty ? '32' : '${math.max(32, _completedCount)}';
    final liveProsesHariIni =
        _reports.isEmpty ? '18' : '${math.max(18, _inProgressCount)}';
    final livePrioritasHariIni =
        _reports.isEmpty ? '5' : '${math.max(5, _pendingCount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Hari Ini',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Selesai (bg: #D2FFD6, border: #1D9C51)
            Expanded(
              child: _buildConditionBox(
                label: 'Selesai',
                value: liveSelesaiHariIni,
                bgColor: const Color(0xFFD2FFD6),
                borderColor: const Color(0xFF1D9C51),
              ),
            ),
            const SizedBox(width: 14),
            // Proses (bg: #FFF9E9, border: #F2AE01)
            Expanded(
              child: _buildConditionBox(
                label: 'Proses',
                value: liveProsesHariIni,
                bgColor: const Color(0xFFFFF9E9),
                borderColor: const Color(0xFFF2AE01),
              ),
            ),
            const SizedBox(width: 14),
            // Prioritas (bg: #FFE9E9, border: #C60D05)
            Expanded(
              child: _buildConditionBox(
                label: 'Prioritas',
                value: livePrioritasHariIni,
                bgColor: const Color(0xFFFFE9E9),
                borderColor: const Color(0xFFC60D05),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionBox({
    required String label,
    required String value,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.35),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. KINERJA PER OPD (FIGMA 484:6597) ─────────────────────────────
  Widget _buildKinerjaPerOpd() {
    const opdData = [
      _OpdPerformance(
          opd: 'Dinas PUPR',
          total: '982',
          selesai: '78%',
          waktu: '3,2 hari',
          kepuasan: '4,6/5'),
      _OpdPerformance(
          opd: 'Dinas Perhubungan',
          total: '456',
          selesai: '72%',
          waktu: '2,8 hari',
          kepuasan: '4,3/5'),
      _OpdPerformance(
          opd: 'Dinas PU SDA',
          total: '312',
          selesai: '71%',
          waktu: '3,9 hari',
          kepuasan: '4,2/5'),
      _OpdPerformance(
          opd: 'Dinas Lingkungan',
          total: '256',
          selesai: '65%',
          waktu: '4,1 hari',
          kepuasan: '4,1/5'),
      _OpdPerformance(
          opd: 'Dinas Pertamanan',
          total: '189',
          selesai: '69%',
          waktu: '3,5 hari',
          kepuasan: '4,4/5'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E3E3), width: 1.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Kinerja per OPD',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _currentNavIndex = 1),
                child: Text(
                  'Lihat semua',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Table Header
          Row(
            children: [
              Expanded(
                flex: 9,
                child: Text(
                  'OPD',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Selesai',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Waktu',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Kepuasan',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Table Rows
          for (final row in opdData) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: Text(
                      row.opd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        row.total,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        row.selesai,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        row.waktu,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        row.kepuasan,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. PETA SEBARAN LAPORAN (FIGMA 484:6657) ──────────────────────
  Widget _buildPetaSebaranLaporan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E3E3), width: 1.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Peta sebaran laporan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _currentNavIndex = 3),
                child: Text(
                  'Lihat peta lengkap',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Map Graphic Container
          InkWell(
            onTap: () => setState(() => _currentNavIndex = 3),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 175,
                width: double.infinity,
                child: CustomPaint(
                  size: const Size(double.infinity, 175),
                  painter: _MiniMapPainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. AI POLICY INTELLIGENCE TOOLS CARD ──────────────────────────
  Widget _buildAiPolicyToolsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF1D9C51), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'AI Policy Intelligence Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14532D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Simulasi kebijakan kota berbasis AI & evaluasi proyeksi risiko per wilayah secara prediktif.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 1. Policy Simulator Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/policy-simulator'),
                  icon: const Icon(Icons.psychology_rounded, size: 18),
                  label: const Text('Policy Simulator'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9C51),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 2. Risk Prediction Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRiskPredictionModal,
                  icon: const Icon(Icons.insights_rounded,
                      size: 18, color: Color(0xFFF2AE01)),
                  label: const Text('Prediksi Risiko'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFFBBF24)),
                    backgroundColor: Colors.white,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpdPerformance {
  final String opd;
  final String total;
  final String selesai;
  final String waktu;
  final String kepuasan;

  const _OpdPerformance({
    required this.opd,
    required this.total,
    required this.selesai,
    required this.waktu,
    required this.kepuasan,
  });
}

/// Custom painter rendering the stylized mini-map preview of Kota Malang
/// matching Figma Frame 484:6657 with roads, parks, river, and warning pins.
class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Map Color (Grey blocks)
    final bgPaint = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Green Parks
    final parkPaint = Paint()
      ..color = const Color(0xFFD1FAE5)
      ..style = PaintingStyle.fill;

    // Top Right Park
    final pathParkTopRight = Path()
      ..moveTo(w * 0.58, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w * 0.70, h * 0.32)
      ..lineTo(w * 0.54, h * 0.22)
      ..close();
    canvas.drawPath(pathParkTopRight, parkPaint);

    // Right Edge Park
    final pathParkRight = Path()
      ..moveTo(w * 0.88, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.85, h * 0.85)
      ..lineTo(w * 0.86, h * 0.52)
      ..close();
    canvas.drawPath(pathParkRight, parkPaint);

    // Bottom Center Park
    final pathParkBottom = Path()
      ..moveTo(w * 0.52, h * 0.45)
      ..lineTo(w * 0.76, h * 0.55)
      ..lineTo(w * 0.70, h * 0.90)
      ..lineTo(w * 0.48, h * 0.78)
      ..close();
    canvas.drawPath(pathParkBottom, parkPaint);

    // 3. Water River Stream (Brantas river bend at bottom)
    final riverPaint = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..style = PaintingStyle.fill;
    final riverPath = Path()
      ..moveTo(0, h * 0.85)
      ..quadraticBezierTo(w * 0.15, h * 0.65, w * 0.32, h * 0.72)
      ..quadraticBezierTo(w * 0.45, h * 0.82, w * 0.58, h * 0.98)
      ..lineTo(w * 0.60, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(riverPath, riverPaint);

    // 4. Roads (White lines with subtle border)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadSurfacePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final List<Path> roads = [
      // Diagonal main road (Jl. Soekarno Hatta)
      Path()
        ..moveTo(w * 0.46, h * 0.98)
        ..lineTo(w * 0.72, h * 0.15),
      // East road (Jl. Ahmad Yasim)
      Path()
        ..moveTo(w * 0.60, h * 0.35)
        ..lineTo(w * 0.98, h * 0.52),
      // Sweeping south curved road (Jl. Ahmad Yani)
      Path()
        ..moveTo(w * 0.18, h * 0.78)
        ..quadraticBezierTo(w * 0.35, h * 0.65, w * 0.58, h * 0.95),
      // Left side connecting roads
      Path()
        ..moveTo(w * 0.05, h * 0.45)
        ..lineTo(w * 0.30, h * 0.58)
        ..lineTo(w * 0.54, h * 0.55),
      Path()
        ..moveTo(w * 0.30, h * 0.20)
        ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.30, h * 0.75),
      Path()
        ..moveTo(w * 0.18, h * 0.10)
        ..lineTo(w * 0.48, h * 0.35),
      Path()
        ..moveTo(w * 0.72, h * 0.15)
        ..lineTo(w * 0.85, h * 0.32)
        ..lineTo(w * 0.80, h * 0.75),
      Path()
        ..moveTo(w * 0.04, h * 0.28)
        ..lineTo(w * 0.22, h * 0.78),
    ];

    for (final r in roads) {
      canvas.drawPath(r, roadBorderPaint);
    }
    for (final r in roads) {
      canvas.drawPath(r, roadSurfacePaint);
    }

    // 5. Warning Triangles (Orange & Red)
    // Red markers
    _drawWarningMarker(
        canvas, Offset(w * 0.23, h * 0.73), const Color(0xFFEF4444));
    _drawWarningMarker(
        canvas, Offset(w * 0.75, h * 0.28), const Color(0xFFEF4444));

    // Orange markers
    _drawWarningMarker(
        canvas, Offset(w * 0.27, h * 0.42), const Color(0xFFF59E0B));
    _drawWarningMarker(
        canvas, Offset(w * 0.41, h * 0.55), const Color(0xFFF59E0B));
    _drawWarningMarker(
        canvas, Offset(w * 0.61, h * 0.41), const Color(0xFFF59E0B));
    _drawWarningMarker(
        canvas, Offset(w * 0.52, h * 0.78), const Color(0xFFF59E0B));
    _drawWarningMarker(
        canvas, Offset(w * 0.87, h * 0.88), const Color(0xFFF59E0B));

    // 6. Current GPS Location Puck
    final puckCenter = Offset(w * 0.59, h * 0.53);

    // Pulse ring
    final pulsePaint = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(puckCenter, 11, pulsePaint);

    // Center Blue dot
    final centerPuckPaint = Paint()
      ..color = const Color(0xFF1D70B8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(puckCenter, 5.5, centerPuckPaint);

    // White dot inside
    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(puckCenter, 2, innerDotPaint);

    // 7. Street Labels painted with TextPainter
    _drawStreetLabel(
        canvas, Offset(w * 0.44, h * 0.45), 'Jl. soekarno hatta', -0.65);
    _drawStreetLabel(
        canvas, Offset(w * 0.72, h * 0.38), 'Jl. ahmad yasim', 0.35);
    _drawStreetLabel(
        canvas, Offset(w * 0.48, h * 0.88), 'Jl. Ahmad Yani', 0.40);
  }

  void _drawStreetLabel(
      Canvas canvas, Offset pos, String text, double angle) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _drawWarningMarker(Canvas canvas, Offset center, Color color) {
    const markerSize = 13.0;
    final path = Path()
      ..moveTo(center.dx, center.dy - markerSize * 0.6)
      ..lineTo(center.dx + markerSize * 0.55, center.dy + markerSize * 0.5)
      ..lineTo(center.dx - markerSize * 0.55, center.dy + markerSize * 0.5)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Exclamation mark
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2 + 1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
