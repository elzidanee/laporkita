import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'admin_report_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Laporan | Admin  (Figma: node 495-8309)
// ─────────────────────────────────────────────────────────────

class AdminReportsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final String? initialOpdFilter;

  const AdminReportsScreen({
    super.key,
    this.initialStatusFilter,
    this.initialOpdFilter,
  });

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<ReportModel> _allReports = [];

  // Filter states
  String _selectedStatus = 'Semua Status';
  String _selectedOpd = 'Semua OPD';
  String _selectedSort = 'Terbaru';
  bool _sortAscending = false;

  final List<String> _statusOptions = [
    'Semua Status',
    'Menunggu Verifikasi',
    'Sedang Diproses',
    'Ditugaskan',
    'Selesai',
    'Ditolak',
  ];

  final List<String> _opdOptions = [
    'Semua OPD',
    'Dinas PUPR',
    'Dinas Perhubungan',
    'Dinas Lingkungan Hidup',
    'Satpol PP',
    'BPBD',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _selectedStatus = _mapApiStatusToDisplay(widget.initialStatusFilter!);
    }
    if (widget.initialOpdFilter != null) {
      _selectedOpd = widget.initialOpdFilter!;
    }
    _searchController.addListener(() => setState(() {}));
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _mapApiStatusToDisplay(String apiStatus) {
    final lower = apiStatus.toLowerCase();
    if (lower.contains('pending')) return 'Menunggu Verifikasi';
    if (lower.contains('progress')) return 'Sedang Diproses';
    if (lower.contains('assign')) return 'Ditugaskan';
    if (lower.contains('complet') || lower.contains('resolv')) return 'Selesai';
    if (lower.contains('reject')) return 'Ditolak';
    return 'Semua Status';
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final reportRepo = context.read<ReportRepository>();
      final categoryRepo = context.read<CategoryRepository>();

      final results = await Future.wait([
        reportRepo.getReports(limit: 100),
        categoryRepo.getCategories(),
      ]);

      final reportsRes = results[0] as dynamic;

      if (mounted) {
        setState(() {
          _allReports = reportsRes.data ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── FILTER & SEARCH LOGIC ──────────────────────────────────────────

  List<ReportModel> get _filteredReports {
    final query = _searchController.text.trim().toLowerCase();

    return _allReports.where((r) {
      // 1. Status Filter
      if (_selectedStatus != 'Semua Status') {
        final matchesStatus = _checkStatusMatch(r.status, _selectedStatus);
        if (!matchesStatus) return false;
      }

      // 2. OPD Filter
      if (_selectedOpd != 'Semua OPD') {
        final agencyName = (r.assignedAgency?['name'] ?? '').toString().toLowerCase();
        final opdLower = _selectedOpd.toLowerCase();
        if (!agencyName.contains(opdLower) && !opdLower.contains(agencyName)) {
          final catName = r.categoryName.toLowerCase();
          if (_selectedOpd == 'Dinas PUPR' &&
              !(catName.contains('jalan') ||
                  catName.contains('jembatan') ||
                  catName.contains('trotoar') ||
                  catName.contains('drainase'))) {
            return false;
          } else if (_selectedOpd == 'Dinas Perhubungan' &&
              !(catName.contains('rambu') ||
                  catName.contains('lampu') ||
                  catName.contains('lalu lintas'))) {
            return false;
          } else if (_selectedOpd == 'Dinas Lingkungan Hidup' &&
              !(catName.contains('sampah') ||
                  catName.contains('kebersihan') ||
                  catName.contains('pohon'))) {
            return false;
          } else if (_selectedOpd == 'Satpol PP' &&
              !(catName.contains('ketertiban') || catName.contains('pkl'))) {
            return false;
          }
        }
      }

      // 3. Search Query
      if (query.isNotEmpty) {
        final code = r.reportCode.toLowerCase();
        final title = r.categoryName.toLowerCase();
        final desc = (r.description ?? '').toLowerCase();
        final addr = (r.addressText ?? '').toLowerCase();
        final reporter = r.reporterName.toLowerCase();

        final matches = code.contains(query) ||
            title.contains(query) ||
            desc.contains(query) ||
            addr.contains(query) ||
            reporter.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_selectedSort == 'Terlama') {
          return a.createdAt.compareTo(b.createdAt);
        } else if (_selectedSort == 'Prioritas') {
          final scoreA = a.urgencyScore ?? 0.0;
          final scoreB = b.urgencyScore ?? 0.0;
          return scoreB.compareTo(scoreA);
        } else {
          // Default: Terbaru
          return _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        }
      });
  }

  bool _checkStatusMatch(ReportStatus status, String filter) {
    switch (filter) {
      case 'Menunggu Verifikasi':
        return status == ReportStatus.pendingVerification;
      case 'Sedang Diproses':
        return status == ReportStatus.inProgress;
      case 'Ditugaskan':
        return status == ReportStatus.assigned;
      case 'Selesai':
        return status == ReportStatus.completed || status == ReportStatus.resolved;
      case 'Ditolak':
        return status == ReportStatus.rejected || status == ReportStatus.disputed;
      default:
        return true;
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildAdminDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Top App Bar: Hamburger + Title
            _buildTopAppBar(),
            const SizedBox(height: 14),

            // Search Bar (Rounded 25px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 14),

            // Filter Row: Filter, Semua Status, Semua OPD, Sort Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildFilterRow(),
            ),
            const SizedBox(height: 16),

            // Total Counter: Total 2.458 Laporan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTotalCounter(filtered.length),
              ),
            ),
            const SizedBox(height: 12),

            // Report List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.greenPrimary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      color: AppColors.greenPrimary,
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 4,
                                bottom: 28,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
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

  // ── TOP APP BAR ────────────────────────────────────────────────────

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Hamburger Menu Icon
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
                Icons.menu_rounded,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Laporan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  // ── SEARCH BAR ─────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 22,
            color: Color(0xFFABABAB),
          ),
          const SizedBox(width: 10),
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
                  color: const Color(0xFFABABAB),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: Color(0xFFABABAB),
              ),
            ),
        ],
      ),
    );
  }

  // ── FILTER ROW ─────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Row(
      children: [
        // 1. Filter Chip
        _buildFilterChip(
          icon: Icons.tune_rounded,
          label: 'Filter',
          onTap: _showSortBottomSheet,
        ),
        const SizedBox(width: 6),

        // 2. Semua Status Dropdown Chip
        Expanded(
          flex: 4,
          child: _buildFilterChip(
            label: _selectedStatus,
            onTap: _showStatusBottomSheet,
          ),
        ),
        const SizedBox(width: 6),

        // 3. Semua OPD Dropdown Chip
        Expanded(
          flex: 3,
          child: _buildFilterChip(
            label: _selectedOpd == 'Dinas Lingkungan Hidup' ? 'DLH' : _selectedOpd,
            onTap: _showOpdBottomSheet,
          ),
        ),
        const SizedBox(width: 6),

        // 4. Quick Sort Toggle Icon
        GestureDetector(
          onTap: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _sortAscending ? 'Urutkan: Terlama dahulu' : 'Urutkan: Terbaru dahulu',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.greenPrimary,
              ),
            );
          },
          child: Container(
            width: 32,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
            ),
            child: Icon(
              _sortAscending ? Icons.arrow_upward_rounded : Icons.menu_rounded,
              size: 18,
              color: const Color(0xFF1976D2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.5),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFF1976D2)),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1976D2),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }

  // ── TOTAL COUNTER ──────────────────────────────────────────────────

  Widget _buildTotalCounter(int count) {
    final formattedCount = count.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Total ',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.3,
            ),
          ),
          TextSpan(
            text: formattedCount,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D9C51),
              letterSpacing: 0.3,
            ),
          ),
          TextSpan(
            text: ' Laporan',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── REPORT CARD (Figma node 503:171) ────────────────────────────────

  Widget _buildReportCard(ReportModel r) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminReportDetailScreen(report: r),
          ),
        );
        if (mounted) _fetchReports();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 116,
                height: 84,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBEC4BD), width: 1.0),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF0F0F0),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildReportThumbnail(r),
                    Positioned(
                      left: 3,
                      bottom: 3,
                      child: _buildWatermarkBadge(r),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          r.categoryName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateShort(r.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFFA8A8A8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          r.addressText ?? 'Jl. Veteran, Kota Malang',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF515151),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatCodeWithHash(r.reportCode),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D9C51),
                        ),
                      ),
                      _buildStatusBadge(r.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportThumbnail(ReportModel r) {
    final url = r.formattedPhotoUrl ?? r.photoUrl;

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildCategoryFallbackImage(r.categoryName),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.greenPrimary,
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
    if (lower.contains('jembatan')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1545558014-8692077e9b5c?q=80&w=400&auto=format&fit=crop';
    } else if (lower.contains('lampu')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?q=80&w=400&auto=format&fit=crop';
    } else if (lower.contains('trotoar')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=400&auto=format&fit=crop';
    } else if (lower.contains('halte')) {
      unsplashUrl =
          'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=400&auto=format&fit=crop';
    } else {
      unsplashUrl =
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=400&auto=format&fit=crop';
    }

    return Image.network(
      unsplashUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE8F5E9),
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.greenPrimary, size: 28),
        ),
      ),
    );
  }

  Widget _buildWatermarkBadge(ReportModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF62D26D), width: 0.3),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 3.8,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _formatCodeWithHash(r.reportCode),
            style: GoogleFonts.poppins(
              fontSize: 4.2,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 4.5, color: Colors.white),
              const SizedBox(width: 1),
              SizedBox(
                width: 44,
                child: Text(
                  r.addressText ?? 'Jl. Malang',
                  style: GoogleFonts.poppins(
                    fontSize: 3.8,
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

  Widget _buildStatusBadge(ReportStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case ReportStatus.pendingVerification:
        bg = const Color(0xFFFFF9E9);
        text = const Color(0xFFF2AE01);
        label = 'Menunggu verifikasi';
        break;
      case ReportStatus.inProgress:
        bg = const Color(0xFFFFF9E9);
        text = const Color(0xFFF2AE01);
        label = 'Sedang Diproses';
        break;
      case ReportStatus.assigned:
        bg = const Color(0xFFE8F3FF);
        text = const Color(0xFF1976D2);
        label = 'Diteruskan';
        break;
      case ReportStatus.completed:
      case ReportStatus.resolved:
        bg = const Color(0xFFE6F7ED);
        text = const Color(0xFF1D9C51);
        label = 'Selesai';
        break;
      case ReportStatus.rejected:
        bg = const Color(0xFFFFEBEB);
        text = AppColors.statusDanger;
        label = 'Ditolak';
        break;
      case ReportStatus.disputed:
        bg = const Color(0xFFFFEBEB);
        text = AppColors.statusDanger;
        label = 'Dispute';
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        text = const Color(0xFF757575);
        label = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }

  // ── BOTTOM SHEETS ──────────────────────────────────────────────────

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urutkan Laporan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ...['Terbaru', 'Terlama', 'Prioritas'].map((sort) {
                final isSelected = _selectedSort == sort;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.greenPrimary : Colors.grey,
                  ),
                  title: Text(
                    sort == 'Prioritas' ? 'Prioritas Tertinggi AI' : sort,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.greenPrimary : Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedSort = sort);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Status Laporan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ..._statusOptions.map((st) {
                final isSelected = _selectedStatus == st;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isSelected ? AppColors.greenPrimary : Colors.grey,
                  ),
                  title: Text(
                    st,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.greenPrimary : Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedStatus = st);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showOpdBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Berdasarkan OPD / Dinas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ..._opdOptions.map((opd) {
                final isSelected = _selectedOpd == opd;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.apartment_rounded : Icons.apartment_outlined,
                    color: isSelected ? AppColors.greenPrimary : Colors.grey,
                  ),
                  title: Text(
                    opd,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.greenPrimary : Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedOpd = opd);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── ADMIN DRAWER ───────────────────────────────────────────────────

  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                String adminName = 'Administrator';
                String adminEmail = 'admin@laporkita.go.id';
                if (authState is AuthAuthenticated) {
                  adminName = authState.user.fullName;
                  adminEmail = authState.user.email ?? 'admin@laporkita.go.id';
                }
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0DFDF)),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.greenPrimary,
                        child: Text(
                          adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adminName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              adminEmail,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Colors.black87),
              title: Text('Dashboard Admin', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/admin-dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded, color: AppColors.greenPrimary),
              title: Text(
                'Daftar Laporan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenPrimary,
                ),
              ),
              selected: true,
              selectedTileColor: const Color(0xFFE6F7ED),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: Colors.black87),
              title: Text('Muat Ulang Data', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _fetchReports();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.statusDanger),
              title: Text(
                'Keluar / Logout',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                Navigator.pushNamedAndRemoveUntil(
                    context, '/get-started', (r) => false);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7ED),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 38,
                color: AppColors.greenPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Laporan Ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba sesuaikan filter status, OPD, atau kata kunci pencarian Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedStatus = 'Semua Status';
                  _selectedOpd = 'Semua OPD';
                  _selectedSort = 'Terbaru';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────

  String _formatCodeWithHash(String code) {
    if (code.isEmpty) return '#LP_2026_0000000';
    if (code.startsWith('#')) return code;
    return '#$code';
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthName = months[dt.month - 1].toLowerCase();
    return '${dt.day} $monthName ${dt.year}';
  }
}
