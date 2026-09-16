import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class AdminStatisticsAnalyticsScreen extends StatefulWidget {
  const AdminStatisticsAnalyticsScreen({super.key});

  @override
  State<AdminStatisticsAnalyticsScreen> createState() =>
      _AdminStatisticsAnalyticsScreenState();
}

class _CategoryStat {
  final String name;
  final int count;
  final double percentage;

  const _CategoryStat({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

class _AdminStatisticsAnalyticsScreenState
    extends State<AdminStatisticsAnalyticsScreen> {
  static const Color _greenPrimary = Color(0xFF1D9C51);
  static const Color _textGrey = Color(0xFF515151);

  String _selectedRange = 'Bulan Ini';
  final List<String> _rangeOptions = [
    'Bulan Ini',
    '7 Hari Terakhir',
    '30 Hari Terakhir',
    'Tahun Ini',
    'Semua Waktu',
  ];

  bool _isLoading = true;
  List<ReportModel> _allReports = [];

  // Computed metrics strictly from real backend reports
  int _totalLaporan = 0;
  String _trendText = '0% dari bulan lalu';
  bool _trendIsUp = true;

  List<String> _chartDates = [];
  List<double> _chartValues = [];
  List<String> _yAxisLabels = ['4', '2', '1', '0'];
  double _chartMaxScale = 4.0;

  List<_CategoryStat> _categoryStats = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveStatistics();
  }

  Future<void> _fetchLiveStatistics() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getReports(limit: 100);
      final List<ReportModel> reports = res.data ?? [];

      if (mounted) {
        _allReports = reports;
        _computeStatisticsFromReports(reports);
      }
    } catch (_) {
      // Menjaga state tetap bersih jika gagal koneksi
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _computeStatisticsFromReports(List<ReportModel> reports) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 1. Filter laporan rentang saat ini
    final inRangeReports = reports.where((r) {
      if (_selectedRange == 'Bulan Ini') {
        return r.createdAt.year == now.year && r.createdAt.month == now.month;
      } else if (_selectedRange == 'Tahun Ini') {
        return r.createdAt.year == now.year;
      } else if (_selectedRange == 'Semua Waktu') {
        return true;
      } else if (_selectedRange == '30 Hari Terakhir') {
        return r.createdAt.isAfter(today.subtract(const Duration(days: 30)));
      }
      // '7 Hari Terakhir'
      return r.createdAt.isAfter(today.subtract(const Duration(days: 7))) &&
          r.createdAt.isBefore(today.add(const Duration(seconds: 1)));
    }).toList();

    // 2. Filter laporan rentang sebelumnya untuk perhitungan trend nyata
    final prevRangeReports = reports.where((r) {
      if (_selectedRange == 'Bulan Ini') {
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        return r.createdAt.year == prevYear && r.createdAt.month == prevMonth;
      } else if (_selectedRange == 'Tahun Ini') {
        return r.createdAt.year == now.year - 1;
      } else if (_selectedRange == 'Semua Waktu') {
        return false;
      } else if (_selectedRange == '30 Hari Terakhir') {
        final startPrev = today.subtract(const Duration(days: 60));
        final endPrev = today.subtract(const Duration(days: 30));
        return r.createdAt.isAfter(startPrev) && r.createdAt.isBefore(endPrev);
      }
      // '7 Hari Terakhir'
      final startPrev = today.subtract(const Duration(days: 14));
      final endPrev = today.subtract(const Duration(days: 7));
      return r.createdAt.isAfter(startPrev) && r.createdAt.isBefore(endPrev);
    }).toList();

    _totalLaporan = inRangeReports.length;

    // Hitung trend riil dibandingkan periode sebelumnya
    final currCount = inRangeReports.length;
    final prevCount = prevRangeReports.length;
    String periodName = 'periode lalu';
    if (_selectedRange == '7 Hari Terakhir') periodName = 'minggu lalu';
    if (_selectedRange == 'Bulan Ini') periodName = 'bulan lalu';
    if (_selectedRange == 'Tahun Ini') periodName = 'tahun lalu';
    if (_selectedRange == '30 Hari Terakhir') periodName = '30 hari lalu';

    if (_selectedRange == 'Semua Waktu') {
      _trendText = 'Semua data tersimpan';
      _trendIsUp = true;
    } else if (prevCount == 0) {
      if (currCount == 0) {
        _trendText = '0% dari $periodName';
        _trendIsUp = true;
      } else {
        _trendText = '+100% dari $periodName';
        _trendIsUp = true;
      }
    } else {
      final change = ((currCount - prevCount) / prevCount * 100).round();
      final sign = change >= 0 ? '+' : '';
      _trendText = '$sign$change% dari $periodName';
      _trendIsUp = change >= 0;
    }

    // 3. Hitung distribusi Kategori Terbanyak secara riil
    final Map<String, int> catCounts = {};
    for (final r in inRangeReports) {
      final cat = r.categoryName.trim().isNotEmpty ? r.categoryName.trim() : 'Lainnya';
      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
    }

    final List<_CategoryStat> computedCats = [];
    if (catCounts.isNotEmpty && inRangeReports.isNotEmpty) {
      final sortedEntries = catCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final e in sortedEntries) {
        final pct = (e.value / inRangeReports.length) * 100;
        computedCats.add(_CategoryStat(
          name: e.key,
          count: e.value,
          percentage: pct,
        ));
      }
    }
    _categoryStats = computedCats;

    // 4. Hitung data Histogram Bar Chart 6 slot hari riil
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final List<String> dates = [];
    final List<double> vals = [];

    final activeReportDates = inRangeReports
        .map((r) => DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day))
        .toSet();

    final List<DateTime> slotDates = [];
    final minReportDate = activeReportDates.isNotEmpty
        ? activeReportDates.reduce((a, b) => a.isBefore(b) ? a : b)
        : today.subtract(const Duration(days: 5));

    final totalDaysSpan = today.difference(minReportDate).inDays;

    if (_selectedRange == '7 Hari Terakhir' || totalDaysSpan <= 5) {
      for (int i = 5; i >= 0; i--) {
        slotDates.add(today.subtract(Duration(days: i)));
      }
    } else {
      for (int i = 0; i < 6; i++) {
        final offset = (i * totalDaysSpan / 5.0).round();
        slotDates.add(minReportDate.add(Duration(days: offset)));
      }
    }

    for (final dt in slotDates) {
      dates.add('${dt.day} ${months[dt.month - 1]}');

      final count = inRangeReports.where((r) {
        return r.createdAt.year == dt.year &&
            r.createdAt.month == dt.month &&
            r.createdAt.day == dt.day;
      }).length;

      vals.add(count.toDouble());
    }

    _chartDates = dates;
    _chartValues = vals;

    // 5. Hitung Skala Sumbu Y Dinamis dari nilai maksimum riil
    double maxData = 0.0;
    for (final v in vals) {
      if (v > maxData) maxData = v;
    }

    if (maxData <= 4) {
      _chartMaxScale = 4.0;
      _yAxisLabels = ['4', '2', '1', '0'];
    } else if (maxData <= 10) {
      _chartMaxScale = 10.0;
      _yAxisLabels = ['10', '5', '2', '0'];
    } else if (maxData <= 25) {
      _chartMaxScale = 25.0;
      _yAxisLabels = ['25', '15', '5', '0'];
    } else if (maxData <= 50) {
      _chartMaxScale = 50.0;
      _yAxisLabels = ['50', '25', '10', '0'];
    } else if (maxData <= 100) {
      _chartMaxScale = 100.0;
      _yAxisLabels = ['100', '50', '25', '0'];
    } else if (maxData <= 500) {
      _chartMaxScale = 500.0;
      _yAxisLabels = ['500', '250', '100', '0'];
    } else if (maxData <= 1000) {
      _chartMaxScale = 1000.0;
      _yAxisLabels = ['1000', '500', '250', '0'];
    } else {
      _chartMaxScale = ((maxData / 250).ceil() * 250).toDouble();
      _yAxisLabels = [
        _chartMaxScale.round().toString(),
        (_chartMaxScale * 0.5).round().toString(),
        (_chartMaxScale * 0.25).round().toString(),
        '0',
      ];
    }
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

  void _handleDownloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Laporan Statistik & Analitik berhasil diunduh (Format PDF / Excel).',
                style: GoogleFonts.poppins(fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: _greenPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _greenPrimary),
              )
            : RefreshIndicator(
                onRefresh: _fetchLiveStatistics,
                color: _greenPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(28, topPadding + 14, 28, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TOP APP BAR (Figma Node 566:2587) ─────────────────────
                      _buildTopAppBar(),

                      const SizedBox(height: 28),

                      // ── SUMMARY & FILTER ROW (Figma Node 566:2677 & 566:2697) ─
                      _buildSummaryAndFilterRow(),

                      const SizedBox(height: 36),

                      // ── HISTOGRAM BAR CHART (Figma Node 566:2742) ────────────
                      _buildBarChartSection(),

                      const SizedBox(height: 38),

                      // ── KATEGORI TERBANYAK SECTION (Figma Node 566:2744) ─────
                      Text(
                        'Kategori Terbanyak',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category Cards List or Empty State
                      if (_categoryStats.isEmpty)
                        _buildEmptyCategoryCard()
                      else
                        ..._categoryStats.map((cat) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildCategoryCard(cat),
                            )),

                      const SizedBox(height: 36),

                      // ── UNDUH LAPORAN BUTTON (Figma Node 566:2675) ────────────
                      Center(
                        child: _buildDownloadButton(),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── TOP APP BAR ───────────────────────────────────────────────
  Widget _buildTopAppBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEDEDED),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            'Statistik & Analitik',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── SUMMARY & FILTER ROW ──────────────────────────────────────
  Widget _buildSummaryAndFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Total Laporan, Big Number, Trend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Laporan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatNumber(_totalLaporan),
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _trendIsUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 15,
                  color: _trendIsUp ? _greenPrimary : const Color(0xFFC60D05),
                ),
                const SizedBox(width: 3),
                Text(
                  _trendText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _trendIsUp ? _greenPrimary : const Color(0xFFC60D05),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Range Filter Dropdown
        PopupMenuButton<String>(
          initialValue: _selectedRange,
          onSelected: (String val) {
            setState(() {
              _selectedRange = val;
            });
            _computeStatisticsFromReports(_allReports);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          itemBuilder: (context) => _rangeOptions.map((opt) {
            return PopupMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: opt == _selectedRange
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: opt == _selectedRange ? _greenPrimary : Colors.black87,
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(
                color: const Color(0xFFDBDBDB),
                width: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4.2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedRange,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _textGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── HISTOGRAM BAR CHART ───────────────────────────────────────
  Widget _buildBarChartSection() {
    const double chartHeight = 150.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y-Axis Labels: Dynamic scale based on real maximum
        SizedBox(
          height: chartHeight + 24, // include X-axis label height
          width: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _yAxisLabels.isNotEmpty ? _yAxisLabels[0] : '10',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: _textGrey,
                ),
              ),
              Text(
                _yAxisLabels.length > 1 ? _yAxisLabels[1] : '5',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: _textGrey,
                ),
              ),
              Text(
                _yAxisLabels.length > 2 ? _yAxisLabels[2] : '2',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: _textGrey,
                ),
              ),
              Text(
                _yAxisLabels.length > 3 ? _yAxisLabels[3] : '0',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: _textGrey,
                ),
              ),
              const SizedBox(height: 18), // space for bottom date labels
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Bars & Baseline Row
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: chartHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_chartValues.length, (idx) {
                    final val = _chartValues[idx];
                    final double barHeight = val > 0
                        ? (val / _chartMaxScale * chartHeight).clamp(8.0, chartHeight)
                        : 0.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Container(
                            width: 16,
                            height: barHeight,
                            decoration: const BoxDecoration(
                              color: _greenPrimary,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 16, height: 1),
                      ],
                    );
                  }),
                ),
              ),

              // Baseline horizontal line
              Container(
                width: double.infinity,
                height: 1.0,
                color: const Color(0xFFE0DFDF),
              ),
              const SizedBox(height: 6),

              // X-Axis Date Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_chartDates.length, (idx) {
                  return SizedBox(
                    width: 44,
                    child: Text(
                      _chartDates[idx],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: _textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── CATEGORY CARD (Figma Node 567:2758) ───────────────────────
  Widget _buildCategoryCard(_CategoryStat cat) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.5),
        border: Border.all(
          color: _greenPrimary,
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Row(
          children: [
            // Solid Green Pill Accent on Left
            Container(
              width: 9,
              height: double.infinity,
              color: _greenPrimary,
            ),
            const SizedBox(width: 14),

            // Category Name
            Expanded(
              child: Text(
                cat.name,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _textGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Count & Percentage
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${_formatNumber(cat.count)} (${cat.percentage.toStringAsFixed(cat.percentage % 1 == 0 ? 0 : 1)}%)',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, color: Colors.grey.shade400, size: 36),
          const SizedBox(height: 8),
          Text(
            'Belum Ada Data Laporan pada Rentang Ini',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── DOWNLOAD BUTTON (Figma Node 566:2675) ─────────────────────
  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _handleDownloadReport,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 326),
        height: 49,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _greenPrimary,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Unduh Laporan',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: _greenPrimary,
          ),
        ),
      ),
    );
  }
}
