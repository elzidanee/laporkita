import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../policy_simulator/policy_simulator_screen.dart';
import '../report_management/admin_report_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Monitoring | Pemerintah (Figma Node 631:1382 & 638:1864)
// ─────────────────────────────────────────────────────────────

class AdminMonitoringScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  final int initialTabIndex; // 0: Progress (631:1382), 1: Peta Sebaran (638:1864)

  const AdminMonitoringScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  late int _activeTabIndex;
  bool _isLoading = true;

  // Metrics
  int _totalLaporan = 2458;
  int _sedangDiproses = 1286;
  int _selesai = 1072;
  int _terlambat = 100;
  int _progressPercentage = 52;

  // Category counts
  int _jalanCount = 1023;
  int _peneranganCount = 456;
  int _drainaseCount = 312;
  int _trotoarCount = 298;
  int _lainnyaCount = 369;

  // Overdue reports list
  List<ReportModel> _overdueReports = [];
  List<ReportModel> _allReports = [];

  // Map state
  final MapController _mapController = MapController();
  final String _selectedCity = 'Kota Malang';

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _fetchLiveMetrics();
  }

  Future<void> _fetchLiveMetrics() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getReports(limit: 100);
      final reports = res.data ?? [];

      if (mounted) {
        _computeMetrics(reports);
      }
    } catch (_) {
      if (mounted) {
        _computeMetrics([]);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _computeMetrics(List<ReportModel> reports) {
    _allReports = reports;

    if (reports.isEmpty) {
      // Use Figma default baseline metrics
      _totalLaporan = 2458;
      _sedangDiproses = 1286;
      _selesai = 1072;
      _terlambat = 100;
      _progressPercentage = 52;
      _jalanCount = 1023;
      _peneranganCount = 456;
      _drainaseCount = 312;
      _trotoarCount = 298;
      _lainnyaCount = 369;
      _overdueReports = _buildFallbackOverdueReports();
      return;
    }

    final total = reports.length;
    final inProgress = reports
        .where((r) =>
            r.status == ReportStatus.inProgress ||
            r.status == ReportStatus.assigned ||
            r.status == ReportStatus.verified)
        .length;
    final resolved = reports
        .where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved)
        .length;
    final overdue = reports
        .where((r) =>
            r.status != ReportStatus.completed &&
            r.status != ReportStatus.resolved &&
            ((r.urgencyScore != null &&
                    (r.urgencyScore! >= 7.0 || r.urgencyScore! >= 70)) ||
                r.needsManualReview))
        .length;

    _totalLaporan = total;
    _sedangDiproses = inProgress;
    _selesai = resolved;
    _terlambat = overdue;

    _progressPercentage = (_totalLaporan > 0)
        ? ((_selesai / _totalLaporan) * 100).round().clamp(0, 100)
        : 0;

    // Categories
    int j = 0, p = 0, d = 0, t = 0, l = 0;
    for (final r in reports) {
      final cat = r.categoryName.toLowerCase();
      if (cat.contains('jalan')) {
        j++;
      } else if (cat.contains('lampu') ||
          cat.contains('penerangan') ||
          cat.contains('rambu')) {
        p++;
      } else if (cat.contains('drainase') || cat.contains('banjir')) {
        d++;
      } else if (cat.contains('trotoar')) {
        t++;
      } else {
        l++;
      }
    }

    _jalanCount = j;
    _peneranganCount = p;
    _drainaseCount = d;
    _trotoarCount = t;
    _lainnyaCount = l;

    // Overdue reports list
    final candidateOverdue = reports.where((r) {
      return r.status != ReportStatus.completed &&
          r.status != ReportStatus.resolved;
    }).toList();

    if (candidateOverdue.isNotEmpty) {
      _overdueReports = candidateOverdue.take(5).toList();
    } else {
      _overdueReports = _buildFallbackOverdueReports();
    }
  }

  List<ReportModel> _buildFallbackOverdueReports() {
    return [
      ReportModel(
        id: 'rep-overdue-1',
        reportCode: 'LP_2026_002487',
        reporterId: 'user-1',
        categoryId: 'cat-1',
        status: ReportStatus.inProgress,
        latitude: -6.382728,
        longitude: 107.734682,
        addressText: 'Jl. Ahmad Yani no. 15',
        description: 'Jalan sudah tidak layak karena banyak retakan.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop',
        supportCount: 14,
        viewCount: 120,
        urgencyScore: 8.5,
        damageSeverity: 0.85,
        rawAiConfidenceScore: 0.98,
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 12, 10, 30),
        updatedAt: DateTime(2026, 5, 12, 10, 30),
        category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
        assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
      ),
      ReportModel(
        id: 'rep-overdue-2',
        reportCode: 'LP_2026_0038217',
        reporterId: 'user-2',
        categoryId: 'cat-2',
        status: ReportStatus.inProgress,
        latitude: -7.942150,
        longitude: 112.617820,
        addressText: 'Jl. soekarno hatta no.20 A',
        description: 'Atap dan dinding halte rusak parah.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1590674899484-d5640e854abe?q=80&w=800&auto=format&fit=crop',
        supportCount: 9,
        viewCount: 85,
        urgencyScore: 5.5,
        damageSeverity: 0.60,
        rawAiConfidenceScore: 0.92,
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 10, 14, 20),
        updatedAt: DateTime(2026, 5, 10, 14, 20),
        category: const {'id': 'cat-2', 'name': 'Halte rusak'},
        assignedAgency: const {'id': 'agency-2', 'name': 'Dinas Perhubungan'},
      ),
      ReportModel(
        id: 'rep-overdue-3',
        reportCode: 'LP_2026_0047630',
        reporterId: 'user-3',
        categoryId: 'cat-1',
        status: ReportStatus.inProgress,
        latitude: -7.954200,
        longitude: 112.614500,
        addressText: 'Jl. Veteran, Malang',
        description: 'Aspal amblas sedalam 15cm membahayakan pengendara.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=800&auto=format&fit=crop',
        supportCount: 22,
        viewCount: 160,
        urgencyScore: 9.0,
        damageSeverity: 0.88,
        rawAiConfidenceScore: 0.96,
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 8, 9, 15),
        updatedAt: DateTime(2026, 5, 8, 9, 15),
        category: const {'id': 'cat-1', 'name': 'Jalan Rusak'},
        assignedAgency: const {'id': 'agency-1', 'name': 'Dinas PUPR'},
      ),
    ];
  }

  String _formatNumber(int val) {
    final s = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Top Bar: Back Chevron + "Monitoring" + Share Button (Figma Node 631:1456 / 638:1869)
            _buildTopBar(),
            const SizedBox(height: 6),

            // Tab Bar: Progress vs Peta Sebaran (Figma Node 631:1648 / 638:1877)
            _buildTabBar(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1D9C51),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchLiveMetrics,
                      color: const Color(0xFF1D9C51),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),
                            if (_activeTabIndex == 0)
                              _buildProgressTabContent()
                            else
                              _buildPetaSebaranTabContent(),
                            const SizedBox(height: 36),
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

  // ── TOP BAR (Figma Node 631:1456 & 638:1869) ──────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(20.5),
              child: Container(
                width: 41,
                height: 41,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 34,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              'Monitoring',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.share_outlined,
                size: 24,
                color: Colors.black,
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'Monitoring Kebijakan & Laporan Kota Malang\nTotal Laporan: $_totalLaporan\nSelesai: $_selesai\nSedang Diproses: $_sedangDiproses',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ringkasan monitoring disalin ke clipboard!'),
                    backgroundColor: Color(0xFF1D9C51),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR (Figma Node 631:1648 & 638:1877) ──────────────────────

  Widget _buildTabBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTabIndex = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    'Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: _activeTabIndex == 0
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _activeTabIndex == 0
                          ? const Color(0xFF1D9C51)
                          : const Color(0xFF8F8F8F),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTabIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    'Peta Sebaran',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: _activeTabIndex == 1
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _activeTabIndex == 1
                          ? const Color(0xFF1D9C51)
                          : const Color(0xFF8F8F8F),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Indicator underline + horizontal separator (Figma node 631:1647 & 631:1651)
        Stack(
          children: [
            Container(
              height: 1.0,
              color: const Color(0xFFE0DFDF),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _activeTabIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Center(
                  child: Container(
                    height: 3.0,
                    width: 151,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9C51),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  TAB 1: PROGRESS (Figma Node 631:1382)
  // ═════════════════════════════════════════════════════════════════

  Widget _buildProgressTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 2x2 Stat Cards (Figma 632:1653, 632:1661, 632:1669, 632:1677)
        _buildStatCardsGrid(),

        const SizedBox(height: 24),

        // 2. Progress Penanganan Section (Figma 634:1694 & 634:1686)
        Text(
          'Progress Penanganan',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildProgressPenangananCard(),

        const SizedBox(height: 24),

        // 3. Grafik Laporan (7 hari terakhir) (Figma 636:1706)
        _buildGrafikLaporanCard(),

        const SizedBox(height: 24),

        // 4. Kategori Laporan Section (Figma 636:1742)
        Text(
          'Kategori Laporan',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        _buildKategoriLaporanList(),

        const SizedBox(height: 24),

        // 5. Analisis & Kebijakan Banner (Figma 645:3571)
        _buildAnalisisKebijakanBanner(),

        const SizedBox(height: 26),

        // 6. Laporan Terlambat Section (Figma 646:3940)
        Text(
          'Laporan Terlambat',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        _buildLaporanTerlambatList(),
      ],
    );
  }

  // ── STAT CARDS GRID (Figma Node 632:1653 - 632:1684) ──────────────

  Widget _buildStatCardsGrid() {
    return Column(
      children: [
        // Row 1: Total Laporan & Sedang Diproses
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 95),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.5),
                    border: Border.all(
                        color: const Color(0xFFE3E3E3), width: 1.35),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Laporan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatNumber(_totalLaporan),
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.6,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 95),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.5),
                    border: Border.all(
                        color: const Color(0xFFE3E3E3), width: 1.35),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sedang Diproses',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF2AE01),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatNumber(_sedangDiproses),
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.6,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Row 2: Selesai & Terlambat (with "dari seminggu lalu")
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 125),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.5),
                    border: Border.all(
                        color: const Color(0xFFE3E3E3), width: 1.35),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selesai',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D9C51),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatNumber(_selesai),
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'dari seminggu lalu',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 125),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.5),
                    border: Border.all(
                        color: const Color(0xFFE3E3E3), width: 1.35),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terlambat',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFC60D05),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatNumber(_terlambat),
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'dari seminggu lalu',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── PROGRESS PENANGANAN CARD (Figma Node 634:1686 & 636:1702) ─────

  Widget _buildProgressPenangananCard() {
    return Row(
      children: [
        // Custom Donut Chart (155x155)
        SizedBox(
          width: 155,
          height: 155,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(155, 155),
                painter: _ProgressDonutPainter(
                  percentage: _progressPercentage.toDouble(),
                ),
              ),
              Text(
                '$_progressPercentage%',
                style: GoogleFonts.poppins(
                  fontSize: 20.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 22),

        // Text Right
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan Selesai',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _formatNumber(_selesai),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D9C51),
                      ),
                    ),
                    TextSpan(
                      text: '  dari ${_formatNumber(_totalLaporan)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
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
    );
  }

  // ── GRAFIK LAPORAN (Figma Node 636:1706) ──────────────────────────

  Widget _buildGrafikLaporanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _MonitoringLineChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  // ── KATEGORI LAPORAN LIST (Figma Node 636:1743) ───────────────────

  Widget _buildKategoriLaporanList() {
    final categories = [
      {'name': 'Jalan', 'count': _jalanCount, 'pct': '41%'},
      {'name': 'Penerangan', 'count': _peneranganCount, 'pct': '19%'},
      {'name': 'Drainase', 'count': _drainaseCount, 'pct': '13%'},
      {'name': 'Trotoar', 'count': _trotoarCount, 'pct': '12%'},
      {'name': 'Lainnya', 'count': _lainnyaCount, 'pct': '15%'},
    ];

    return Column(
      children: categories.map((cat) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFF1D9C51), width: 0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4.2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Green indicator strip at left
                Container(
                  width: 9,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D9C51),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  cat['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13.7,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF515151),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_formatNumber(cat['count'] as int)} (${cat['pct']})',
                  style: GoogleFonts.poppins(
                    fontSize: 13.7,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF515151),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── ANALISIS & KEBIJAKAN BANNER (Figma Node 645:3571) ─────────────

  Widget _buildAnalisisKebijakanBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          // Warning Icon
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFF2AE01),
              size: 30,
            ),
          ),
          const SizedBox(width: 10),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisis & Kebijakan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Simulasi dampak kebijakan terhadap penanganan laporan dan kondisi wilayah.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF515151),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Button: Buka Policy Simulator
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PolicySimulatorScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9C51),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 27),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: const BorderSide(color: Color(0xFFB9D19E), width: 0.87),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buka Policy Simulator',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LAPORAN TERLAMBAT LIST (Figma Node 646:3603) ───────────────────

  Widget _buildLaporanTerlambatList() {
    return Column(
      children: _overdueReports.map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminReportDetailScreen(report: report),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 97,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                children: [
                  // Photo with telemetry stamp
                  Container(
                    width: 119,
                    height: 83,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBEC4BD),
                        width: 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImageWidget(report.formattedPhotoUrl ??
                              report.directPhotoUrl),
                          // Watermark
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.52),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0x9942A54B),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'LaporKita',
                                          style: GoogleFonts.poppins(
                                            fontSize: 5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    report.reportCode.replaceAll('-', '_'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 5.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Middle Information
                  Expanded(
                    child: SizedBox(
                      height: 83,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.categoryName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                report.addressText ?? 'Jl. Malang, Jawa Timur',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  report.reportCode.startsWith('#')
                                      ? report.reportCode
                                      : '#${report.reportCode}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF1D9C51),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  report.assignedAgency?['name'] ?? 'Dinas PUPR',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w300,
                                    color: const Color(0xFF8F8F8F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right Badge & Chevron
                  SizedBox(
                    height: 83,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildPriorityTag(report),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityTag(ReportModel r) {
    final isTinggi = (r.urgencyScore != null &&
            (r.urgencyScore! >= 70 || r.urgencyScore! >= 7.0)) ||
        r.categoryName.toLowerCase().contains('jalan');

    if (isTinggi) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Prioritas Tinggi',
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFC60D05),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Sedang',
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFF2AE01),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? photoUrl) {
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('http')) {
      try {
        final f = File(photoUrl);
        if (f.existsSync()) {
          return Image.file(f, fit: BoxFit.cover);
        }
      } catch (_) {}
    }

    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackRoadImage(),
      );
    }

    return _buildFallbackRoadImage();
  }

  Widget _buildFallbackRoadImage() {
    return Image.network(
      'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF0F4F8),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 28, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  TAB 2: PETA SEBARAN (Figma Node 638:1864)
  // ═════════════════════════════════════════════════════════════════

  Widget _buildPetaSebaranTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Interactive Map Container with Floating Overlays (Figma 640:3567)
        _buildPetaSebaranMapContainer(),

        const SizedBox(height: 24),

        // 2. Ringkasan Lokasi Section (Figma 640:3501)
        Text(
          'Ringkasan Lokasi',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        _buildRingkasanLokasiCard(),

        const SizedBox(height: 24),

        // 3. Analisis & Kebijakan Banner (Figma 645:3571)
        _buildAnalisisKebijakanBanner(),

        const SizedBox(height: 26),

        // 4. Laporan Terlambat Section (Figma 646:3940)
        Text(
          'Laporan Terlambat',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        _buildLaporanTerlambatList(),
      ],
    );
  }

  // ── MAP CONTAINER (Figma Node 640:3567 & 638:3111 - 638:3230) ────

  Widget _buildPetaSebaranMapContainer() {
    final centerPoint = const LatLng(-7.983908, 112.621391); // Kota Malang

    // Marker locations from live backend reports or Figma baseline pins
    final List<Map<String, dynamic>> markerItems = [];
    if (_allReports.isNotEmpty) {
      for (final r in _allReports) {
        if (r.latitude != 0 && r.longitude != 0) {
          final isTinggi = (r.urgencyScore != null &&
                  (r.urgencyScore! >= 70 || r.urgencyScore! >= 7.0)) ||
              r.status == ReportStatus.pendingVerification;
          final isSedang = (r.urgencyScore != null &&
                  (r.urgencyScore! >= 40 || r.urgencyScore! >= 4.0)) ||
              r.status == ReportStatus.inProgress;

          markerItems.add({
            'point': LatLng(r.latitude, r.longitude),
            'priority': isTinggi ? 'Tinggi' : (isSedang ? 'Sedang' : 'Rendah'),
            'color': isTinggi
                ? const Color(0xFFC60D05)
                : (isSedang
                    ? const Color(0xFFF2AE01)
                    : const Color(0xFF1D9C51)),
            'title': r.categoryName.isNotEmpty ? r.categoryName : 'Laporan',
            'img': r.formattedPhotoUrl ??
                r.photoUrl ??
                'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=400&auto=format&fit=crop',
          });
        }
      }
    }
    if (markerItems.isEmpty) {
      markerItems.addAll(const [
        {
          'point': LatLng(-7.975000, 112.628000), // Klojen/Ahmad Yani
          'priority': 'Tinggi',
          'color': Color(0xFFC60D05),
          'title': 'Jalan Rusak',
          'img':
              'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=400&auto=format&fit=crop',
        },
        {
          'point': LatLng(-7.982000, 112.618000), // Jembatan
          'priority': 'Sedang',
          'color': Color(0xFFF2AE01),
          'title': 'Jembatan Rusak',
          'img':
              'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=400&auto=format&fit=crop',
        },
        {
          'point': LatLng(-7.971000, 112.634000), // Taman
          'priority': 'Rendah',
          'color': Color(0xFF1D9C51),
          'title': 'Bangku Rusak',
          'img':
              'https://images.unsplash.com/photo-1590674899484-d5640e854abe?q=80&w=400&auto=format&fit=crop',
        },
        {
          'point': LatLng(-7.992000, 112.616000), // Subardjo
          'priority': 'Sedang',
          'color': Color(0xFFF2AE01),
          'title': 'Penerangan Jalan',
          'img':
              'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=400&auto=format&fit=crop',
        },
        {
          'point': LatLng(-7.990000, 112.632000), // Simpang Ibrahim
          'priority': 'Rendah',
          'color': Color(0xFF1D9C51),
          'title': 'Trotoar Rusak',
          'img':
              'https://images.unsplash.com/photo-1590674899484-d5640e854abe?q=80&w=400&auto=format&fit=crop',
        },
      ]);
    }

    return Container(
      width: double.infinity,
      height: 469,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBEC4BD), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 1. FlutterMap Tile Layer
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 14.2,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.laporkita.app',
                ),
                MarkerLayer(
                  markers: markerItems.map((m) {
                    final color = m['color'] as Color;
                    final img = m['img'] as String;
                    final pt = m['point'] as LatLng;

                    return Marker(
                      point: pt,
                      width: 50,
                      height: 56,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${m['title']} (${m['priority']}) terpilih di peta'),
                              backgroundColor: color,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color, width: 2.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Tiny triangle pointer
                            CustomPaint(
                              size: const Size(10, 6),
                              painter: _TrianglePainter(color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // 2. Top-Left Dropdown Pill: Kota Malang (Figma Node 638:1864)
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCity,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top-Right Settings / Layer Button
            Positioned(
              right: 14,
              top: 14,
              child: InkWell(
                onTap: () {
                  _mapController.move(centerPoint, 14.2);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // 4. Bottom-Right GPS Locate & Compass Buttons
            Positioned(
              right: 14,
              bottom: 60,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      _mapController.move(centerPoint, 15.5);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      _mapController.rotate(0);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Bottom Legend Pill (Figma Node 638:1864)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Center(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFE0DFDF), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      // Red dot: Tinggi
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC60D05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tinggi (>=10)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Yellow dot: Sedang
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2AE01),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sedang (5-9)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Green dot: Rendah
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D9C51),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rendah (1-4)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RINGKASAN LOKASI CARD (Figma Node 640:3503) ───────────────────

  Widget _buildRingkasanLokasiCard() {
    List<Map<String, dynamic>> subdistricts;

    if (_allReports.isNotEmpty) {
      int klojen = 0, lowokwaru = 0, blimbing = 0, kedungkandang = 0, sukun = 0;
      for (final r in _allReports) {
        final addr = (r.addressText ?? '').toLowerCase();
        if (addr.contains('klojen')) {
          klojen++;
        } else if (addr.contains('lowokwaru')) {
          lowokwaru++;
        } else if (addr.contains('blimbing')) {
          blimbing++;
        } else if (addr.contains('kedung') || addr.contains('kandang')) {
          kedungkandang++;
        } else if (addr.contains('sukun')) {
          sukun++;
        } else {
          if (r.latitude > -7.96) {
            lowokwaru++;
          } else if (r.longitude > 112.64) {
            blimbing++;
          } else {
            klojen++;
          }
        }
      }

      final rawList = [
        {'name': 'Klojen', 'count': klojen},
        {'name': 'Lowokwaru', 'count': lowokwaru},
        {'name': 'Blimbing', 'count': blimbing},
        {'name': 'Kedung Kandang', 'count': kedungkandang},
        {'name': 'Sukun', 'count': sukun},
      ];
      rawList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      subdistricts = [];
      for (int i = 0; i < math.min(4, rawList.length); i++) {
        subdistricts.add({
          'num': '${i + 1}',
          'name': rawList[i]['name'] as String,
          'count': rawList[i]['count'] as int,
        });
      }
    } else {
      subdistricts = [
        {'num': '1', 'name': 'Klojen', 'count': 248},
        {'num': '2', 'name': 'Lowokwaru', 'count': 194},
        {'num': '3', 'name': 'Blimbing', 'count': 172},
        {'num': '4', 'name': 'Kedung Kandang', 'count': 156},
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
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
        children: subdistricts.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // Circular Digit Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8F8F8F),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item['num'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name
                Expanded(
                  child: Text(
                    item['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Count
                Text(
                  '${item['count']} Laporan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8F8F8F),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAINTERS: DONUT CHART & LINE CHART
// ─────────────────────────────────────────────────────────────

class _ProgressDonutPainter extends CustomPainter {
  final double percentage;

  _ProgressDonutPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 20.0;

    // Background track (lighter green)
    final bgPaint = Paint()
      ..color = const Color(0xFF5EE18B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc (solid deep green #1D9C51)
    final progressPaint = Paint()
      ..color = const Color(0xFF1D9C51)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const startAngle = -math.pi / 2;
    final sweepAngle = (percentage / 100.0) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Subtle sector division lines as in Figma (Node 634:1688 - 634:1692)
    final dividerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final p1 = Offset(
        center.dx + (radius - strokeWidth / 2) * math.cos(angle),
        center.dy + (radius - strokeWidth / 2) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + strokeWidth / 2) * math.cos(angle),
        center.dy + (radius + strokeWidth / 2) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, dividerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressDonutPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

class _MonitoringLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 32.0;
    const bottomPadding = 24.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1.0;

    final yLabels = ['100', '80', '60', '40', '20', '0'];
    final textStyle = GoogleFonts.poppins(
      fontSize: 10.5,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF626262),
    );

    // Draw horizontal grid lines & Y labels
    for (int i = 0; i < yLabels.length; i++) {
      final y = (i / (yLabels.length - 1)) * chartHeight;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      final textSpan = TextSpan(text: yLabels[i], style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }

    // X labels: 6 Mei, 13 Mei, 20 Mei, 27 Mei, 3 Juni
    final xLabels = ['6 Mei', '13 Mei', '20 Mei', '27 Mei', '3 Juni'];
    final xStep = chartWidth / (xLabels.length - 1);

    for (int i = 0; i < xLabels.length; i++) {
      final x = leftPadding + (i * xStep);
      final textSpan = TextSpan(text: xLabels[i], style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(x - tp.width / 2, chartHeight + 8));
    }

    // Green line values (normalized 0..100)
    // 6 Mei: 15, 13 Mei: 38, 20 Mei: 58, 27 Mei: 82, 3 Juni: 88
    final greenPoints = [
      Offset(leftPadding + (0 * xStep), chartHeight - (15 / 100) * chartHeight),
      Offset(leftPadding + (1 * xStep), chartHeight - (38 / 100) * chartHeight),
      Offset(leftPadding + (2 * xStep), chartHeight - (58 / 100) * chartHeight),
      Offset(leftPadding + (3 * xStep), chartHeight - (82 / 100) * chartHeight),
      Offset(leftPadding + (4 * xStep), chartHeight - (88 / 100) * chartHeight),
    ];

    // Blue line values
    // 6 Mei: 5, 13 Mei: 20, 20 Mei: 32, 27 Mei: 52, 3 Juni: 68
    final bluePoints = [
      Offset(leftPadding + (0 * xStep), chartHeight - (5 / 100) * chartHeight),
      Offset(leftPadding + (1 * xStep), chartHeight - (20 / 100) * chartHeight),
      Offset(leftPadding + (2 * xStep), chartHeight - (32 / 100) * chartHeight),
      Offset(leftPadding + (3 * xStep), chartHeight - (52 / 100) * chartHeight),
      Offset(leftPadding + (4 * xStep), chartHeight - (68 / 100) * chartHeight),
    ];

    // Draw Blue line
    final bluePaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bluePath = Path();
    bluePath.moveTo(bluePoints[0].dx, bluePoints[0].dy);
    for (int i = 1; i < bluePoints.length; i++) {
      bluePath.lineTo(bluePoints[i].dx, bluePoints[i].dy);
    }
    canvas.drawPath(bluePath, bluePaint);

    // Draw Green line
    final greenPaint = Paint()
      ..color = const Color(0xFF1D9C51)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final greenPath = Path();
    greenPath.moveTo(greenPoints[0].dx, greenPoints[0].dy);
    for (int i = 1; i < greenPoints.length; i++) {
      greenPath.lineTo(greenPoints[i].dx, greenPoints[i].dy);
    }
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
