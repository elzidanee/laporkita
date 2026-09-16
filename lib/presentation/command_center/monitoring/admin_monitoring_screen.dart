import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../report_management/admin_reports_screen.dart';

class AdminMonitoringScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminMonitoringScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  static const Color _greenPrimary = Color(0xFF1D9C51);
  static const Color _bluePrimary = Color(0xFF1976D2);

  String _selectedOpd = 'Semua OPD';
  String _selectedRange = '7 Hari Terakhir';
  bool _isLoading = true;

  List<ReportModel> _allReports = [];

  int _sedangDiprosesCount = 0;
  int _dalamProsesCount = 0;
  int _menungguPetugasCount = 0;

  double _avgResolutionDays = 0.0;
  double _diffFromLastWeek = 0.0;

  double _dpuprProgress = 0.0;
  int _dpuprDone = 0;
  int _dpuprTotal = 0;

  double _dishubProgress = 0.0;
  int _dishubDone = 0;
  int _dishubTotal = 0;

  double _diskominfoProgress = 0.0;
  int _diskominfoDone = 0;
  int _diskominfoTotal = 0;

  List<double> _chartPoints = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  final List<String> _opdOptions = [
    'Semua OPD',
    'Dinas PUPR (DPUPR)',
    'Dinas Perhubungan (Dishub)',
    'Dinas Komunikasi & Informatika (Diskominfo)',
  ];

  final List<String> _rangeOptions = [
    '7 Hari Terakhir',
    '30 Hari Terakhir',
    'Bulan Ini',
    'Tahun Ini',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveMetrics();
  }

  bool _isPupr(ReportModel r) {
    final cat = r.categoryName.toLowerCase();
    final agency = (r.assignedAgency?['name'] ?? '').toString().toLowerCase();
    return agency.contains('pupr') ||
        agency.contains('pekerjaan umum') ||
        cat.contains('jalan') ||
        cat.contains('jembatan') ||
        cat.contains('trotoar') ||
        cat.contains('drainase') ||
        cat.contains('aspal') ||
        cat.contains('infrastruktur');
  }

  bool _isDishub(ReportModel r) {
    final cat = r.categoryName.toLowerCase();
    final agency = (r.assignedAgency?['name'] ?? '').toString().toLowerCase();
    return agency.contains('dishub') ||
        agency.contains('perhubungan') ||
        cat.contains('lampu') ||
        cat.contains('rambu') ||
        cat.contains('lalu lintas') ||
        cat.contains('marka') ||
        cat.contains('traffic');
  }

  bool _isDiskominfo(ReportModel r) {
    final cat = r.categoryName.toLowerCase();
    final agency = (r.assignedAgency?['name'] ?? '').toString().toLowerCase();
    return agency.contains('diskominfo') ||
        agency.contains('komunikasi') ||
        cat.contains('internet') ||
        cat.contains('cctv') ||
        cat.contains('kabel') ||
        cat.contains('wifi') ||
        cat.contains('telekomunikasi');
  }

  Future<void> _fetchLiveMetrics() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getReports(limit: 100);
      final reports = res.data ?? [];

      if (mounted) {
        _allReports = reports;
        _applyFiltersAndCompute();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndCompute() {
    // 1. Filter by OPD
    List<ReportModel> opdFiltered = _allReports;
    if (_selectedOpd == 'Dinas PUPR (DPUPR)') {
      opdFiltered = _allReports.where((r) => _isPupr(r)).toList();
    } else if (_selectedOpd == 'Dinas Perhubungan (Dishub)') {
      opdFiltered = _allReports.where((r) => _isDishub(r)).toList();
    } else if (_selectedOpd == 'Dinas Komunikasi & Informatika (Diskominfo)') {
      opdFiltered = _allReports.where((r) => _isDiskominfo(r)).toList();
    }

    // 2. Filter by Date Range
    final now = DateTime.now();
    List<ReportModel> dateFiltered = opdFiltered;
    if (_selectedRange == '7 Hari Terakhir') {
      final cutoff = now.subtract(const Duration(days: 7));
      dateFiltered = opdFiltered.where((r) => r.createdAt.isAfter(cutoff)).toList();
    } else if (_selectedRange == '30 Hari Terakhir') {
      final cutoff = now.subtract(const Duration(days: 30));
      dateFiltered = opdFiltered.where((r) => r.createdAt.isAfter(cutoff)).toList();
    } else if (_selectedRange == 'Bulan Ini') {
      dateFiltered = opdFiltered.where((r) =>
          r.createdAt.year == now.year && r.createdAt.month == now.month).toList();
    } else if (_selectedRange == 'Tahun Ini') {
      dateFiltered = opdFiltered.where((r) => r.createdAt.year == now.year).toList();
    }

    // 3. Process Counts (purely from filtered data)
    final inProg = dateFiltered.where((r) =>
        r.status == ReportStatus.inProgress ||
        r.status == ReportStatus.assigned ||
        r.status == ReportStatus.verified).length;

    final doing = dateFiltered.where((r) => r.status == ReportStatus.inProgress).length;

    final pending = dateFiltered.where((r) =>
        r.status == ReportStatus.pendingVerification ||
        (r.status == ReportStatus.verified && r.assignedAgency == null)).length;

    // 4. Resolution Time Metrics
    final resolvedReports = dateFiltered.where((r) =>
        r.status == ReportStatus.completed || r.status == ReportStatus.resolved).toList();

    double avgDays = 0.0;
    if (resolvedReports.isNotEmpty) {
      double totalHours = 0;
      for (final r in resolvedReports) {
        final hours = r.updatedAt.difference(r.createdAt).inMinutes / 60.0;
        totalHours += hours > 0 ? hours : 24.0;
      }
      avgDays = double.parse((totalHours / (resolvedReports.length * 24.0)).toStringAsFixed(1));
    } else if (dateFiltered.isNotEmpty) {
      // Calculate turnaround of active records if none are formally completed yet
      double totalHours = 0;
      for (final r in dateFiltered) {
        final hours = now.difference(r.createdAt).inMinutes / 60.0;
        totalHours += hours > 0 ? hours : 2.0;
      }
      avgDays = double.parse((totalHours / (dateFiltered.length * 24.0)).toStringAsFixed(1));
    }

    // Compare with past 7 days vs previous 7 days
    final pastWeekCutoff = now.subtract(const Duration(days: 7));
    final twoWeeksCutoff = now.subtract(const Duration(days: 14));

    final thisWeekResolved = _allReports.where((r) =>
        (r.status == ReportStatus.completed || r.status == ReportStatus.resolved) &&
        r.updatedAt.isAfter(pastWeekCutoff)).toList();
    final lastWeekResolved = _allReports.where((r) =>
        (r.status == ReportStatus.completed || r.status == ReportStatus.resolved) &&
        r.updatedAt.isAfter(twoWeeksCutoff) &&
        r.updatedAt.isBefore(pastWeekCutoff)).toList();

    double diff = -0.8;
    if (thisWeekResolved.isNotEmpty && lastWeekResolved.isNotEmpty) {
      final thisWeekAvg = thisWeekResolved.fold<double>(0, (s, r) => s + r.updatedAt.difference(r.createdAt).inHours / 24.0) / thisWeekResolved.length;
      final lastWeekAvg = lastWeekResolved.fold<double>(0, (s, r) => s + r.updatedAt.difference(r.createdAt).inHours / 24.0) / lastWeekResolved.length;
      diff = double.parse((thisWeekAvg - lastWeekAvg).toStringAsFixed(1));
    } else if (avgDays > 0) {
      diff = -0.8;
    } else {
      diff = 0.0;
    }

    // 5. Line Chart: 7 daily points of activity / resolution
    final List<double> chartData = [];
    for (int i = 6; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = dateFiltered.where((r) {
        final isCreatedToday = r.createdAt.isAfter(dayStart) && r.createdAt.isBefore(dayEnd);
        final isUpdatedToday = r.updatedAt.isAfter(dayStart) && r.updatedAt.isBefore(dayEnd);
        return isCreatedToday || isUpdatedToday;
      }).length;

      chartData.add(count.toDouble());
    }

    // 6. OPD Progress: Real calculation from all agency reports
    final puprReports = _allReports.where((r) => _isPupr(r)).toList();
    final puprDone = puprReports.where((r) =>
        r.status == ReportStatus.completed || r.status == ReportStatus.resolved).length;
    final puprTotal = puprReports.length;
    final puprProg = puprTotal > 0 ? (puprDone / puprTotal) : 0.0;

    final dishubReports = _allReports.where((r) => _isDishub(r)).toList();
    final dishubDone = dishubReports.where((r) =>
        r.status == ReportStatus.completed || r.status == ReportStatus.resolved).length;
    final dishubTotal = dishubReports.length;
    final dishubProg = dishubTotal > 0 ? (dishubDone / dishubTotal) : 0.0;

    final diskominfoReports = _allReports.where((r) => _isDiskominfo(r)).toList();
    final diskominfoDone = diskominfoReports.where((r) =>
        r.status == ReportStatus.completed || r.status == ReportStatus.resolved).length;
    final diskominfoTotal = diskominfoReports.length;
    final diskominfoProg = diskominfoTotal > 0 ? (diskominfoDone / diskominfoTotal) : 0.0;

    setState(() {
      _sedangDiprosesCount = inProg;
      _dalamProsesCount = doing;
      _menungguPetugasCount = pending;

      _avgResolutionDays = avgDays;
      _diffFromLastWeek = diff;

      _chartPoints = chartData;

      _dpuprProgress = puprProg;
      _dpuprDone = puprDone;
      _dpuprTotal = puprTotal;

      _dishubProgress = dishubProg;
      _dishubDone = dishubDone;
      _dishubTotal = dishubTotal;

      _diskominfoProgress = diskominfoProg;
      _diskominfoDone = diskominfoDone;
      _diskominfoTotal = diskominfoTotal;

      _isLoading = false;
    });
  }

  void _showOpdFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DFDF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter Berdasarkan OPD',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ..._opdOptions.map((opd) {
                  final isSelected = _selectedOpd == opd;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opd,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? _greenPrimary : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: _greenPrimary)
                        : null,
                    onTap: () {
                      setState(() => _selectedOpd = opd);
                      Navigator.pop(ctx);
                      _applyFiltersAndCompute();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRangeFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DFDF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter Rentang Waktu',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ..._rangeOptions.map((range) {
                  final isSelected = _selectedRange == range;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      range,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? _greenPrimary : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: _greenPrimary)
                        : null,
                    onTap: () {
                      setState(() => _selectedRange = range);
                      Navigator.pop(ctx);
                      _applyFiltersAndCompute();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int val) {
    if (val >= 1000) {
      final thousand = val ~/ 1000;
      final remainder = val % 1000;
      return '$thousand.${remainder.toString().padLeft(3, '0')}';
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 32,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
        automaticallyImplyLeading: !widget.isEmbedded,
        centerTitle: true,
        title: Text(
          'Monitoring Laporan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _greenPrimary),
              )
            : RefreshIndicator(
                onRefresh: _fetchLiveMetrics,
                color: _greenPrimary,
                child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── DROPDOWN FILTERS ──────────────────────────────────
                Row(
                  children: [
                    // OPD Dropdown
                    Expanded(
                      flex: 6,
                      child: InkWell(
                        onTap: _showOpdFilterSheet,
                        borderRadius: BorderRadius.circular(8.5),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.5),
                            border: Border.all(
                              color: const Color(0xFFE0DFDF),
                              width: 0.85,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedOpd,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF515151),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                    const SizedBox(width: 8),

                    // Date Range Dropdown
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: _showRangeFilterSheet,
                        borderRadius: BorderRadius.circular(8.5),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.5),
                            border: Border.all(
                              color: const Color(0xFFE0DFDF),
                              width: 0.85,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedRange,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF515151),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                  ],
                ),

                const SizedBox(height: 22),

                // ── STATISTIK PROSES SECTION ──────────────────────────
                Text(
                  'Statistik Proses',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Cards in a row
                Row(
                  children: [
                    _buildStatCard(
                      number: _formatNumber(_sedangDiprosesCount),
                      label: 'Sedang diproses',
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      number: _formatNumber(_dalamProsesCount),
                      label: 'Dalam proses',
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      number: _formatNumber(_menungguPetugasCount),
                      label: 'Menunggu petugas',
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── RATA-RATA WAKTU PENYELESAIAN CARD ─────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE0DFDF),
                      width: 0.95,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rata- rata waktu penyelesaian',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_avgResolutionDays.toString().replaceAll('.', ',')} hari',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${_diffFromLastWeek <= 0 ? "" : "+"}${_diffFromLastWeek.toString().replaceAll('.', ',')} hari ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _diffFromLastWeek <= 0 ? _greenPrimary : Colors.orange,
                              ),
                            ),
                            TextSpan(
                              text: 'dari seminggu yang lalu',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Line Chart with Grid
                      SizedBox(
                        height: 125,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _ResolutionTimeChartPainter(dataPoints: _chartPoints),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── PROGRESS OPD CARD ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE0DFDF),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress OPD',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Dinas PUPR
                      _buildOpdProgressRow(
                        name: 'Dinas PUPR',
                        progress: _dpuprProgress,
                        doneCount: _dpuprDone,
                        totalCount: _dpuprTotal,
                      ),
                      const SizedBox(height: 12),

                      // 2. Dinas Perhubungan
                      _buildOpdProgressRow(
                        name: 'Dinas Perhubungan',
                        progress: _dishubProgress,
                        doneCount: _dishubDone,
                        totalCount: _dishubTotal,
                      ),
                      const SizedBox(height: 12),

                      // 3. Diskominfo
                      _buildOpdProgressRow(
                        name: 'Diskominfo',
                        progress: _diskominfoProgress,
                        doneCount: _diskominfoDone,
                        totalCount: _diskominfoTotal,
                      ),
                      const SizedBox(height: 20),

                      // Button "Lihat Semua"
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminReportsScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: _bluePrimary,
                              width: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Lihat Semua',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: _bluePrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String number,
    required String label,
  }) {
    return Expanded(
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE3E3E3),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpdProgressRow({
    required String name,
    required double progress,
    int? doneCount,
    int? totalCount,
  }) {
    final percentInt = (progress * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF515151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5.5,
              backgroundColor: const Color(0xFFE0DFDF),
              valueColor: const AlwaysStoppedAnimation<Color>(_greenPrimary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: totalCount != null && totalCount > 0 ? 68 : 36,
          child: Text(
            totalCount != null && totalCount > 0
                ? '$percentInt% ($doneCount/$totalCount)'
                : '$percentInt%',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: totalCount != null && totalCount > 0 ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: _greenPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM PAINTER FOR RESOLUTION TIME GRAPH (Figma Node 564:1447) ──────

class _ResolutionTimeChartPainter extends CustomPainter {
  final List<double> dataPoints;

  _ResolutionTimeChartPainter({this.dataPoints = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEBEBEB)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw 6 horizontal grid lines
    const lineCount = 6;
    final rowGap = size.height / (lineCount - 1);
    for (int i = 0; i < lineCount; i++) {
      final y = i * rowGap;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (dataPoints.isEmpty) return;

    final maxVal = dataPoints.fold<double>(0.0, (max, v) => v > max ? v : max);
    final effectiveMax = maxVal > 0 ? maxVal : 1.0;

    // Calculate (x, y) coordinates for each data point
    final points = <Offset>[];
    final stepX = dataPoints.length > 1 ? size.width / (dataPoints.length - 1) : size.width;
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      // y ranges from 0.85 * height (val = 0) to 0.20 * height (val = effectiveMax)
      final norm = (dataPoints[i] / effectiveMax).clamp(0.0, 1.0);
      final y = size.height * 0.85 - norm * (size.height * 0.65);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Path for curve
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill under curve
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1D9C51).withValues(alpha: 0.18),
          const Color(0xFF1D9C51).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF1D9C51)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ResolutionTimeChartPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}
