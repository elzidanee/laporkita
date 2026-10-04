import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'operator_report_detail_screen.dart';
import '../../shared_widgets/report_thumbnail_image.dart';

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

class _TeamProgressData {
  final String name;
  final String initials;
  final int totalTasks;
  final int completedTasks;

  _TeamProgressData({
    required this.name,
    required this.initials,
    required this.totalTasks,
    required this.completedTasks,
  });

  double get percentage =>
      totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;
  String get percentText => '${(percentage * 100).toInt()}%';
  String get tasksText => '$totalTasks Tugas';
}

class _ActivityItemData {
  final String name;
  final String action;
  final DateTime time;
  final IconData icon;
  final Color iconColor;
  final ReportModel? report;

  _ActivityItemData({
    required this.name,
    required this.action,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.report,
  });
}

class _OperatorMonitoringScreenState extends State<OperatorMonitoringScreen> {
  List<ReportModel> _allReports = [];
  bool _isLoading = true;
  bool _showAllTeamMembers = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ReportRepository>();
      List<ReportModel> list = [];
      try {
        final res = await repo.getReports(limit: 100);
        list = res.data ?? [];
      } catch (_) {
        list = repo.localSubmittedReports;
      }
      if (list.isEmpty) {
        list = repo.localSubmittedReports;
      }

      if (mounted) {
        setState(() {
          _allReports = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Metric counts 100% dinamis dari data backend
    final totalCount = _allReports.length;
    final inProgressCount = _allReports
        .where((r) => r.status == ReportStatus.inProgress)
        .length;
    final completedCount = _allReports
        .where((r) =>
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved)
        .length;
    final now = DateTime.now();
    final overdueCount = _allReports.where((r) {
      if (r.status == ReportStatus.completed ||
          r.status == ReportStatus.resolved ||
          r.status == ReportStatus.rejected) {
        return false;
      }
      final isOverdue = r.estimatedCompletionAt != null &&
          r.estimatedCompletionAt!.isBefore(now);
      final isHighPriority =
          r.priorityLabel.toLowerCase().contains('tinggi') ||
          r.needsManualReview;
      return isOverdue || isHighPriority;
    }).length;

    // 2. Daftar tugas perlu perhatian dinamis
    final attentionReports = _getAttentionReports();

    // 3. Progres tim dinamis
    final teamProgressList = _buildTeamProgressList();

    // 4. Aktivitas tim dinamis
    final activityList = _buildActivityList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 22),
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
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D9C51)),
              )
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF1D9C51),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 2x2 Stat Cards (Node 678:2315)
                      _build2x2StatCards(
                        total: totalCount,
                        inProgress: inProgressCount,
                        completed: completedCount,
                        overdue: overdueCount,
                      ),
                      const SizedBox(height: 24),

                      // 2. Card: "Progress Tim" (Node 678:2315)
                      _buildProgressTimCard(teamProgressList),
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
                      _buildAttentionSection(attentionReports),
                      const SizedBox(height: 24),

                      // 4. Section: "Aktivitas Tim" (Node 678:2315)
                      _buildAktivitasTimCard(activityList),
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
  Widget _buildProgressTimCard(List<_TeamProgressData> teamList) {
    if (teamList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
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
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada penugasan pengerjaan tim yang aktif.',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayed =
        _showAllTeamMembers ? teamList : teamList.take(3).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Tim',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${teamList.length} Divisi/Petugas',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D9C51),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Render team members
          for (int i = 0; i < displayed.length; i++) ...[
            _buildTeamMemberRow(displayed[i]),
            if (i < displayed.length - 1) const SizedBox(height: 16),
          ],

          if (teamList.length > 3) ...[
            const SizedBox(height: 18),
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
                  setState(() => _showAllTeamMembers = !_showAllTeamMembers);
                },
                child: Text(
                  _showAllTeamMembers ? 'Sembunyikan' : 'Lihat Semua (${teamList.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(_TeamProgressData item) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFFE2E8F0),
          child: Text(
            item.initials,
            style: GoogleFonts.poppins(
              fontSize: 11,
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
                item.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 65,
                    child: Text(
                      item.tasksText,
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
                        value: item.percentage,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1D9C51)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.percentText,
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

  List<_TeamProgressData> _buildTeamProgressList() {
    if (_allReports.isEmpty) return [];

    // 1. Ekstrak nama personil dari status history / note
    final Map<String, List<ReportModel>> perActor = {};

    for (final r in _allReports) {
      String? foundActor;
      for (final h in r.statusHistory) {
        if (h.actorName != null &&
            h.actorName!.isNotEmpty &&
            !h.actorName!.toLowerCase().contains('citizen') &&
            !h.actorName!.toLowerCase().contains('warga') &&
            !h.actorName!.toLowerCase().contains('admin')) {
          foundActor = h.actorName;
          break;
        }
        if (h.note != null && h.note!.contains('Petugas:')) {
          final match = RegExp(r'Petugas:\s*([^,\)\|\n]+)').firstMatch(h.note!);
          if (match != null) {
            foundActor = match.group(1)!.trim();
            break;
          }
        }
      }

      if (foundActor != null && foundActor.isNotEmpty) {
        perActor.putIfAbsent(foundActor, () => []).add(r);
      }
    }

    if (perActor.isNotEmpty) {
      return perActor.entries.map((e) {
        final list = e.value;
        final completed = list
            .where((r) =>
                r.status == ReportStatus.completed ||
                r.status == ReportStatus.resolved)
            .length;
        return _TeamProgressData(
          name: e.key,
          initials: _getInitials(e.key),
          totalTasks: list.length,
          completedTasks: completed,
        );
      }).toList();
    }

    // 2. Jika belum ada nama personil individual di history, kelompokkan berdasarkan Divisi/Kategori OPD
    final Map<String, List<ReportModel>> perCategory = {};
    for (final r in _allReports) {
      final key = _getTeamNameForCategory(r.categoryName);
      perCategory.putIfAbsent(key, () => []).add(r);
    }

    return perCategory.entries.map((e) {
      final list = e.value;
      final completed = list
          .where((r) =>
              r.status == ReportStatus.completed ||
              r.status == ReportStatus.resolved)
          .length;
      return _TeamProgressData(
        name: e.key,
        initials: _getInitials(e.key),
        totalTasks: list.length,
        completedTasks: completed,
      );
    }).toList();
  }

  String _getTeamNameForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('jalan') || lower.contains('lubang') || lower.contains('aspal')) {
      return 'Tim Pemeliharaan Jalan';
    } else if (lower.contains('lampu') || lower.contains('pju') || lower.contains('penerangan')) {
      return 'Tim Penerangan Jalan (PJU)';
    } else if (lower.contains('drainase') || lower.contains('saluran') || lower.contains('banjir')) {
      return 'Tim Drainase & Sanitasi';
    } else if (lower.contains('rambu') || lower.contains('lalu lintas') || lower.contains('marka')) {
      return 'Tim Rambu Lalu Lintas';
    } else if (lower.contains('trotoar') || lower.contains('pedestrian')) {
      return 'Tim Trotoar & Pedestrian';
    } else {
      return 'Tim Reaksi Cepat OPD';
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'OP';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  // ── 3. Tugas Perlu Perhatian ──────────────────────────────────────────────
  List<ReportModel> _getAttentionReports() {
    final active = _allReports.where((r) {
      return r.status != ReportStatus.completed &&
          r.status != ReportStatus.resolved &&
          r.status != ReportStatus.rejected;
    }).toList();

    active.sort((a, b) {
      final now = DateTime.now();
      final aOverdue = a.estimatedCompletionAt != null &&
          a.estimatedCompletionAt!.isBefore(now);
      final bOverdue = b.estimatedCompletionAt != null &&
          b.estimatedCompletionAt!.isBefore(now);
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;

      final aHigh = a.priorityLabel.toLowerCase().contains('tinggi');
      final bHigh = b.priorityLabel.toLowerCase().contains('tinggi');
      if (aHigh != bHigh) return aHigh ? -1 : 1;

      return a.createdAt.compareTo(b.createdAt);
    });

    return active.take(3).toList();
  }

  Widget _buildAttentionSection(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF1D9C51), size: 20),
            const SizedBox(width: 8),
            Text(
              'Semua tugas berjalan lancar & terkendali.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    return Column(
      children: [
        for (int i = 0; i < reports.length; i++) ...[
          _buildAttentionCard(reports[i], now),
          if (i < reports.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAttentionCard(ReportModel report, DateTime now) {
    final isOverdue = report.estimatedCompletionAt != null &&
        report.estimatedCompletionAt!.isBefore(now);
    final isHigh = report.priorityLabel.toLowerCase().contains('tinggi');
    final isAssigned = report.status == ReportStatus.assigned;

    String label;
    Color bg;
    Color text;

    if (isOverdue) {
      label = 'Terlambat';
      bg = const Color(0xFFFFE9E9);
      text = const Color(0xFFEF4444);
    } else if (isHigh) {
      label = 'Prioritas Tinggi';
      bg = const Color(0xFFFFE9E9);
      text = const Color(0xFFC60D05);
    } else if (isAssigned) {
      label = 'Belum dikerjakan';
      bg = const Color(0xFFFFF6D8);
      text = const Color(0xFFD97706);
    } else {
      label = 'Sedang diproses';
      bg = const Color(0xFFE0F2FE);
      text = const Color(0xFF0284C7);
    }

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
                    report.addressText ?? 'Jl. Malang, Jawa Timur',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.black87),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: text,
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
  List<_ActivityItemData> _buildActivityList() {
    final List<_ActivityItemData> items = [];

    for (final r in _allReports) {
      if (r.statusHistory.isNotEmpty) {
        for (final h in r.statusHistory) {
          final author = (h.actorName != null && h.actorName!.isNotEmpty)
              ? h.actorName!
              : (r.assignedAgency?['name'] as String? ?? 'Petugas OPD');

          IconData icon;
          Color color;
          String action;

          switch (h.targetStatus) {
            case ReportStatus.completed:
            case ReportStatus.resolved:
              icon = Icons.task_alt_rounded;
              color = const Color(0xFF1D9C51);
              action =
                  'Menyelesaikan perbaikan pada ${r.categoryName} (${r.formattedReportCode})';
              break;
            case ReportStatus.inProgress:
              icon = Icons.play_circle_outline_rounded;
              color = const Color(0xFF1976D2);
              action = h.note != null && h.note!.contains('Progress')
                  ? 'Memperbarui ${h.note} pada ${r.categoryName}'
                  : 'Memulai pengerjaan pada ${r.categoryName} (${r.formattedReportCode})';
              break;
            case ReportStatus.assigned:
              icon = Icons.assignment_turned_in_outlined;
              color = const Color(0xFFE6A100);
              action =
                  'Ditugaskan untuk perbaikan ${r.categoryName} di ${r.addressText ?? "Malang"}';
              break;
            case ReportStatus.verified:
              icon = Icons.verified_outlined;
              color = const Color(0xFF1D9C51);
              action = 'Laporan ${r.formattedReportCode} terverifikasi valid';
              break;
            default:
              icon = Icons.info_outline_rounded;
              color = const Color(0xFF64748B);
              action = h.note?.isNotEmpty == true
                  ? h.note!
                  : 'Status laporan diperbarui ke ${h.targetStatus.displayName}';
              break;
          }

          items.add(_ActivityItemData(
            name: author,
            action: action,
            time: h.createdAt,
            icon: icon,
            iconColor: color,
            report: r,
          ));
        }
      } else {
        items.add(_ActivityItemData(
          name: r.reporterName.isNotEmpty ? r.reporterName : 'Warga Pelapor',
          action: 'Melaporkan ${r.categoryName} (${r.formattedReportCode})',
          time: r.createdAt,
          icon: Icons.add_circle_outline_rounded,
          iconColor: const Color(0xFF1976D2),
          report: r,
        ));
      }
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(8).toList();
  }

  Widget _buildAktivitasTimCard(List<_ActivityItemData> activityList) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Tim',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.bolt_rounded,
                  color: Color(0xFFE6A100), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          if (activityList.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Belum ada riwayat aktivitas tim terbaru.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ] else ...[
            for (int i = 0; i < activityList.length; i++) ...[
              _buildActivityItem(activityList[i]),
              if (i < activityList.length - 1) const Divider(height: 20),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(_ActivityItemData item) {
    return InkWell(
      onTap: item.report != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OperatorReportDetailScreen(
                    report: item.report!,
                    onStatusUpdated: _fetchData,
                  ),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: '${item.name} ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: item.action),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(item.time),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative || diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildThumbnailImage(ReportModel report) {
    return ReportThumbnailImage(
      report: report,
      width: 84,
      height: 64,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
