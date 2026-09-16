import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class AdminAssignReportScreen extends StatefulWidget {
  final ReportModel report;

  const AdminAssignReportScreen({
    super.key,
    required this.report,
  });

  @override
  State<AdminAssignReportScreen> createState() =>
      _AdminAssignReportScreenState();
}

class _AdminAssignReportScreenState extends State<AdminAssignReportScreen> {
  static const Color _redPrimary = Color(0xFFC60D05);
  static const Color _greenPrimary = Color(0xFF1D9C51);
  static const Color _amberPrimary = Color(0xFFF2AE01);

  String _selectedOpd = 'Dinas PUPR (DPUPR)';
  String _selectedPriority = 'Tinggi';
  Map<String, String>? _selectedPetugas = {
    'name': 'Andi Pratama',
    'role': 'Petugas Lapangan DPUPR',
    'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
  };
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _opdList = [
    'Dinas PUPR (DPUPR)',
    'Dinas Perhubungan (Dishub)',
    'Dinas Komunikasi & Informatika (Diskominfo)',
  ];

  final List<Map<String, String>> _petugasList = [
    {
      'name': 'Andi Pratama',
      'role': 'Petugas Lapangan DPUPR',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    },
    {
      'name': 'Cahyo Wibowo',
      'role': 'Teknisi Jalan & Jembatan DPUPR',
      'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
    },
    {
      'name': 'Budi Santoso',
      'role': 'Koordinator Lapangan Dishub',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    },
    {
      'name': 'Eko Prasetyo',
      'role': 'Teknisi Marka & Rambu Dishub',
      'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
    },
    {
      'name': 'Dedi Kurniawan',
      'role': 'Inspektur Jaringan Diskominfo',
      'avatar': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
    },
    {
      'name': 'Fajar Ramadhan',
      'role': 'Teknisi CCTV & Fiber Optik Diskominfo',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatCodeWithHash(String code) {
    if (code.isEmpty) return '#LP-2026-002487';
    if (code.startsWith('#')) return code;
    return '#$code';
  }

  Future<void> _submitAssignment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = context.read<ReportRepository>();
      final noteText = _notesController.text.trim();
      final petugasInfo = _selectedPetugas != null
          ? ' | Petugas: ${_selectedPetugas!['name']}'
          : '';
      final combinedNote = noteText.isNotEmpty
          ? '$noteText (Prioritas: $_selectedPriority$petugasInfo)'
          : 'Penugasan laporan ke $_selectedOpd (Prioritas: $_selectedPriority$petugasInfo)';

      await repo.updateReportStatus(
        widget.report.id,
        'assigned',
        notes: combinedNote,
        assignedAgencyId: _selectedOpd,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Laporan berhasil ditugaskan ke $_selectedOpd',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: _greenPrimary,
        ),
      );

      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menugaskan laporan: $e'),
          backgroundColor: _redPrimary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showOpdPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                  'Pilih OPD Tujuan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _opdList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = _opdList[idx];
                      final isSelected = item == _selectedOpd;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        title: Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? _greenPrimary
                                : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: _greenPrimary)
                            : null,
                        onTap: () {
                          setState(() => _selectedOpd = item);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPetugasPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                  'Pilih Petugas Lapangan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _petugasList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = _petugasList[idx];
                      final isSelected =
                          _selectedPetugas?['name'] == item['name'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE8F5E9),
                          backgroundImage: NetworkImage(item['avatar']!),
                          onBackgroundImageError: (exception, stackTrace) {},
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        title: Text(
                          item['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? _greenPrimary
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          item['role']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: _greenPrimary)
                            : null,
                        onTap: () {
                          setState(() => _selectedPetugas = item);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
                if (_selectedPetugas != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _selectedPetugas = null);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Hapus Pilihan Petugas',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _redPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final displayTitle = report.categoryName.isNotEmpty
        ? report.categoryName
        : 'Jalan Rusak';
    final codeWithHash = _formatCodeWithHash(report.reportCode);
    final displayAddress = (report.addressText != null &&
            report.addressText!.trim().isNotEmpty)
        ? report.addressText!
        : 'Jl. Ahmad Yani no. 15';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 32,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Tugaskan Laporan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── REPORT HEADER SUMMARY ──────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                codeWithHash,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Sedang Diproses',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _amberPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── OPD TUJUAN ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'OPD Tujuan',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _showOpdPicker,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFE0DFDF),
                            width: 0.85,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF757575),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedOpd,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF515151),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 24,
                              color: Color(0xFF515151),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── PRIORITAS ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Prioritas',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildPriorityChip('Rendah'),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Sedang'),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Tinggi'),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── PETUGAS (OPSIONAL) ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Petugas ',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: '(Opsional)',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF8F8F8F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_selectedPetugas != null) ...[
                      InkWell(
                        onTap: _showPetugasPicker,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFFE0DFDF),
                              width: 0.85,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: Image.network(
                                  _selectedPetugas!['avatar']!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    color: const Color(0xFFE8F5E9),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _selectedPetugas!['name']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF515151),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedPetugas!['role']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFF515151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 24,
                                color: Color(0xFF515151),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Outlined button "Pilih Petugas"
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: _showPetugasPicker,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF1976D2),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pilih Petugas',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── CATATAN (*OPSIONAL) ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0DFDF),
                          width: 1,
                        ),
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
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 10),
                            child: Icon(
                              Icons.assignment_outlined,
                              size: 36,
                              color: Colors.black87,
                            ),
                          ),
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
                                    const SizedBox(width: 4),
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
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE0DFDF),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: TextField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    maxLength: 200,
                                    onChanged: (text) => setState(() {}),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: 'Tambahkan catatan laporan.....',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFF8F8F8F),
                                      ),
                                      counterText:
                                          '${_notesController.text.length}/200',
                                      counterStyle: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFFBBBBBB),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── BOTTOM ACTION BUTTON ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _greenPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(
                        color: Color(0xFFC9E1BF),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Tugaskan Laporan',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label) {
    final isSelected = _selectedPriority == label;

    Color borderColor;
    Color textColor;
    Widget iconWidget;

    if (label == 'Tinggi') {
      if (isSelected) {
        borderColor = _redPrimary;
        textColor = _redPrimary;
        iconWidget = const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: _redPrimary,
        );
      } else {
        borderColor = const Color(0xFFE0DFDF);
        textColor = const Color(0xFF515151);
        iconWidget = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF757575),
              width: 1.5,
            ),
          ),
        );
      }
    } else if (label == 'Sedang') {
      if (isSelected) {
        borderColor = _amberPrimary;
        textColor = _amberPrimary;
        iconWidget = const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: _amberPrimary,
        );
      } else {
        borderColor = const Color(0xFFE0DFDF);
        textColor = const Color(0xFF515151);
        iconWidget = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF757575),
              width: 1.5,
            ),
          ),
        );
      }
    } else {
      // Rendah
      if (isSelected) {
        borderColor = _greenPrimary;
        textColor = _greenPrimary;
        iconWidget = const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: _greenPrimary,
        );
      } else {
        borderColor = const Color(0xFFE0DFDF);
        textColor = const Color(0xFF515151);
        iconWidget = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF757575),
              width: 1.5,
            ),
          ),
        );
      }
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = label),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.0 : 0.85,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
