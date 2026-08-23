import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:laporkita/core/theme/app_colors.dart';
import 'package:laporkita/presentation/reports/bloc/report_bloc.dart';
import 'package:laporkita/data/models/report_model.dart';

class CitizenPetaTab extends StatefulWidget {
  const CitizenPetaTab({super.key});

  @override
  State<CitizenPetaTab> createState() => _CitizenPetaTabState();
}

class _CitizenPetaTabState extends State<CitizenPetaTab> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Jalan', 'Trotoar', 'Lampu', 'Fasilitas'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportBloc>().add(const ReportLoadRequested());
    });
  }

  List<ReportModel> _filterReports(List<ReportModel> reports) {
    if (_selectedFilter == 'Semua') return reports;
    return reports
        .where((r) => r.categoryName
            .toLowerCase()
            .contains(_selectedFilter.toLowerCase()))
        .toList();
  }

  LatLng _safeLatLng(double lat, double lng) {
    if (lat.isNaN || lng.isNaN || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return const LatLng(-7.9666, 112.6326);
    }
    return LatLng(lat, lng);
  }

  /// Warna sesuai status laporan — digunakan konsisten di pin marker & kartu
  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendingVerification:
        return const Color(0xFF2B82C4);  // Biru — menunggu verifikasi
      case ReportStatus.verified:
        return const Color(0xFF26A69A);  // Teal — terverifikasi
      case ReportStatus.rejected:
        return const Color(0xFFE53935);  // Merah — ditolak
      case ReportStatus.assigned:
        return const Color(0xFF7B1FA2);  // Ungu — ditugaskan
      case ReportStatus.inProgress:
        return const Color(0xFFF5A623);  // Oranye — sedang diproses
      case ReportStatus.completed:
        return const Color(0xFF1D9C51);  // Hijau tua — selesai
      case ReportStatus.resolved:
        return const Color(0xFF388E3C);  // Hijau gelap — terselesaikan
      case ReportStatus.disputed:
        return const Color(0xFF757575);  // Abu-abu — diperdebatkan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          List<ReportModel> apiReports = [];
          if (state is ReportListLoaded) {
            apiReports = state.reports;
          }

          final displayReports = _filterReports(apiReports);

          return Stack(
            children: [
              // 1. FlutterMap Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: displayReports.isNotEmpty
                      ? _safeLatLng(
                          displayReports.first.latitude,
                          displayReports.first.longitude,
                        )
                      : const LatLng(-7.9666, 112.6326),
                  initialZoom: 14.0,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.laporkita.app',
                  ),
                  MarkerLayer(
                    markers: displayReports.map((report) {
                      final point =
                          _safeLatLng(report.latitude, report.longitude);
                      final pinColor = _statusColor(report.status);

                      return Marker(
                        point: point,
                        width: 40,
                        height: 48,
                        child: GestureDetector(
                          onTap: () {
                            _mapController.move(point, 16.0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${report.categoryName} — ${report.status.displayName}'),
                                backgroundColor: pinColor,
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'Detail',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/report-detail',
                                      arguments: {
                                        'id': report.id,
                                        'reportModel': report,
                                        'title': report.categoryName,
                                        'address': report.addressText ?? 'Malang',
                                        'fullAddress':
                                            report.addressText ?? 'Kota Malang',
                                        'status': report.status.displayName,
                                        'description': report.description ??
                                            'Laporan fasilitas umum.',
                                        'photoUrl': report.photoUrl,
                                        'supports': report.supportCount,
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: pinColor,
                                size: 48,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 2. Top Header & Search Bar Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Search Bar Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE0DFDF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search_rounded,
                              color: AppColors.neutral500),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari laporan di Peta Malang...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.neutral500,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(Icons.my_location_rounded,
                              color: AppColors.greenPrimary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Category Horizontal Scrollable Chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.neutral900,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                            selectedColor: AppColors.greenPrimary,
                            backgroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.greenPrimary
                                    : const Color(0xFFE0DFDF),
                              ),
                            ),
                            elevation: 2,
                            pressElevation: 4,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2b. Status Legend Overlay (bottom-left)
              Positioned(
                left: 16,
                bottom: MediaQuery.of(context).size.height * 0.38,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Legenda',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(const Color(0xFF2B82C4), 'Menunggu'),
                      _buildLegendItem(const Color(0xFF26A69A), 'Terverifikasi'),
                      _buildLegendItem(const Color(0xFF7B1FA2), 'Ditugaskan'),
                      _buildLegendItem(const Color(0xFFF5A623), 'Diproses'),
                      _buildLegendItem(const Color(0xFF1D9C51), 'Selesai'),
                      _buildLegendItem(const Color(0xFFE53935), 'Ditolak'),
                    ],
                  ),
                ),
              ),

              // 3. DraggableScrollableSheet for Pull-Up Menu
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.35,
                minChildSize: 0.18,
                maxChildSize: 0.88,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      children: [
                        // Pull Handle Indicator Bar
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD0D0D0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Sheet Title & Counter Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sebaran Laporan Sekitar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral900,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${displayReports.length} Laporan',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.greenPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // List of Report Cards
                        if (state is ReportLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.greenPrimary,
                              ),
                            ),
                          )
                        else if (displayReports.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Belum ada laporan di lokasi ini.',
                                style: TextStyle(
                                  color: AppColors.neutral500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ...displayReports.take(20).map((report) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildMapReportCardFromModel(
                                    context, report),
                              )),

                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF444444),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapReportCardFromModel(
      BuildContext context, ReportModel report) {
    try {
      final statusColor = _statusColor(report.status);
      final statusBgColor = statusColor.withValues(alpha: 0.12);
      final statusTextColor = statusColor;

      final imgUrl = report.formattedPhotoUrl ?? report.photoUrl;
      final String? localPath = report.directPhotoUrl ?? report.photoUrl;

      bool isLocalValid = false;
      if (localPath != null &&
          localPath.isNotEmpty &&
          !localPath.startsWith('http')) {
        try {
          isLocalValid = File(localPath).existsSync();
        } catch (_) {
          isLocalValid = false;
        }
      }

      final Widget safePlaceholderWidget = Container(
        width: 80,
        height: 64,
        color: AppColors.greenLight,
        child: const Center(
          child: Icon(
            Icons.location_city_rounded,
            size: 28,
            color: AppColors.greenPrimary,
          ),
        ),
      );

      Widget cardImageWidget;
      if (isLocalValid && localPath != null) {
        cardImageWidget = Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => safePlaceholderWidget,
        );
      } else if (imgUrl != null && imgUrl.isNotEmpty) {
        cardImageWidget = Image.network(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => safePlaceholderWidget,
        );
      } else {
        cardImageWidget = safePlaceholderWidget;
      }

      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/report-detail', arguments: {
            'id': report.id,
            'reportModel': report,
            'title': report.categoryName,
            'address': report.addressText ?? 'Malang',
            'fullAddress': report.addressText ?? 'Kota Malang',
            'status': report.status.displayName,
            'description': report.description ?? 'Laporan fasilitas umum.',
            'photoUrl': imgUrl,
            'imagePath': localPath,
            'supports': report.supportCount,
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 64,
                  child: cardImageWidget,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${report.createdAt.day}/${report.createdAt.month}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.addressText ?? 'Malang',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${report.supportCount} Dukungan',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              report.status.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.neutral900,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
