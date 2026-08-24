import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laporkita/core/theme/app_colors.dart';
import 'package:laporkita/data/datasources/remote/ai_service_datasource.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/risk_prediction_model.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/presentation/reports/bloc/report_bloc.dart';
import '../report_detail/report_detail_screen.dart';
import '../map/map_tab_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenPrimary,
      body: Stack(
        children: [
          // Screen body tab content
          IndexedStack(
            index: _currentIndex,
            children: [
              const CitizenDashboardTab(),
              const CitizenPetaTab(),
              const CitizenLaporTab(),
              const CitizenNotifikasiTab(),
              const CitizenProfileTab(),
            ],
          ),

          // Custom Floating Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCustomBottomNavBar(),
          ),
        ],
      ),
    );
  }

  /// Custom Bottom Navigation Bar matching Screenshot 2
  Widget _buildCustomBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, math.max(10.0, bottomPadding)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. Dashboard
          _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Dashboard'),

          // 2. Peta
          _buildNavItem(index: 1, icon: Icons.map_outlined, label: 'Peta'),

          // 3. Lapor (Center Prominent Green Camera Button)
          _buildCenterLaporItem(),

          // 4. Notifikasi
          _buildNavItem(
            index: 3,
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
          ),

          // 5. Profile
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Regular Nav Item (Icon + Text)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.greenPrimary : AppColors.neutral500;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Center Floating Camera Button ("Lapor")
  Widget _buildCenterLaporItem() {
    final isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/camera');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Circular Green Camera Button
          Transform.translate(
            offset: const Offset(0, -14), // Lift button above bottom navbar
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.greenPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenPrimary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              'Lapor',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: AppColors.greenPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 0: CITIZEN DASHBOARD (Matching Screenshot 1)
// =============================================================================
class CitizenDashboardTab extends StatefulWidget {
  const CitizenDashboardTab({super.key});

  @override
  State<CitizenDashboardTab> createState() => _CitizenDashboardTabState();
}

class _CitizenDashboardTabState extends State<CitizenDashboardTab> {
  final TextEditingController _searchController = TextEditingController();
  RiskPredictionResult? _riskResult;
  bool _isLoadingRisk = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportBloc>().add(const ReportLoadRequested());
      _fetchRiskPrediction();
    });
  }

  Future<void> _fetchRiskPrediction() async {
    if (!mounted) return;
    setState(() => _isLoadingRisk = true);
    try {
      final result = await AiServiceDatasource().predictRisk(
        reportDensity: 10,
        rainfallMm: 5.0,
        temperatureC: 27.0,
        weatherCondition: 'Berawan',
      );
      if (mounted) setState(() => _riskResult = result);
    } catch (_) {
      // AI service tidak tersedia — sembunyikan widget saja
    } finally {
      if (mounted) setState(() => _isLoadingRisk = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Top Green Header Section
        SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.greenPrimary,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                String userName = 'Warga';
                if (authState is AuthAuthenticated) {
                  userName = authState.user.fullName;
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Welcome Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hallo!, selamat datang',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$userName !',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ayo jaga kota kita bersama!',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Logo LK Top Right
                    Image.asset(
                      'assets/images/logoLK.png',
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'LK',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // 2. White Curved Container with Dashboard Widgets
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar & Hamburger Menu Row
                    _buildSearchBarRow(),
                    const SizedBox(height: 16),

                    // Urban Health Score Gauge Card
                    _buildUrbanHealthScoreCard(),
                    const SizedBox(height: 16),

                    // Risk Prediction Card (AI Service)
                    if (_isLoadingRisk || _riskResult != null)
                      _buildRiskPredictionCard(),
                    if (_isLoadingRisk || _riskResult != null)
                      const SizedBox(height: 16),

                    // 3 Stat Cards Row (12 Laporan Saya, 8 Sedang diproses, 5 Laporan selesai)
                    _buildStatCardsRow(),
                    const SizedBox(height: 24),

                    // Kategori Section Header & Grid/Row
                    _buildKategoriSection(),
                    const SizedBox(height: 24),

                    // Laporan Terdekat Section Header & List Cards
                    _buildLaporanTerdekatSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Search Bar + Green Hamburger Button Row
  Widget _buildSearchBarRow() {
    return Row(
      children: [
        // Search TextField Input
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari laporan, kategori, lokasi..',
                hintStyle: TextStyle(color: AppColors.neutral500, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.neutral500,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Green Hamburger Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.greenPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /// Risk Prediction Card — menampilkan hasil dari AI Service POST /v1/predict-risk
  Widget _buildRiskPredictionCard() {
    if (_isLoadingRisk) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0DFDF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.greenPrimary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Memuat prediksi kondisi wilayah...',
              style: TextStyle(fontSize: 13, color: AppColors.neutral500),
            ),
          ],
        ),
      );
    }

    final result = _riskResult!;
    final Color riskColor = result.isHighRisk
        ? const Color(0xFFE53935)
        : result.isMediumRisk
            ? const Color(0xFFF5A623)
            : AppColors.greenPrimary;
    final String riskLabel = result.isHighRisk
        ? 'TINGGI'
        : result.isMediumRisk
            ? 'SEDANG'
            : 'RENDAH';
    final IconData riskIcon = result.isHighRisk
        ? Icons.warning_amber_rounded
        : result.isMediumRisk
            ? Icons.info_rounded
            : Icons.check_circle_rounded;

    // Ikon cuaca
    final IconData weatherIcon = result.weatherCondition.toLowerCase().contains('hujan')
        ? Icons.thunderstorm_rounded
        : result.weatherCondition.toLowerCase().contains('cerah')
            ? Icons.wb_sunny_rounded
            : Icons.cloud_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withValues(alpha: 0.08),
            AppColors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header baris atas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield_rounded, color: riskColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Kondisi Risiko Wilayah',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                ],
              ),
              // Badge level risiko
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(riskIcon, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      riskLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info row: cuaca + suhu + flood risk
          Row(
            children: [
              _riskInfoChip(
                icon: weatherIcon,
                label: result.weatherCondition,
                color: const Color(0xFF2B82C4),
              ),
              const SizedBox(width: 8),
              _riskInfoChip(
                icon: Icons.thermostat_rounded,
                label: '${result.temperatureC.toStringAsFixed(0)}°C',
                color: const Color(0xFFF5A623),
              ),
              const SizedBox(width: 8),
              _riskInfoChip(
                icon: Icons.water_drop_rounded,
                label: '${result.floodRiskPercent}% banjir',
                color: riskColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rekomendasi
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 15, color: Color(0xFFF5A623)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.recommendation,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.neutral900),
                  ),
                ),
              ],
            ),
          ),

          // Tombol refresh
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _fetchRiskPrediction,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Perbarui', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: riskColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  /// Urban Health Score Card with Arc Gauge Meter dynamically calculated from report counts
  Widget _buildUrbanHealthScoreCard() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        List<ReportModel> reportList = [];
        try {
          if (state is ReportListLoaded) {
            reportList = state.reports;
          } else {
            final repo = context.read<ReportRepository>();
            reportList = repo.localSubmittedReports;
          }
        } catch (_) {}

        // Hitung Urban Health Score dinamis:
        // Skor awal 100. Semakin banyak laporan aktif (belum selesai), skor semakin turun.
        final activeCount = reportList.where((r) =>
            r.status == ReportStatus.pendingVerification ||
            r.status == ReportStatus.verified ||
            r.status == ReportStatus.assigned ||
            r.status == ReportStatus.inProgress).length;

        final completedCount = reportList.where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved).length;

        int score = 100 - (activeCount * 3) + (completedCount * 1);
        if (reportList.isEmpty) {
          score = 88; // Default skor kota sehat saat belum ada laporan
        }
        score = score.clamp(15, 100);

        final double percentage = score / 100.0;

        String statusText = 'Status : Sehat & Terkendali';
        Color statusColor = AppColors.greenPrimary;
        IconData statusIcon = Icons.check_circle_outline_rounded;

        if (score < 50) {
          statusText = 'Status : Perlu Penanganan Segera';
          statusColor = const Color(0xFFFF3D00);
          statusIcon = Icons.error_outline_rounded;
        } else if (score < 75) {
          statusText = 'Status : Waspada & Dalam Perbaikan';
          statusColor = const Color(0xFFE68A00);
          statusIcon = Icons.warning_amber_rounded;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Left City Dropdown
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Kota Malang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.neutral900,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Arc Gauge Meter (Dynamic semi circle arc gauge painter)
              SizedBox(
                width: 180,
                height: 95,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(180, 90),
                      painter: UrbanHealthArcPainter(
                        percentage: percentage,
                        arcColor: statusColor,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Title: Urban Health Score
              const Text(
                'Urban Health Score',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 4),

              // Dynamic Status Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 3 Stat Cards Row (Laporan Saya, Sedang Diproses, Laporan Selesai)
  Widget _buildStatCardsRow() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        int totalReports = 0;
        int inProgressCount = 0;
        int completedCount = 0;

        try {
          List<ReportModel> reportList = [];
          final repo = context.read<ReportRepository>();
          if (state is ReportListLoaded) {
            reportList = state.reports;
          } else {
            reportList = repo.localSubmittedReports;
          }

          final authState = context.watch<AuthBloc>().state;
          List<ReportModel> myReports = [];

          if (authState is AuthAuthenticated) {
            final String userId = authState.user.id;
            final userReports =
                reportList.where((r) => r.reporterId == userId).toList();
            final localUnsynced = repo.localSubmittedReports
                .where((lr) => !userReports.any((ur) => ur.id == lr.id))
                .toList();
            myReports = [...userReports, ...localUnsynced];
          } else {
            myReports = List.from(repo.localSubmittedReports);
          }

          totalReports = myReports.length;
          inProgressCount = myReports
              .where((r) =>
                  r.status == ReportStatus.inProgress ||
                  r.status == ReportStatus.assigned ||
                  r.status == ReportStatus.verified ||
                  r.status == ReportStatus.pendingVerification)
              .length;
          completedCount = myReports
              .where((r) =>
                  r.status == ReportStatus.completed ||
                  r.status == ReportStatus.resolved)
              .length;
        } catch (_) {}

        return Row(
          children: [
            // Card 1: Laporan Saya (Blue)
            Expanded(
              child: _buildStatItem(
                value: '$totalReports',
                label: 'Laporan Saya',
                color: const Color(0xFF2B82C4),
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Sedang diproses (Orange/Amber)
            Expanded(
              child: _buildStatItem(
                value: '$inProgressCount',
                label: 'Sedang diproses',
                color: const Color(0xFFE68A00),
              ),
            ),
            const SizedBox(width: 8),

            // Card 3: Laporan selesai (Green)
            Expanded(
              child: _buildStatItem(
                value: '$completedCount',
                label: 'Laporan selesai',
                color: AppColors.greenPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Kategori Section Header + 4 Original Category Illustration Cards
  Widget _buildKategoriSection() {
    return Column(
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Category Cards Row with original illustrations
        Row(
          children: [
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/route.png',
                label: 'Routes',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/trotoar.png',
                label: 'Trotoar',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/laluLintas.png',
                label: 'Lalu Lintas',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/fasilitasUmum.png',
                label: 'Fasilitas\nUmum',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKategoriCard({
    required String imagePath,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.grid_view_rounded,
              size: 36,
              color: AppColors.greenPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Laporan Terdekat Section Header & List Cards from ReportBloc
  Widget _buildLaporanTerdekatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Terdekat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 12),

        BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            try {
              if (state is ReportLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.greenPrimary,
                    ),
                  ),
                );
              }

              List<ReportModel> reports = [];
              if (state is ReportListLoaded) {
                reports = state.reports;
              }

              if (reports.isEmpty) {
                try {
                  final repo = context.read<ReportRepository>();
                  reports = repo.localSubmittedReports;
                } catch (_) {}
              }

              final searchQuery = _searchController.text.trim().toLowerCase();
              if (searchQuery.isNotEmpty) {
                reports = reports.where((r) {
                  final cat = r.categoryName.toLowerCase();
                  final addr = (r.addressText ?? '').toLowerCase();
                  final desc = (r.description ?? '').toLowerCase();
                  return cat.contains(searchQuery) ||
                      addr.contains(searchQuery) ||
                      desc.contains(searchQuery);
                }).toList();
              }

              if (reports.isNotEmpty) {
                final displayList = reports.take(20).toList();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReportListItemFromModel(displayList[index]),
                    );
                  },
                );
              }
            } catch (_) {}

            // Empty State jika belum ada laporan publik
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: AppColors.neutral500,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada laporan di sekitarmu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ayo buat laporan fasilitas publik pertama!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportListItemFromModel(ReportModel report) {
    try {
      Color statusBgColor = const Color(0xFFFFF8E6);
      Color statusTextColor = const Color(0xFFE68A00);

      if (report.status == ReportStatus.resolved ||
          report.status == ReportStatus.completed) {
        statusBgColor = const Color(0xFFE6F7ED);
        statusTextColor = AppColors.greenPrimary;
      } else if (report.status == ReportStatus.pendingVerification) {
        statusBgColor = const Color(0xFFE6F2FF);
        statusTextColor = const Color(0xFF2B82C4);
      } else if (report.status == ReportStatus.rejected) {
        statusBgColor = const Color(0xFFFFEFEB);
        statusTextColor = const Color(0xFFFF3D00);
      }

      final dateStr =
          '${report.createdAt.day} ${_monthName(report.createdAt.month)} ${report.createdAt.year}';

      final imgUrl = report.formattedPhotoUrl ?? report.photoUrl;
      final String? localPath = report.directPhotoUrl ?? report.photoUrl;

      bool isLocalFileValid = false;
      if (localPath != null &&
          localPath.isNotEmpty &&
          !localPath.startsWith('http')) {
        try {
          isLocalFileValid = File(localPath).existsSync();
        } catch (_) {
          isLocalFileValid = false;
        }
      }

      final Widget safePlaceholderWidget = Container(
        width: 80,
        height: 72,
        color: AppColors.greenLight,
        child: const Center(
          child: Icon(
            Icons.location_city_rounded,
            size: 32,
            color: AppColors.greenPrimary,
          ),
        ),
      );

      Widget cardImageWidget;
      if (isLocalFileValid && localPath != null) {
        cardImageWidget = Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => safePlaceholderWidget,
        );
      } else if (imgUrl != null && imgUrl.isNotEmpty) {
        cardImageWidget = Image.network(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => safePlaceholderWidget,
        );
      } else {
        cardImageWidget = safePlaceholderWidget;
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(
                reportData: {
                  'id': report.id,
                  'reportCode': report.reportCode,
                  'title': report.categoryName,
                  'date': 'Dibuat : $dateStr',
                  'address': report.addressText ?? 'Malang',
                  'fullAddress': report.addressText ?? 'Kota Malang',
                  'status': report.status.displayName,
                  'description': report.description ?? 'Laporan fasilitas umum.',
                  'photoUrl': imgUrl,
                  'imagePath': localPath,
                  'supports': report.supportCount,
                  'reportModel': report,
                },
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 72,
                  child: cardImageWidget,
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
                            report.categoryName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.addressText ?? 'Malang',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${report.supportCount} Dukungan',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            report.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[(month - 1) % 12];
  }
}

/// Custom Painter for Arc Gauge Meter ("Urban Health Score")
class UrbanHealthArcPainter extends CustomPainter {
  final double percentage; // e.g. 0.78 for 78
  final Color? arcColor;

  UrbanHealthArcPainter({required this.percentage, this.arcColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - (strokeWidth / 2);

    // 1. Background Arc (Light Grey)
    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // start at left (180 degrees)
      math.pi, // sweep 180 degrees to right
      false,
      bgPaint,
    );

    // 2. Active Arc (Dynamic Color: Green / Amber / Red)
    final activePaint = Paint()
      ..color = arcColor ?? AppColors.greenPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * percentage.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant UrbanHealthArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.arcColor != arcColor;
  }
}

// =============================================================================
// TAB 1: PETA TAB
// =============================================================================


// =============================================================================
// TAB 2: LAPOR / CAMERA VISION TAB
// =============================================================================
class CitizenLaporTab extends StatelessWidget {
  const CitizenLaporTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 64,
                color: AppColors.greenPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Citizen Vision AI Camera',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ambil foto masalah publik di sekitarmu, AI LaporKita akan mendeteksi otomatis kategori & lokasimu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              icon: const Icon(Icons.camera),
              label: const Text('Buka Kamera Lapor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 3: NOTIFIKASI TAB
// =============================================================================
// =============================================================================
// TAB 3: NOTIFIKASI TAB (Figma Node 111:2983)
// =============================================================================
class CitizenNotifikasiTab extends StatelessWidget {
  const CitizenNotifikasiTab({super.key});

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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Card 1: Perbaikan dimulai (Blue Container)
            _buildNotifCard(
              title: 'Perbaikan dimulai',
              message: 'Laporan #LP_2026_002487 sedang dikerjakan oleh petugas.',
              time: '10.46',
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF1976D2),
              bgColor: const Color(0xFFE4F2FF),
              borderColor: const Color(0xFFABD5FF),
              isUnread: true,
            ),
            const SizedBox(height: 12),

            // Card 2: Laporan anda diverifikasi
            _buildNotifCard(
              title: 'Laporan anda diverifikasi',
              message: 'Laporan #LP_2026_002487 telah diverifikasi.',
              time: '07.23',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.greenPrimary,
              bgColor: AppColors.white,
              borderColor: const Color(0xFFE0DFDF),
              isUnread: false,
            ),
            const SizedBox(height: 12),

            // Card 3: Perbaikan selesai
            _buildNotifCard(
              title: 'Perbaikan selesai',
              message: 'Laporan #LP_2026_002328 telah selesai diperbaiki',
              time: 'Kemarin',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.greenPrimary,
              bgColor: AppColors.white,
              borderColor: const Color(0xFFE0DFDF),
              isUnread: false,
            ),
            const SizedBox(height: 12),

            // Card 4: Permintaan informasi tambahan
            _buildNotifCard(
              title: 'Permintaan informasi tambahan',
              message: 'Mohon lengkapi informasi pada laporan #LP_2026_002328',
              time: '3 hari lalu',
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFE68A00),
              bgColor: AppColors.white,
              borderColor: const Color(0xFFE0DFDF),
              isUnread: false,
            ),
            const SizedBox(height: 80), // Padding for floating navbar
          ],
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
                        color: Color(0xFF565657),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF565657),
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

// =============================================================================
// TAB 4: PROFILE TAB (Figma Node 113:3320)
// =============================================================================
class CitizenProfileTab extends StatelessWidget {
  const CitizenProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String fullName = 'Warga LaporKita';
            String emailOrPhone = '-';
            int points = 0;
            String? avatarUrl;

            if (authState is AuthAuthenticated) {
              fullName = authState.user.fullName;
              emailOrPhone = authState.user.email ??
                  authState.user.phoneNumber ??
                  '-';
              points = authState.user.contributionPoints;
              avatarUrl = authState.user.avatarUrl;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Avatar & Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.greenPrimary
                                  .withValues(alpha: 0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: AppColors.greenLight,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 54,
                                        color: AppColors.greenPrimary,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.greenLight,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 54,
                                      color: AppColors.greenPrimary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emailOrPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF565657),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 16,
                                color: AppColors.greenPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$points Poin Kontribusi',
                                style: const TextStyle(
                                  fontSize: 12,
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
                  const SizedBox(height: 24),

                  // Menu Item 1: Riwayat Laporan
                  _buildProfileMenuItem(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Riwayat Laporan',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka Riwayat Laporan...'),
                          backgroundColor: AppColors.greenPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Menu Item 2: Dukungan Saya
                  _buildProfileMenuItem(
                    icon: Icons.thumb_up_alt_outlined,
                    title: 'Dukungan Saya',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka Dukungan Saya...'),
                          backgroundColor: AppColors.greenPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Menu Item 3: Pengaturan
                  _buildProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka Pengaturan...'),
                          backgroundColor: AppColors.greenPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Menu Item 4: Pusat Bantuan
                  _buildProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Pusat Bantuan',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka Pusat Bantuan...'),
                          backgroundColor: AppColors.greenPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Menu Item 5: Tentang LaporKita
                  _buildProfileMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang LaporKita',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('LaporKita v1.0.0'),
                          backgroundColor: AppColors.greenPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Logout Button (Red Outlined Container)
                  GestureDetector(
                    onTap: () {
                      context
                          .read<AuthBloc>()
                          .add(const AuthLogoutRequested());
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/get-started', (route) => false);
                    },
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFEB),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFFF3D00)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFFF3D00),
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF3D00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0DFDF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.neutral900,
            ),
          ],
        ),
      ),
    );
  }
}
