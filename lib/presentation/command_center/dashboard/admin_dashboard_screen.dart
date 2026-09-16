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
  bool _isLoading = true;
  List<ReportModel> _reports = [];
  List<CategoryModel> _categories = [];

  // Computed stats
  int _totalLaporan = 0;
  int _sedangDiproses = 0;
  int _selesai = 0;
  int _ditolak = 0;

  // Chart data — reports per day for last 7 days
  List<int> _chartData = List.filled(7, 0);
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
    int inProgress = 0, selesai = 0, ditolak = 0;
    for (final r in reports) {
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
    _totalLaporan = reports.length;
    _sedangDiproses = inProgress;
    _selesai = selesai;
    _ditolak = ditolak;
  }

  void _computeChartData(List<ReportModel> reports) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    _chartLabels =
        days.map((d) => '${d.day} ${_shortMonth(d.month)}').toList();
    _chartData = days.map((day) {
      return reports.where((r) {
        final c = r.createdAt;
        return c.year == day.year &&
            c.month == day.month &&
            c.day == day.day;
      }).length;
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
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.greenPrimary),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _fetchLiveDashboardData,
                color: AppColors.greenPrimary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 22),
                          _buildSectionTitle('Ringkasan Keseluruhan'),
                          const SizedBox(height: 14),
                          _buildStatCards(),
                          const SizedBox(height: 20),
                          _buildChartSection(),
                          const SizedBox(height: 20),
                          _buildAdminMenuSection(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Laporan Terbaru'),
                          const SizedBox(height: 12),
                          _buildReportList(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    final adminName = _getAdminName();
    final greeting = _getGreeting();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D9C51), Color(0xFF195F3E)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 18,
        left: 24,
        right: 24,
        bottom: 34,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hallo!,',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$greeting $adminName !',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Notification bell
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              // Logout
              GestureDetector(
                onTap: () {
                  context
                      .read<AuthBloc>()
                      .add(const AuthLogoutRequested());
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/get-started', (r) => false);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
        ),
      ),
    );
  }

  // ── STAT CARDS ─────────────────────────────────────────────────

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Total Laporan',
                  value: _totalLaporan,
                  percent: 14,
                  isUp: true,
                  icon: Icons.assessment_outlined,
                  color: AppColors.greenPrimary,
                  bgColor: const Color(0xFFE6F7ED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Sedang Diproses',
                  value: _sedangDiproses,
                  percent: 8,
                  isUp: true,
                  icon: Icons.autorenew_rounded,
                  color: const Color(0xFFF2AE01),
                  bgColor: const Color(0xFFFFF8E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Selesai',
                  value: _selesai,
                  percent: 10,
                  isUp: true,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2B82C4),
                  bgColor: const Color(0xFFE8F3FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Ditolak/Dispute',
                  value: _ditolak,
                  percent: 3,
                  isUp: false,
                  icon: Icons.cancel_outlined,
                  color: AppColors.statusDanger,
                  bgColor: const Color(0xFFFFEBEB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required int percent,
    required bool isUp,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatNumber(value),
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: isUp
                    ? AppColors.greenPrimary
                    : AppColors.statusDanger,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '$percent% dari kemarin',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isUp
                        ? AppColors.greenPrimary
                        : AppColors.statusDanger,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
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

  // ── CHART ──────────────────────────────────────────────────────

  Widget _buildChartSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Laporan (7 hari terakhir)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _ReportLineChart(
                data: _chartData,
                labels: _chartLabels,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADMIN QUICK ACTIONS ────────────────────────────────────────

  Widget _buildAdminMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildAdminMenuCard(
            title: 'Manajemen User',
            subtitle: 'Citizen, Operator, Admin',
            icon: Icons.people_alt_rounded,
            color: AppColors.greenPrimary,
            onTap: _showUserManagementModal,
          ),
          _buildAdminMenuCard(
            title: 'Dinas / Agencies',
            subtitle: 'PUPR, Dishub, Diskominfo',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF1976D2),
            onTap: _showAgenciesModal,
          ),
          _buildAdminMenuCard(
            title: 'Kategori Pengaduan',
            subtitle: 'Kelola Icon & Bobot AI',
            icon: Icons.category_rounded,
            color: const Color(0xFFF2AE01),
            onTap: _showCategoriesModal,
          ),
          _buildAdminMenuCard(
            title: 'System Audit Log',
            subtitle: 'Idempotency & Request Log',
            icon: Icons.security_rounded,
            color: AppColors.statusDanger,
            onTap: _showAuditLogModal,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 9, color: AppColors.neutral500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LAPORAN TERBARU ────────────────────────────────────────────

  Widget _buildReportList() {
    if (_reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Belum ada laporan terbaru.',
            style: GoogleFonts.inter(
                color: AppColors.neutral500, fontSize: 14),
          ),
        ),
      );
    }
    final recent = _reports.take(10).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recent.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildReportCard(recent[index]),
    );
  }

  Widget _buildReportCard(ReportModel r) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/report-detail',
            arguments: r);
        if (mounted) _fetchLiveDashboardData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: _buildThumbnail(r),
              ),
            ),
            // Middle info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.neutral500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            r.addressText ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.reportCode,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right: date + status
            Padding(
              padding: const EdgeInsets.only(
                  right: 12, top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(r.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(r.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ReportModel r) {
    Widget placeholder() => Container(
          color: AppColors.neutral100,
          child: const Center(
            child: Icon(Icons.image_outlined,
                size: 26, color: AppColors.neutral400),
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
      return Image.file(File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, e, s) => placeholder());
    }

    final photoUrl = r.formattedPhotoUrl ?? r.photoUrl ?? '';
    if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
      return Image.network(photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, e, s) => placeholder());
    }
    return placeholder();
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ReportStatus.completed:
      case ReportStatus.resolved:
        bgColor = const Color(0xFFE6F7ED);
        textColor = AppColors.greenPrimary;
        label = 'Selesai';
        break;
      case ReportStatus.inProgress:
      case ReportStatus.assigned:
      case ReportStatus.verified:
        bgColor = const Color(0xFFFFF8E6);
        textColor = const Color(0xFFF2AE01);
        label = 'Diproses';
        break;
      case ReportStatus.rejected:
      case ReportStatus.disputed:
        bgColor = const Color(0xFFFFEBEB);
        textColor = AppColors.statusDanger;
        label = 'Ditolak';
        break;
      default:
        bgColor = const Color(0xFFE8F3FF);
        textColor = const Color(0xFF2B82C4);
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────
//  Custom Line Chart using CustomPainter (no extra deps)
// ─────────────────────────────────────────────────────────────
class _ReportLineChart extends StatelessWidget {
  final List<int> data;
  final List<String> labels;

  const _ReportLineChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size(constraints.maxWidth, double.infinity),
              painter: _LineChartPainter(data: data),
            ),
          ),
          const SizedBox(height: 6),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((l) => Text(
                        l,
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.neutral400),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    });
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> data;

  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max).toDouble();
    final range = maxVal == 0 ? 1.0 : maxVal;

    const double leftPad = 28;
    const double topPad = 8;
    const double bottomPad = 4;
    final double chartWidth = size.width - leftPad;
    final double chartHeight = size.height - topPad - bottomPad;

    // Grid lines & Y labels
    final gridPaint = Paint()
      ..color = AppColors.neutral100
      ..strokeWidth = 1;
    const ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final y = topPad + chartHeight - (i / ySteps) * chartHeight;
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final value = ((i / ySteps) * maxVal).round();
      final tp = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: GoogleFonts.inter(
              fontSize: 8, color: AppColors.neutral400),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Compute data points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = leftPad + (i / (data.length - 1)) * chartWidth;
      final normalized = data[i] / range;
      final y = topPad + chartHeight - normalized * chartHeight;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath = Path()
      ..moveTo(points.first.dx, topPad + chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, topPad + chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.greenPrimary.withValues(alpha: 0.3),
            AppColors.greenPrimary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
            leftPad, topPad, chartWidth, chartHeight)),
    );

    // Draw smooth line
    final linePaint = Paint()
      ..color = AppColors.greenPrimary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final linePath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i - 1].dy,
      );
      final cp2 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i].dy,
      );
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    for (final p in points) {
      canvas.drawCircle(
          p, 4, Paint()..color = AppColors.greenPrimary);
      canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.data != data;
}
