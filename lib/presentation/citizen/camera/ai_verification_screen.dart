import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/remote/ai_service_datasource.dart';
import '../../../data/models/ai_verification_model.dart';
import '../../../data/repositories/report_repository.dart';

class AiVerificationScreen extends StatefulWidget {
  const AiVerificationScreen({super.key});

  @override
  State<AiVerificationScreen> createState() => _AiVerificationScreenState();
}

class _AiVerificationScreenState extends State<AiVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isVerifying = false;
  AiVerificationResult? _verificationResult;
  String? _verificationError;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Mulai verifikasi otomatis setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAiVerification());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _args =>
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  Future<void> _runAiVerification() async {
    final args = _args;
    final String? imagePath = args?['imagePath'];
    final String? imageUrl = args?['photoUrl'];
    final String coordinates = args?['coordinates'] ?? '-7.9827,112.6304';

    double lat = -7.9827;
    double lng = 112.6304;
    if (coordinates.contains(',')) {
      try {
        final parts = coordinates.split(',');
        if (parts.length == 2) {
          lat = double.parse(parts[0].trim());
          lng = double.parse(parts[1].trim());
        }
      } catch (_) {}
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
      _verificationError = null;
    });

    try {
      final String? hintCategory = args?['detectedCategory'] ?? args?['claimedCategory'];
      final double? hintConfidence = (args?['confidence'] as num?)?.toDouble();

      final result = await AiServiceDatasource().verifyReport(
        imagePath: imagePath,
        imageUrl: imageUrl,
        claimedCategory: hintCategory,
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        deviceHintCategory: hintCategory,
        deviceHintConfidence: hintConfidence,
      );
      if (!mounted) return;
      setState(() {
        _verificationResult = result;
        _isVerifying = false;
      });
      _pulseController.stop();
    } catch (e) {
      if (!mounted) return;
      // Jika AI service tidak dapat dihubungi, tetap izinkan lanjut
      setState(() {
        _verificationError = 'Layanan AI tidak tersedia. Laporan tetap dapat dikirim.';
        _isVerifying = false;
      });
      _pulseController.stop();
    }
  }

  Future<void> _handleLanjut() async {
    final args = _args;
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
        Navigator.pushNamed(
          context,
          '/similar-reports',
          arguments: {
            if (args != null) ...args,
            'similarReports': similarReports,
            if (_verificationResult != null)
              'aiVerification': _verificationResult,
          },
        );
      } else {
        Navigator.pushNamed(
          context,
          '/new-report-form',
          arguments: {
            if (args != null) ...args,
            if (_verificationResult != null)
              'aiVerification': _verificationResult,
          },
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/new-report-form', arguments: args);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  bool get _isRejectedByAi {
    final result = _verificationResult;
    if (result == null) return false;
    return !result.isWithinMalang || result.detectedCategory == 'bukan_fasilitas';
  }

  bool get _isVerified {
    final result = _verificationResult;
    if (result == null) return false;
    return result.isVerified;
  }

  bool get _needsManualReview {
    final result = _verificationResult;
    if (result == null) return false;
    return result.needsManualReview;
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final String? imagePath = args?['imagePath'];
    final String location = args?['location'] ?? 'Kota Malang';
    final String coordinates = args?['coordinates'] ?? '-7.9827,112.6304';
    final String timestamp = args?['timestamp'] ?? '-';

    final bool isRejectedByAi = _isRejectedByAi;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Foto Preview
                    _buildPhotoPreview(
                      imagePath: imagePath,
                      location: location,
                      coordinates: coordinates,
                      timestamp: timestamp,
                    ),
                    const SizedBox(height: 20),

                    // 2. Status Cards (GPS, Timestamp, Metadata)
                    _buildStaticCheckCard(
                      icon: Icons.gps_fixed_rounded,
                      title: 'GPS Valid',
                      subtitle: coordinates,
                      color: AppColors.greenPrimary,
                    ),
                    const SizedBox(height: 10),
                    _buildStaticCheckCard(
                      icon: Icons.access_time_rounded,
                      title: 'Timestamp Valid',
                      subtitle: timestamp,
                      color: AppColors.greenPrimary,
                    ),
                    const SizedBox(height: 10),
                    _buildStaticCheckCard(
                      icon: Icons.location_city_rounded,
                      title: 'Wilayah Kota Malang',
                      subtitle: location,
                      color: _verificationResult?.isWithinMalang == false
                          ? const Color(0xFFE53935)
                          : AppColors.greenPrimary,
                      statusOverride: _verificationResult?.isWithinMalang == false
                          ? 'Di luar area'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // 3. AI Detection Card
                    _buildAiDetectionCard(),
                    const SizedBox(height: 16),

                    // 4. Pesan error / penolakan / review manual jika ada
                    if (isRejectedByAi) ...[
                      _buildRejectionBanner(
                        _verificationResult?.rejectionReason ??
                            'Foto tidak dapat diproses: Lokasi berada di luar wilayah Kota Malang atau objek bukan fasilitas publik.',
                      ),
                      const SizedBox(height: 16),
                    ] else if (_needsManualReview) ...[
                      _buildManualReviewBanner(
                        _verificationResult?.rejectionReason ??
                            'Laporan ini memerlukan peninjauan manual oleh tim verifikator. Anda tetap dapat melanjutkan untuk mengirimkan laporan.',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRejectedByAi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Foto tidak lolos verifikasi AI. Silakan ambil foto ulang.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: (_isChecking || _isVerifying || isRejectedByAi)
                        ? null
                        : _handleLanjut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenPrimary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: isRejectedByAi
                          ? const Color(0xFFE53935).withValues(alpha: 0.5)
                          : null,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: (_isChecking || _isVerifying)
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isRejectedByAi ? 'Foto Ditolak AI' : 'Lanjut',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildPhotoPreview({
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
            Positioned.fill(child: _buildImageWidget(imagePath)),
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
                        color:
                            AppColors.greenPrimary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('LaporKita',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    _stampRow(Icons.location_on_outlined, location),
                    const SizedBox(height: 3),
                    _stampRow(Icons.access_time_outlined, timestamp),
                    const SizedBox(height: 3),
                    _stampRow(Icons.memory_outlined, coordinates),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath) {
    final placeholder = Container(
      color: const Color(0xFFF0F4F8),
      child: const Icon(Icons.image_not_supported_rounded,
          size: 48, color: AppColors.greenPrimary),
    );
    if (imagePath == null || imagePath.isEmpty) return placeholder;
    if (!imagePath.startsWith('http')) {
      try {
        if (File(imagePath).existsSync()) {
          return Image.file(File(imagePath), fit: BoxFit.cover);
        }
      } catch (_) {}
      return placeholder;
    }
    return Image.network(imagePath, fit: BoxFit.cover,
        errorBuilder: (context, error, _) => placeholder);
  }

  Widget _stampRow(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w400)),
        ],
      );

  Widget _buildStaticCheckCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? statusOverride,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DFDF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900)),
                const SizedBox(height: 1),
                Text(
                  statusOverride ?? subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: statusOverride != null
                          ? const Color(0xFFE53935)
                          : AppColors.neutral500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            statusOverride != null
                ? Icons.cancel_rounded
                : Icons.check_circle_rounded,
            color: statusOverride != null
                ? const Color(0xFFE53935)
                : AppColors.greenPrimary,
            size: 22,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _verificationResult == null
              ? const Color(0xFFE0DFDF)
              : _verificationResult!.isVerified
                  ? AppColors.greenPrimary.withValues(alpha: 0.4)
                  : const Color(0xFFE53935).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon AI
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _isRejectedByAi
                      ? const Color(0xFFFFEBEB)
                      : _needsManualReview && !_isVerified
                          ? const Color(0xFFFFF8E7)
                          : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isVerifying
                    ? ScaleTransition(
                        scale: _pulseAnimation,
                        child: const Icon(Icons.psychology_rounded,
                            size: 30, color: AppColors.greenPrimary),
                      )
                    : Icon(
                        _isRejectedByAi
                            ? Icons.cancel_rounded
                            : _isVerified
                                ? Icons.verified_rounded
                                : _needsManualReview
                                    ? Icons.warning_amber_rounded
                                    : Icons.psychology_rounded,
                        size: 30,
                        color: _isRejectedByAi
                            ? const Color(0xFFE53935)
                            : _isVerified
                                ? AppColors.greenPrimary
                                : _needsManualReview
                                    ? const Color(0xFFF5A623)
                                    : AppColors.greenPrimary,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isVerifying
                          ? 'AI Sedang Menganalisa...'
                          : _verificationError != null
                              ? 'AI Tidak Tersedia'
                              : _isRejectedByAi
                                  ? 'Ditolak AI ❌'
                                  : _isVerified
                                      ? 'Terverifikasi Otomatis ✓'
                                      : _needsManualReview
                                          ? 'Perlu Review Manual ⚠️'
                                          : 'Menunggu Analisis',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isVerifying || _verificationResult == null
                            ? AppColors.neutral900
                            : _isRejectedByAi
                                ? const Color(0xFFE53935)
                                : _isVerified
                                    ? AppColors.greenPrimary
                                    : _needsManualReview
                                        ? const Color(0xFFF5A623)
                                        : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isVerifying
                          ? 'Sedang memproses gambar dengan YOLOv11...'
                          : _verificationError != null
                              ? _verificationError!
                              : _verificationResult?.detectedCategory ??
                                  'Menunggu...',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Confidence bar (hanya tampil jika ada hasil)
          if (_verificationResult != null && !_isVerifying) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Confidence AI',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900)),
                Text(
                  '${_verificationResult!.confidencePercent}%',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _isVerified
                          ? AppColors.greenPrimary
                          : _needsManualReview
                              ? const Color(0xFFF5A623)
                              : const Color(0xFFE53935)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _verificationResult!.confidence.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE8E8E8),
                color: _isVerified
                    ? AppColors.greenPrimary
                    : _needsManualReview
                        ? const Color(0xFFF5A623)
                        : const Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Urgency Score',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900)),
                Text(
                  '${_verificationResult!.urgencyPercent}%',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5A623)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _verificationResult!.urgencyScore.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE8E8E8),
                color: const Color(0xFFF5A623),
              ),
            ),

            // Auto description dari AI
            if (_verificationResult!.autoDescription.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FBF7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.greenLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.greenPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _verificationResult!.autoDescription,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.neutral900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Loading shimmer saat verifikasi berjalan
          if (_isVerifying) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: Color(0xFFE8E8E8),
                color: AppColors.greenPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionBanner(String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE53935), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verifikasi Ditolak',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935),
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(reason,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF8B0000))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualReviewBanner(String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFD9822B), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Perlu Review Manual',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD9822B),
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(reason,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF7A4A00))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
