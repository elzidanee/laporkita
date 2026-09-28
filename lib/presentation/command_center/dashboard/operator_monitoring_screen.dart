import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_report_detail_screen.dart';

class OperatorMonitoringScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const OperatorMonitoringScreen({
    super.key,
    this.isTab = false,
    this.onBackToDashboard,
  });

  @override
  State<OperatorMonitoringScreen> createState() =>
      _OperatorMonitoringScreenState();
}

class _OperatorMonitoringScreenState extends State<OperatorMonitoringScreen> {
  List<ReportModel> _allReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      final res = await repo.getReports(limit: 50);
      if (mounted) {
        setState(() {
          _allReports = res.data ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic counts
    final totalCount = _allReports.isNotEmpty ? _allReports.length : 128;
    final inProgressCount = _allReports
        .where((r) => r.status == ReportStatus.inProgress)
        .length;
    final completedCount = _allReports
        .where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved)
        .length;
    final lateCount = _allReports
        .where((r) =>
            r.priorityLabel.toLowerCase().contains('tinggi') &&
            r.status != ReportStatus.completed)
        .length;

    // Urgent reports
    final attentionReports = _allReports.take(2).toList();

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
          'Mentoring OPD',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9C51)))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF1D9C51),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 2x2 Stat Cards (Node 678:2315)
                      _build2x2StatCards(
                        total: totalCount,
                        inProgress: inProgressCount > 0 ? inProgressCount : 32,
                        completed: completedCount > 0 ? completedCount : 18,
                        overdue: lateCount > 0 ? lateCount : 4,
                      ),
                      const SizedBox(height: 24),

                      // 2. Card: "Progress Tim" (Node 678:2315)
                      _buildProgressTimCard(),
                      const SizedBox(height: 24),

                      // 3. Section: "Tugas Perlu perhatian" (Node 678:2315)
                      Text(
                        'Tugas Perlu perhatian',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAttentionReports(attentionReports),
                      const SizedBox(height: 24),

                      // 4. Section: "Aktivitas Tim" (Node 678:2315)
                      _buildAktivitasTimCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── 1. 2x2 Stat Cards ─────────────────────────────────────────────────────
  Widget _build2x2StatCards({
    required int total,
    required int inProgress,
    required int completed,
    required int overdue,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSingleStatCard(
                title: 'Total Laporan',
                titleColor: Colors.black87,
                count: '$total',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSingleStatCard(
                title: 'Sedang Diproses',
                titleColor: const Color(0xFFE6A100),
                count: '$inProgress',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildSingleStatCard(
                title: 'Selesai minggu ini',
                titleColor: const Color(0xFF1D9C51),
                count: '$completed',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSingleStatCard(
                title: 'Terlambat',
                titleColor: const Color(0xFFEF4444),
                count: '$overdue',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleStatCard({
    required String title,
    required Color titleColor,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Progress Tim Card ──────────────────────────────────────────────────
  Widget _buildProgressTimCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Tim',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Team Member 1: Andi Pratama
          _buildTeamMemberRow(
            name: 'Andi Pratama',
            initials: 'AP',
            tasks: '8 Tugas',
            percentage: 0.80,
            percentText: '80%',
          ),
          const SizedBox(height: 16),

          // Team Member 2: Budi Santoso
          _buildTeamMemberRow(
            name: 'Budi Santoso',
            initials: 'BS',
            tasks: '6 Tugas',
            percentage: 0.67,
            percentText: '67%',
          ),
          const SizedBox(height: 16),

          // Team Member 3: Rina Marlina
          _buildTeamMemberRow(
            name: 'Rina Marlina',
            initials: 'RM',
            tasks: '5 Tugas',
            percentage: 0.90,
            percentText: '90%',
          ),
          const SizedBox(height: 20),

          // Button: Lihat Semua
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1976D2), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menampilkan seluruh anggota tim OPD')),
                );
              },
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow({
    required String name,
    required String initials,
    required String tasks,
    required double percentage,
    required String percentText,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFFE2E8F0),
          child: Text(
            initials,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 55,
                    child: Text(
                      tasks,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF1D9C51),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D9C51)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    percentText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D9C51),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 3. Tugas Perlu Perhatian ──────────────────────────────────────────────
  Widget _buildAttentionReports(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF)),
        ),
        child: Center(
          child: Text(
            'Tidak ada tugas yang memerlukan perhatian khusus',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildAttentionCard(
          report: reports.first,
          badgeLabel: 'Belum ada progress',
          badgeBg: const Color(0xFFFFF6D8),
          badgeText: const Color(0xFFD97706),
        ),
        if (reports.length > 1) ...[
          const SizedBox(height: 12),
          _buildAttentionCard(
            report: reports[1],
            badgeLabel: 'Terlambat',
            badgeBg: const Color(0xFFFFE9E9),
            badgeText: const Color(0xFFEF4444),
          ),
        ],
      ],
    );
  }

  Widget _buildAttentionCard({
    required ReportModel report,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeText,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorReportDetailScreen(
              report: report,
              onStatusUpdated: _fetchData,
            ),
          ),
        );
      },
      child: Container(
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
            Container(
              width: 100,
              height: 70,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.categoryName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.addressText ?? 'Jl. Veteran, Malang',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: badgeText,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black54,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Aktivitas Tim Card ─────────────────────────────────────────────────
  Widget _buildAktivitasTimCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Tim',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            name: 'Andi Pratama',
            action: 'Mengunggah progres 80% pada Jalan Rusak Malang',
            time: '10 menit lalu',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF1D9C51),
          ),
          const Divider(height: 20),
          _buildActivityItem(
            name: 'Budi Santoso',
            action: 'Mulai pengerjaan pada Halte Rusak Jl. Soekarno Hatta',
            time: '35 menit lalu',
            icon: Icons.play_circle_outline,
            iconColor: const Color(0xFF1976D2),
          ),
          const Divider(height: 20),
          _buildActivityItem(
            name: 'Rina Marlina',
            action: 'Menyelesaikan perbaikan trotoar Jl. Budi Luhur',
            time: '1 jam lalu',
            icon: Icons.task_alt,
            iconColor: const Color(0xFF1D9C51),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String action,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                  children: [
                    TextSpan(
                      text: '$name ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: action),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
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
