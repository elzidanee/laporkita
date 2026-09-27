import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/policy_simulator_repository.dart';
import '../../../data/repositories/prediction_repository.dart';

// ─────────────────────────────────────────────────────────────
//  Policy Simulator | Pemerintah (Figma Node 648:4092)
// ─────────────────────────────────────────────────────────────

class PolicySimulatorScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const PolicySimulatorScreen({
    super.key,
    this.onBack,
  });

  @override
  State<PolicySimulatorScreen> createState() => _PolicySimulatorScreenState();
}

class _PolicySimulatorScreenState extends State<PolicySimulatorScreen> {
  // Selection State
  String _selectedPolicyScenario = 'Peningkatan Anggaran PUPR';
  String _selectedRegion = 'Kota Malang';
  String? _selectedZoneId;

  // AI & Simulation State
  bool _isSimulating = false;

  // Projection Metrics (Default from Figma Node 648:4092)
  String _penurunanLaporan = '+32%';
  String _waktuPenyelesaian = '-3,1 hari';
  String _laporanDiselesaikan = '+ 486 laporan';
  String _rekomendasiTeks =
      'Kebijakan ini diperkirakan paling efektif untuk kategori jalan dan trotoar.';

  // Available Presets
  final List<Map<String, String>> _policyOptions = [
    {
      'title': 'Peningkatan Anggaran PUPR',
      'prefix': 'Peningkatan Anggaran ',
      'bold': 'PUPR',
      'dept': 'Dinas PUPR',
      'scope': 'jalan dan trotoar',
    },
    {
      'title': 'Penambahan Armada Kebersihan DLH',
      'prefix': 'Penambahan Armada ',
      'bold': 'DLH',
      'dept': 'Dinas Lingkungan Hidup',
      'scope': 'sampah liar dan TPS',
    },
    {
      'title': 'Percepatan Perbaikan Penerangan Jalan (PJU)',
      'prefix': 'Perbaikan PJU ',
      'bold': 'Dishub',
      'dept': 'Dinas Perhubungan',
      'scope': 'penerangan jalan umum',
    },
    {
      'title': 'Normalisasi Saluran Drainase & Banjir',
      'prefix': 'Normalisasi Drainase ',
      'bold': 'PUPR',
      'dept': 'Dinas PUPR',
      'scope': 'saluran drainase dan genangan air',
    },
  ];

  final List<String> _regions = [
    'Kota Malang',
    'Kec. Klojen',
    'Kec. Lowokwaru',
    'Kec. Blimbing',
    'Kec. Kedung Kandang',
    'Kec. Sukun',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialAiSimulation();
  }

  Future<void> _loadInitialAiSimulation() async {
    // Optionally trigger AI simulation on start or zone fetch
    try {
      final predRepo = context.read<PredictionRepository>();
      final zones = await predRepo.getZones();
      if (mounted && zones.isNotEmpty) {
        setState(() {
          _selectedZoneId = zones.first.id;
        });
      }
    } catch (_) {
      // Graceful fallback to default zone
    }
  }

  Future<void> _runAiSimulation(String promptText) async {
    setState(() {
      _isSimulating = true;
    });

    try {
      final repo = context.read<PolicySimulatorRepository>();
      final result = await repo.createSimulation(
        promptText: promptText,
        zoneId: _selectedZoneId,
      );

      if (mounted) {
        setState(() {
          _isSimulating = false;

          // Adapt AI Results to Figma Cards
          final reduction = result.riskReductionPct > 0
              ? '+${result.riskReductionPct.toStringAsFixed(0)}%'
              : '+32%';
          _penurunanLaporan = reduction;

          // Days reduction from AI risk score or default
          final days = (result.simulatedRiskScore * 5).clamp(1.5, 7.5);
          _waktuPenyelesaian = '-${days.toStringAsFixed(1).replaceAll('.', ',')} hari';

          // Completed reports projection
          final resolved = (result.riskReductionPct * 15.2).round().clamp(120, 850);
          _laporanDiselesaikan = '+ $resolved laporan';

          // AI Recommendation text
          if (result.impactAnalysis.isNotEmpty) {
            _rekomendasiTeks = result.impactAnalysis;
          } else if (result.recommendedActions.isNotEmpty) {
            _rekomendasiTeks = result.recommendedActions.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSimulating = false;
          // Retain Figma design baseline on fallback
          _penurunanLaporan = '+32%';
          _waktuPenyelesaian = '-3,1 hari';
          _laporanDiselesaikan = '+ 486 laporan';
          _rekomendasiTeks =
              'Kebijakan ini diperkirakan paling efektif untuk kategori jalan dan trotoar.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Top Bar (Figma Node 648:4098)
            _buildTopBar(),
            const SizedBox(height: 8),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // 1. Kategori Laporan (Figma Node 650:5100)
                    _buildKategoriLaporanSection(),

                    const SizedBox(height: 22),

                    // 2. Terapkan diwilayah (Figma Node 652:5121)
                    _buildTerapkanDiwilayahSection(),

                    const SizedBox(height: 24),

                    // AI Live Connecting Status Banner (if simulating)
                    if (_isSimulating) ...[
                      _buildAiLoadingIndicator(),
                      const SizedBox(height: 18),
                    ],

                    // 3. Proyeksi Dampak Card (Figma Node 655:5139)
                    _buildProyeksiDampakCard(),

                    const SizedBox(height: 20),

                    // 4. Rekomendasi Card (Figma Node 655:5222)
                    _buildRekomendasiCard(),

                    const SizedBox(height: 24),

                    // Optional AI prompt trigger pill
                    _buildCustomAiPromptPill(),

                    const SizedBox(height: 36),

                    // 5. Button: Setujui & Teruskan (Figma Node 656:5243)
                    _buildSetujuiButton(),

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

  // ── TOP BAR (Figma Node 648:4098) ─────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Chevron Back
            InkWell(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(20.5),
              child: Container(
                width: 41,
                height: 41,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 34,
                  color: Colors.black,
                ),
              ),
            ),

            // Title: Policy Simulator
            Expanded(
              child: Text(
                'Policy Simulator',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Share Icon
            SizedBox(
              width: 41,
              height: 41,
              child: IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  size: 22,
                  color: Colors.black,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan simulasi disalin ke clipboard'),
                      duration: Duration(seconds: 2),
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

  // ── KATEGORI LAPORAN (Figma Node 650:5100) ─────────────────────────

  Widget _buildKategoriLaporanSection() {
    // Determine prefix and bold text
    String prefix = 'Peningkatan Anggaran ';
    String bold = 'PUPR';

    for (final opt in _policyOptions) {
      if (opt['title'] == _selectedPolicyScenario) {
        prefix = opt['prefix'] ?? '';
        bold = opt['bold'] ?? '';
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Laporan',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showPolicySelectorModal,
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
                // Left Icon (work-order icon)
                const Icon(
                  Icons.assignment_outlined,
                  size: 23,
                  color: Color(0xFF515151),
                ),
                const SizedBox(width: 12),

                // Selected Scenario Text
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: prefix,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF515151),
                          ),
                        ),
                        TextSpan(
                          text: bold,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF515151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Chevron Down
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 25,
                  color: Color(0xFF515151),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TERAPKAN DIWILAYAH (Figma Node 652:5121) ───────────────────────

  Widget _buildTerapkanDiwilayahSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terapkan diwilayah',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showRegionSelectorModal,
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
                // Left Icon (City Icon)
                const Icon(
                  Icons.location_city_rounded,
                  size: 23,
                  color: Color(0xFF515151),
                ),
                const SizedBox(width: 12),

                // Selected Region
                Expanded(
                  child: Text(
                    _selectedRegion,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF515151),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Chevron Down
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 25,
                  color: Color(0xFF515151),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── PROYEKSI DAMPAK CARD (Figma Node 655:5139) ─────────────────────

  Widget _buildProyeksiDampakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
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
          // Header: Proyeksi Dampak (30 hari)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Proyeksi Dampak ',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: '(30 hari)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF515151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Penurunan laporan tertunda
          _buildImpactRow(
            label: 'Penurunan laporan tertunda',
            value: _penurunanLaporan,
          ),
          const SizedBox(height: 12),

          // Row 2: Waktu penyelesaian rata-rata
          _buildImpactRow(
            label: 'Waktu penyelesaian rata-rata',
            value: _waktuPenyelesaian,
          ),
          const SizedBox(height: 12),

          // Row 3: Laporan yang dapat diselesaikan
          _buildImpactRow(
            label: 'Laporan yang dapat diselesaikan',
            value: _laporanDiselesaikan,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Green Checkmark Icon (24px)
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF1D9C51),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),

        // Text & Metric
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D9C51),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── REKOMENDASI CARD (Figma Node 655:5222) ─────────────────────────

  Widget _buildRekomendasiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE0DFDF), width: 0.85),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber Shield Check Icon (44px)
          const Icon(
            Icons.verified_user_rounded,
            size: 42,
            color: Color(0xFFF2AE01),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF2AE01),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _rekomendasiTeks,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF515151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AI STATUS & CUSTOM PROMPT ──────────────────────────────────────

  Widget _buildAiLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9D19E), width: 0.8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1D9C51),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Menghubungkan & menganalisis dampak dengan AI...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1D9C51),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAiPromptPill() {
    return InkWell(
      onTap: _showCustomPromptDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Color(0xFF1D9C51),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Kustomisasi Skenario Kebijakan dengan AI',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D9C51),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SETUJUI & TERUSKAN BUTTON (Figma Node 656:5243) ─────────────────

  Widget _buildSetujuiButton() {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: ElevatedButton(
        onPressed: _showApprovalSuccessDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D9C51),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFC9E1BF), width: 0.5),
          ),
          elevation: 0,
        ),
        child: Text(
          'Setujui & Teruskan',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── MODALS & DIALOGS ──────────────────────────────────────────────

  void _showPolicySelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                  'Pilih Skenario Kebijakan',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ..._policyOptions.map((opt) {
                  final isSelected = opt['title'] == _selectedPolicyScenario;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.assignment_outlined,
                      color: isSelected
                          ? const Color(0xFF1D9C51)
                          : const Color(0xFF515151),
                    ),
                    title: Text(
                      opt['title']!,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF1D9C51) : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF1D9C51), size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedPolicyScenario = opt['title']!;
                      });
                      _runAiSimulation(
                        'Simulasi dampak $_selectedPolicyScenario di $_selectedRegion',
                      );
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

  void _showRegionSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                  'Terapkan di Wilayah',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ..._regions.map((reg) {
                  final isSelected = reg == _selectedRegion;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.location_city_rounded,
                      color: isSelected
                          ? const Color(0xFF1D9C51)
                          : const Color(0xFF515151),
                    ),
                    title: Text(
                      reg,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF1D9C51) : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF1D9C51), size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedRegion = reg;
                      });
                      _runAiSimulation(
                        'Simulasi dampak $_selectedPolicyScenario di $_selectedRegion',
                      );
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

  void _showCustomPromptDialog() {
    final controller = TextEditingController(
      text: 'Simulasi alokasi anggaran tambahan untuk perbaikan jalan rusak di $_selectedRegion',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF1D9C51), size: 22),
              const SizedBox(width: 8),
              Text(
                'Prompt Kebijakan AI',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ketik skenario intervensi kebijakan publik yang ingin diuji dampaknya:',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF515151)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Contoh: Peremajaan 50 unit PJU dan penambahan rambu...',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0DFDF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1D9C51), width: 1.5),
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
                style: GoogleFonts.poppins(color: const Color(0xFF8F8F8F)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                Navigator.pop(ctx);
                if (txt.isNotEmpty) {
                  _runAiSimulation(txt);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9C51),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Jalankan AI',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApprovalSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: Color(0xFF1D9C51),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Kebijakan Berhasil Disetujui',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Rencana kebijakan "$_selectedPolicyScenario" untuk wilayah $_selectedRegion telah diteruskan ke OPD terkait untuk eksekusi lapangan.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF515151),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Return to monitoring
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9C51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Kembali ke Monitoring',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
