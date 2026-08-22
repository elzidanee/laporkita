import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/report_repository.dart';

class AiVerificationScreen extends StatefulWidget {
  const AiVerificationScreen({super.key});

  @override
  State<AiVerificationScreen> createState() => _AiVerificationScreenState();
}

class _AiVerificationScreenState extends State<AiVerificationScreen> {
  bool _isChecking = false;

  Future<void> _handleLanjut(Map<String, dynamic>? args) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    double lat = -7.9827;
    double lng = 112.6304;
    final String? coordinates = args?['coordinates'];

    if (coordinates != null && coordinates.contains(',')) {
      try {
        final parts = coordinates.split(',');
        if (parts.length == 2) {
          lat = double.parse(parts[0].trim());
          lng = double.parse(parts[1].trim());
        }
      } catch (_) {}
    }

    try {
      final repository = context.read<ReportRepository>();
      final similarReports = await repository.checkSimilarReports(
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;

      if (similarReports.isNotEmpty) {
        // Ada laporan serupa! Buka halaman Deteksi Laporan Serupa
        Navigator.pushNamed(
          context,
          '/similar-reports',
          arguments: {
            if (args != null) ...args,
            'similarReports': similarReports,
          },
        );
      } else {
        // Tidak ada laporan serupa! Langsung buka halaman Laporan Baru
        Navigator.pushNamed(
          context,
          '/new-report-form',
          arguments: args,
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/new-report-form',
        arguments: args,
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed from camera screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String? imagePath = args?['imagePath'];
    final String location =
        args?['location'] ?? 'Jl. Ahmad Yani No.15 Malang';
    final String coordinates =
        args?['coordinates'] ?? '-6.382728,107.734682';
    final String timestamp =
        args?['timestamp'] ?? 'Kamis, 12 Mei 2026 | 10.30 WIB';

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
          'Verifikasi AI',
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
                    // 1. Photo Container with Stamp Overlay
                    _buildPhotoPreviewWithStamp(
                      imagePath: imagePath,
                      location: location,
                      coordinates: coordinates,
                      timestamp: timestamp,
                    ),
                    const SizedBox(height: 20),

                    // 2. 4 Verification Status Cards List
                    _buildVerificationCard(
                      title: 'Foto Asli',
                      subtitle: 'Foto diambil langsung dari camera',
                    ),
                    const SizedBox(height: 12),
                    _buildVerificationCard(
                      title: 'GPS Valid',
                      subtitle: 'Lokasi sesuai dan akurat',
                    ),
                    const SizedBox(height: 12),
                    _buildVerificationCard(
                      title: 'Timestamp Valid',
                      subtitle: 'Waktu sesuai saat pengambilan',
                    ),
                    const SizedBox(height: 12),
                    _buildVerificationCard(
                      title: 'Metadata Lengkap',
                      subtitle: 'Data foto lengkap dan utuh',
                    ),
                    const SizedBox(height: 20),

                    // 3. AI Detection & Confidence Card
                    _buildAiDetectionCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 4. Bottom Action Button: "Lanjut"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ElevatedButton(
                onPressed: _isChecking ? null : () => _handleLanjut(args),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Lanjut',
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

  /// Photo preview with camera metadata overlay stamp
  Widget _buildPhotoPreviewWithStamp({
    required String? imagePath,
    required String location,
    required String coordinates,
    required String timestamp,
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
            Positioned.fill(
              child: imagePath != null &&
                      imagePath.isNotEmpty &&
                      !kIsWeb &&
                      File(imagePath).existsSync()
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    )
                  : (imagePath != null && imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFF0F4F8),
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 48,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F4F8),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 48,
                            color: AppColors.greenPrimary,
                          ),
                        )),
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
                    const Text(
                      '#LP_2026_002487',
                      style: TextStyle(
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

  Widget _buildVerificationCard({
    required String title,
    required String subtitle,
  }) {
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.greenPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.greenPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiDetectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 32,
                  color: AppColors.greenPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'AI Mendeteksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Jalan rusak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kerusakan pada permukaan jalan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Confidence',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                '98%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.98,
              minHeight: 8,
              backgroundColor: AppColors.neutral100,
              color: AppColors.greenPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
