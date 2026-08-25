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
import '../../report_detail/report_detail_screen.dart';

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
  bool _riskError = false;

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
    setState(() {
      _isLoadingRisk = true;
      _riskError = false;
    });
    try {
      final result = await AiServiceDatasource().predictRisk(
        reportDensity: 10,
        rainfallMm: 5.0,
        temperatureC: 27.0,
        weatherCondition: 'Berawan',
      );
      if (mounted) setState(() => _riskResult = result);
    } catch (_) {
      // AI service tidak tersedia — tampilkan fallback card
      if (mounted) setState(() => _riskError = true);
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
                    _buildRiskPredictionCard(),
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
          border: Border.all(color: AppColors.neutral200),
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

    // Fallback card ketika AI service tidak tersedia
    if (_riskError || _riskResult == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.statusPending.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.statusPending, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediksi Cuaca Tidak Tersedia',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tidak dapat terhubung ke layanan AI',
                    style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _fetchRiskPrediction,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Coba Lagi', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.greenPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    final result = _riskResult!;
    final Color riskColor = result.isHighRisk
        ? AppColors.statusDanger
        : result.isMediumRisk
            ? AppColors.statusPending
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
                color: AppColors.statusInfo,
              ),
              const SizedBox(width: 8),
              _riskInfoChip(
                icon: Icons.thermostat_rounded,
                label: '${result.temperatureC.toStringAsFixed(0)}°C',
                color: AppColors.statusPending,
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
                    size: 15, color: AppColors.statusPending),
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
          statusColor = AppColors.statusDanger;
          statusIcon = Icons.error_outline_rounded;
        } else if (score < 75) {
          statusText = 'Status : Waspada & Dalam Perbaikan';
          statusColor = AppColors.statusWarning;
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
                color: AppColors.statusInfo,
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Sedang diproses (Orange/Amber)
            Expanded(
              child: _buildStatItem(
                value: '$inProgressCount',
                label: 'Sedang diproses',
                color: AppColors.statusWarning,
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
      Color statusBgColor = AppColors.surfaceWarning;
      Color statusTextColor = AppColors.statusWarning;

      if (report.status == ReportStatus.resolved ||
          report.status == ReportStatus.completed) {
        statusBgColor = AppColors.surfaceSuccess;
        statusTextColor = AppColors.greenPrimary;
      } else if (report.status == ReportStatus.pendingVerification) {
        statusBgColor = const Color(0xFFE6F2FF);
        statusTextColor = AppColors.statusInfo;
      } else if (report.status == ReportStatus.rejected) {
        statusBgColor = const Color(0xFFFFEFEB);
        statusTextColor = AppColors.statusDanger;
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
      ..color = AppColors.border
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
