import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import 'operator_foto_sebelum_screen.dart';
import 'operator_update_progress_screen.dart';
import 'operator_foto_sesudah_screen.dart';
import '../../shared_widgets/report_thumbnail_image.dart';

class OperatorReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  final VoidCallback? onStatusUpdated;

  const OperatorReportDetailScreen({
    super.key,
    required this.report,
    this.onStatusUpdated,
  });

  @override
  State<OperatorReportDetailScreen> createState() =>
      _OperatorReportDetailScreenState();
}

class _OperatorReportDetailScreenState
    extends State<OperatorReportDetailScreen> {
  late ReportModel _currentReport;
  late ReportStatus _selectedStatus;
  bool _isUpdating = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'status': ReportStatus.assigned,
      'label': 'Belum dikerjakan',
      'apiValue': 'assigned',
    },
    {
      'status': ReportStatus.inProgress,
      'label': 'Sedang Dikerjakan',
      'apiValue': 'in_progress',
    },
    {
      'status': ReportStatus.completed,
      'label': 'Selesai',
      'apiValue': 'completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _selectedStatus = _mapToOperatorStatus(_currentReport.status);
  }

  ReportStatus _mapToOperatorStatus(ReportStatus status) {
    if (status == ReportStatus.completed || status == ReportStatus.resolved) {
      return ReportStatus.completed;
    }
    if (status == ReportStatus.inProgress) {
      return ReportStatus.inProgress;
    }
    return ReportStatus.assigned;
  }

  String _formatCodeWithHash(String code) {
    if (code.startsWith('#')) return code;
    return '#$code';
  }

  String _formatDateSimple(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final d = date.day;
    final m = months[date.month - 1];
    final y = date.year;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d $m $y | $h.$min';
  }

  String _formatDateFull(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dayName = days[date.weekday - 1];
    final d = date.day;
    final m = months[date.month - 1];
    final y = date.year;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
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

  Future<void> _updateReportStatus(ReportStatus newStatus, {String? customNote}) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final repo = context.read<ReportRepository>();

      // Sesuai state machine Rules.md §1.1 & intruksi.md:
      // Alur: verified -> assigned -> in_progress -> completed.
      // Jika status laporan masih verified dan operator memilih in_progress,
      // lakukan transisi assigned terlebih dahulu agar backend tidak menolak (409 Conflict).
      if (_currentReport.status == ReportStatus.verified &&
          newStatus == ReportStatus.inProgress) {
        await repo.updateReportStatus(
          _currentReport.id,
          ReportStatus.assigned.apiValue,
          notes: 'Laporan ditugaskan ke operator lapangan.',
          existingReport: _currentReport,
        );
      }

      final updated = await repo.updateReportStatus(
        _currentReport.id,
        newStatus.apiValue,
        notes: customNote ?? 'Status diperbarui oleh Operator Lapangan OPD.',
        existingReport: _currentReport,
      );

      if (mounted) {
        setState(() {
          _currentReport = updated;
          _selectedStatus = _mapToOperatorStatus(updated.status);
          _isUpdating = false;
        });

        // Trigger local notification for responsiveness
        try {
          context.read<NotificationRepository>().addStatusUpdateNotification(
                reportCode: _currentReport.reportCode,
                newStatus: _selectedStatus,
                note: 'Status laporan diubah ke ${_selectedStatus.displayName}.',
              );
        } catch (_) {}

        widget.onStatusUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1D9C51),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Status berhasil diubah ke ${_selectedStatus.displayName}!',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _selectedStatus = _mapToOperatorStatus(_currentReport.status);
        });

        final isAuthErr = e is ApiException &&
            (e.isTokenInvalid || e.code == 'UNAUTHORIZED' || e.statusCode == 401);
        final errorMsg = isAuthErr
            ? 'Sesi tidak terautentikasi atau kedaluwarsa. Silakan login kembali dengan akun Petugas/Operator.'
            : (e is ApiException ? e.message : e.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: isAuthErr
                ? SnackBarAction(
                    label: 'Login',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushNamed(context, '/login',
                          arguments: 'CommandCenter');
                    },
                  )
                : null,
            content: Text(
              'Gagal memperbarui status: $errorMsg',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    }
  }



  void _showNavigationSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_rounded, color: Color(0xFF1D9C51), size: 26),
                const SizedBox(width: 10),
                Text(
                  'Koordinat Lokasi Tugas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentReport.addressText ?? 'Malang, Jawa Timur',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 16, color: Color(0xFF1D9C51)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_currentReport.latitude.toStringAsFixed(6)}, ${_currentReport.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.black54),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${_currentReport.latitude},${_currentReport.longitude}',
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1D9C51),
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Koordinat disalin ke clipboard!',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Salin Koordinat',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9C51),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Salin & Navigasi ke Maps',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '${_currentReport.latitude},${_currentReport.longitude}',
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1D9C51),
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Koordinat berhasil disalin! Buka Google Maps untuk navigasi.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _currentReport;
    final priorityText = r.priorityLabel;
    final centerPoint = LatLng(
      (r.latitude != 0.0) ? r.latitude : -7.9826,
      (r.longitude != 0.0) ? r.longitude : 112.6308,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Detail Laporan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1D9C51),
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Tautan laporan ${r.reportCode} disalin!',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Report Code & Priority Pill Row (Figma Frame 2790)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCodeWithHash(r.reportCode),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4A5568),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.categoryName,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.addressText ?? 'Jl. Ahmad Yani no. 15',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityBgColor(priorityText),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      priorityText,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getPriorityTextColor(priorityText),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Large Photo Container with Watermark (Figma Rectangle 2797 + Frame 2687)
              _buildHeroPhotoWithWatermark(r),
              const SizedBox(height: 20),

              // 3. Description Section (Figma 662:6378)
              Text(
                'Deskripsi :',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (r.description != null && r.description!.isNotEmpty)
                    ? r.description!
                    : 'Jalan sudah tidak layak karena banyak retakan dan lubang disepanjang jalan.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Status Pengerjaan Dropdown (Figma Frame 2791)
              Text(
                'Status Pengerjaan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0DFDF)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF4A5568),
                      size: 24,
                    ),
                    items: _statusOptions.map((opt) {
                      return DropdownMenuItem<ReportStatus>(
                        value: opt['status'] as ReportStatus,
                        child: Text(
                          opt['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newVal) {
                      if (newVal != null && newVal != _selectedStatus) {
                        setState(() => _selectedStatus = newVal);
                        _updateReportStatus(newVal);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Metadata Table (Figma Frame 2774)
              _buildMetadataTable(r),
              const SizedBox(height: 24),

              // 6. Map Card with "Navigasi ke lokasi" Button (Figma Frame 2830)
              _buildMapCard(r, centerPoint),
              const SizedBox(height: 28),

              // 7. Bottom Main Action Button (Figma Frame 2695 / 663:7765)
              _buildBottomActionButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPhotoWithWatermark(ReportModel r) {
    return ReportThumbnailImage(
      report: r,
      width: double.infinity,
      height: 204,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      overlay: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: _buildWatermarkBadge(r),
          ),
        ],
      ),
    );
  }


  Widget _buildWatermarkBadge(ReportModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Green LaporKita Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF42A54B).withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF62D26D), width: 0.5),
            ),
            child: Text(
              'LaporKita',
              style: GoogleFonts.poppins(
                fontSize: 7,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 2.5),
          Text(
            _formatCodeWithHash(r.reportCode),
            style: GoogleFonts.poppins(
              fontSize: 7.5,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 9, color: Colors.white),
              const SizedBox(width: 3),
              SizedBox(
                width: 110,
                child: Text(
                  r.addressText ?? 'Jl. Ahmad Yani No.15 Malang',
                  style: GoogleFonts.poppins(
                    fontSize: 7,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 9, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                _formatDateFull(r.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 9, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                r.categoryName,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory_rounded, size: 9, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                '${r.latitude.toStringAsFixed(6)},${r.longitude.toStringAsFixed(6)}',
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataTable(ReportModel r) {
    final aiConfidence = (r.rawAiConfidenceScore ??
            (r.damageSeverity != null ? r.damageSeverity! * 100 : 85))
        .toInt();
    final priorityText = r.priorityLabel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildMetadataRow('Laporan dibuat', _formatDateSimple(r.createdAt)),
          _buildMetadataRow('Pelapor', r.reporterName.isNotEmpty ? r.reporterName : 'Budi Santoso'),
          _buildMetadataRow('Kategori', r.categoryName),
          _buildMetadataRow(
            'Prioritas AI',
            '${priorityText.replaceAll('Prioritas ', '')} ($aiConfidence/100)',
            valueColor: _getPriorityTextColor(priorityText),
            isBoldValue: true,
          ),
          _buildMetadataRow('OPD Tujuan', r.assignedAgency?['name'] ?? 'Dinas PUPR'),
          _buildMetadataRow(
            'Koordinat',
            '${r.latitude.toStringAsFixed(6)},${r.longitude.toStringAsFixed(6)}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: const Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF2D3748),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isBoldValue ? FontWeight.w600 : FontWeight.w400,
                      color: valueColor ?? const Color(0xFF4A5568),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(ReportModel r, LatLng centerPoint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // FlutterMap
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: centerPoint,
                  initialZoom: 15.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.laporkita.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: centerPoint,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53E3E),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Green "Navigasi ke lokasi" button (Figma Frame 2695 / 663:7762)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9C51),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.near_me_rounded, color: Colors.white, size: 20),
              label: Text(
                'Navigasi ke lokasi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: _showNavigationSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton() {
    String buttonText = 'Mulai Pengerjaan';
    VoidCallback? onTap = () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OperatorFotoSebelumScreen(
            report: _currentReport,
            onStatusUpdated: () {
              widget.onStatusUpdated?.call();
              setState(() {
                _selectedStatus = ReportStatus.inProgress;
              });
            },
          ),
        ),
      );
      widget.onStatusUpdated?.call();
    };

    if (_selectedStatus == ReportStatus.inProgress) {
      buttonText = 'Update Progress / Selesai';
      onTap = () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorUpdateProgressScreen(
              report: _currentReport,
              onStatusUpdated: () {
                widget.onStatusUpdated?.call();
              },
            ),
          ),
        );
        widget.onStatusUpdated?.call();
      };
    } else if (_selectedStatus == ReportStatus.completed ||
        _selectedStatus == ReportStatus.resolved) {
      buttonText = 'Lihat Bukti Selesai';
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorFotoSesudahScreen(
              report: _currentReport,
              onStatusUpdated: () {
                widget.onStatusUpdated?.call();
              },
            ),
          ),
        );
      };
    }

    return SizedBox(
      width: double.infinity,
      height: 49,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D9C51),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isUpdating ? null : onTap,
        child: _isUpdating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
