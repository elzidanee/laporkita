import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../reports/bloc/report_bloc.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const ReportDetailScreen({super.key, this.reportData});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();

  ReportModel? _report;
  bool _isLoading = false;
  bool _isSupported = false;
  int _supportCount = 360;
  bool _isUpdatingStatus = false;

  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final initialModel = widget.reportData?['reportModel'] as ReportModel?;
    if (initialModel != null) {
      _report = initialModel;
      _supportCount = initialModel.supportCount;
    } else {
      _supportCount = widget.reportData?['supports'] as int? ?? 360;
    }

    _fetchLatestReportDetail();
    _fetchComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String? get _resolvedReportId =>
      widget.reportData?['id'] as String? ??
      widget.reportData?['reportId'] as String? ??
      _report?.id ??
      (widget.reportData?['reportModel'] as ReportModel?)?.id;

  Future<void> _fetchLatestReportDetail() async {
    final String? reportId = _resolvedReportId;
    if (reportId == null || reportId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repository = context.read<ReportRepository>();
      final detail = await repository.getReportById(reportId);
      if (mounted) {
        setState(() {
          _report = detail;
          _supportCount = detail.supportCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchComments() async {
    final String? reportId = _resolvedReportId;
    if (reportId == null || reportId.isEmpty) return;

    setState(() => _isLoadingComments = true);

    try {
      final repository = context.read<ReportRepository>();
      final response = await repository.getComments(reportId);
      if (mounted) {
        setState(() {
          _comments = response.data ?? [];
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final String? reportId = _resolvedReportId;
    if (reportId == null || reportId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID laporan tidak valid untuk mengirim komentar.'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    setState(() => _isSendingComment = true);

    try {
      final repository = context.read<ReportRepository>();
      await repository.addComment(reportId, text);
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await _fetchComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil terkirim!'),
            backgroundColor: AppColors.greenPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  String _monthName(int month) {
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
    return months[(month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    final title = report?.categoryName ??
        (widget.reportData?['title'] as String? ?? 'Jalan Rusak');
    final address = report?.addressText ??
        (widget.reportData?['address'] as String? ?? 'Jl. Ahmad Yani no. 15');
    final fullAddress = report?.addressText ??
        (widget.reportData?['fullAddress'] as String? ??
            'Jl. ahmad yani no. 15 sawojajar kota Malang');
    final reportCode = (report?.reportCode.isNotEmpty == true)
        ? report!.reportCode
        : (widget.reportData?['reportCode'] as String? ??
            widget.reportData?['id'] as String? ??
            '#LP-2026-002487');
    final statusText = report?.status.displayName ??
        (widget.reportData?['status'] as String? ?? 'Sedang Diproses');
    final description = report?.description ??
        (widget.reportData?['description'] as String? ??
            'Jalan sudah tidak layak karena  banyak retakan dan lubang disepanjang jalan.');
    final photoUrl = report?.formattedPhotoUrl ??
        report?.photoUrl ??
        (widget.reportData?['photoUrl'] as String? ?? '');

    final createdAt = report?.createdAt ?? DateTime.now();
    final dateStr =
        '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}';
    final timeStr =
        '${createdAt.hour.toString().padLeft(2, '0')}.${createdAt.minute.toString().padLeft(2, '0')} WIB';
    final latLngStr =
        '${report?.latitude ?? -6.382728}, ${report?.longitude ?? 107.734682}';

    final supportCount = report?.supportCount ?? _supportCount;
    final viewCount = report?.viewCount ?? 512;
    final commentCount = _comments.isNotEmpty ? _comments.length : 5;

    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isCommandCenter = user?.role.isCommandCenter == true;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.neutral900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Terdekat',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.neutral900,
              size: 22,
            ),
            onPressed: () {
              final code = report?.reportCode ?? _resolvedReportId ?? '';
              if (code.isNotEmpty) {
                Clipboard.setData(ClipboardData(
                    text: 'LaporKita #$code: ${AppConfig.baseUrl}/reports/$code'));
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan laporan berhasil disalin!'),
                  backgroundColor: AppColors.greenPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading && report == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.greenPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header: Report Code & Status Badge (Figma node 62:597 & 62:605)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reportCode,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.neutral900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF2AE01),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title & Address (Figma node 62:598 & 62:603)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Large Photo Card (Figma node 62:608 & 193:2)
                  _buildReportImageWithOverlay(
                    photoUrl: photoUrl,
                    reportCode: reportCode,
                    address: address,
                    dateStr: dateStr,
                    timeStr: timeStr,
                    title: title,
                    latLngStr: latLngStr,
                  ),
                  const SizedBox(height: 12),

                  // 3. Created At Date & Description (Figma node 62:609 & 65:610)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Dibuat : $dateStr | $timeStr',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF2AE01),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral900,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Deskripsi :\n',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. AI Verification Card (Figma node 95:454)
                  _buildAiVerificationCard(),
                  const SizedBox(height: 14),

                  // 5. Confidence Card (Figma node 95:500)
                  _buildConfidenceCard(),
                  const SizedBox(height: 20),

                  // 6. 3 Stat Cards Row (Dukungan 360, Dilihat 512, Komentar 5) (Figma node 65:618)
                  _buildStatCardsRow(supportCount, viewCount, commentCount),
                  const SizedBox(height: 20),

                  // Command Center Verification Action Panel (Admin & Operator B2G)
                  if (isCommandCenter && report != null && user != null) ...[
                    _buildCommandCenterActionPanel(report, user),
                    const SizedBox(height: 16),
                  ],

                  // 7. Action Buttons Row (Dukung + Chat) (Figma node 65:649)
                  _buildActionButtonsRow(supportCount),
                  const SizedBox(height: 24),

                  // 8. 3 Tab Bar Header (Timeline, Detail, Komentar) (Figma node 65:650)
                  Container(
                    height: 44,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.statusInfo,
                      indicatorWeight: 3,
                      labelColor: AppColors.statusInfo,
                      unselectedLabelColor: AppColors.neutral400,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: const [
                        Tab(text: 'Timeline'),
                        Tab(text: 'Detail'),
                        Tab(text: 'Komentar'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 9. Tab Content
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0) {
                        return _buildTimelineTab(
                          report: report,
                          dateStr: dateStr,
                          timeStr: timeStr,
                          photoUrl: photoUrl,
                        );
                      } else if (_tabController.index == 1) {
                        return _buildDetailTab(
                          fullAddress: fullAddress,
                          reportCode: reportCode,
                          report: report,
                          description: description,
                          dateStr: dateStr,
                        );
                      } else {
                        return _buildKomentarTab();
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // ── Photo Card with Camera Metadata Overlay (Figma node 193:2) ─────────────
  Widget _buildReportImageWithOverlay({
    required String photoUrl,
    required String reportCode,
    required String address,
    required String dateStr,
    required String timeStr,
    required String title,
    required String latLngStr,
  }) {
    final String? localPath = widget.reportData?['imagePath'] as String? ??
        widget.reportData?['photoPath'] as String? ??
        _report?.directPhotoUrl;

    bool isLocalValid = false;
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http')) {
      try {
        isLocalValid = File(localPath).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    Widget buildLocalPlaceholder() {
      return Container(
        color: AppColors.neutral100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 44,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildNetworkFallback() {
      return Image.network(
        ReportModel.getCategoryFallbackImage(title),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildLocalPlaceholder(),
      );
    }

    Widget imgWidget;
    if (isLocalValid && localPath != null) {
      imgWidget = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildNetworkFallback(),
      );
    } else if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
      imgWidget = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildNetworkFallback(),
      );
    } else {
      imgWidget = buildNetworkFallback();
    }

    return Container(
      height: 204,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBEC4BD)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(child: imgWidget),
            // Stamp Box (Figma Node 193:3)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenPrimary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8.7),
                        border: Border.all(
                            color: const Color(0xFF62D26D), width: 0.35),
                      ),
                      child: const Text(
                        'LaporKita',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reportCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStampRow(Icons.location_on_outlined, address),
                    const SizedBox(height: 2),
                    _buildStampRow(
                        Icons.access_time_outlined, '$dateStr | $timeStr'),
                    const SizedBox(height: 2),
                    _buildStampRow(Icons.warning_amber_rounded, title),
                    const SizedBox(height: 2),
                    _buildStampRow(Icons.memory_rounded, latLngStr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.white),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // ── AI Verification Card (Figma node 95:454) ──────────────────────────────
  Widget _buildAiVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Verification',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckRow('Foto Valid'),
          const SizedBox(height: 8),
          _buildCheckRow('GPS Valid'),
          const SizedBox(height: 8),
          _buildCheckRow('Timestamp Valid'),
          const SizedBox(height: 8),
          _buildCheckRow('Metadata lengkap'),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.greenPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 16, color: AppColors.white),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  // ── Confidence Card (Figma node 95:500) ───────────────────────────────────
  Widget _buildConfidenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Confidence',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                '98%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.98,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.greenPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3 Stat Cards Row (Figma node 65:618) ──────────────────────────────────
  Widget _buildStatCardsRow(int supports, int views, int comments) {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Dukungan', '$supports')),
        const SizedBox(width: 11),
        Expanded(child: _buildStatItem('Dilihat', '$views')),
        const SizedBox(width: 11),
        Expanded(child: _buildStatItem('komentar', '$comments')),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      height: 79,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons Row (Figma node 65:649 & 230:559) ─────────────────────
  Widget _buildActionButtonsRow(int currentSupports) {
    final reportId = _resolvedReportId;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            // Jika sudah mendukung, disable tombol (tidak bisa toggle balik)
            onPressed: _isSupported
                ? null
                : () async {
                    setState(() {
                      _isSupported = true;
                      _supportCount += 1;
                    });

                    if (reportId != null && reportId.isNotEmpty) {
                      try {
                        final repo = context.read<ReportRepository>();
                        await repo.supportReport(reportId);
                        if (mounted) {
                          context.read<ReportBloc>().add(
                                ReportSupportRequested(reportId),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dukungan berhasil dikirim!'),
                              backgroundColor: AppColors.greenPrimary,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isSupported = false;
                            _supportCount -= 1;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal mengirim dukungan: $e'),
                              backgroundColor: AppColors.statusDanger,
                            ),
                          );
                        }
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              // Abu-abu jika sudah didukung, hijau jika belum
              backgroundColor: _isSupported
                  ? AppColors.neutral300
                  : AppColors.greenPrimary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.neutral300,
              disabledForegroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _isSupported
                      ? AppColors.neutral300
                      : const Color(0xFFBCFFC2),
                ),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSupported ? 'Didukung ' : 'Dukung ',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isSupported
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_off_alt_rounded,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {
            _tabController.animateTo(2); // Pindah ke tab Komentar
          },
          child: Container(
            width: 63,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFBCFFC2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCFFDF)),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.greenPrimary,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COMMAND CENTER ACTION PANEL (Admin & Operator B2G Control)
  // ===========================================================================
  Widget _buildCommandCenterActionPanel(ReportModel report, UserModel user) {
    final status = report.status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel Kontrol ${user.role == UserRole.admin ? "Super Admin" : "Operator Dinas"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Kelola status verifikasi langsung ke database backend',
                      style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.neutral200),
          const SizedBox(height: 14),

          if (status == ReportStatus.pendingVerification) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingStatus
                        ? null
                        : () => _handleUpdateStatus(
                              reportId: report.id,
                              newStatus: ReportStatus.verified,
                              note: 'Laporan diverifikasi oleh ${user.fullName}',
                            ),
                    icon: _isUpdatingStatus
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_rounded, size: 18),
                    label: const Text(
                      'Verifikasi Laporan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _isUpdatingStatus
                      ? null
                      : () => _showRejectReasonDialog(report, user),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Tolak', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusDanger,
                    side: const BorderSide(color: AppColors.statusDanger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
              ],
            ),
          ] else if (status == ReportStatus.verified) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _handleUpdateStatus(
                          reportId: report.id,
                          newStatus: ReportStatus.assigned,
                          note: 'Ditugaskan ke tim dinas oleh ${user.fullName}',
                        ),
                icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                label: const Text(
                  'Tugaskan ke Dinas Lapangan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else if (status == ReportStatus.assigned) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _handleUpdateStatus(
                          reportId: report.id,
                          newStatus: ReportStatus.inProgress,
                          note: 'Penanganan dimulai oleh tim teknis',
                        ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text(
                  'Mulai Pengerjaan Perbaikan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else if (status == ReportStatus.inProgress) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _handlePromptCompletion(report, user),
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text(
                  'Selesaikan Perbaikan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.greenPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Status saat ini: ${status.displayName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleUpdateStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? note,
  }) async {
    setState(() => _isUpdatingStatus = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ReportRepository>();
    final reportBloc = context.read<ReportBloc>();

    try {
      final updated = await repo.updateReportStatus(
        reportId,
        newStatus.apiValue,
        notes: note,
        existingReport: _report,
      );

      if (!mounted) return;
      setState(() {
        _report = updated;
        _isUpdatingStatus = false;
      });

      reportBloc.add(ReportUpdateStatusRequested(
        reportId: reportId,
        newStatus: newStatus.apiValue,
        notes: note,
      ));

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Status laporan berhasil diubah menjadi "${newStatus.displayName}" dan disimpan ke backend database!',
          ),
          backgroundColor: AppColors.greenPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    }
  }

  void _showRejectReasonDialog(ReportModel report, UserModel user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alasan penolakan laporan untuk dicatat di database backend:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Misal: Foto tidak jelas, lokasi bukan fasilitas umum...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              _handleUpdateStatus(
                reportId: report.id,
                newStatus: ReportStatus.rejected,
                note: reason.isNotEmpty
                    ? reason
                    : 'Ditolak oleh petugas (${user.fullName})',
              );
            },
            child: const Text('Tolak Laporan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePromptCompletion(ReportModel report, UserModel user) async {
    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    } catch (_) {
      image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    }

    if (image != null) {
      try {
        final repo = context.read<ReportRepository>();
        await repo.uploadReportMedia(
          reportId: report.id,
          filePath: image.path,
          type: 'completion_photo',
        );
      } catch (_) {}
    }

    await _handleUpdateStatus(
      reportId: report.id,
      newStatus: ReportStatus.completed,
      note: 'Perbaikan diselesaikan oleh ${user.fullName}',
    );
  }

  // ===========================================================================
  // ===========================================================================
  // TAB 1 CONTENT: TIMELINE TAB (Exact Figma node 62:576 & 230:559)
  // ===========================================================================
  Widget _buildTimelineTab({
    ReportModel? report,
    required String dateStr,
    required String timeStr,
    required String photoUrl,
  }) {
    final status = report?.status ?? ReportStatus.pendingVerification;

    final isCreated = true; // selalu ada
    final isVerified = status != ReportStatus.pendingVerification &&
        status != ReportStatus.rejected;
    final isAssigned = status == ReportStatus.assigned ||
        status == ReportStatus.inProgress ||
        status == ReportStatus.completed ||
        status == ReportStatus.resolved;
    final isInProgress = status == ReportStatus.inProgress ||
        status == ReportStatus.completed ||
        status == ReportStatus.resolved;
    final isCompleted =
        status == ReportStatus.completed || status == ReportStatus.resolved;

    final agencyName =
        report?.assignedAgency?['name'] as String? ?? 'Dinas PUPR Malang';

    // Ambil foto progres dari media backend (type: progress_photo)
    final progressPhotos = report?.media
            .where((m) => m.type == 'progress_photo')
            .toList() ??
        [];
    final latestProgressPhoto =
        progressPhotos.isNotEmpty ? progressPhotos.last : null;

    String progressPhotoDateStr = dateStr;
    String progressPhotoTimeStr = timeStr;
    if (latestProgressPhoto != null) {
      final d = latestProgressPhoto.createdAt;
      progressPhotoDateStr =
          '${d.day} ${_monthName(d.month)} ${d.year}';
      progressPhotoTimeStr =
          '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')} WIB';
    }

    String? progressPhotoUrl;
    if (latestProgressPhoto != null) {
      final raw = latestProgressPhoto.url;
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        progressPhotoUrl = raw;
      } else {
        progressPhotoUrl = report?.formattedPhotoUrl ?? raw;
      }
    }

    // Ambil foto validasi / penyelesaian (type: validation_photo atau completion_photo)
    final validationPhotos = report?.media
            .where((m) =>
                m.type == 'validation_photo' ||
                m.type == 'completion_photo')
            .toList() ??
        [];
    final latestValidationPhoto =
        validationPhotos.isNotEmpty ? validationPhotos.last : null;

    String validationPhotoDateStr = dateStr;
    String validationPhotoTimeStr = timeStr;
    if (latestValidationPhoto != null) {
      final d = latestValidationPhoto.createdAt;
      validationPhotoDateStr =
          '${d.day} ${_monthName(d.month)} ${d.year}';
      validationPhotoTimeStr =
          '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')} WIB';
    }

    String? validationPhotoUrl;
    if (latestValidationPhoto != null) {
      final raw = latestValidationPhoto.url;
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        validationPhotoUrl = raw;
      } else {
        validationPhotoUrl = report?.formattedPhotoUrl ?? raw;
      }
    }

    // Kumpulkan item timeline yang sudah terjadi
    final timelineItems = <Widget>[];

    // 1. Laporan dibuat — selalu tampil (Figma node 230:597)
    timelineItems.add(_buildTimelineItem(
      title: 'Laporan dibuat',
      time: '$dateStr | $timeStr',
      desc: 'Laporan berhasil dibuat oleh masyarakat',
      isDone: isCreated,
      icon: Icons.check,
      iconBgColor: AppColors.greenPrimary,
      isLast: !isVerified && !isAssigned && !isInProgress && !isCompleted,
    ));

    // 2. Diverifikasi Admin — hanya jika sudah verified (Figma node 230:631)
    if (isVerified) {
      final verifiedAt = report?.statusHistory
          .where((h) => h.targetStatus == ReportStatus.verified)
          .toList();
      final verifiedTime = verifiedAt?.isNotEmpty == true
          ? () {
              final d = verifiedAt!.first.createdAt;
              return '${d.day} ${_monthName(d.month)} ${d.year} | ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
            }()
          : dateStr;
      timelineItems.add(_buildTimelineItem(
        title: 'Diverifikasi Admin',
        time: verifiedTime,
        desc: 'Laporan telah diverifikasi dan sesuai ketentuan.',
        isDone: true,
        icon: Icons.check,
        iconBgColor: AppColors.greenPrimary,
        isLast: !isAssigned && !isInProgress && !isCompleted,
      ));
    }

    // 3. Diteruskan ke Dinas — hanya jika sudah assigned (Figma node 230:647)
    if (isAssigned) {
      final assignedAt = report?.statusHistory
          .where((h) => h.targetStatus == ReportStatus.assigned)
          .toList();
      final assignedTime = assignedAt?.isNotEmpty == true
          ? () {
              final d = assignedAt!.first.createdAt;
              return '${d.day} ${_monthName(d.month)} ${d.year} | ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
            }()
          : dateStr;
      timelineItems.add(_buildTimelineItem(
        title: 'Diteruskan ke $agencyName',
        time: assignedTime,
        desc: 'Laporan diteruskan ke $agencyName.',
        isDone: true,
        icon: Icons.shortcut_rounded,
        iconBgColor: AppColors.statusInfo,
        isLast: !isInProgress && !isCompleted,
      ));
    }

    // 4. Sedang Diproses — hanya jika in_progress atau lebih (Figma node 230:659)
    if (isInProgress) {
      final inProgressAt = report?.statusHistory
          .where((h) => h.targetStatus == ReportStatus.inProgress)
          .toList();
      final inProgressTime = inProgressAt?.isNotEmpty == true
          ? () {
              final d = inProgressAt!.first.createdAt;
              return '${d.day} ${_monthName(d.month)} ${d.year} | ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
            }()
          : dateStr;
      timelineItems.add(_buildTimelineItem(
        title: 'Sedang Diproses',
        time: inProgressTime,
        desc: 'Petugas $agencyName sedang menangani laporan ini.',
        isDone: true,
        icon: Icons.build_rounded,
        iconBgColor: AppColors.statusInfo,
        isLast: !isCompleted,
        customChild: progressPhotoUrl != null
            ? _buildProgressPhotoCard(
                photoUrl: progressPhotoUrl,
                title: 'Foto Progres',
                dateStr: progressPhotoDateStr,
                timeStr: progressPhotoTimeStr,
              )
            : null,
      ));
    }

    // 5. Selesai — jika sudah completed/resolved (Figma node 230:620)
    if (isCompleted) {
      final completedAt = report?.statusHistory
          .where((h) =>
              h.targetStatus == ReportStatus.completed ||
              h.targetStatus == ReportStatus.resolved)
          .toList();
      final completedTime = completedAt?.isNotEmpty == true
          ? () {
              final d = completedAt!.first.createdAt;
              return '${d.day} ${_monthName(d.month)} ${d.year} | ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
            }()
          : dateStr;

      final bool hasValidated = latestValidationPhoto != null ||
          (report?.statusHistory.any(
                  (h) => h.note?.toLowerCase().contains('pelapor') == true) ??
              false);

      timelineItems.add(_buildTimelineItem(
        title: 'Selesai',
        time: completedTime,
        desc: hasValidated
            ? 'Laporan telah tervalidasi dan selesai ditangani.'
            : 'Menunggu konfirmasi validasi pelapor',
        isDone: true,
        icon: Icons.check,
        iconBgColor: AppColors.greenPrimary,
        isLast: true,
        customChild: validationPhotoUrl != null
            ? _buildProgressPhotoCard(
                photoUrl: validationPhotoUrl,
                title: 'Foto Validasi',
                dateStr: validationPhotoDateStr,
                timeStr: validationPhotoTimeStr,
              )
            : null,
      ));

      // Card Validasi Perbaikan di bawah Timeline (Figma node 230:766)
      if (!hasValidated) {
        timelineItems.add(const SizedBox(height: 12));
        timelineItems.add(_buildValidationPromptCard(report));
      }
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: timelineItems,
    );
  }

  // ── Card Validasi Perbaikan (Figma node 230:766) ──────────────────────────
  Widget _buildValidationPromptCard(ReportModel? report) {
    final reportId = _resolvedReportId;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD2FFD6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greenPrimary,
          width: 1.8,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validasi Perbaikan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Apakah perbaikan sudah sesuai dengan kondisi dilapangan?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutral900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/validasi-laporan',
                  arguments: {
                    'id': reportId,
                    'reportId': reportId,
                    'reportCode': report?.reportCode ??
                        widget.reportData?['reportCode'] ??
                        '#LP-2026-002267',
                    'title': report?.categoryName ??
                        widget.reportData?['title'] ??
                        'Kursi Tidak Layak',
                    'address': report?.addressText ??
                        widget.reportData?['address'] ??
                        'Jl. simpang ibrahim',
                    'fullAddress': report?.addressText ??
                        widget.reportData?['fullAddress'] ??
                        'Jl. simpang ibrahim',
                    'date': widget.reportData?['date'] ?? '31 Maret 2026',
                    'supports': report?.supportCount ?? _supportCount,
                    'photoUrl': report?.formattedPhotoUrl ??
                        report?.photoUrl ??
                        widget.reportData?['photoUrl'],
                    'imagePath': widget.reportData?['imagePath'] ??
                        report?.directPhotoUrl,
                    'reportModel': report,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFB9D19E)),
                ),
              ),
              child: const Text(
                'Lakukan Validasi sekarang',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Foto Progres / Foto Validasi Media Card ───────────────────────────────
  Widget _buildProgressPhotoCard({
    required String photoUrl,
    String title = 'Foto Progres',
    required String dateStr,
    required String timeStr,
  }) {
    bool isLocalValid = false;
    if (!photoUrl.startsWith('http')) {
      try {
        isLocalValid = File(photoUrl).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    Widget img;
    if (isLocalValid) {
      img = Image.file(File(photoUrl), fit: BoxFit.cover);
    } else if (photoUrl.startsWith('http')) {
      img = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.neutral50,
          child: const Icon(
            Icons.image_not_supported_rounded,
            color: AppColors.greenPrimary,
          ),
        ),
      );
    } else {
      img = Container(
        color: AppColors.greenLight,
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.greenPrimary,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 104,
              height: 64,
              child: img,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr | $timeStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
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
  }

  // ── Timeline Milestone Item (Overflow-Safe) ──────────────────────────────
  Widget _buildTimelineItem({
    required String title,
    required String time,
    required String desc,
    required bool isDone,
    required IconData icon,
    required Color iconBgColor,
    bool isLast = false,
    Widget? customChild,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: AppColors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.neutral200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? AppColors.neutral900
                                : AppColors.neutral500,
                          ),
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral500,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (customChild != null) customChild,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 CONTENT: DETAIL TAB (Exact Figma node 70:767)
  // ===========================================================================
  Widget _buildDetailTab({
    required String fullAddress,
    required String reportCode,
    required ReportModel? report,
    required String description,
    required String dateStr,
  }) {
    final categoryName = report?.categoryName ?? 'Jalan';
    final agencyName =
        report?.assignedAgency?['name'] as String? ?? 'Dinas PUPR Kota Malang';
    final supportsCount = report?.supportCount ?? _supportCount;
    final viewCount = report?.viewCount ?? 200;

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _buildDetailCard(
          icon: Icons.location_on_outlined,
          label: 'Lokasi',
          value: fullAddress,
        ),
        _buildDetailCard(
          icon: Icons.dashboard_outlined,
          label: 'Kategori',
          value: categoryName,
        ),
        _buildDetailCard(
          icon: Icons.flag_outlined,
          label: 'Prioritas',
          value: 'Tinggi',
          valueColor: AppColors.statusDanger,
        ),
        _buildDetailCard(
          icon: Icons.warning_amber_rounded,
          label: 'Jenis kerusakan',
          value: description,
        ),
        _buildDetailCard(
          icon: Icons.thumb_up_alt_outlined,
          label: 'Dukungan',
          value: '$supportsCount Orang',
        ),
        _buildDetailCard(
          icon: Icons.remove_red_eye_outlined,
          label: 'Dilihat',
          value: '$viewCount Orang',
        ),
        _buildDetailCard(
          icon: Icons.account_balance_outlined,
          label: 'Petugas',
          value: agencyName,
        ),
        _buildDetailCard(
          icon: Icons.calendar_today_outlined,
          label: 'Estimasi Selesai',
          value: '18 Mei 2026',
        ),
        _buildDetailCard(
          icon: Icons.access_alarm_rounded,
          label: 'Dibuat Pada',
          value: dateStr,
        ),
        _buildDetailCard(
          icon: Icons.info_outline_rounded,
          label: 'ID Laporan',
          value: reportCode,
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.neutral900),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: valueColor ?? AppColors.neutral900,
                    fontWeight: valueColor != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.neutral900,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3 CONTENT: KOMENTAR TAB (Exact Figma node 70:1066)
  // ===========================================================================
  Widget _buildKomentarTab() {
    return Column(
      children: [
        if (_isLoadingComments)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(color: AppColors.greenPrimary),
          )
        else if (_comments.isNotEmpty)
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final c = _comments[index];
              final user = c['user'] as Map<String, dynamic>?;
              final name = user?['full_name'] as String? ?? 'Kalandra Garendra';
              final content = c['content'] as String? ??
                  'Semoga cepat diperbaiki, karena sangat membahayakan';
              final time = c['created_at'] as String? ?? '2 jam yang lalu';

              return _buildCommentCard(
                name: name,
                time: time,
                comment: content,
                likes: 12,
              );
            },
          )
        else ...[
          _buildCommentCard(
            name: 'Kalandra Garendra',
            time: '2 jam yang lalu',
            comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
            likes: 12,
          ),
          _buildCommentCard(
            name: 'Kalandra Garendra',
            time: '2 jam yang lalu',
            comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
            likes: 12,
          ),
          _buildCommentCard(
            name: 'Kalandra Garendra',
            time: '2 jam yang lalu',
            comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
            likes: 12,
          ),
        ],
        const SizedBox(height: 12),

        // Input Komentar Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.neutral200),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              _isSendingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.greenPrimary,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.greenPrimary,
                      ),
                      onPressed: _sendComment,
                    ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCommentCard({
    required String name,
    required String time,
    required String comment,
    int likes = 12,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.greenLight,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.greenPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral900,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_rounded,
                      size: 16,
                      color: AppColors.statusInfo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusInfo,
                      ),
                    ),
                    const SizedBox(width: 26),
                    const Text(
                      'Balas',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
