import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../reports/bloc/report_bloc.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  bool _isLoading = true;
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  
  int _manualReviewCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;

  String _searchQuery = '';
  String _selectedFilterTab = 'all'; // 'all', 'manual_review', 'in_progress', 'completed'

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repository = context.read<ReportRepository>();
      List<ReportModel> data = [];
      try {
        final response = await repository.getReports(limit: 100);
        data = response.data ?? [];
      } catch (_) {
        data = repository.localSubmittedReports;
      }

      if (data.isEmpty) {
        data = repository.localSubmittedReports;
      }

      if (mounted) {
        setState(() {
          _allReports = data;
          _recalculateCounts();
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

  void _recalculateCounts() {
    int inProgress = 0;
    int completed = 0;
    int manualReview = 0;

    for (final r in _allReports) {
      if (r.needsManualReview) {
        manualReview++;
      }
      if (r.status == ReportStatus.inProgress ||
          r.status == ReportStatus.assigned ||
          r.status == ReportStatus.verified) {
        inProgress++;
      } else if (r.status == ReportStatus.completed ||
          r.status == ReportStatus.resolved) {
        completed++;
      }
    }

    _manualReviewCount = manualReview;
    _inProgressCount = inProgress;
    _completedCount = completed;
  }

  void _applyFilters() {
    List<ReportModel> list = List.from(_allReports);

    // Filter by Tab
    if (_selectedFilterTab == 'manual_review') {
      list = list.where((r) => r.needsManualReview).toList();
    } else if (_selectedFilterTab == 'in_progress') {
      list = list
          .where((r) =>
              r.status == ReportStatus.inProgress ||
              r.status == ReportStatus.assigned ||
              r.status == ReportStatus.verified)
          .toList();
    } else if (_selectedFilterTab == 'completed') {
      list = list
          .where((r) =>
              r.status == ReportStatus.completed ||
              r.status == ReportStatus.resolved)
          .toList();
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        final code = r.reportCode.toLowerCase();
        final cat = r.categoryName.toLowerCase();
        final addr = (r.addressText ?? '').toLowerCase();
        final desc = (r.description ?? '').toLowerCase();
        return code.contains(q) || cat.contains(q) || addr.contains(q) || desc.contains(q);
      }).toList();
    }

    _filteredReports = list;
  }

  void _showUpdateStatusModal(ReportModel report) {
    ReportStatus targetStatus = report.status;
    final notesController = TextEditingController();
    String? completionPhotoPath;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle indicator bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.neutral300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.engineering_rounded,
                                  color: Color(0xFFD97706),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Update Penanganan Task',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    Text(
                                      report.reportCode,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFD97706),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.neutral500),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Info Card Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: _buildReportImageThumbnail(report),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.categoryName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  report.addressText ?? 'Lokasi tidak tersedia',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildSmallBadge(
                                      label: 'AI ${((report.aiConfidenceScore ?? 0.85) * 100).toInt()}%',
                                      color: (report.aiConfidenceScore ?? 0.85) >= 0.6
                                          ? AppColors.greenPrimary
                                          : AppColors.statusDanger,
                                    ),
                                    _buildSmallBadge(
                                      label: 'Urgensi ${(report.urgencyScore ?? 1.0).toStringAsFixed(1)}',
                                      color: const Color(0xFFD97706),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Select Target Status
                    const Text(
                      'Pilih Status Penanganan Baru:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAllowedOperatorStatuses(report.status).map((st) {
                        final isSelected = targetStatus == st;
                        return ChoiceChip(
                          label: Text(
                            st.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: AppColors.neutral100,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => targetStatus = st);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Catatan Operator
                    const Text(
                      'Catatan / Disposisi Operator:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan catatan perbaikan atau penugasan tim lapangan...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.neutral300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Upload Completion Photo (Wajib jika status COMPLETED)
                    if (targetStatus == ReportStatus.completed) ...[
                      Row(
                        children: const [
                          Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.greenPrimary),
                          SizedBox(width: 6),
                          Text(
                            'Foto Bukti Penyelesaian (Wajib)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          try {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setModalState(() {
                                completionPhotoPath = image.path;
                              });
                            }
                          } catch (_) {
                            // Fallback to gallery if camera fails (e.g. desktop/emulator without camera)
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setModalState(() {
                                completionPhotoPath = image.path;
                              });
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.greenPrimary.withValues(alpha: 0.5),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: completionPhotoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(completionPhotoPath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo_rounded,
                                        color: AppColors.greenPrimary, size: 28),
                                    SizedBox(height: 4),
                                    Text(
                                      'Ambil Foto Bukti Penyelesaian Perbaikan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.greenPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Save Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                final repo = context.read<ReportRepository>();
                                final notifRepo = context.read<NotificationRepository>();
                                final reportBloc = context.read<ReportBloc>();
                                final messenger = ScaffoldMessenger.of(modalContext);

                                try {
                                  // Upload completion photo if status is completed and photo selected
                                  if (targetStatus == ReportStatus.completed &&
                                      completionPhotoPath != null) {
                                    await repo.uploadReportMedia(
                                      reportId: report.id,
                                      filePath: completionPhotoPath!,
                                      type: 'completion_photo',
                                    );
                                  }

                                  final noteText = notesController.text.trim();
                                  final updatedReport = await repo.updateReportStatus(
                                    report.id,
                                    targetStatus.apiValue,
                                    notes: noteText.isNotEmpty ? noteText : null,
                                    existingReport: report,
                                  );

                                  try {
                                    notifRepo.addStatusUpdateNotification(
                                      reportCode: report.reportCode,
                                      newStatus: targetStatus,
                                      note: noteText.isNotEmpty ? noteText : null,
                                    );
                                  } catch (_) {}

                                  if (mounted) {
                                    setState(() {
                                      final idx = _allReports.indexWhere((r) => r.id == report.id);
                                      if (idx != -1) {
                                        _allReports[idx] = updatedReport;
                                      }
                                      _recalculateCounts();
                                      _applyFilters();
                                    });
                                  }

                                  if (modalContext.mounted) {
                                    reportBloc.add(
                                      ReportUpdateStatusRequested(
                                        reportId: report.id,
                                        newStatus: targetStatus.apiValue,
                                      ),
                                    );
                                    Navigator.pop(modalContext);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Status ${report.reportCode} berhasil diperbarui menjadi ${targetStatus.displayName}!'),
                                        backgroundColor: AppColors.greenPrimary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (modalContext.mounted) {
                                    final errStr = e.toString();
                                    String msg = 'Gagal memperbarui status: $errStr';
                                    if (errStr.contains('UNAUTHORIZED') ||
                                        errStr.contains('Unauthorized') ||
                                        errStr.contains('401') ||
                                        errStr.contains('403')) {
                                      msg =
                                          'Akses Ditolak (401/403): Akun Anda tidak memiliki role Operator/Admin atau token login telah kadaluarsa. Silakan login kembali dengan akun Operator.';
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: AppColors.statusDanger,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          isSaving ? 'Menyimpan...' : 'Simpan Status Penanganan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<ReportStatus> _getAllowedOperatorStatuses(ReportStatus current) {
    switch (current) {
      case ReportStatus.pendingVerification:
        return [ReportStatus.verified, ReportStatus.rejected];
      case ReportStatus.verified:
        return [ReportStatus.assigned, ReportStatus.inProgress, ReportStatus.rejected];
      case ReportStatus.assigned:
        return [ReportStatus.inProgress, ReportStatus.completed];
      case ReportStatus.inProgress:
        return [ReportStatus.completed];
      case ReportStatus.completed:
        return [ReportStatus.resolved, ReportStatus.disputed];
      case ReportStatus.disputed:
        return [ReportStatus.inProgress, ReportStatus.completed];
      case ReportStatus.resolved:
      case ReportStatus.rejected:
        return [current];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD97706), Color(0xFFB45309)],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.engineering_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Operator Task Force',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'DPUPR / Dishub Command Panel',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchLiveDashboardData,
            tooltip: 'Refresh Task Queue',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                  context, '/get-started', (route) => false);
            },
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97706)),
            )
          : RefreshIndicator(
              onRefresh: _fetchLiveDashboardData,
              color: const Color(0xFFD97706),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Alert Banner
                    _buildOperatorHeaderBanner(),
                    const SizedBox(height: 16),

                    // Metric Stat Cards
                    _buildMetricCards(),
                    const SizedBox(height: 20),

                    // Search Input & Filter Tabs
                    _buildSearchAndFilters(),
                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar Tugas Lapangan (${_filteredReports.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          'Tap Card Untuk Update',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Task Cards List
                    _buildTaskList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOperatorHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF9E9),
            const Color(0xFFFEF3C7).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_late_rounded,
              color: Color(0xFFD97706),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Antrean Task Force Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _manualReviewCount > 0
                      ? '$_manualReviewCount laporan perlu verifikasi manual & penugasan tim lapangan.'
                      : 'Semua verifikasi AI berjalan lancar. Siap memproses perbaikan lapangan.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral700,
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

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInteractiveStatCard(
            id: 'manual_review',
            title: 'Perlu Review',
            value: '$_manualReviewCount',
            icon: Icons.warning_amber_rounded,
            color: AppColors.statusDanger,
            bgColor: const Color(0xFFFFF1F2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInteractiveStatCard(
            id: 'in_progress',
            title: 'Diperbaiki',
            value: '$_inProgressCount',
            icon: Icons.build_circle_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInteractiveStatCard(
            id: 'completed',
            title: 'Selesai',
            value: '$_completedCount',
            icon: Icons.check_circle_rounded,
            color: AppColors.greenPrimary,
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveStatCard({
    required String id,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final bool isSelected = _selectedFilterTab == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterTab = isSelected ? 'all' : id;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.neutral200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Input Field
        TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
              _applyFilters();
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari kode (#LP-2026), kategori, lokasi...',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutral500, size: 20),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Semua (${_allReports.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Perlu Review ($_manualReviewCount)', 'manual_review'),
              const SizedBox(width: 8),
              _buildFilterChip('Sedang Diproses ($_inProgressCount)', 'in_progress'),
              const SizedBox(width: 8),
              _buildFilterChip('Selesai ($_completedCount)', 'completed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilterTab == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.neutral700,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFD97706),
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFFD97706) : AppColors.neutral300,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterTab = value;
            _applyFilters();
          });
        }
      },
    );
  }

  Widget _buildTaskList() {
    if (_filteredReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(Icons.assignment_outlined, size: 48, color: AppColors.neutral400),
            SizedBox(height: 12),
            Text(
              'Tidak ada tugas yang sesuai filter.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian atau tab filter.',
              style: TextStyle(fontSize: 11, color: AppColors.neutral500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredReports.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _filteredReports[index];
        return _buildTaskCard(r);
      },
    );
  }

  Widget _buildTaskCard(ReportModel r) {
    final statusColor = _getStatusColor(r.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.needsManualReview ? AppColors.statusDanger.withValues(alpha: 0.4) : AppColors.neutral200,
          width: r.needsManualReview ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUpdateStatusModal(r),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Image + Code + Category + Urgency Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: _buildReportImageThumbnail(r),
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
                              Text(
                                r.reportCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              _buildStatusBadge(r.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.categoryName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address & Details
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.neutral500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        r.addressText ?? 'Lokasi tidak tersedia',
                        style: const TextStyle(fontSize: 11, color: AppColors.neutral700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.neutral200),
                const SizedBox(height: 10),

                // Bottom Meta Bar: AI Score + Urgency + Update CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildSmallBadge(
                            label: 'AI: ${((r.aiConfidenceScore ?? 0.85) * 100).toInt()}%',
                            color: (r.aiConfidenceScore ?? 0.85) >= 0.6
                                ? AppColors.greenPrimary
                                : AppColors.statusDanger,
                          ),
                          _buildSmallBadge(
                            label: 'Urgensi ${(r.urgencyScore ?? 1.0).toStringAsFixed(1)}',
                            color: const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),

                    // Update Status Button CTA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportImageThumbnail(ReportModel r) {
    final photoUrl = r.formattedPhotoUrl ?? r.photoUrl ?? '';
    if (photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.network(
          ReportModel.getCategoryFallbackImage(r.categoryName),
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.network(
      ReportModel.getCategoryFallbackImage(r.categoryName),
      fit: BoxFit.cover,
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSmallBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendingVerification:
        return AppColors.statusDanger;
      case ReportStatus.verified:
        return const Color(0xFF3B82F6);
      case ReportStatus.assigned:
        return const Color(0xFF8B5CF6);
      case ReportStatus.inProgress:
        return const Color(0xFFD97706);
      case ReportStatus.completed:
      case ReportStatus.resolved:
        return AppColors.greenPrimary;
      case ReportStatus.rejected:
        return AppColors.neutral700;
      case ReportStatus.disputed:
        return AppColors.statusDanger;
    }
  }
}
