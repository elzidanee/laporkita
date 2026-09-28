import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Ringkasan Kota | Pemerintah Screen
/// Faithfully implementing Figma Node 613:3502
class GovernmentSummaryScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const GovernmentSummaryScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<GovernmentSummaryScreen> createState() =>
      _GovernmentSummaryScreenState();
}

class _GovernmentSummaryScreenState extends State<GovernmentSummaryScreen> {
  String _selectedOpd = 'Semua OPD';
  String _selectedRange = '30 Hari Terakhir';
  bool _isLoading = true;
  List<ReportModel> _reports = [];

  final List<String> _opdOptions = [
    'Semua OPD',
    'Dinas PUPR',
    'Dinas Perhubungan',
    'Dinas PU SDA',
    'Dinas Lingkungan',
    'Dinas Pertamanan',
  ];

  final List<String> _rangeOptions = [
    '7 Hari Terakhir',
    '30 Hari Terakhir',
    'Bulan Ini',
    'Tahun Ini',
    'Semua Waktu',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveReports();
  }

  Future<void> _fetchLiveReports() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<ReportRepository>();
      final response = await repository.getReports(limit: 50);
      if (mounted) {
        setState(() {
          _reports = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _checkOpdMatch(ReportModel r, String filterOpd) {
    if (filterOpd == 'Semua OPD') return true;
    final agencyName = (r.assignedAgency?['name'] ?? '').toString().toLowerCase();
    final agencyType = (r.assignedAgency?['type'] ?? '').toString().toLowerCase();
    final catName = r.categoryName.toLowerCase();
    final opdLower = filterOpd.toLowerCase();

    if (opdLower.contains('pupr')) {
      final isAgency = agencyName.contains('pupr') || agencyType.contains('pupr') || agencyName.contains('pekerjaan umum');
      final isCat = catName.contains('jalan') ||
          catName.contains('jembatan') ||
          catName.contains('trotoar') ||
          catName.contains('drainase') ||
          catName.contains('infrastruktur') ||
          catName.contains('aspal') ||
          catName.contains('lubang');
      return isAgency || isCat;
    } else if (opdLower.contains('dishub') || opdLower.contains('perhubungan')) {
      final isAgency = agencyName.contains('dishub') || agencyType.contains('dishub') || agencyName.contains('perhubungan');
      final isCat = catName.contains('rambu') ||
          catName.contains('lampu') ||
          catName.contains('lalu lintas') ||
          catName.contains('marka') ||
          catName.contains('halte') ||
          catName.contains('traffic');
      return isAgency || isCat;
    } else if (opdLower.contains('sda')) {
      final isAgency = agencyName.contains('sda') || agencyType.contains('sda');
      final isCat = catName.contains('drainase') || catName.contains('banjir') || catName.contains('sungai');
      return isAgency || isCat;
    } else if (opdLower.contains('lingkungan')) {
      final isAgency = agencyName.contains('dlh') || agencyName.contains('lingkungan');
      final isCat = catName.contains('sampah') || catName.contains('kebersihan');
      return isAgency || isCat;
    } else if (opdLower.contains('pertamanan')) {
      final isCat = catName.contains('taman') || catName.contains('pohon');
      return isCat;
    }
    return agencyName.contains(opdLower);
  }

  List<ReportModel> get _filteredReports {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _reports.where((r) {
      // 1. OPD filter
      if (_selectedOpd != 'Semua OPD') {
        if (!_checkOpdMatch(r, _selectedOpd)) return false;
      }

      // 2. Date Range filter
      if (_selectedRange == '7 Hari Terakhir') {
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        if (r.createdAt.isBefore(sevenDaysAgo)) return false;
      } else if (_selectedRange == '30 Hari Terakhir') {
        final thirtyDaysAgo = today.subtract(const Duration(days: 30));
        if (r.createdAt.isBefore(thirtyDaysAgo)) return false;
      } else if (_selectedRange == 'Bulan Ini') {
        if (r.createdAt.year != now.year || r.createdAt.month != now.month) return false;
      } else if (_selectedRange == 'Tahun Ini') {
        if (r.createdAt.year != now.year) return false;
      }
      return true;
    }).toList();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
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
              _buildZoneRiskTile('Kecamatan Kedung Kandang', '0.42',
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D9C51)),
              )
            : RefreshIndicator(
                onRefresh: _fetchLiveReports,
                color: const Color(0xFF1D9C51),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header (Chevron Back + Ringkasan Kota Title)
                      _buildHeader(),
                      const SizedBox(height: 18),

                      // 2. Filter Pills Row (Semua OPD & 30 Hari Terakhir)
                      _buildFilterRow(),
                      const SizedBox(height: 22),

                      // 3. Section 1: Perkembangan Laporan (Grafik Line Chart)
                      _buildSectionTitle('Perkembangan Laporan'),
                      const SizedBox(height: 10),
                      _buildLineChartCard(),
                      const SizedBox(height: 24),

                      // 4. Section 2: Perkembangan Laporan (Donut Chart + Breakdown)
                      _buildSectionTitle('Perkembangan Laporan'),
                      const SizedBox(height: 14),
                      _buildDonutChartSection(),
                      const SizedBox(height: 26),

                      // 5. Section 3: Wilayah dengan Laporan Terbanyak
                      _buildSectionTitle('Wilayah dengan Laporan Terbanyak'),
                      const SizedBox(height: 12),
                      _buildTopRegionsCard(),
                      const SizedBox(height: 24),

                      // 6. Section 4: Two Action Cards (Prediksi kondisi Kota & Policy Simulator)
                      _buildActionCardsRow(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── 1. HEADER (BACK BUTTON & TITLE) ──────────────────────────────
  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            'Ringkasan Kota',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. FILTER PILLS ROW ──────────────────────────────────────────
  Widget _buildFilterRow() {
    return Row(
      children: [
        // Dropdown Pill 1: Semua OPD
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFDBDBDB), width: 0.85),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4.2,
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedOpd,
              onSelected: (val) => setState(() => _selectedOpd = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => _opdOptions.map((opd) {
                return PopupMenuItem(
                  value: opd,
                  child: Text(
                    opd,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: _selectedOpd == opd
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: Color(0xFF515151),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _selectedOpd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF515151),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF515151),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Dropdown Pill 2: 30 Hari Terakhir
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFDBDBDB), width: 0.85),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4.2,
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedRange,
              onSelected: (val) => setState(() => _selectedRange = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => _rangeOptions.map((range) {
                return PopupMenuItem(
                  value: range,
                  child: Text(
                    range,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: _selectedRange == range
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF515151),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF515151),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── 3. LINE CHART CARD (GRAFIK LAPORAN 7 HARI TERAKHIR) ───────────
  Widget _buildLineChartCard() {
    final filtered = _filteredReports;
    List<double> greenData = const [10, 38, 38, 62, 82, 88];
    List<double> blueData = const [2, 20, 20, 36, 56, 72];
    List<String> labels = const ['6 Mei', '13 Mei', '20 Mei', '27 Mei', '3 Juni'];

    if (filtered.isNotEmpty) {
      final now = DateTime.now();
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      labels = [];
      greenData = [];
      blueData = [];
      for (int i = 4; i >= 0; i--) {
        final d = now.subtract(Duration(days: i * 2));
        labels.add('${d.day} ${monthNames[d.month - 1]}');
        final inBucket = filtered.where((r) => r.createdAt.isBefore(d.add(const Duration(days: 1)))).toList();
        final solvedBucket = inBucket.where((r) => r.status == ReportStatus.completed || r.status == ReportStatus.resolved).toList();
        greenData.add(inBucket.length.toDouble());
        blueData.add(solvedBucket.length.toDouble());
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Grafik Laporan  ',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: '(${_selectedRange.toLowerCase()})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF515151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Custom Painted Dual Line Chart with Grid
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _DualLineChartPainter(
                greenData: greenData,
                blueData: blueData,
                labels: labels,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. DONUT CHART SECTION (DISTRIBUSI KATEGORI) ───────────────────
  Widget _buildDonutChartSection() {
    final filtered = _filteredReports;
    final liveTotalReports = filtered.isEmpty
        ? (_reports.isEmpty ? '2.458' : '0')
        : '${filtered.length}';

    List<_CategoryLegendItem> categoryStats;
    List<_DonutSegment> segments = [];

    if (filtered.isNotEmpty) {
      int jalan = 0, lampu = 0, trotoar = 0, taman = 0, lainnya = 0;
      for (final r in filtered) {
        final cat = r.categoryName.toLowerCase();
        if (cat.contains('jalan') || cat.contains('lubang') || cat.contains('aspal')) {
          jalan++;
        } else if (cat.contains('lampu') || cat.contains('penerangan')) {
          lampu++;
        } else if (cat.contains('trotoar') || cat.contains('pedestrian')) {
          trotoar++;
        } else if (cat.contains('taman') || cat.contains('pohon')) {
          taman++;
        } else {
          lainnya++;
        }
      }
      final total = filtered.length;
      final jPct = total > 0 ? ((jalan / total) * 100).round() : 0;
      final lPct = total > 0 ? ((lampu / total) * 100).round() : 0;
      final trPct = total > 0 ? ((trotoar / total) * 100).round() : 0;
      final tmPct = total > 0 ? ((taman / total) * 100).round() : 0;
      final lnPct = total > 0 ? ((lainnya / total) * 100).round() : 0;

      categoryStats = [
        _CategoryLegendItem(
            name: 'Jalan',
            percent: '$jPct%',
            color: const Color(0xFFFF0000)),
        _CategoryLegendItem(
            name: 'Lampu Jalan',
            percent: '$lPct%',
            color: const Color(0xFFFFA500)),
        _CategoryLegendItem(
            name: 'Trotoar',
            percent: '$trPct%',
            color: const Color(0xFF00E676)),
        _CategoryLegendItem(
            name: 'Taman',
            percent: '$tmPct%',
            color: const Color(0xFF0066FF)),
        _CategoryLegendItem(
            name: 'Lainnya',
            percent: '$lnPct%',
            color: const Color(0xFFE000FF)),
      ];

      segments = [
        if (jalan > 0)
          _DonutSegment(sweepFraction: jalan / total, color: const Color(0xFFFF0000)),
        if (lampu > 0)
          _DonutSegment(sweepFraction: lampu / total, color: const Color(0xFFFFA500)),
        if (trotoar > 0)
          _DonutSegment(sweepFraction: trotoar / total, color: const Color(0xFF00E676)),
        if (taman > 0)
          _DonutSegment(sweepFraction: taman / total, color: const Color(0xFF0066FF)),
        if (lainnya > 0)
          _DonutSegment(sweepFraction: lainnya / total, color: const Color(0xFFE000FF)),
      ];
    } else {
      categoryStats = const [
        _CategoryLegendItem(
            name: 'Jalan',
            percent: '45%',
            color: Color(0xFFFF0000)), // Red
        _CategoryLegendItem(
            name: 'Lapu Jalan',
            percent: '20%',
            color: Color(0xFFFFA500)), // Orange
        _CategoryLegendItem(
            name: 'Trotoar',
            percent: '20%',
            color: Color(0xFF00E676)), // Green
        _CategoryLegendItem(
            name: 'Taman',
            percent: '20%',
            color: Color(0xFF0066FF)), // Blue
        _CategoryLegendItem(
            name: 'Lainya',
            percent: '20%',
            color: Color(0xFFE000FF)), // Magenta
      ];
      segments = const [
        _DonutSegment(sweepFraction: 0.45, color: Color(0xFFFF0000)),
        _DonutSegment(sweepFraction: 0.20, color: Color(0xFFFFA500)),
        _DonutSegment(sweepFraction: 0.15, color: Color(0xFF00E676)),
        _DonutSegment(sweepFraction: 0.10, color: Color(0xFF0066FF)),
        _DonutSegment(sweepFraction: 0.10, color: Color(0xFFE000FF)),
      ];
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Donut Chart on Left
        SizedBox(
          width: 155,
          height: 155,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(155, 155),
                painter: _DonutChartPainter(segments: segments),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    liveTotalReports,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'Total Laporan',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF626262),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Legend on Right
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in categoryStats) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.5),
                  child: Row(
                    children: [
                      // Colored circle
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category Name
                      Expanded(
                        child: Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Percentage
                      Text(
                        item.percent,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── 5. TOP REGIONS CARD ───────────────────────────────────────────
  Widget _buildTopRegionsCard() {
    final filtered = _filteredReports;
    List<_RegionItem> regions;
    if (filtered.isNotEmpty) {
      int klojen = 0, lowokwaru = 0, blimbing = 0, kedungkandang = 0;
      for (final r in filtered) {
        final addr = (r.addressText ?? '').toLowerCase();
        if (addr.contains('klojen')) {
          klojen++;
        } else if (addr.contains('lowokwaru')) {
          lowokwaru++;
        } else if (addr.contains('blimbing')) {
          blimbing++;
        } else if (addr.contains('kedung') || addr.contains('kandang')) {
          kedungkandang++;
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
      final raw = [
        {'name': 'Klojen', 'count': klojen},
        {'name': 'Lowokwaru', 'count': lowokwaru},
        {'name': 'Blimbing', 'count': blimbing},
        {'name': 'Kedung Kandang', 'count': kedungkandang},
      ];
      raw.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      regions = [
        for (int i = 0; i < raw.length; i++)
          _RegionItem(
            rank: '${i + 1}',
            name: raw[i]['name'] as String,
            count: '${raw[i]['count']} Laporan',
          ),
      ];
    } else {
      regions = const [
        _RegionItem(rank: '1', name: 'Klojen', count: '248 Laporan'),
        _RegionItem(rank: '2', name: 'Lowokwaru', count: '194 Laporan'),
        _RegionItem(rank: '3', name: 'Blimbing', count: '172 Laporan'),
        _RegionItem(rank: '4', name: 'Kedung Kandang', count: '156 Laporan'),
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < regions.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.5),
              child: Row(
                children: [
                  // Rank badge (grey circle with white digit)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8F8F8F),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      regions[i].rank,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Region name
                  Expanded(
                    child: Text(
                      regions[i].name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Report count
                  Text(
                    regions[i].count,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8F8F8F),
                    ),
                  ),
                ],
              ),
            ),
            if (i < regions.length - 1)
              const Divider(color: Color(0xFFF1F5F9), height: 8),
          ],
        ],
      ),
    );
  }

  // ── 6. TWO ACTION CARDS (PREDIKSI KONDISI KOTA & POLICY SIMULATOR) ─
  Widget _buildActionCardsRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Prediksi kondisi Kota
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 144),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13.5),
                border: Border.all(color: const Color(0xFFE3E3E3), width: 1.35),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prediksi kondisi Kota',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '3 Wilayah menunjukan peningkatan laporan.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: const Color(0xFF515151),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _showRiskPredictionModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9C51),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.8),
                          side: const BorderSide(
                              color: Color(0xFFBCFFC2), width: 0.8),
                        ),
                      ),
                      child: Text(
                        'Lihat Prediksi',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Card 2: Policy Simulator
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 144),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13.5),
                border: Border.all(color: const Color(0xFFE3E3E3), width: 1.35),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Policy Simulator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Simulasikan dampak kebijakan terhadap penggunaan laporan.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: const Color(0xFF515151),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/policy-simulator'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9C51),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.8),
                          side: const BorderSide(
                              color: Color(0xFFBCFFC2), width: 0.8),
                        ),
                      ),
                      child: Text(
                        'Buat Simulator',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegendItem {
  final String name;
  final String percent;
  final Color color;

  const _CategoryLegendItem({
    required this.name,
    required this.percent,
    required this.color,
  });
}

class _RegionItem {
  final String rank;
  final String name;
  final String count;

  const _RegionItem({
    required this.rank,
    required this.name,
    required this.count,
  });
}

/// Custom painter for the Dual Line Chart matching Figma 613:3823
class _DualLineChartPainter extends CustomPainter {
  final List<double> greenData;
  final List<double> blueData;
  final List<String> labels;

  const _DualLineChartPainter({
    required this.greenData,
    required this.blueData,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const rightMargin = 12.0;
    const topMargin = 8.0;
    const bottomMargin = 26.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;
    const maxVal = 100.0;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1.0;

    // Y Axis levels: 0, 20, 40, 60, 80, 100
    const yLevels = [100.0, 80.0, 60.0, 40.0, 20.0, 0.0];
    for (final level in yLevels) {
      final y = topMargin + chartHeight - (level / maxVal) * chartHeight;
      // Draw grid line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      // Y Label
      final tp = TextPainter(
        text: TextSpan(
          text: level.toInt().toString(),
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

    // Points for Green Line (Total Selesai)
    final greenPoints = <Offset>[];
    for (int i = 0; i < greenData.length; i++) {
      final x = leftMargin + (i / (greenData.length - 1)) * chartWidth;
      final val = greenData[i].clamp(0.0, maxVal);
      final y = topMargin + chartHeight - (val / maxVal) * chartHeight;
      greenPoints.add(Offset(x, y));
    }

    // Points for Blue Line (Total Diproses)
    final bluePoints = <Offset>[];
    for (int i = 0; i < blueData.length; i++) {
      final x = leftMargin + (i / (blueData.length - 1)) * chartWidth;
      final val = blueData[i].clamp(0.0, maxVal);
      final y = topMargin + chartHeight - (val / maxVal) * chartHeight;
      bluePoints.add(Offset(x, y));
    }

    // Draw Green Line
    if (greenPoints.length >= 2) {
      final path = _createSmoothPath(greenPoints);
      final paint = Paint()
        ..color = const Color(0xFF1D9C51)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    }

    // Draw Blue Line
    if (bluePoints.length >= 2) {
      final path = _createSmoothPath(bluePoints);
      final paint = Paint()
        ..color = const Color(0xFF1976D2)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    }

    // Draw X-axis labels
    for (int i = 0; i < labels.length; i++) {
      final x = leftMargin + (i / (labels.length - 1)) * chartWidth;
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

/// Custom painter for Donut Chart matching Figma 614:3942
class _DonutChartPainter extends CustomPainter {
  final List<_DonutSegment>? segments;

  const _DonutChartPainter({this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 22.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final list = (segments != null && segments!.isNotEmpty)
        ? segments!
        : const [
            _DonutSegment(sweepFraction: 0.45, color: Color(0xFFFF0000)),
            _DonutSegment(sweepFraction: 0.20, color: Color(0xFFFFA500)),
            _DonutSegment(sweepFraction: 0.15, color: Color(0xFF00E676)),
            _DonutSegment(sweepFraction: 0.10, color: Color(0xFF0066FF)),
            _DonutSegment(sweepFraction: 0.10, color: Color(0xFFE000FF)),
          ];

    double startAngle = -math.pi / 2;

    for (final seg in list) {
      if (seg.sweepFraction <= 0) continue;
      final sweepAngle = seg.sweepFraction * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _DonutSegment {
  final double sweepFraction;
  final Color color;

  const _DonutSegment({
    required this.sweepFraction,
    required this.color,
  });
}
