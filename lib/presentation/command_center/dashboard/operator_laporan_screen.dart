import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_report_detail_screen.dart';

class OperatorLaporanScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const OperatorLaporanScreen({
    super.key,
    this.isTab = false,
    this.onBackToDashboard,
  });

  @override
  State<OperatorLaporanScreen> createState() => _OperatorLaporanScreenState();
}

class _OperatorLaporanScreenState extends State<OperatorLaporanScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  bool _isLoading = true;

  String _selectedPriority = 'Semua Prioritas';
  String _selectedCategory = 'Semua Kategori';

  final List<String> _priorityOptions = [
    'Semua Prioritas',
    'Prioritas Tinggi',
    'Sedang',
    'Perlu Penanganan',
    'Rendah',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getReports(limit: 50);
      if (mounted) {
        setState(() {
          _allReports = res.data ?? [];
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredReports = _allReports.where((r) {
        // Search query filter
        final matchSearch = query.isEmpty ||
            r.categoryName.toLowerCase().contains(query) ||
            r.formattedReportCode.toLowerCase().contains(query) ||
            (r.addressText ?? '').toLowerCase().contains(query) ||
            (r.description ?? '').toLowerCase().contains(query);

        // Priority filter
        bool matchPriority = true;
        if (_selectedPriority != 'Semua Prioritas') {
          final pLabel = r.priorityLabel.toLowerCase();
          if (_selectedPriority == 'Prioritas Tinggi') {
            matchPriority = pLabel.contains('tinggi');
          } else if (_selectedPriority == 'Sedang') {
            matchPriority = pLabel.contains('sedang');
          } else if (_selectedPriority == 'Perlu Penanganan') {
            matchPriority = pLabel.contains('penanganan') || pLabel.contains('perlu');
          } else if (_selectedPriority == 'Rendah') {
            matchPriority = pLabel.contains('rendah');
          }
        }

        // Category filter
        bool matchCategory = true;
        if (_selectedCategory != 'Semua Kategori') {
          matchCategory = r.categoryName.toLowerCase() == _selectedCategory.toLowerCase();
        }

        return matchSearch && matchPriority && matchCategory;
      }).toList();
    });
  }

  void _showCategoryFilterDialog() {
    final categories = ['Semua Kategori', ..._allReports.map((r) => r.categoryName).toSet()];

    showModalBottomSheet(
      context: context,
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
                Text(
                  'Pilih Kategori Laporan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF1D9C51) : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: Color(0xFF1D9C51))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _applyFilters();
                      Navigator.pop(ctx);
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
    if (lower.contains('perlu penanganan')) return const Color(0xFFFFF2D6);
    if (lower.contains('sedang')) return const Color(0xFFFFF9E9);
    return const Color(0xFFE9F9EE);
  }

  Map<String, dynamic> _getStatusPill(ReportStatus status) {
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
        'bg': const Color(0xFFDCFFDF),
        'text': const Color(0xFF1D9C51),
      };
    }
    if (status == ReportStatus.assigned) {
      return {
        'label': 'Belum dikerjakan',
        'bg': const Color(0xFFFFF6D8),
        'text': const Color(0xFFD97706),
      };
    }
    return {
      'label': 'Baru',
      'bg': const Color(0xFFDDF0FF),
      'text': const Color(0xFF0284C7),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
          onPressed: () {
            if (widget.isTab) {
              widget.onBackToDashboard?.call();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Laporan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar & Filter Controls (Node 676:1696)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Cari ID, judul, lokasi, atau pelapor...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            onPressed: () => _searchController.clear(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filter button
                      Flexible(
                        child: GestureDetector(
                          onTap: _showCategoryFilterDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, color: Color(0xFF1976D2), size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _selectedCategory == 'Semua Kategori' ? 'Filter' : _selectedCategory,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1976D2),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1976D2), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Priority Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1976D2),
                              size: 18,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1976D2),
                            ),
                            items: _priorityOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text(opt),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPriority = val);
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 2. Report Cards List (Node 676:1696)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9C51)))
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      color: const Color(0xFF1D9C51),
                      child: _filteredReports.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada laporan yang sesuai',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filteredReports.length,
                              itemBuilder: (context, index) {
                                return _buildReportCard(_filteredReports[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final priorityText = report.priorityLabel;
    final statusPill = _getStatusPill(report.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorReportDetailScreen(
              report: report,
              onStatusUpdated: _fetchReports,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
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
            // Thumbnail
            Container(
              width: 119,
              height: 83,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBEC4BD), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildThumbnailImage(report),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
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
                    report.addressText ?? 'Jl. Ahmad Yani no. 15',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.formattedReportCode,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D9C51),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusPill['bg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusPill['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: statusPill['text'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Priority badge & Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                const SizedBox(height: 28),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black54,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(ReportModel report) {
    final url = report.primaryPhotoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      } else if (File(url).existsSync()) {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      }
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
      ),
    );
  }
}
