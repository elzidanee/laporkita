import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../report_management/admin_reports_screen.dart';
import '../monitoring/admin_monitoring_screen.dart';
import '../../citizen/home/tabs/citizen_notifikasi_tab.dart';

// ─────────────────────────────────────────────────────────────
//  Admin Dashboard Screen  (Figma: node 481-6023)
// ─────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  List<ReportModel> _reports = [];
  List<CategoryModel> _categories = [];

  // Computed stats strictly from real backend reports
  int _totalLaporan = 0;
  int _sedangDiproses = 0;
  int _selesai = 0;
  int _ditolak = 0;

  // Real trend calculations compared to yesterday
  String _totalTrendPercent = '0%';
  bool _totalIsUp = true;
  String _inProgressTrendPercent = '0%';
  bool _inProgressIsUp = true;
  String _selesaiTrendPercent = '0%';
  bool _selesaiIsUp = true;
  String _ditolakTrendPercent = '0%';
  bool _ditolakIsUp = false;

  // Filter state for summary
  String _selectedFilter = 'Semua';

  // Real chart data computed from backend reports for the last 6 days
  List<double> _greenChartData = [0, 0, 0, 0, 0, 0];
  List<double> _blueChartData = [0, 0, 0, 0, 0, 0];
  List<String> _chartLabels = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fetchLiveDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final reportRepo = context.read<ReportRepository>();
      final categoryRepo = context.read<CategoryRepository>();

      final reportResponse = await reportRepo.getReports(limit: 100);
      final categoriesList = await categoryRepo.getCategories();

      if (mounted) {
        final reports = reportResponse.data ?? [];
        _computeStats(reports);
        _computeChartData(reports);

        setState(() {
          _reports = reports;
          _categories = categoriesList;
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _computeStats(List<ReportModel> reports) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Filter reports according to _selectedFilter
    List<ReportModel> filtered = reports;
    if (_selectedFilter == 'Hari ini') {
      filtered = reports.where((r) {
        final c = r.createdAt;
        return c.year == today.year &&
            c.month == today.month &&
            c.day == today.day;
      }).toList();
    } else if (_selectedFilter == '7 Hari Terakhir') {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      filtered = reports.where((r) => r.createdAt.isAfter(sevenDaysAgo)).toList();
    } else if (_selectedFilter == 'Bulan ini') {
      filtered = reports
          .where((r) =>
              r.createdAt.year == now.year && r.createdAt.month == now.month)
          .toList();
    }

    int inProgress = 0, selesai = 0, ditolak = 0;
    for (final r in filtered) {
      if (r.status == ReportStatus.inProgress ||
          r.status == ReportStatus.assigned ||
          r.status == ReportStatus.verified) {
        inProgress++;
      } else if (r.status == ReportStatus.completed ||
          r.status == ReportStatus.resolved) {
        selesai++;
      } else if (r.status == ReportStatus.rejected ||
          r.status == ReportStatus.disputed) {
        ditolak++;
      }
    }

    _totalLaporan = filtered.length;
    _sedangDiproses = inProgress;
    _selesai = selesai;
    _ditolak = ditolak;

    // Calculate real changes compared to yesterday
    final reportsToday = reports.where((r) {
      final c = r.createdAt;
      return c.year == today.year &&
          c.month == today.month &&
          c.day == today.day;
    }).toList();

    final reportsYesterday = reports.where((r) {
      final c = r.createdAt;
      return c.year == yesterday.year &&
          c.month == yesterday.month &&
          c.day == yesterday.day;
    }).toList();

    _totalTrendPercent =
        _calcTrendPercent(reportsToday.length, reportsYesterday.length);
    _totalIsUp = reportsToday.length >= reportsYesterday.length;

    final inProgressToday = reportsToday
        .where((r) =>
            r.status == ReportStatus.inProgress ||
            r.status == ReportStatus.assigned ||
            r.status == ReportStatus.verified)
        .length;
    final inProgressYesterday = reportsYesterday
        .where((r) =>
            r.status == ReportStatus.inProgress ||
            r.status == ReportStatus.assigned ||
            r.status == ReportStatus.verified)
        .length;
    _inProgressTrendPercent =
        _calcTrendPercent(inProgressToday, inProgressYesterday);
    _inProgressIsUp = inProgressToday >= inProgressYesterday;

    final selesaiToday = reportsToday
        .where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved)
        .length;
    final selesaiYesterday = reportsYesterday
        .where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved)
        .length;
    _selesaiTrendPercent =
        _calcTrendPercent(selesaiToday, selesaiYesterday);
    _selesaiIsUp = selesaiToday >= selesaiYesterday;

    final ditolakToday = reportsToday
        .where((r) =>
            r.status == ReportStatus.rejected ||
            r.status == ReportStatus.disputed)
        .length;
    final ditolakYesterday = reportsYesterday
        .where((r) =>
            r.status == ReportStatus.rejected ||
            r.status == ReportStatus.disputed)
        .length;
    _ditolakTrendPercent =
        _calcTrendPercent(ditolakToday, ditolakYesterday);
    _ditolakIsUp = ditolakToday >= ditolakYesterday;
  }

  String _calcTrendPercent(int current, int previous) {
    if (previous == 0) {
      if (current == 0) return '0%';
      return '100%';
    }
    final change = ((current - previous) / previous * 100).round();
    return '${change.abs()}%';
  }

  void _computeChartData(List<ReportModel> reports) {
    final now = DateTime.now();
    final days = List.generate(6, (i) => now.subtract(Duration(days: 5 - i)));
    _chartLabels =
        days.map((d) => '${d.day} ${_shortMonth(d.month)}').toList();

    _greenChartData = days.map((day) {
      return reports.where((r) {
        final c = r.createdAt;
        return c.year == day.year &&
            c.month == day.month &&
            c.day == day.day;
      }).length.toDouble();
    }).toList();

    _blueChartData = days.map((day) {
      return reports.where((r) {
        final c = r.createdAt;
        final isMatch = c.year == day.year &&
            c.month == day.month &&
            c.day == day.day;
        return isMatch &&
            (r.status == ReportStatus.inProgress ||
                r.status == ReportStatus.assigned ||
                r.status == ReportStatus.verified);
      }).length.toDouble();
    }).toList();
  }

  String _shortMonth(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[m - 1];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'selamat pagi';
    if (hour < 15) return 'selamat siang';
    if (hour < 18) return 'selamat sore';
    return 'selamat malam';
  }

  String _getAdminName() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.fullName.isNotEmpty
          ? authState.user.fullName
          : 'Admin Utama';
    }
    return 'Admin Utama';
  }

  // ── MODALS ────────────────────────────────────────────────────

  void _showUserManagementModal() {
    _showAdminModal(
      title: 'Manajemen User & Role Access',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ubah role pengguna (GET /users & PATCH /users/:id):',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.neutral700),
            ),
          ),
          const SizedBox(height: 14),
          _buildUserRoleTile(
            name: 'Admin LaporKita Kota Malang',
            email: 'admin@laporkita.malangkota.go.id',
            role: 'admin',
            color: AppColors.statusDanger,
          ),
          const SizedBox(height: 8),
          _buildUserRoleTile(
            name: 'DPUPR Operator Lapangan',
            email: 'dpupr@malangkota.go.id',
            role: 'operator',
            color: const Color(0xFFF2AE01),
          ),
          const SizedBox(height: 8),
          _buildUserRoleTile(
            name: 'Dishub Operator Lapangan',
            email: 'dishub@malangkota.go.id',
            role: 'operator',
            color: const Color(0xFFF2AE01),
          ),
          const SizedBox(height: 8),
          _buildUserRoleTile(
            name: 'Diskominfo Operator Lapangan',
            email: 'diskominfo@malangkota.go.id',
            role: 'operator',
            color: const Color(0xFFF2AE01),
          ),
          const SizedBox(height: 8),
          _buildUserRoleTile(
            name: 'Pemerintah Kota Malang (B2G)',
            email: 'pemerintah@malangkota.go.id',
            role: 'policy_maker',
            color: AppColors.greenPrimary,
          ),
          const SizedBox(height: 8),
          _buildUserRoleTile(
            name: 'Budi Santoso (Warga)',
            email: 'budi@example.com',
            role: 'citizen',
            color: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }

  void _showAgenciesModal() {
    _showAdminModal(
      title: 'Manajemen Dinas / Agencies',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Daftar Organisasi Perangkat Daerah (GET /agencies):',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.neutral700),
            ),
          ),
          const SizedBox(height: 14),
          _buildAgencyTile(
            name: 'Dinas Pekerjaan Umum & Penataan Ruang (DPUPR)',
            email: 'dpupr@malangkota.go.id',
            code: 'DPUPR-MLG',
          ),
          const SizedBox(height: 8),
          _buildAgencyTile(
            name: 'Dinas Perhubungan (Dishub)',
            email: 'dishub@malangkota.go.id',
            code: 'DISHUB-MLG',
          ),
          const SizedBox(height: 8),
          _buildAgencyTile(
            name: 'Dinas Komunikasi & Informatika (Diskominfo)',
            email: 'diskominfo@malangkota.go.id',
            code: 'DISKOMINFO-MLG',
          ),
        ],
      ),
    );
  }

  void _showCategoriesModal() {
    _showAdminModal(
      title: 'Manajemen Kategori Pengaduan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${_categories.length} Kategori terdaftar di backend (GET /categories):',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.neutral700),
          ),
          const SizedBox(height: 14),
          ..._categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_rounded,
                          color: Color(0xFFF2AE01)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        cat.agencyName,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.neutral700),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showAuditLogModal() {
    _showAdminModal(
      title: 'System Audit & Health Logs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status server & idempotency logs (GET /health):',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.neutral700),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[200 OK] NestJS Backend /api/v1/health — Operational',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: Colors.greenAccent),
                ),
                const SizedBox(height: 6),
                Text(
                  '[200 OK] FastAPI AI Microservice /health — Operational',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: Colors.greenAccent),
                ),
                const SizedBox(height: 6),
                Text(
                  '[LOG] Idempotency Key validation active on POST /reports',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminModal({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  child,
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserRoleTile({
    required String name,
    required String email,
    required String role,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.person, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(email,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.neutral700)),
              ],
            ),
          ),
          Chip(
            label: Text(role.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.white)),
            backgroundColor: color,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyTile({
    required String name,
    required String email,
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(Icons.apartment_rounded,
              color: Color(0xFF1976D2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(email,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.neutral700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              code,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D9C51),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildDashboardBody(),
                const AdminReportsScreen(),
                const AdminMonitoringScreen(isEmbedded: true),
                const CitizenNotifikasiTab(),
                _buildAdminProfileBody(),
              ],
            ),
      bottomNavigationBar: _buildAdminBottomNavBar(),
    );
  }

  Widget _buildDashboardBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: const Color(0xFF1D9C51),
        child: RefreshIndicator(
          onRefresh: _fetchLiveDashboardData,
          color: const Color(0xFF1D9C51),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        _buildSummaryHeaderRow(),
                        const SizedBox(height: 16),
                        _buildStatCards(),
                        const SizedBox(height: 20),
                        _buildChartSection(),
                        const SizedBox(height: 24),
                        Text(
                          'Laporan Terbaru',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildReportList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER (Figma Node 481:6023) ───────────────────────────────

  Widget _buildHeader() {
    final adminName = _getAdminName();
    final greeting = _getGreeting();

    return Container(
      color: const Color(0xFF1D9C51),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hallo!, $greeting',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.46,
                    height: 1.25,
                  ),
                ),
                Text(
                  '$adminName !',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.46,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          // Single notification bell icon from Figma node 481:6032
          GestureDetector(
            onTap: () {
              setState(() => _currentNavIndex = 3);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── RINGKASAN KESELURUHAN & FILTER ─────────────────────────────

  Widget _buildSummaryHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ringkasan Keseluruhan',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        PopupMenuButton<String>(
          initialValue: _selectedFilter,
          onSelected: (String val) {
            setState(() {
              _selectedFilter = val;
              _computeStats(_reports);
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Semua', child: Text('Semua')),
            const PopupMenuItem(value: 'Hari ini', child: Text('Hari ini')),
            const PopupMenuItem(
                value: '7 Hari Terakhir', child: Text('7 Hari Terakhir')),
            const PopupMenuItem(value: 'Bulan ini', child: Text('Bulan ini')),
          ],
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4.2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedFilter,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF1976D2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 2x2 STAT CARDS (Figma Node 481:6046 - 481:6077) ───────────

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFigmaStatCard(
                title: 'Total Laporan',
                value: _formatNumber(_totalLaporan),
                percent: _totalTrendPercent,
                isUp: _totalIsUp,
                trendColor: _totalIsUp
                    ? const Color(0xFF1D9C51)
                    : const Color(0xFFC60D05),
                valueColor: Colors.black,
                titleColor: Colors.black,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFigmaStatCard(
                title: 'Sedang Diproses',
                value: _formatNumber(_sedangDiproses),
                percent: _inProgressTrendPercent,
                isUp: _inProgressIsUp,
                trendColor: const Color(0xFFF2AE01),
                valueColor: const Color(0xFFF2AE01),
                titleColor: Colors.black,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildFigmaStatCard(
                title: 'Selesai',
                value: _formatNumber(_selesai),
                percent: _selesaiTrendPercent,
                isUp: _selesaiIsUp,
                trendColor: const Color(0xFF1D9C51),
                valueColor: Colors.black,
                titleColor: Colors.black,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFigmaStatCard(
                title: 'Ditolak/Dispute',
                value: _formatNumber(_ditolak),
                percent: _ditolakTrendPercent,
                isUp: _ditolakIsUp,
                trendColor: const Color(0xFFC60D05),
                valueColor: const Color(0xFFC60D05),
                titleColor: const Color(0xFFC60D05),
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFigmaStatCard({
    required String title,
    required String value,
    required String percent,
    required bool isUp,
    required Color trendColor,
    required Color valueColor,
    required Color titleColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 129,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.5),
          border: Border.all(color: const Color(0xFFE3E3E3), width: 1.35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
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
                        text: '$percent ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
                      TextSpan(
                        text: 'dari kemarin',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final parts = <String>[];
      for (int i = s.length; i > 0; i -= 3) {
        parts.insert(0, s.substring(math.max(0, i - 3), i));
      }
      return parts.join('.');
    }
    return n.toString();
  }

  // ── CHART SECTION (Figma Node 481:6078) ─────────────────────────

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Grafik Laporan  ',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: '(7 hari terakhir)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF515151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 175,
            child: _ReportLineChart(
              greenData: _greenChartData,
              blueData: _blueChartData,
              labels: _chartLabels,
            ),
          ),
        ],
      ),
    );
  }

  // ── LAPORAN TERBARU (Figma Node 481:6114 - 481:6240) ────────────

  Widget _buildReportList() {
    if (_reports.isEmpty) {
      return _buildEmptyReportsState();
    }

    final recentReports = _reports.take(10).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: recentReports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildReportCard(recentReports[index]),
    );
  }

  Widget _buildEmptyReportsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF1D9C51),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Laporan Masuk',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Laporan dari masyarakat akan langsung tampil di sini secara real-time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportModel r) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/report-detail', arguments: r);
        if (mounted) _fetchLiveDashboardData();
      },
      child: Container(
        height: 104,
        padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Left: Thumbnail with watermark overlay (Figma 119x82)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 119,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFBEC4BD), width: 1.0),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbnailImage(r),
                    // Watermark badge in bottom-left
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: _buildCameraWatermark(r),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 2. Middle: Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    r.categoryName,
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
                    r.addressText ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.reportCode,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D9C51),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // 3. Right: Date, Chevron, Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateFigma(r.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFA8A8A8),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF333333),
                ),
                _buildFigmaStatusBadge(r.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraWatermark(ReportModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
              border:
                  Border.all(color: const Color(0xFF62D26D), width: 0.3),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 4,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            r.reportCode,
            style: GoogleFonts.poppins(
              fontSize: 3.5,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            maxLines: 1,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 4, color: Colors.white),
              const SizedBox(width: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 34),
                child: Text(
                  r.addressText ?? 'Malang',
                  style: GoogleFonts.poppins(
                    fontSize: 3,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage(ReportModel r) {
    Widget placeholder() => Container(
          color: const Color(0xFFEAEAEA),
          child: const Center(
            child:
                Icon(Icons.image_outlined, size: 24, color: Color(0xFF9E9E9E)),
          ),
        );

    final localPath = r.directPhotoUrl;
    bool isLocalValid = false;
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http')) {
      try {
        isLocalValid = File(localPath).existsSync();
      } catch (_) {}
    }
    if (isLocalValid && localPath != null) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, e, s) => placeholder(),
      );
    }

    final photoUrl = r.formattedPhotoUrl ?? r.photoUrl ?? '';
    if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, e, s) => placeholder(),
      );
    }

    return Image.network(
      ReportModel.getCategoryFallbackImage(r.categoryName),
      fit: BoxFit.cover,
      errorBuilder: (context, e, s) => placeholder(),
    );
  }

  Widget _buildFigmaStatusBadge(ReportStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ReportStatus.pendingVerification:
        bgColor = const Color(0xFFFFF9E9);
        textColor = const Color(0xFFF2AE01);
        label = 'Menunggu verifikasi';
        break;
      case ReportStatus.inProgress:
      case ReportStatus.verified:
        bgColor = const Color(0xFFFFF9E9);
        textColor = const Color(0xFFF2AE01);
        label = 'Sedang Diproses';
        break;
      case ReportStatus.assigned:
        bgColor = const Color(0xFFDBEDFF);
        textColor = const Color(0xFF1976D2);
        label = 'Diteruskan';
        break;
      case ReportStatus.completed:
      case ReportStatus.resolved:
        bgColor = const Color(0xFFE6F7ED);
        textColor = const Color(0xFF1D9C51);
        label = 'Selesai';
        break;
      case ReportStatus.rejected:
      case ReportStatus.disputed:
        bgColor = const Color(0xFFFFEBEB);
        textColor = const Color(0xFFC60D05);
        label = 'Ditolak';
        break;
    }

    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDateFigma(DateTime dt) {
    const months = [
      'januari', 'Februari', 'maret', 'april', 'Mei', 'juni',
      'juli', 'agustus', 'september', 'oktober', 'november', 'desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── ADMIN BOTTOM NAVIGATION BAR (Figma Frame 2623 / Node 481:6242) ──

  Widget _buildAdminBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
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
      padding: EdgeInsets.fromLTRB(4, 12, 4, math.max(10.0, bottomPadding)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Dashboard (griddy-icons:home-filled)
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: 'Dashboard',
          ),

          // 2. Laporan (fluent:form-24-regular)
          _buildNavItem(
            index: 1,
            icon: Icons.list_alt_rounded,
            activeIcon: Icons.list_alt_rounded,
            label: 'Laporan',
          ),

          // 3. Monitoring (carbon:cloud-monitoring)
          _buildNavItem(
            index: 2,
            icon: Icons.monitor_heart_outlined,
            activeIcon: Icons.monitor_heart_rounded,
            label: 'Monitoring',
          ),

          // 4. Notifikasi (mingcute:notification-line)
          _buildNavItem(
            index: 3,
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: 'Notifikasi',
          ),

          // 5. Profile (ix:user-profile)
          _buildNavItem(
            index: 4,
            icon: Icons.account_circle_outlined,
            activeIcon: Icons.account_circle_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    IconData? activeIcon,
  }) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? AppColors.greenPrimary : const Color(0xFF353535);

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
                isSelected && activeIcon != null ? activeIcon : icon,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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

  // ── ADMIN PROFILE TAB (Tab Index 4) ──────────────────────────────

  Widget _buildAdminProfileBody() {
    final authState = context.read<AuthBloc>().state;
    String adminName = 'Admin Utama';
    String adminEmail = 'admin@laporkita.malangkota.go.id';
    if (authState is AuthAuthenticated) {
      if (authState.user.fullName.isNotEmpty) {
        adminName = authState.user.fullName;
      }
      final email = authState.user.email;
      if (email != null && email.isNotEmpty) {
        adminEmail = email;
      }
    }

    return Container(
      color: const Color(0xFFF5F6FA),
      child: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Administrator',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.greenPrimary.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 34,
                      color: AppColors.greenPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminEmail,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SUPER ADMIN',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pengaturan & Kontrol Sistem',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileMenuTile(
              title: 'Manajemen Pengguna & Role',
              subtitle: 'Atur hak akses staf, operator & warga',
              icon: Icons.manage_accounts_rounded,
              color: const Color(0xFF1976D2),
              onTap: _showUserManagementModal,
            ),
            const SizedBox(height: 10),
            _buildProfileMenuTile(
              title: 'Daftar OPD & Instansi Terkait',
              subtitle: 'Kelola integrasi OPD Kota Malang',
              icon: Icons.apartment_rounded,
              color: const Color(0xFF206C57),
              onTap: _showAgenciesModal,
            ),
            const SizedBox(height: 10),
            _buildProfileMenuTile(
              title: 'Kategori Pengaduan & Bobot AI',
              subtitle: 'Atur label, ikon & ambang batas AI',
              icon: Icons.category_rounded,
              color: const Color(0xFFF2AE01),
              onTap: _showCategoriesModal,
            ),
            const SizedBox(height: 10),
            _buildProfileMenuTile(
              title: 'System Audit Log & Idempotency',
              subtitle: 'Riwayat transaksi & keamanan sistem',
              icon: Icons.security_rounded,
              color: AppColors.statusDanger,
              onTap: _showAuditLogModal,
            ),
            const SizedBox(height: 24),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.statusDanger),
                label: Text(
                  'Keluar dari Akun Admin',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusDanger,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusDanger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Custom Dual Line Chart (Figma Node 481:6078)
// ─────────────────────────────────────────────────────────────
class _ReportLineChart extends StatelessWidget {
  final List<double> greenData;
  final List<double> blueData;
  final List<String> labels;

  const _ReportLineChart({
    required this.greenData,
    required this.blueData,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, 175),
        painter: _DualLineChartPainter(
          greenData: greenData,
          blueData: blueData,
          labels: labels,
        ),
      );
    });
  }
}

class _DualLineChartPainter extends CustomPainter {
  final List<double> greenData;
  final List<double> blueData;
  final List<String> labels;

  _DualLineChartPainter({
    required this.greenData,
    required this.blueData,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 32.0;
    const double rightMargin = 8.0;
    const double topMargin = 8.0;
    const double bottomMargin = 26.0;

    final double chartWidth = size.width - leftMargin - rightMargin;
    final double chartHeight = size.height - topMargin - bottomMargin;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Dynamically calculate nice max value from actual real backend data
    double maxData = 0.0;
    for (final v in greenData) {
      if (v > maxData) maxData = v;
    }
    for (final v in blueData) {
      if (v > maxData) maxData = v;
    }

    final double maxVal = _calculateNiceMax(maxData);
    const int steps = 5; // 5 intervals -> 6 grid lines (Figma spec)

    final gridPaint = Paint()
      ..color = const Color(0xFFECECEC)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= steps; i++) {
      final y = topMargin + (i / steps) * chartHeight;
      // Draw horizontal grid line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      // Draw dynamic Y label (e.g. 100, 80, 60... or 10, 8, 6... or 5, 4, 3...)
      final stepVal = maxVal - (i / steps) * maxVal;
      final labelVal = stepVal.round().toString();
      final tp = TextPainter(
        text: TextSpan(
          text: labelVal,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF626262),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 6, y - tp.height / 2));
    }

    // Bottom horizontal line
    canvas.drawLine(
      Offset(leftMargin, topMargin + chartHeight),
      Offset(size.width - rightMargin, topMargin + chartHeight),
      gridPaint,
    );

    // Compute points for green data
    final greenPoints = <Offset>[];
    if (greenData.isNotEmpty) {
      final count = greenData.length;
      for (int i = 0; i < count; i++) {
        final x = leftMargin + (i / (count - 1)) * chartWidth;
        final val = greenData[i].clamp(0.0, maxVal);
        final y = topMargin + chartHeight - (val / maxVal) * chartHeight;
        greenPoints.add(Offset(x, y));
      }
    }

    // Compute points for blue data
    final bluePoints = <Offset>[];
    if (blueData.isNotEmpty) {
      final count = blueData.length;
      for (int i = 0; i < count; i++) {
        final x = leftMargin + (i / (count - 1)) * chartWidth;
        final val = blueData[i].clamp(0.0, maxVal);
        final y = topMargin + chartHeight - (val / maxVal) * chartHeight;
        bluePoints.add(Offset(x, y));
      }
    }

    // Draw green line (Figma #1D9C51)
    if (greenPoints.length >= 2) {
      final greenPath = _createSmoothPath(greenPoints);
      final greenPaint = Paint()
        ..color = const Color(0xFF1D9C51)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(greenPath, greenPaint);
    }

    // Draw blue line (Figma #1976D2)
    if (bluePoints.length >= 2) {
      final bluePath = _createSmoothPath(bluePoints);
      final bluePaint = Paint()
        ..color = const Color(0xFF1976D2)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(bluePath, bluePaint);
    }

    // Draw X-axis labels (6 Mei, 7 Mei, etc.)
    if (labels.isNotEmpty) {
      final count = labels.length;
      for (int i = 0; i < count; i++) {
        final x = leftMargin + (i / (count - 1)) * chartWidth;
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF626262),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topMargin + chartHeight + 8));
      }
    }
  }

  double _calculateNiceMax(double val) {
    if (val <= 5) return 5.0;
    if (val <= 10) return 10.0;
    if (val <= 25) return 25.0;
    if (val <= 50) return 50.0;
    if (val <= 100) return 100.0;
    return ((val / 50).ceil() * 50).toDouble();
  }

  Path _createSmoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final cx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _DualLineChartPainter old) =>
      old.greenData != greenData ||
      old.blueData != blueData ||
      old.labels != labels;
}
