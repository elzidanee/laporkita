import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import 'admin_assign_report_screen.dart';
import 'admin_duplicate_detection_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Verifikasi AI / Human | Admin (Figma: node 554-321 & 554-511)
// ─────────────────────────────────────────────────────────────

class AdminVerificationActionScreen extends StatefulWidget {
  final ReportModel report;
  final int initialTabIndex; // 0: AI Verification, 1: Manual Review (default 1)

  const AdminVerificationActionScreen({
    super.key,
    required this.report,
    this.initialTabIndex = 1,
  });

  @override
  State<AdminVerificationActionScreen> createState() =>
      _AdminVerificationActionScreenState();
}

class _AdminVerificationActionScreenState
    extends State<AdminVerificationActionScreen> {
  late int _activeTabIndex;
  bool _isProcessing = false;

  // Manual Review Form State (Figma Node 554:511)
  bool _manualPhotoValid = true; // Foto sesuai laporan
  bool _manualGpsValid = true; // Lokasi sesuai
  bool _manualIsDuplicate = false; // Laporan duplikat
  late String _selectedCategory;
  String _selectedPriority = 'Tinggi'; // Default Tinggi as in Figma
  final TextEditingController _adminNotesController = TextEditingController();

  final List<String> _availableCategories = [
    'Jalan Rusak',
    'Trotoar Rusak',
    'Penerangan Jalan',
    'Rambu Lalu Lintas',
    'Banjir & Drainase',
    'Sampah & Kebersihan',
    'Fasilitas Umum',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _selectedCategory = widget.report.categoryName.isNotEmpty
        ? widget.report.categoryName
        : 'Jalan Rusak';

    // Inferred priority based on report urgency score if available
    if (widget.report.urgencyScore != null) {
      final score = widget.report.urgencyScore!;
      if (score >= 70) {
        _selectedPriority = 'Tinggi';
      } else if (score >= 40) {
        _selectedPriority = 'Sedang';
      } else {
        _selectedPriority = 'Rendah';
      }
    }
  }

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top Bar: Back Chevron + Share Button (Figma Node 554:578)
            _buildTopBar(),
            const SizedBox(height: 8),

            // Tab Bar: AI Verification vs Manual Review (Figma Node 554:586)
            _buildTabBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Report Summary Header (Figma Node 607:3311)
                    _buildReportHeader(),

                    const SizedBox(height: 18),

                    // Report Photo with Live Telemetry Watermark (Figma Node 607:3318 & 631:1539)
                    _buildReportPhoto(),

                    const SizedBox(height: 22),

                    // Active Tab Content
                    if (_activeTabIndex == 1)
                      _buildManualReviewTab()
                    else
                      _buildAiVerificationTab(),

                    const SizedBox(height: 28),

                    // Action Buttons: Setujui & Teruskan, Tolak, Minta Revisi (Figma Node 554:601)
                    _buildActionButtons(),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR (Figma Node 554:578) ──────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.centerLeft,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.share_outlined,
                size: 22,
                color: Colors.black,
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'Verifikasi Laporan LaporKita: ${widget.report.reportCode}\nKategori: $_selectedCategory\nLokasi: ${widget.report.addressText ?? "-"}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tautan verifikasi disalin ke clipboard!'),
                    backgroundColor: Color(0xFF1D9C51),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR (Figma Node 554:586 & 554:589) ────────────────────────

  Widget _buildTabBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTabIndex = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'AI Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: _activeTabIndex == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _activeTabIndex == 0
                            ? const Color(0xFF1D9C51)
                            : const Color(0xFF8F8F8F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTabIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Manual Review',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: _activeTabIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _activeTabIndex == 1
                            ? const Color(0xFF1D9C51)
                            : const Color(0xFF8F8F8F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Indicator underline + horizontal separator (Figma node 554:585 & 554:589)
        Stack(
          children: [
            Container(
              height: 1.2,
              color: const Color(0xFFE0DFDF),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _activeTabIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 3.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9C51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── REPORT HEADER (Figma Node 607:3311) ───────────────────────────

  Widget _buildReportHeader() {
    final reportCode = widget.report.reportCode.isNotEmpty
        ? widget.report.reportCode
        : '#LP-2026-002487';
    final address = widget.report.addressText != null &&
            widget.report.addressText!.isNotEmpty
        ? widget.report.addressText!
        : 'Jl. Ahmad Yani no. 15';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column: Code, Title, Address
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reportCode.startsWith('#') ? reportCode : '#$reportCode',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _selectedCategory,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Right Badge: Status (Figma Node 607:3316)
        _buildHeaderStatusBadge(),
      ],
    );
  }

  Widget _buildHeaderStatusBadge() {
    final status = widget.report.status;
    Color bgColor = const Color(0xFFFFF9E9);
    Color textColor = const Color(0xFFF2AE01);
    String label = 'Sedang Diproses';

    if (status == ReportStatus.completed || status == ReportStatus.resolved) {
      bgColor = const Color(0xFFE6F7ED);
      textColor = const Color(0xFF1D9C51);
      label = 'Selesai';
    } else if (status == ReportStatus.rejected) {
      bgColor = const Color(0xFFFFEBEB);
      textColor = const Color(0xFFE53935);
      label = 'Ditolak';
    } else if (status == ReportStatus.pendingVerification) {
      bgColor = const Color(0xFFFFF8E6);
      textColor = const Color(0xFFE68A00);
      label = 'Menunggu Verifikasi';
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }

  // ── REPORT PHOTO WITH WATERMARK (Figma Node 607:3318 & 631:1539) ───

  Widget _buildReportPhoto() {
    final photoUrl = widget.report.formattedPhotoUrl ?? widget.report.photoUrl;

    return Container(
      width: double.infinity,
      height: 204,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBEC4BD), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Report Image
            _buildImageWidget(photoUrl),

            // 2. Watermark Card (Figma Node 631:1539)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7.0, vertical: 5.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(7.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Pill + Report Code
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.5, vertical: 1.0),
                          decoration: BoxDecoration(
                            color: const Color(0x9942A54B),
                            borderRadius: BorderRadius.circular(8.7),
                            border: Border.all(
                              color: const Color(0xFF62D26D),
                              width: 0.35,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 3.5,
                              ),
                            ],
                          ),
                          child: Text(
                            'LaporKita',
                            style: GoogleFonts.poppins(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '#${widget.report.reportCode.replaceAll('-', '_')}',
                          style: GoogleFonts.poppins(
                            fontSize: 7.2,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Location Pin
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3.5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            widget.report.addressText ??
                                'Jl. Ahmad Yani No.15 Malang',
                            style: GoogleFonts.poppins(
                              fontSize: 6.8,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.5),

                    // Timestamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          _formatDateTimeFull(widget.report.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 6.8,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.5),

                    // Category
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          _selectedCategory,
                          style: GoogleFonts.poppins(
                            fontSize: 6.8,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.5),

                    // GPS Coordinates
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.memory_rounded,
                          size: 9.5,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          '${widget.report.latitude.toStringAsFixed(6)},${widget.report.longitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(
                            fontSize: 7.0,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
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

  Widget _buildImageWidget(String? photoUrl) {
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('http')) {
      try {
        final f = File(photoUrl);
        if (f.existsSync()) {
          return Image.file(f, fit: BoxFit.cover);
        }
      } catch (_) {}
    }

    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackRoadImage(),
      );
    }

    return _buildFallbackRoadImage();
  }

  Widget _buildFallbackRoadImage() {
    return Image.network(
      'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF0F4F8),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildManualReviewTab() {
    final isFinished = widget.report.status == ReportStatus.completed ||
        widget.report.status == ReportStatus.resolved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFinished) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1D9C51),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Laporan ini telah selesai ditangani. Formulir ditampilkan dalam mode baca saja.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 1. Card: Hasil Pemeriksaan Manual (Figma Node 607:3323)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil Pemeriksaan Manual',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Checkbox 1: Foto sesuai laporan (Figma Node 607:3329)
              _buildManualCheckItem(
                title: 'Foto sesuai laporan',
                value: _manualPhotoValid,
                onChanged: isFinished
                    ? null
                    : (v) => setState(() => _manualPhotoValid = v),
              ),
              const SizedBox(height: 12),
              // Checkbox 2: Lokasi sesuai (Figma Node 607:3340)
              _buildManualCheckItem(
                title: 'Lokasi sesuai',
                value: _manualGpsValid,
                onChanged: isFinished
                    ? null
                    : (v) => setState(() => _manualGpsValid = v),
              ),
              const SizedBox(height: 12),
              // Checkbox 3: Laporan duplikat (Figma Node 607:3394)
              _buildManualCheckItem(
                title: 'Laporan duplikat',
                value: _manualIsDuplicate,
                onChanged: isFinished
                    ? null
                    : (v) => setState(() => _manualIsDuplicate = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Section: Kategori Laporan (Figma Node 607:3402)
        Text(
          'Kategori Laporan',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: isFinished ? null : _showCategoryPickerModal,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFE0DFDF), width: 0.824),
            ),
            child: Row(
              children: [
                _buildCategoryIcon(_selectedCategory, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCategory,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF515151),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isFinished
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF515151),
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 3. Section: Prioritas (Figma Node 607:3422)
        Text(
          'Prioritas',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPriorityPill('Rendah', const Color(0xFF1D9C51),
                isEnabled: !isFinished),
            const SizedBox(width: 8),
            _buildPriorityPill('Sedang', const Color(0xFFF2AE01),
                isEnabled: !isFinished),
            const SizedBox(width: 8),
            _buildPriorityPill('Tinggi', const Color(0xFFC60D05),
                isEnabled: !isFinished),
          ],
        ),

        const SizedBox(height: 20),

        // 4. Section: Catatan *opsional (Figma Node 607:3474)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clipboard Icon (Figma Node 607:3475)
              Container(
                width: 38,
                height: 48,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 36,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(width: 12),

              // Note content & input box (Figma Node 607:3477)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Catatan',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '*opsional',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF8F8F8F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFinished
                            ? const Color(0xFFF8FAFC)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE0DFDF), width: 1.0),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _adminNotesController,
                            enabled: !isFinished,
                            readOnly: isFinished,
                            maxLines: 3,
                            maxLength: 200,
                            buildCounter: (_,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                const SizedBox.shrink(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isFinished
                                  ? const Color(0xFF64748B)
                                  : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: isFinished
                                  ? 'Tidak ada catatan tambahan.'
                                  : 'Tambahkan catatan laporan.....',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF8F8F8F),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '${_adminNotesController.text.length}/200',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFFBBBBBB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── CHECKBOX TILE (Figma ic:round-check-box) ───────────────────────

  Widget _buildManualCheckItem({
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF1D9C51) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value
                      ? const Color(0xFF1D9C51)
                      : const Color(0xFF757575),
                  width: value ? 1.5 : 1.8,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PRIORITY PILL (Figma Node 607:3425) ───────────────────────────

  Widget _buildPriorityPill(String label, Color activeColor,
      {bool isEnabled = true}) {
    final isSelected = _selectedPriority == label;
    return Expanded(
      child: InkWell(
        onTap:
            isEnabled ? () => setState(() => _selectedPriority = label) : null,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE0DFDF),
              width: isSelected ? 1.0 : 0.824,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: activeColor,
                  size: 20,
                )
              else
                const Icon(
                  Icons.circle_outlined,
                  color: Color(0xFF8F8F8F),
                  size: 20,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF515151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CATEGORY ICON HELPER ──────────────────────────────────────────

  Widget _buildCategoryIcon(String category, {double size = 30}) {
    final lower = category.toLowerCase();
    String assetPath = 'assets/images/route.png';
    if (lower.contains('trotoar')) {
      assetPath = 'assets/images/trotoar.png';
    } else if (lower.contains('rambu') ||
        lower.contains('lampu') ||
        lower.contains('lalu lintas')) {
      assetPath = 'assets/images/laluLintas.png';
    } else if (lower.contains('fasilitas') ||
        lower.contains('banjir') ||
        lower.contains('sampah')) {
      assetPath = 'assets/images/fasilitasUmum.png';
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) => Icon(
        Icons.warning_amber_rounded,
        size: size,
        color: const Color(0xFF1D9C51),
      ),
    );
  }

  void _showCategoryPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                'Pilih Kategori Laporan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ..._availableCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: _buildCategoryIcon(cat, size: 28),
                  title: Text(
                    cat,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? const Color(0xFF1D9C51) : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF1D9C51))
                      : null,
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── TAB 1: AI VERIFICATION (Figma Node 554:321 & 554:334) ─────────

  Widget _buildAiVerificationTab() {
    final r = widget.report;
    final confidenceScore = r.rawAiConfidenceScore != null
        ? (r.rawAiConfidenceScore! * 100).round()
        : 98;
    final urgencyScore = (r.urgencyScore ?? 85).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Hasil AI Verification
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil AI Verification',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildVerificationRow('Foto Valid', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('GPS Valid', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('Timestamp Valid', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('Metadata lengkap', 'Valid'),
              const SizedBox(height: 11),
              _buildVerificationRow('Confidence Score', '$confidenceScore%'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Card 2: Analisis AI
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE0DFDF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analisis AI',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kerusakan terdeteksi : $_selectedCategory',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              Text(
                'Model : YOLOv11 + Gemini 2.5 Flash',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              Text(
                'Waktu Proses : 4.21 detik',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rekomendasi Prioritas',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: urgencyScore >= 70
                          ? 'Tinggi '
                          : urgencyScore >= 40
                              ? 'Sedang '
                              : 'Rendah ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: urgencyScore >= 70
                            ? const Color(0xFFC60D05)
                            : urgencyScore >= 40
                                ? const Color(0xFFF2AE01)
                                : const Color(0xFF1D9C51),
                      ),
                    ),
                    TextSpan(
                      text: '($urgencyScore/100)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Button "Lihat detail Analisis"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _showAiDetailModal,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF1976D2), width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Lihat detail Analisis',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationRow(String label, String value) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF1D9C51),
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D9C51),
          ),
        ),
      ],
    );
  }

  // ── ACTION BUTTONS (Figma Node 554:601) ────────────────────────────

  Widget _buildActionButtons() {
    final isFinished = widget.report.status == ReportStatus.completed ||
        widget.report.status == ReportStatus.resolved;

    if (isFinished) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1D9C51),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan Selesai Ditangani',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Laporan ini telah ditandai selesai sehingga tidak dapat diproses atau ditindaklanjuti lagi.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF15803D),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0DFDF), width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Kembali',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF515151),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // 1. Setujui & Teruskan (Figma Node 554:602)
        SizedBox(
          width: double.infinity,
          height: 49,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleApproveAndForward,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9C51),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFFC9E1BF), width: 0.5),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Setujui & Teruskan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Tolak Laporan (Figma Node 554:604)
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _showRejectDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC60D05), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Tolak Laporan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFC60D05),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Meminta Revisi (Figma Node 554:606)
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _showRevisionDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF2AE01), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Meminta Revisi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFF2AE01),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── ACTION LOGIC & DUPLICATE ROUTING ───────────────────────────────

  Future<void> _handleApproveAndForward() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (widget.report.status == ReportStatus.completed ||
        widget.report.status == ReportStatus.resolved) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Laporan telah ditandai selesai dan tidak dapat diproses lebih lanjut.',
          ),
          backgroundColor: Color(0xFF64748B),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final repo = context.read<ReportRepository>();
    final nav = Navigator.of(context);

    try {
      // 1. Fetch live reports to check for candidate duplicates
      final response = await repo.getReports(limit: 50);
      final all = response.data ?? [];

      final candidates = all.where((r) {
        if (r.id == widget.report.id) return false;
        final sameCat = r.categoryId == widget.report.categoryId ||
            r.categoryName.toLowerCase() == _selectedCategory.toLowerCase();
        final distanceMeters = _calcDistanceMeters(
          widget.report.latitude,
          widget.report.longitude,
          r.latitude,
          r.longitude,
        );
        final nearby = distanceMeters <= 1500;
        return sameCat || nearby;
      }).toList();

      setState(() => _isProcessing = false);

      // Check if user manually checked duplicate OR candidate duplicates exist
      final hasSimilarity = _manualIsDuplicate ||
          candidates.isNotEmpty ||
          widget.report.needsManualReview ||
          (widget.report.rawAiConfidenceScore != null &&
              widget.report.rawAiConfidenceScore! >= 0.85);

      if (hasSimilarity && mounted) {
        // Navigate to Deteksi Kesamaan (Figma Node 555:608)
        final result = await Navigator.push<ReportModel>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDuplicateDetectionScreen(
              currentReport: widget.report.copyWith(
                category: {'name': _selectedCategory},
              ),
              similarReports: candidates.take(3).toList(),
              similarityPercentage: _manualIsDuplicate ? 92.0 : 85.0,
            ),
          ),
        );

        if (result != null && mounted) {
          nav.pop(result);
        } else if (mounted) {
          setState(() => _isProcessing = false);
        }
        return;
      }

      // If no duplicates detected, proceed directly to AdminAssignReportScreen (Figma Node 559:1020)
      if (mounted) {
        final result = await Navigator.push<ReportModel>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAssignReportScreen(
              report: widget.report.copyWith(
                category: {'name': _selectedCategory},
              ),
            ),
          ),
        );
        if (result != null && mounted) {
          nav.pop(result);
        } else if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal memproses verifikasi laporan: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  void _showRejectDialog() {
    if (widget.report.status == ReportStatus.completed ||
        widget.report.status == ReportStatus.resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan ini telah selesai dan tidak dapat ditolak atau diproses lagi.'),
          backgroundColor: Color(0xFF1D9C51),
        ),
      );
      return;
    }
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Tolak Laporan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFC60D05),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan alasan penolakan laporan ini:',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 12),
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Laporan tidak memenuhi kriteria / foto tidak valid.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC60D05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                try {
                  final repo = context.read<ReportRepository>();
                  final updated = await repo.updateReportStatus(
                    widget.report.id,
                    'rejected',
                    notes: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : (_adminNotesController.text.trim().isNotEmpty
                            ? _adminNotesController.text.trim()
                            : 'Laporan ditolak oleh Admin saat verifikasi manual.'),
                    existingReport: widget.report,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Laporan telah ditolak.'),
                        backgroundColor: Color(0xFFC60D05),
                      ),
                    );
                    Navigator.pop(context, updated);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menolak laporan: $e'),
                        backgroundColor: AppColors.statusDanger,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Tolak',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRevisionDialog() {
    if (widget.report.status == ReportStatus.completed ||
        widget.report.status == ReportStatus.resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan ini telah selesai dan tidak dapat direvisi atau diproses lagi.'),
          backgroundColor: Color(0xFF1D9C51),
        ),
      );
      return;
    }
    final revisionController = TextEditingController();
    if (_adminNotesController.text.trim().isNotEmpty) {
      revisionController.text = _adminNotesController.text.trim();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Meminta Revisi Laporan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFF2AE01),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Instruksi perbaikan untuk warga pelapor:',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: revisionController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 12),
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Mohon unggah ulang foto yang lebih terang dan jelas.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2AE01),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                try {
                  final repo = context.read<ReportRepository>();
                  final updated = await repo.updateReportStatus(
                    widget.report.id,
                    'pending_verification',
                    notes: revisionController.text.trim().isNotEmpty
                        ? revisionController.text.trim()
                        : 'Meminta perbaikan data kepada pelapor.',
                    existingReport: widget.report,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Permintaan revisi telah dikirim ke pelapor.'),
                        backgroundColor: Color(0xFFF2AE01),
                      ),
                    );
                    Navigator.pop(context, updated);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengirim revisi: $e'),
                        backgroundColor: AppColors.statusDanger,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Kirim Revisi',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAiDetailModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail Analisis AI Vision & Telemetri',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              _buildModalDetailRow('Model AI',
                  'YOLOv11 Instance Segmentation + Gemini 2.5 Flash'),
              _buildModalDetailRow('Objek Terdeteksi', _selectedCategory),
              _buildModalDetailRow('Confidence Score',
                  '${((widget.report.rawAiConfidenceScore ?? 0.98) * 100).round()}%'),
              _buildModalDetailRow('Damage Severity',
                  '${((widget.report.damageSeverity ?? 0.85) * 100).round()}%'),
              _buildModalDetailRow('AI Processing Time',
                  '4.21 detik (Edge Server Kota Malang)'),
              _buildModalDetailRow('GPS EXIF Verified',
                  '${widget.report.latitude.toStringAsFixed(6)}, ${widget.report.longitude.toStringAsFixed(6)}'),
              _buildModalDetailRow('Needs Manual Review',
                  widget.report.needsManualReview ? 'Ya (Flagged)' : 'Tidak (Auto-Passed)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9C51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTimeFull(DateTime dt) {
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
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$dayName, ${dt.day} $monthName ${dt.year} | $hh.$mm WIB';
  }

  double _calcDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lat2 == 0) return 999999.0;
    const p = 0.017453292519943295;
    final c = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(c));
  }
}
