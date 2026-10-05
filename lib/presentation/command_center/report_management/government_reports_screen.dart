import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'admin_report_detail_screen.dart';

/// Government & Policy Maker Reports Screen
/// Faithfully implementing Figma Node 622:219 (Laporan | Pemerintah)
class GovernmentReportsScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  final String? initialStatusFilter;
  final String? initialOpdFilter;

  const GovernmentReportsScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
    this.initialStatusFilter,
    this.initialOpdFilter,
  });

  @override
  State<GovernmentReportsScreen> createState() =>
      _GovernmentReportsScreenState();
}

class _GovernmentReportsScreenState extends State<GovernmentReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<ReportModel> _allReports = [];

  // Filter Row 1 States (Blue-themed)
  String _selectedFilterQuick = 'Filter';
  String _selectedStatus = 'Semua Status';
  String _selectedOpd = 'Semua OPD';

  // Filter Row 2 States (Gray-themed)
  String _selectedCategory = 'Semua Kategori';
  String _selectedOpdSecondary = 'OPD';
  String _selectedPriority = 'Prioritas';

  // Options
  final List<String> _quickFilterOptions = [
    'Filter',
    'Terbaru',
    'Terlama',
    'Prioritas Tertinggi',
    'Paling Banyak Dukungan',
  ];

  final List<String> _statusOptions = [
    'Semua Status',
    'Menunggu Verifikasi',
    'Terverifikasi',
    'Sedang Diproses',
    'Ditugaskan',
    'Selesai',
    'Ditolak',
  ];

  final List<String> _opdOptions = [
    'Semua OPD',
    'Dinas PUPR',
    'Dinas Perhubungan',
    'Dinas PU SDA',
    'Dinas Lingkungan',
    'Dinas Pertamanan',
  ];

  final List<String> _categoryOptions = [
    'Semua Kategori',
    'Jalan Rusak',
    'Halte bus rusak',
    'Trotoar Rusak',
    'Lampu Jalan',
    'Drainase',
    'Fasilitas Umum',
  ];

  final List<String> _priorityOptions = [
    'Prioritas',
    'Prioritas Tinggi',
    'Sedang',
    'Perlu Penanganan',
    'Rendah',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _selectedStatus = _mapApiStatusToDisplay(widget.initialStatusFilter!);
    }
    if (widget.initialOpdFilter != null) {
      _selectedOpd = widget.initialOpdFilter!;
      _selectedOpdSecondary = widget.initialOpdFilter! == 'Semua OPD'
          ? 'OPD'
          : widget.initialOpdFilter!;
    }
    _searchController.addListener(() => setState(() {}));
    _fetchReports();
  }

  String _mapApiStatusToDisplay(String apiStatus) {
    final lower = apiStatus.toLowerCase();
    if (lower.contains('pending')) return 'Menunggu Verifikasi';
    if (lower.contains('verif')) return 'Terverifikasi';
    if (lower.contains('progress')) return 'Sedang Diproses';
    if (lower.contains('assign')) return 'Ditugaskan';
    if (lower.contains('complet') || lower.contains('resolv')) return 'Selesai';
    if (lower.contains('reject')) return 'Ditolak';
    return 'Semua Status';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final reportRepo = context.read<ReportRepository>();
      final results = await reportRepo.getReports(limit: 100);

      if (mounted) {
        final reports = results.data ?? [];
        final listToUse = reports.isNotEmpty ? reports : _getFigmaMockReports();
        try {
          reportRepo.cacheReports(listToUse);
        } catch (_) {}
        setState(() {
          _allReports = listToUse;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final fallback = _getFigmaMockReports();
        try {
          context.read<ReportRepository>().cacheReports(fallback);
        } catch (_) {}
        setState(() {
          _allReports = fallback;
          _isLoading = false;
        });
      }
    }
  }

  List<ReportModel> _getFigmaMockReports() {
    return [
      ReportModel(
        id: 'rep-figma-1',
        reportCode: 'LP_2026_0024487',
        reporterId: 'usr-1',
        categoryId: 'cat-jalan',
        status: ReportStatus.inProgress,
        latitude: -6.382728,
        longitude: 107.734682,
        addressText: 'Jl. Ahmad Yani no. 15',
        description: 'Jalan berlubang cukup dalam dan membahayakan pengendara.',
        supportCount: 42,
        viewCount: 156,
        urgencyScore: 9.5,
        damageSeverity: 0.95,
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 12, 10, 30),
        updatedAt: DateTime(2026, 5, 12, 10, 30),
        category: const {'name': 'Jalan Rusak'},
        assignedAgency: const {'name': 'Dinas PUPR', 'acronym': 'DPUPR'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-1',
            reportId: 'rep-figma-1',
            targetStatus: ReportStatus.inProgress,
            note: 'Penugasan laporan ke Dinas PUPR (DPUPR) (Prioritas: Tinggi | Petugas: Andi Pratama)',
            createdAt: DateTime(2026, 5, 12, 10, 30),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=600&auto=format&fit=crop',
      ),
      ReportModel(
        id: 'rep-figma-2',
        reportCode: 'LP_2026_0038217',
        reporterId: 'usr-2',
        categoryId: 'cat-halte',
        status: ReportStatus.assigned,
        latitude: -6.382728,
        longitude: 107.278728,
        addressText: 'Jl. soekarno hatta no.20 A',
        description: 'Atap dan bangku halte rusak parah terkena ranting pohon.',
        supportCount: 28,
        viewCount: 98,
        urgencyScore: 4.5,
        damageSeverity: 0.55,
        needsManualReview: false,
        createdAt: DateTime(2026, 4, 4, 10, 23),
        updatedAt: DateTime(2026, 4, 4, 10, 23),
        category: const {'name': 'Halte rusak'},
        assignedAgency: const {'name': 'Dinas Perhubungan', 'acronym': 'Dishub'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-2',
            reportId: 'rep-figma-2',
            targetStatus: ReportStatus.assigned,
            note: 'Penugasan laporan ke Dinas Perhubungan (Prioritas: Sedang)',
            createdAt: DateTime(2026, 4, 4, 10, 23),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=600&auto=format&fit=crop',
      ),
      ReportModel(
        id: 'rep-figma-3',
        reportCode: 'LP_2026_0047630',
        reporterId: 'usr-3',
        categoryId: 'cat-jalan',
        status: ReportStatus.inProgress,
        latitude: -6.382728,
        longitude: 107.733241,
        addressText: 'Jl. Veteran, Malang',
        description: 'Aspal amblas di tikungan jalan Veteran dekat kampus.',
        supportCount: 35,
        viewCount: 140,
        urgencyScore: 9.0,
        damageSeverity: 0.90,
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 5, 11, 53),
        updatedAt: DateTime(2026, 5, 5, 11, 53),
        category: const {'name': 'Jalan Rusak'},
        assignedAgency: const {'name': 'Dinas PUPR', 'acronym': 'DPUPR'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-3',
            reportId: 'rep-figma-3',
            targetStatus: ReportStatus.inProgress,
            note: 'Penugasan laporan ke Dinas PUPR (Prioritas: Tinggi)',
            createdAt: DateTime(2026, 5, 5, 11, 53),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=600&auto=format&fit=crop',
      ),
      ReportModel(
        id: 'rep-figma-4',
        reportCode: 'LP_2026_00471245',
        reporterId: 'usr-4',
        categoryId: 'cat-halte',
        status: ReportStatus.assigned,
        latitude: -6.382728,
        longitude: 107.738923,
        addressText: 'Jl. S.parman, Malang',
        description: 'Kaca pelindung dan tempat duduk halte bus hancur.',
        supportCount: 19,
        viewCount: 84,
        urgencyScore: 4.0,
        damageSeverity: 0.50,
        needsManualReview: false,
        createdAt: DateTime(2026, 4, 28, 12, 41),
        updatedAt: DateTime(2026, 4, 28, 12, 41),
        category: const {'name': 'Halte bus rusak'},
        assignedAgency: const {'name': 'Dinas Perhubungan', 'acronym': 'Dishub'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-4',
            reportId: 'rep-figma-4',
            targetStatus: ReportStatus.assigned,
            note: 'Penugasan laporan ke Dinas Perhubungan (Prioritas: Sedang)',
            createdAt: DateTime(2026, 4, 28, 12, 41),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1545558014-8692077e9b5c?q=80&w=600&auto=format&fit=crop',
      ),
      ReportModel(
        id: 'rep-figma-5',
        reportCode: 'LP_2026_00125369',
        reporterId: 'usr-5',
        categoryId: 'cat-trotoar',
        status: ReportStatus.pendingVerification,
        latitude: -6.382728,
        longitude: 107.737231,
        addressText: 'Jl. budi luhur, Malang',
        description: 'Paving block trotoar terangkat dan berserakan.',
        supportCount: 14,
        viewCount: 72,
        urgencyScore: 5.5,
        damageSeverity: 0.65,
        needsManualReview: true,
        createdAt: DateTime(2026, 4, 21, 11, 32),
        updatedAt: DateTime(2026, 4, 21, 11, 32),
        category: const {'name': 'Trotoar Rusak'},
        assignedAgency: const {'name': 'Dinas PUPR', 'acronym': 'DPUPR'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-5',
            reportId: 'rep-figma-5',
            targetStatus: ReportStatus.pendingVerification,
            note: 'Menunggu review manual verifikator (Prioritas: Perlu Penanganan)',
            createdAt: DateTime(2026, 4, 21, 11, 32),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=600&auto=format&fit=crop',
      ),
      ReportModel(
        id: 'rep-figma-6',
        reportCode: 'LP_2026_0024487',
        reporterId: 'usr-1',
        categoryId: 'cat-jalan',
        status: ReportStatus.inProgress,
        latitude: -6.382728,
        longitude: 107.734682,
        addressText: 'Jl. Ahmad Yani no. 15',
        description: 'Jalan berlubang cukup dalam dan membahayakan pengendara.',
        supportCount: 42,
        viewCount: 156,
        urgencyScore: 9.5,
        damageSeverity: 0.95,
        needsManualReview: false,
        createdAt: DateTime(2026, 5, 12, 10, 30),
        updatedAt: DateTime(2026, 5, 12, 10, 30),
        category: const {'name': 'Jalan Rusak'},
        assignedAgency: const {'name': 'Dinas PUPR', 'acronym': 'DPUPR'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-6',
            reportId: 'rep-figma-6',
            targetStatus: ReportStatus.inProgress,
            note: 'Prioritas: Tinggi',
            createdAt: DateTime(2026, 5, 12, 10, 30),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=600&auto=format&fit=crop',
      ),
      ReportModel(
        id: 'rep-figma-7',
        reportCode: 'LP_2026_0038217',
        reporterId: 'usr-2',
        categoryId: 'cat-halte',
        status: ReportStatus.assigned,
        latitude: -6.382728,
        longitude: 107.278728,
        addressText: 'Jl. soekarno hatta no.20 A',
        description: 'Atap dan bangku halte rusak parah terkena ranting pohon.',
        supportCount: 28,
        viewCount: 98,
        urgencyScore: 4.5,
        damageSeverity: 0.55,
        needsManualReview: false,
        createdAt: DateTime(2026, 4, 4, 10, 23),
        updatedAt: DateTime(2026, 4, 4, 10, 23),
        category: const {'name': 'Halte rusak'},
        assignedAgency: const {'name': 'Dinas Perhubungan', 'acronym': 'Dishub'},
        statusHistory: [
          ReportStatusHistoryModel(
            id: 'h-7',
            reportId: 'rep-figma-7',
            targetStatus: ReportStatus.assigned,
            note: 'Prioritas: Sedang',
            createdAt: DateTime(2026, 4, 4, 10, 23),
          ),
        ],
        directPhotoUrl:
            'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=600&auto=format&fit=crop',
      ),
    ];
  }

  // ── HELPER MAPPING & DETERMINASI BACKEND ────────────────────────────
  String _getReportOpdName(ReportModel r) {
    final agencyName =
        (r.assignedAgency?['name'] as String? ?? '').toLowerCase();
    final agencyType =
        (r.assignedAgency?['type'] as String? ?? '').toLowerCase();
    final agencyAcronym =
        (r.assignedAgency?['acronym'] as String? ?? '').toLowerCase();
    final cat = r.categoryName.toLowerCase();

    if (agencyType.contains('pupr') ||
        agencyAcronym.contains('pupr') ||
        agencyName.contains('pupr') ||
        agencyName.contains('pekerjaan umum') ||
        cat.contains('jalan') ||
        cat.contains('lubang') ||
        cat.contains('jembatan')) {
      return 'Dinas PUPR';
    } else if (agencyType.contains('dishub') ||
        agencyAcronym.contains('dishub') ||
        agencyType.contains('perhubungan') ||
        agencyName.contains('perhubungan') ||
        cat.contains('halte') ||
        cat.contains('rambu') ||
        cat.contains('lampu') ||
        cat.contains('lalu lintas')) {
      return 'Dinas Perhubungan';
    } else if (agencyType.contains('sda') ||
        agencyName.contains('sda') ||
        cat.contains('drainase') ||
        cat.contains('banjir') ||
        cat.contains('sungai')) {
      return 'Dinas PU SDA';
    } else if (agencyType.contains('dlh') ||
        agencyName.contains('lingkungan') ||
        cat.contains('sampah') ||
        cat.contains('kebersihan')) {
      return 'Dinas Lingkungan';
    } else if (cat.contains('taman') || cat.contains('pohon')) {
      return 'Dinas Pertamanan';
    }
    return 'Dinas PUPR';
  }

  bool _checkOpdMatch(ReportModel r, String filterOpd) {
    if (filterOpd == 'Semua OPD' || filterOpd == 'OPD') return true;
    final opdName = _getReportOpdName(r);
    return opdName.toLowerCase() == filterOpd.toLowerCase();
  }

  bool _checkCategoryMatch(String reportCat, String filterCat) {
    if (filterCat == 'Semua Kategori') return true;
    final rCat = reportCat.toLowerCase();
    final fCat = filterCat.toLowerCase();

    if (fCat.contains('lampu') || fCat.contains('penerangan')) {
      return rCat.contains('lampu') || rCat.contains('penerangan');
    }
    if (fCat.contains('halte')) {
      return rCat.contains('halte');
    }
    if (fCat.contains('trotoar') || fCat.contains('pedestrian')) {
      return rCat.contains('trotoar') || rCat.contains('pedestrian');
    }
    if (fCat.contains('drainase') ||
        fCat.contains('banjir') ||
        fCat.contains('selokan')) {
      return rCat.contains('drainase') ||
          rCat.contains('banjir') ||
          rCat.contains('selokan');
    }
    if (fCat.contains('jalan') || fCat.contains('lubang') || fCat.contains('aspal')) {
      return (rCat.contains('jalan') ||
              rCat.contains('lubang') ||
              rCat.contains('aspal')) &&
          !rCat.contains('lampu') &&
          !rCat.contains('penerangan');
    }
    return rCat.contains(fCat) || fCat.contains(rCat);
  }

  /// Status prioritas riil disesuaikan dengan input dan metrik backend
  String _getPriorityLabel(ReportModel r) => r.priorityLabel;

  // ── FILTERING LOGIC ────────────────────────────────────────────────
  List<ReportModel> get _filteredReports {
    final query = _searchController.text.trim().toLowerCase();

    return _allReports.where((r) {
      // 1. Search Query
      if (query.isNotEmpty) {
        final matchesQuery = r.reportCode.toLowerCase().contains(query) ||
            r.categoryName.toLowerCase().contains(query) ||
            (r.addressText ?? '').toLowerCase().contains(query) ||
            (r.description ?? '').toLowerCase().contains(query) ||
            r.reporterName.toLowerCase().contains(query) ||
            _getReportOpdName(r).toLowerCase().contains(query) ||
            _getPriorityLabel(r).toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      // 2. Status Filter
      if (_selectedStatus != 'Semua Status') {
        final matchesStatus = _checkStatusMatch(r.status, _selectedStatus);
        if (!matchesStatus) return false;
      }

      // 3. OPD Filter (Row 1 & Row 2 unified)
      final activeOpd = _selectedOpd != 'Semua OPD'
          ? _selectedOpd
          : (_selectedOpdSecondary != 'OPD' ? _selectedOpdSecondary : null);
      if (activeOpd != null) {
        if (!_checkOpdMatch(r, activeOpd)) return false;
      }

      // 4. Category Filter (Row 2)
      if (_selectedCategory != 'Semua Kategori') {
        if (!_checkCategoryMatch(r.categoryName, _selectedCategory)) return false;
      }

      // 5. Priority Filter (Row 2)
      if (_selectedPriority != 'Prioritas') {
        final priority = _getPriorityLabel(r).toLowerCase();
        final target = _selectedPriority.toLowerCase().replaceAll('prioritas ', '').trim();
        if (!priority.contains(target)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_selectedFilterQuick == 'Terlama') {
          return a.createdAt.compareTo(b.createdAt);
        } else if (_selectedFilterQuick == 'Prioritas Tertinggi') {
          final scoreA = (a.damageSeverity ?? 0) * 10 + (a.urgencyScore ?? 0);
          final scoreB = (b.damageSeverity ?? 0) * 10 + (b.urgencyScore ?? 0);
          return scoreB.compareTo(scoreA);
        } else if (_selectedFilterQuick == 'Paling Banyak Dukungan') {
          return b.supportCount.compareTo(a.supportCount);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  bool _checkStatusMatch(ReportStatus status, String filter) {
    switch (filter) {
      case 'Menunggu Verifikasi':
        return status == ReportStatus.pendingVerification;
      case 'Terverifikasi':
        return status == ReportStatus.verified;
      case 'Sedang Diproses':
        return status == ReportStatus.inProgress;
      case 'Ditugaskan':
        return status == ReportStatus.assigned;
      case 'Selesai':
        return status == ReportStatus.completed ||
            status == ReportStatus.resolved;
      case 'Ditolak':
        return status == ReportStatus.rejected ||
            status == ReportStatus.disputed;
      default:
        return true;
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ── BUILD METHOD ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 1. App Bar (Chevron Back + Laporan Title)
            _buildTopAppBar(),
            const SizedBox(height: 14),

            // 2. Search Bar (Rounded 25px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 14),

            // 3. Filter Row 1 (Blue themed pills: Filter, Semua Status, Semua OPD, Menu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildFilterRow1(),
            ),
            const SizedBox(height: 10),

            // 4. Filter Row 2 (Gray themed pills: Semua Kategori, OPD, Prioritas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildFilterRow2(),
            ),
            const SizedBox(height: 16),

            // 5. Report Cards List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF1D9C51)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      color: const Color(0xFF1D9C51),
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildReportCard(filtered[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. TOP APP BAR ─────────────────────────────────────────────────
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
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
                decoration: const BoxDecoration(shape: BoxShape.circle),
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
              'Laporan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. SEARCH BAR ──────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 22,
            color: Color(0xFFABABAB),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari ID, judul, lokasi, atau pelapor...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFABABAB),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFFABABAB),
              ),
            ),
        ],
      ),
    );
  }

  // ── 3. FILTER ROW 1 (BLUE-THEMED PILLS) ────────────────────────────
  Widget _buildFilterRow1() {
    return Row(
      children: [
        // Pill 1: Filter
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.5),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _selectedFilterQuick,
            onSelected: (val) => setState(() => _selectedFilterQuick = val),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (_) => _quickFilterOptions.map((opt) {
              return PopupMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: _selectedFilterQuick == opt
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 15,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedFilterQuick,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Pill 2: Semua Status
        Expanded(
          flex: 5,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedStatus,
              onSelected: (val) => setState(() => _selectedStatus = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => _statusOptions.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: _selectedStatus == status
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
                        _selectedStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF1976D2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Pill 3: Semua OPD
        Expanded(
          flex: 4,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedOpd,
              onSelected: (val) {
                setState(() {
                  _selectedOpd = val;
                  _selectedOpdSecondary = val == 'Semua OPD' ? 'OPD' : val;
                });
              },
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
                    Expanded(
                      child: Text(
                        _selectedOpd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF1976D2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Menu Toggle Action
        InkWell(
          onTap: () {
            setState(() {
              _selectedFilterQuick = 'Filter';
              _selectedStatus = 'Semua Status';
              _selectedOpd = 'Semua OPD';
              _selectedCategory = 'Semua Kategori';
              _selectedOpdSecondary = 'OPD';
              _selectedPriority = 'Prioritas';
              _searchController.clear();
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: Color(0xFF1976D2),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. FILTER ROW 2 (GRAY-THEMED PILLS) ────────────────────────────
  Widget _buildFilterRow2() {
    return Row(
      children: [
        // Pill 1: Semua Kategori
        Expanded(
          flex: 4,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFDBDBDB), width: 0.85),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedCategory,
              onSelected: (val) => setState(() => _selectedCategory = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => _categoryOptions.map((cat) {
                return PopupMenuItem(
                  value: cat,
                  child: Text(
                    cat,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: _selectedCategory == cat
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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
        const SizedBox(width: 8),

        // Pill 2: OPD
        Expanded(
          flex: 2,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFDBDBDB), width: 0.85),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedOpdSecondary,
              onSelected: (val) {
                setState(() {
                  _selectedOpdSecondary = val;
                  _selectedOpd = val == 'OPD' ? 'Semua OPD' : val;
                });
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => _opdOptions.map((opd) {
                return PopupMenuItem(
                  value: opd == 'Semua OPD' ? 'OPD' : opd,
                  child: Text(
                    opd,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: _selectedOpdSecondary == opd
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
                        _selectedOpdSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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
        const SizedBox(width: 8),

        // Pill 3: Prioritas
        Expanded(
          flex: 3,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.5),
              border: Border.all(color: const Color(0xFFDBDBDB), width: 0.85),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 4.2),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedPriority,
              onSelected: (val) => setState(() => _selectedPriority = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => _priorityOptions.map((p) {
                return PopupMenuItem(
                  value: p,
                  child: Text(
                    p,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: _selectedPriority == p
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
                        _selectedPriority,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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

  // ── 5. REPORT CARD ITEM ────────────────────────────────────────────
  Widget _buildReportCard(ReportModel r) {
    final priority = _getPriorityLabel(r);
    final opdName = _getReportOpdName(r);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final updated = await Navigator.push<ReportModel>(
              context,
              MaterialPageRoute(
                builder: (_) => AdminReportDetailScreen(report: r),
              ),
            );
            if (mounted) {
              if (updated != null) {
                setState(() {
                  final idx = _allReports.indexWhere((e) => e.id == updated.id);
                  if (idx != -1) {
                    _allReports[idx] = updated;
                  }
                });
              }
              _fetchReports();
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Left Thumbnail with Geotag Stamp Overlay
                _buildThumbnailWithStamp(r),
                const SizedBox(width: 13),

                // 2. Middle & Right Info (exact height 83px matching thumbnail)
                Expanded(
                  child: SizedBox(
                    height: 83,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column: Title, Address, Code
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.categoryName,
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
                                    r.addressText ?? 'Jl. Ahmad Yani no. 15',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.normal,
                                      color: const Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Text(
                                _formatReportCode(r.reportCode),
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
                        const SizedBox(width: 8),

                        // Right Column: Priority Badge, Chevron, OPD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPriorityBadge(priority),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: Color(0xFF515151),
                            ),
                            Text(
                              opdName,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFFA8A8A8),
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  // ── THUMBNAIL WITH GEOTAG STAMP OVERLAY ────────────────────────────
  Widget _buildThumbnailWithStamp(ReportModel r) {
    return Container(
      width: 119,
      height: 83,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBEC4BD), width: 0.9),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            _buildImageWidget(r),

            // Geotag Stamp Box at bottom-left (Matching Figma node 626:751)
            Positioned(
              left: 3,
              bottom: 3,
              child: Container(
                width: 76,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x8C000000),
                  borderRadius: BorderRadius.circular(2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mini Green Pill: LaporKita
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2.5, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: const Color(0x9942A54B),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                            color: const Color(0xFF62D26D), width: 0.15),
                      ),
                      child: const Text(
                        'LaporKita',
                        style: TextStyle(
                          fontSize: 4,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),

                    // Code
                    Text(
                      _formatReportCode(r.reportCode),
                      style: const TextStyle(
                        fontSize: 4.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location Pin + Address
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            size: 4.5, color: Colors.white),
                        const SizedBox(width: 1.5),
                        Expanded(
                          child: Text(
                            r.addressText ?? 'Malang',
                            style: const TextStyle(
                              fontSize: 4,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Clock + Timestamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 4.5, color: Colors.white),
                        const SizedBox(width: 1.5),
                        Expanded(
                          child: Text(
                            _formatDateTimeShort(r.createdAt),
                            style: const TextStyle(
                              fontSize: 4,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Alert + Category
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 4.5, color: Colors.white),
                        const SizedBox(width: 1.5),
                        Expanded(
                          child: Text(
                            r.categoryName,
                            style: const TextStyle(
                              fontSize: 4,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Chip + Coordinates
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.memory,
                            size: 4.5, color: Colors.white),
                        const SizedBox(width: 1.5),
                        Expanded(
                          child: Text(
                            '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 4,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
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
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(ReportModel r) {
    final url = r.formattedPhotoUrl ?? r.photoUrl ?? r.directPhotoUrl;

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildCategoryFallbackImage(r.categoryName),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFFF0F0F0),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Color(0xFF1D9C51),
                  ),
                ),
              ),
            );
          },
        );
      } else if (File(url).existsSync()) {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildCategoryFallbackImage(r.categoryName),
        );
      }
    }

    return _buildCategoryFallbackImage(r.categoryName);
  }

  Widget _buildCategoryFallbackImage(String categoryName) {
    final lower = categoryName.toLowerCase();
    String unsplashUrl;
    if (lower.contains('halte')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=400&auto=format&fit=crop';
    } else if (lower.contains('trotoar')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=400&auto=format&fit=crop';
    } else if (lower.contains('lampu')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?q=80&w=400&auto=format&fit=crop';
    } else {
      unsplashUrl =
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=400&auto=format&fit=crop';
    }

    return Image.network(
      unsplashUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
      ),
    );
  }

  // ── PRIORITY BADGE ─────────────────────────────────────────────────
  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color textColor;

    switch (priority) {
      case 'Prioritas Tinggi':
        bg = const Color(0xFFFFE9E9);
        textColor = const Color(0xFFC60D05);
        break;
      case 'Sedang':
        bg = const Color(0xFFFFF9E9);
        textColor = const Color(0xFFF2AE01);
        break;
      case 'Perlu Penanganan':
        bg = const Color(0xFFFFF9E9);
        textColor = const Color(0xFFF2AE01);
        break;
      case 'Rendah':
      default:
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
    }

    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        priority,
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada laporan ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba sesuaikan kata kunci pencarian atau ubah filter yang dipilih.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReportCode(String code) {
    if (code.startsWith('#')) return code;
    return '#$code';
  }

  String _formatDateTimeShort(DateTime dt) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jum\'at',
      'Sabtu',
      'Minggu'
    ];
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
    final localDt = dt.toLocal();
    final dayName = days[(localDt.weekday - 1) % 7];
    final monthName = months[(localDt.month - 1) % 12];
    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$dayName, ${localDt.day} $monthName ${localDt.year} | $hour.$minute WIB';
  }
}
