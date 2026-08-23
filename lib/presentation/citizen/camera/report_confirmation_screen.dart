import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ReportConfirmationScreen extends StatefulWidget {
  const ReportConfirmationScreen({super.key});

  @override
  State<ReportConfirmationScreen> createState() =>
      _ReportConfirmationScreenState();
}

class _ReportConfirmationScreenState extends State<ReportConfirmationScreen> {
  // Option 0: Mendukung laporan yang sudah ada (Default selected matching Screenshot 3)
  // Option 1: Tetap membuat laporan baru
  int _selectedOption = 0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onLanjutTap() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (_selectedOption == 0) {
      // User selected Option 1: Mendukung laporan yang sudah ada -> Navigate to Success Page (Support mode)
      Navigator.pushNamed(
        context,
        '/report-success',
        arguments: {
          if (args != null) ...args,
          'isSupportOnly': true,
          'notes': _notesController.text,
        },
      );
    } else {
      // User selected Option 2: Tetap membuat laporan baru -> Navigate to Form Laporan Baru
      Navigator.pushNamed(
        context,
        '/new-report-form',
        arguments: {
          if (args != null) ...args,
          'notes': _notesController.text,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Konfirmasi laporan',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. AI Verification Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
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
                    ),
                    const SizedBox(height: 16),

                    // 2. Similarity Percentage Card (Green bar 90%)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Tingkat kesamaan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              Text(
                                '90%',
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
                            child: const LinearProgressIndicator(
                              value: 0.90,
                              minHeight: 8,
                              backgroundColor: AppColors.neutral100,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Selection Option Section Header
                    const Text(
                      'Saya memilih',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Option A: Mendukung laporan yang sudah ada
                    _buildOptionCard(
                      optionIndex: 0,
                      title: 'Mendukung laporan yang sudah ada',
                      subtitle:
                          'Dukungan anda akan menambahkan bobot pada laporan tersebut.',
                    ),
                    const SizedBox(height: 12),

                    // Option B: Tetap membuat laporan baru
                    _buildOptionCard(
                      optionIndex: 1,
                      title: 'Tetap membuat laporan baru',
                      subtitle:
                          'Kasus berbeda atau lokasi/kerusakan tidak sama',
                    ),
                    const SizedBox(height: 16),

                    // 4. Optional Notes Card Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.assignment_outlined,
                                size: 24,
                                color: AppColors.neutral900,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Catatan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '*opsional',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLines: 3,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                hintText: 'Tambahkan catatan laporan__',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.neutral500,
                                ),
                                border: InputBorder.none,
                                counterStyle: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.neutral500,
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
            ),

            // 5. Bottom Action Button: Lanjut
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: _onLanjutTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lanjut',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: AppColors.greenPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 14,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required int optionIndex,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedOption == optionIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = optionIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F3FF) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B82C4) : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2B82C4) : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2B82C4)
                      : AppColors.neutral500,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
