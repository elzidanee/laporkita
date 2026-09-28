import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_report_detail_screen.dart';

class OperatorTugasScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const OperatorTugasScreen({
    super.key,
    this.isTab = false,
    this.onBackToDashboard,
  });

  @override
  State<OperatorTugasScreen> createState() => _OperatorTugasScreenState();
}

class _OperatorTugasScreenState extends State<OperatorTugasScreen> {
  bool _isLoading = true;
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];

  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua'; // 'Semua', 'Belum dikerjakan', 'Dikerjakan', 'Selesai'
  String _selectedPriorityFilter = 'Semua Prioritas'; // 'Semua Prioritas', 'Prioritas Tinggi', 'Sedang', 'Rendah', 'Perlu Penanganan'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLiveTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final repository = context.read<ReportRepository>();
      List<ReportModel> list = [];
      try {
        final res = await repository.getReports(limit: 100);
        list = res.data ?? [];
      } catch (_) {
        list = repository.localSubmittedReports;
      }

      if (list.isEmpty) {
        list = repository.localSubmittedReports;
      }

      if (mounted) {
        setState(() {
          _allReports = list;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<ReportModel> list = List.from(_allReports);

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final code = r.reportCode.toLowerCase();
        final cat = r.categoryName.toLowerCase();
        final addr = (r.addressText ?? '').toLowerCase();
        final reporter = r.reporterName.toLowerCase();
        return code.contains(query) ||
            cat.contains(query) ||
            addr.contains(query) ||
            reporter.contains(query);
      }).toList();
    }

    // Status filter
    if (_selectedStatusFilter != 'Semua') {
      if (_selectedStatusFilter == 'Belum dikerjakan') {
        list = list.where((r) =>
            r.status == ReportStatus.assigned ||
            r.status == ReportStatus.pendingVerification ||
            r.status == ReportStatus.verified).toList();
      } else if (_selectedStatusFilter == 'Dikerjakan') {
        list = list.where((r) => r.status == ReportStatus.inProgress).toList();
      } else if (_selectedStatusFilter == 'Selesai') {
        list = list.where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved).toList();
      }
    }

    // Priority filter
    if (_selectedPriorityFilter != 'Semua Prioritas') {
      final filterLower = _selectedPriorityFilter.toLowerCase();
      list = list.where((r) {
        final p = r.priorityLabel.toLowerCase();
        if (filterLower.contains('tinggi')) {
          return p.contains('tinggi');
        } else if (filterLower.contains('sedang')) {
          return p.contains('sedang');
        } else if (filterLower.contains('rendah')) {
          return p.contains('rendah');
        } else if (filterLower.contains('perlu penanganan')) {
          return p.contains('perlu penanganan') || r.needsManualReview;
        }
        return true;
      }).toList();
    }

    _filteredReports = list;
  }

  void _showStatusFilterModal() {
    final options = ['Semua', 'Belum dikerjakan', 'Dikerjakan', 'Selesai'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                Text(
                  'Filter Status Tugas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = _selectedStatusFilter == opt;
              return ListTile(
                title: Text(
                  opt,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1976D2))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStatusFilter = opt;
                    _applyFilters();
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilterModal() {
    final options = [
      'Semua Prioritas',
      'Prioritas Tinggi',
      'Sedang',
      'Rendah',
      'Perlu Penanganan'
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                Text(
                  'Filter Prioritas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = _selectedPriorityFilter == opt;
              return ListTile(
                title: Text(
                  opt,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1976D2))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedPriorityFilter = opt;
                    _applyFilters();
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatCodeWithHash(String code) {
    if (code.startsWith('#')) return code;
    return '#$code';
  }

  String _formatDateTimeShort(DateTime dt) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[dt.weekday - 1];
    final d = dt.day;
    final m = months[dt.month - 1];
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dayName, $d $m $y | $h.$min WIB';
  }

  Color _getPriorityTextColor(String priority) {
    final lower = priority.toLowerCase();
    if (lower.contains('tinggi')) return const Color(0xFFC60D05);
    if (lower.contains('perlu penanganan')) return const Color(0xFFD97706);
    if (lower.contains('sedang')) return const Color(0xFFF2AE01);
    return const Color(0xFF1D9C51);
  }

  Color _getPriorityBgColor(String priority) {
    final lower = priority.toLowerCase();
    if (lower.contains('tinggi')) return const Color(0xFFFFE9E9);
    if (lower.contains('perlu penanganan')) return const Color(0xFFFFF4E5);
    if (lower.contains('sedang')) return const Color(0xFFFFF9E9);
    return const Color(0xFFE9F9EE);
  }

  Map<String, dynamic> _getStatusBadge(ReportStatus status) {
    if (status == ReportStatus.completed || status == ReportStatus.resolved) {
      return {
        'label': 'Selesai',
        'bg': const Color(0xFFE9F9EE),
        'text': const Color(0xFF1D9C51),
      };
    }
    if (status == ReportStatus.inProgress) {
      return {
        'label': 'Dikerjakan',
        'bg': const Color(0xFFE9F9EE),
        'text': const Color(0xFF1D9C51),
      };
    }
    if (status == ReportStatus.assigned) {
      return {
        'label': 'Belum dikerjakan',
        'bg': const Color(0xFFFFF9E9),
        'text': const Color(0xFFF2AE01),
      };
    }
    return {
      'label': 'Baru',
      'bg': const Color(0xFFEBF4FF),
      'text': const Color(0xFF1976D2),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            if (widget.isTab && widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Tugas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLiveTasks,
          color: const Color(0xFF1D9C51),
          child: Column(
            children: [
              // 1. Search Bar (Figma Node 662:5690)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _applyFilters();
                      });
                    },
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFABABAB),
                        size: 22,
                      ),
                      hintText: 'Cari ID, judul, lokasi, atau pelapor...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFABABAB),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _applyFilters();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // 2. Filter Pills Row (Figma Node 662:5697)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Filter Pill (Button 1)
                    Flexible(
                      child: InkWell(
                        onTap: _showStatusFilterModal,
                        borderRadius: BorderRadius.circular(8.5),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.4),
                            border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.menu_rounded,
                                size: 15,
                                color: Color(0xFF1976D2),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _selectedStatusFilter == 'Semua'
                                      ? 'Filter'
                                      : _selectedStatusFilter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1976D2),
                                  ),
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
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Priority Pill (Button 2)
                    Flexible(
                      child: InkWell(
                        onTap: _showPriorityFilterModal,
                        borderRadius: BorderRadius.circular(8.5),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.4),
                            border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _selectedPriorityFilter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1976D2),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
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
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Task Cards List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF1D9C51)),
                      )
                    : _filteredReports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_turned_in_outlined,
                                    size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada tugas yang sesuai',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: _filteredReports.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final report = _filteredReports[index];
                              return _buildTaskCard(report);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(ReportModel report) {
    final priorityText = report.priorityLabel;
    final statusBadge = _getStatusBadge(report.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail with Watermark (119x83, radius 8px)
              _buildThumbnailWithWatermark(report),
              const SizedBox(width: 12),

              // 2. Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Priority Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getPriorityBgColor(priorityText),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            priorityText,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: _getPriorityTextColor(priorityText),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Address
                    Text(
                      report.addressText ?? 'Jl. Ahmad Yani no. 15',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF4A5568),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Report ID (green text #1D9C51)
                    Text(
                      _formatCodeWithHash(report.reportCode),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1D9C51),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Status pill (e.g. Belum dikerjakan / Baru / Dikerjakan)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusBadge['bg'] as Color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        statusBadge['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: statusBadge['text'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Button "Lihat Tugas" bottom right (Figma Frame 676:1950)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 35,
                width: 105,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9C51),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFBCFFC2), width: 0.8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OperatorReportDetailScreen(
                          report: report,
                          onStatusUpdated: _fetchLiveTasks,
                        ),
                      ),
                    ).then((_) => _fetchLiveTasks());
                  },
                  child: Text(
                    'Lihat Tugas',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailWithWatermark(ReportModel r) {
    final photoUrl = r.directPhotoUrl != null && r.directPhotoUrl!.isNotEmpty
        ? r.directPhotoUrl!
        : (r.media.isNotEmpty ? r.media.first.url : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 119,
        height: 83,
        color: const Color(0xFFE2E8F0),
        child: Stack(
          children: [
            // Photo
            if (photoUrl != null && photoUrl.isNotEmpty)
              Image.network(
                photoUrl,
                width: 119,
                height: 83,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
              )
            else
              _buildFallbackThumbnail(),

            // Mini Watermark Stamp Badge (Figma 662:5980)
            Positioned(
              left: 3,
              bottom: 3,
              child: _buildMiniWatermarkBadge(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: Center(
        child: Icon(Icons.image_outlined, size: 28, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildMiniWatermarkBadge(ReportModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // LaporKita green tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 4.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _formatCodeWithHash(r.reportCode),
            style: GoogleFonts.poppins(
              fontSize: 5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 6, color: Colors.white),
              const SizedBox(width: 1.5),
              SizedBox(
                width: 55,
                child: Text(
                  r.addressText ?? 'Malang, Jawa Timur',
                  style: GoogleFonts.poppins(
                    fontSize: 4.5,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 6, color: Colors.white),
              const SizedBox(width: 1.5),
              Text(
                _formatDateTimeShort(r.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 4.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
