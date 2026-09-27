import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/report_model.dart';

/// Reusable thumbnail widget for report photos.
/// Ensures real photos from backend/camera are prioritized,
/// falls back to realistic category photos on network issues,
/// and never displays a broken/empty grey placeholder box.
class ReportThumbnailImage extends StatelessWidget {
  final ReportModel report;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? overlay;

  const ReportThumbnailImage({
    super.key,
    required this.report,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = _buildImageContent(context);

    if (overlay != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          overlay!,
        ],
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: content,
      );
    }

    return content;
  }

  Widget _buildImageContent(BuildContext context) {
    // 1. Cek berkas foto riil dari kamera/galeri di perangkat lokal
    final localPath = report.directPhotoUrl;
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http')) {
      try {
        final file = File(localPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            errorBuilder: (ctx, err, stack) => _buildNetworkOrFallbackImage(),
          );
        }
      } catch (_) {}
    }

    return _buildNetworkOrFallbackImage();
  }

  Widget _buildNetworkOrFallbackImage() {
    final photoUrl = report.formattedPhotoUrl ?? report.photoUrl ?? '';
    final fallbackUrl = ReportModel.getCategoryFallbackImage(report.categoryName);

    // 2. Jika ada URL foto asli dari backend, prioritaskan pemuatan foto tersebut
    if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1D9C51),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Jika DNS domain backend belum publik (internal storage),
          // gunakan foto asli kategori infrastruktur, BUKAN kotak abu-abu kosong.
          return Image.network(
            fallbackUrl,
            fit: fit,
            errorBuilder: (ctx, err, stack) =>
                _buildOfflineCategoryCard(report.categoryName),
          );
        },
      );
    }

    // 3. Fallback foto visual kategori nyata
    return Image.network(
      fallbackUrl,
      fit: fit,
      errorBuilder: (ctx, err, stack) =>
          _buildOfflineCategoryCard(report.categoryName),
    );
  }

  Widget _buildOfflineCategoryCard(String categoryName) {
    IconData icon;
    final lower = categoryName.toLowerCase();
    if (lower.contains('jalan') || lower.contains('aspal')) {
      icon = Icons.add_road_rounded;
    } else if (lower.contains('lampu') || lower.contains('penerangan')) {
      icon = Icons.lightbulb_outline_rounded;
    } else if (lower.contains('drainase') || lower.contains('banjir') || lower.contains('selokan')) {
      icon = Icons.water_damage_outlined;
    } else if (lower.contains('trotoar') || lower.contains('pedestrian')) {
      icon = Icons.directions_walk_rounded;
    } else if (lower.contains('rambu') || lower.contains('lalu')) {
      icon = Icons.traffic_rounded;
    } else if (lower.contains('sampah') || lower.contains('kebersihan')) {
      icon = Icons.delete_outline_rounded;
    } else {
      icon = Icons.location_city_rounded;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF2E7D32)),
            const SizedBox(height: 2),
            Text(
              categoryName,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
