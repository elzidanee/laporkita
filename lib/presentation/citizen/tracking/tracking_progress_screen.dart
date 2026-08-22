import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrackingProgressScreen extends StatelessWidget {
  const TrackingProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract args if any
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String? imagePath = args?['imagePath'];
    final String location =
        args?['location'] ?? 'Jl. Ahmad Yani No.15 Malang';
    final String coordinates =
        args?['coordinates'] ?? '-6.382728,107.734682';
    final String timestamp =
        args?['timestamp'] ?? 'Kamis, 12 Mei 2026 | 10.30 WIB';
    final String reportId = args?['reportId'] ?? '#LP_2026_002487';

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
          'Tracking Progress',
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
                    // Photo Preview with Overlay Stamp
                    _buildPhotoPreviewWithStamp(
                      imagePath: imagePath,
                      location: location,
                      coordinates: coordinates,
                      timestamp: timestamp,
                      reportId: reportId,
                    ),
                    const SizedBox(height: 24),

                    // Status Card (Figma Node 98:806)
                    _buildStatusCard(),
                    const SizedBox(height: 12),

                    // Progress Card (Figma Node 103:892)
                    _buildProgressCard(),
                    const SizedBox(height: 12),

                    // Estimasi Selesai Card (Figma Node 98:815)
                    _buildEstimasiSelesaiCard(),
                    const SizedBox(height: 12),

                    // Petugas Penanganan Card (Figma Node 103:881)
                    _buildPetugasCard(),
                    const SizedBox(height: 24),

                    // Foto Progres Terbaru
                    _buildFotoProgresTerbaru(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Button: Lihat Detail Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/report-detail', arguments: args);
                },
                icon: const Icon(Icons.remove_red_eye_rounded, size: 22),
                label: const Text(
                  'Lihat Detail Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2), // Blue button
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreviewWithStamp({
    required String? imagePath,
    required String location,
    required String coordinates,
    required String timestamp,
    required String reportId,
  }) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Captured Image / High-res fallback
            Positioned.fill(
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenPrimary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'LaporKita',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStampItem(
                      icon: Icons.location_on_outlined,
                      text: location,
                    ),
                    const SizedBox(height: 3),
                    _buildStampItem(
                      icon: Icons.access_time_outlined,
                      text: timestamp,
                    ),
                    const SizedBox(height: 3),
                    _buildStampItem(
                      icon: Icons.warning_amber_rounded,
                      text: 'Jalan Rusak',
                    ),
                    const SizedBox(height: 3),
                    _buildStampItem(
                      icon: Icons.memory_outlined,
                      text: coordinates,
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

  Widget _buildStampItem({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0DFDF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Status saat ini',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sedang Dikerjakan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF2AE01), // Yellow/Orange
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Untuk Petugas dinas PUPR sedang mengerjakan perbaikan dilokasi laporan anda.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                '78%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.78,
              minHeight: 8,
              backgroundColor: AppColors.neutral100,
              color: AppColors.greenPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimasiSelesaiCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.greenPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.greenPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Estimasi Selesai',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '2 Hari Lagi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '18 Mei 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetugasCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Petugas Penanganan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dinas PUPR Kota Malang Bidang Bina Marga',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kontak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(
                      Icons.call_rounded,
                      size: 16,
                      color: AppColors.greenPrimary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '+62 80878367243',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 28,
              color: AppColors.greenPrimary,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFotoProgresTerbaru(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Progres Terbaru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?q=80&w=200&auto=format&fit=crop',
                  width: 100,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 70,
                      color: const Color(0xFFF0F4F8),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: AppColors.greenPrimary,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sedang diperbaiki',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '13 Mei 2026. 12.43',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Baru',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/foto-progress');
            },
            child: const Text(
              'Lihat Semua Foto Progres',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2), // Blue
              ),
            ),
          ),
        ),
      ],
    );
  }
}
