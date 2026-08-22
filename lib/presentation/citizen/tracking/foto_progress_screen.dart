import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FotoProgressScreen extends StatelessWidget {
  const FotoProgressScreen({super.key});

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
          'Foto Progress',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estimasi Selesai Card
              _buildEstimasiSelesaiCard(),
              const SizedBox(height: 12),

              // Progress Card
              _buildProgressCard(),
              const SizedBox(height: 24),

              // Timeline Title
              const Text(
                'Timeline foto progres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 12),

              // Timeline Items
              _buildTimelineItem(
                date: '17 Mei 2026 | 07.42',
                progressText: 'Progres 87%',
                description: 'Pekerjaan pengaspalan tahap pertama selesai',
                imageUrl:
                    'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?q=80&w=200&auto=format&fit=crop',
                isNew: true,
              ),
              const SizedBox(height: 12),
              _buildTimelineItem(
                date: '16 Mei 2026 | 14.32',
                progressText: 'Progres 75%',
                description: 'Pengerjaan pengaspalan sedang berlangsung',
                imageUrl:
                    'https://images.unsplash.com/photo-1541888046830-22c6080cb9d6?q=80&w=200&auto=format&fit=crop',
                isNew: false,
              ),
              const SizedBox(height: 12),
              _buildTimelineItem(
                date: '15 Mei 2026 | 10.28',
                progressText: 'Progres 57%',
                description: 'Persiapan alat dan bahan dilokasi',
                imageUrl:
                    'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=200&auto=format&fit=crop',
                isNew: false,
              ),
            ],
          ),
        ),
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
                '87%',
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
              value: 0.87,
              minHeight: 8,
              backgroundColor: AppColors.neutral100,
              color: AppColors.greenPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String date,
    required String progressText,
    required String description,
    required String imageUrl,
    required bool isNew,
  }) {
    return Container(
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
              imageUrl,
              width: 100,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 80,
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
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progressText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
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
    );
  }
}
