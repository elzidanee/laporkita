import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/policy_simulation_model.dart';
import '../../../data/models/risk_prediction_model.dart';
import '../../../data/repositories/policy_simulator_repository.dart';
import '../../../data/repositories/prediction_repository.dart';

class PolicySimulatorScreen extends StatefulWidget {
  const PolicySimulatorScreen({super.key});

  @override
  State<PolicySimulatorScreen> createState() => _PolicySimulatorScreenState();
}

class _PolicySimulatorScreenState extends State<PolicySimulatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  String? _selectedZoneId;
  List<ZoneMetricsModel> _zones = [];
  bool _isLoadingZones = true;
  bool _isSimulating = false;
  PolicySimulationModel? _currentResult;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _presetScenarios = [
    'Penambalan aspal serentak & perbaikan drainase di Kec. Klojen',
    'Pembersihan sampah & pelebaran saluran Kali Mas Wonokromo',
    'Peremajaan 50 unit PJU & penambahan rambu di jalan protokol',
    'Normalisasi drainase daerah rawan banjir menjelang musim hujan',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchZones();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchZones() async {
    try {
      final repo = context.read<PredictionRepository>();
      final zonesList = await repo.getZones();
      if (mounted) {
        setState(() {
          _zones = zonesList;
          _isLoadingZones = false;
          if (_zones.isNotEmpty) {
            _selectedZoneId = _zones.first.id;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingZones = false;
        });
      }
    }
  }

  Future<void> _runSimulation() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan skenario kebijakan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
      _currentResult = null;
      _errorMessage = null;
    });

    try {
      final repo = context.read<PolicySimulatorRepository>();
      final result = await repo.createSimulation(
        promptText: text,
        zoneId: _selectedZoneId,
      );

      if (mounted) {
        setState(() {
          _currentResult = result;
          _isSimulating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Gagal menjalankan simulasi: ${e.toString().replaceAll("Exception: ", "")}';
          _isSimulating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Policy Simulator AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: AppColors.greenDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner Card
              _buildHeaderBanner(),
              const SizedBox(height: 16),

              // Input Form Card
              _buildInputCard(),
              const SizedBox(height: 20),

              // Simulation Results Area
              if (_isSimulating)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorCard(_errorMessage!)
              else if (_currentResult != null)
                _buildResultCard(_currentResult!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenDark, AppColors.greenPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Simulasi Kebijakan Publik AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Proyeksikan penurunan risiko infrastruktur & estimasi anggaran daerah berbasis DeepSeek LLM.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wilayah Target Simulasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingZones
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    initialValue: _selectedZoneId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _zones.map((zone) {
                      return DropdownMenuItem<String>(
                        value: zone.id,
                        child: Text(
                          '${zone.name} (Laporan: ${zone.reportDensity}, Risiko: ${(zone.floodRiskProbability * 100).round()}%)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedZoneId = val);
                    },
                  ),
            const SizedBox(height: 16),
            const Text(
              'Skenario Kebijakan / Intervensi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText:
                    'Contoh: Normalisasi saluran air sepanjang 2 km & perbaikan lubang jalan utama di Klojen.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),

            // Preset Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetScenarios.map((scenario) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _promptController.text = scenario;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.greenPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 14, color: AppColors.greenDark),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            scenario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Submit Simulation Button
            ElevatedButton.icon(
              onPressed: _isSimulating ? null : _runSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.analytics_rounded),
              label: const Text(
                'Jalankan Simulasi Kebijakan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 48,
                  color: AppColors.greenPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DeepSeek LLM Sedang Menganalisis...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Menghitung penurunan probabilitas risiko, proyeksi efisiensi anggaran, dan dampak pada warga.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.greenPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Card(
      color: const Color(0xFFFFEBEB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(PolicySimulationModel result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Metrics Grid (2x2)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildMetricTile(
              title: 'Estimasi Biaya (APBD)',
              value: result.formattedBudget,
              subtitle: 'Proyeksi Anggaran',
              color: AppColors.greenDark,
              icon: Icons.account_balance_wallet_outlined,
            ),
            _buildMetricTile(
              title: 'Penurunan Risiko',
              value: '-${(result.riskReductionPct).toStringAsFixed(1)}%',
              subtitle: 'Reduksi Kerentanan',
              color: Colors.blue.shade700,
              icon: Icons.trending_down_rounded,
            ),
            _buildMetricTile(
              title: 'Skor Risiko Simulasi',
              value: '${(result.simulatedRiskScore * 100).round()}%',
              subtitle: 'Pasca Intervensi',
              color: Colors.orange.shade800,
              icon: Icons.shield_outlined,
            ),
            _buildMetricTile(
              title: 'Keyakinan AI',
              value: '${(result.confidenceLevel * 100).round()}%',
              subtitle: 'DeepSeek LLM',
              color: Colors.purple.shade700,
              icon: Icons.verified_user_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Impact Analysis Card
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.assessment_outlined,
                        color: AppColors.greenDark, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Analisis Dampak Kebijakan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  result.impactAnalysis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Actionable Recommendations
        if (result.recommendedActions.isNotEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.playlist_add_check_circle_outlined,
                          color: AppColors.greenPrimary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rekomendasi Tindakan Strategis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...result.recommendedActions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.greenPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
