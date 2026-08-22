import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NewReportFormScreen extends StatefulWidget {
  const NewReportFormScreen({super.key});

  @override
  State<NewReportFormScreen> createState() => _NewReportFormScreenState();
}

class _NewReportFormScreenState extends State<NewReportFormScreen> {
  late TextEditingController _notesController;
  String _selectedCategory = 'Jalan';

  final List<String> _categories = [
    'Jalan',
    'Trotoar',
    'Lalu Lintas',
    'Fasilitas Umum',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onKirimLaporan() {
    Navigator.pushNamed(
      context,
      '/report-success',
      arguments: {'isSupportOnly': false},
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String? imagePath = args?['imagePath'];
    final String location =
        args?['location'] ?? 'Jl. ahmad yani no. 15 sawojajar kota Malang';
    final String coordinates =
        args?['coordinates'] ?? '-6.382728,107.734682';
    final String timestamp = args?['timestamp'] ?? '12 Mei 2026 | 10.30 WIB';
    
    // Split timestamp into date and time if available
    String dateStr = '12 Mei 2026';
    String timeStr = '10.30 WIB';
    if (timestamp.contains('|')) {
      final parts = timestamp.split('|');
      dateStr = parts[0].trim();
      timeStr = parts[1].trim();
    } else if (timestamp.contains(' ')) {
      dateStr = timestamp;
    }

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
          'Konfirmasi Laporan Baru',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Header Card (Figma Node 88:1793)
                    _buildTopHeaderCard(imagePath: imagePath),
                    const SizedBox(height: 16),

                    // 2. Field 1: Lokasi (*tidak dapat diubah)
                    _buildFieldBox(
                      icon: Icons.location_on_outlined,
                      label: 'Lokasi',
                      tagText: '*tidak dapat diubah',
                      tagColor: const Color(0xFFFF3D00),
                      valueText: location,
                    ),
                    const SizedBox(height: 10),

                    // 3. Field 2: Koordinat (*tidak dapat diubah + Copy Icon)
                    _buildFieldBox(
                      icon: Icons.memory_outlined,
                      label: 'Koordinat',
                      tagText: '*tidak dapat diubah',
                      tagColor: const Color(0xFFFF3D00),
                      valueText: coordinates,
                      trailingIcon: Icons.copy_rounded,
                      onTrailingTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Koordinat berhasil disalin!'),
                            backgroundColor: AppColors.greenPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // 4. Field 3: Tanggal (*tidak dapat diubah)
                    _buildFieldBox(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tanggal',
                      tagText: '*tidak dapat diubah',
                      tagColor: const Color(0xFFFF3D00),
                      valueText: dateStr,
                    ),
                    const SizedBox(height: 10),

                    // 5. Field 4: Jam (*tidak dapat diubah)
                    _buildFieldBox(
                      icon: Icons.access_time_outlined,
                      label: 'Jam',
                      tagText: '*tidak dapat diubah',
                      tagColor: const Color(0xFFFF3D00),
                      valueText: timeStr,
                    ),
                    const SizedBox(height: 10),

                    // 6. Field 5: Kategori (*dapat diubah - Dropdown)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0DFDF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            size: 24,
                            color: AppColors.neutral900,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text(
                                      'Kategori',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '*dapat diubah',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8F8F8F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE0DFDF)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.neutral900,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                      items: _categories.map((String cat) {
                                        return DropdownMenuItem<String>(
                                          value: cat,
                                          child: Text(cat),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedCategory = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 7. Field 6: Catatan (*opsional)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0DFDF)),
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
                          const Icon(
                            Icons.assignment_outlined,
                            size: 24,
                            color: AppColors.neutral900,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text(
                                      'Catatan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '*opsional',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8F8F8F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE0DFDF)),
                                  ),
                                  child: TextField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    maxLength: 200,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.neutral900,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Tambahkan catatan laporan__',
                                      hintStyle: TextStyle(
                                        fontSize: 12,
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Action Button: Kirim Laporan
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ElevatedButton(
                onPressed: _onKirimLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kirim Laporan',
                  style: TextStyle(
                    fontSize: 18,
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

  /// Top Card matching Figma Node 88:1793
  Widget _buildTopHeaderCard({required String? imagePath}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 120,
              child: imagePath != null &&
                      imagePath.isNotEmpty &&
                      !kIsWeb &&
                      File(imagePath).existsSync()
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=800&auto=format&fit=crop',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF0F4F8),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.greenPrimary,
                            size: 32,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Right Category & Confidence
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori AI',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jalan Rusak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Confidence',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral900,
                      ),
                    ),
                    Text(
                      '98%',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenPrimary,
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

  Widget _buildFieldBox({
    required IconData icon,
    required String label,
    required String tagText,
    required Color tagColor,
    required String valueText,
    IconData? trailingIcon,
    VoidCallback? onTrailingTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.neutral900,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tagText,
                      style: TextStyle(
                        fontSize: 11,
                        color: tagColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null)
            IconButton(
              icon: Icon(trailingIcon, size: 20, color: AppColors.neutral900),
              onPressed: onTrailingTap,
            ),
        ],
      ),
    );
  }
}
