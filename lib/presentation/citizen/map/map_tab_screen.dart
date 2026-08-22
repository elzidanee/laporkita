import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

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

  // Sample report markers around Malang (-7.9666, 112.6326)
  final List<Map<String, dynamic>> _reports = [
    {
      'id': '#LP_2026_002487',
      'title': 'Jalan Rusak',
      'address': 'Jl. Ahmad Yani No. 15, Malang',
      'category': 'Jalan',
      'status': 'Sedang Diproses',
      'statusColor': const Color(0xFFFFF8E6),
      'statusTextColor': const Color(0xFFE68A00),
      'pinColor': const Color(0xFFF5A623), // Yellow/Amber
      'supports': '360 Dukungan',
      'date': '12 Mei 2026',
      'point': const LatLng(-7.9666, 112.6326),
      'imageUrl':
          'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': '#LP_2026_002488',
      'title': 'Lampu Jalan Mati',
      'address': 'Jl. Veteran No. 8, Malang',
      'category': 'Lampu',
      'status': 'Menunggu',
      'statusColor': const Color(0xFFFFEAEA),
      'statusTextColor': const Color(0xFFE53935),
      'pinColor': const Color(0xFFE53935), // Red
      'supports': '142 Dukungan',
      'date': '14 Mei 2026',
      'point': const LatLng(-7.9540, 112.6140),
      'imageUrl':
          'https://images.unsplash.com/photo-1508873696983-2df515122519?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': '#LP_2026_002489',
      'title': 'Trotoar Berlubang',
      'address': 'Jl. Soekarno Hatta No. 45, Malang',
      'category': 'Trotoar',
      'status': 'Selesai',
      'statusColor': const Color(0xFFE8F5E9),
      'statusTextColor': AppColors.greenPrimary,
      'pinColor': AppColors.greenPrimary, // Green
      'supports': '512 Dukungan',
      'date': '10 Mei 2026',
      'point': const LatLng(-7.9420, 112.6200),
      'imageUrl':
          'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': '#LP_2026_002490',
      'title': 'Saluran Air Tersumbat',
      'address': 'Jl. Kawi No. 12, Malang',
      'category': 'Fasilitas',
      'status': 'Sedang Diproses',
      'statusColor': const Color(0xFFFFF8E6),
      'statusTextColor': const Color(0xFFE68A00),
      'pinColor': const Color(0xFFF5A623), // Yellow/Amber
      'supports': '89 Dukungan',
      'date': '15 Mei 2026',
      'point': const LatLng(-7.9780, 112.6250),
      'imageUrl':
          'https://images.unsplash.com/photo-1541888046830-22c6080cb9d6?q=80&w=400&auto=format&fit=crop',
    },
  ];

  List<Map<String, dynamic>> get _filteredReports {
    if (_selectedFilter == 'Semua') return _reports;
    return _reports
        .where((r) => r['category'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 1. FlutterMap Layer
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-7.9666, 112.6326),
              initialZoom: 14.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.laporkita.app',
              ),
              MarkerLayer(
                markers: _filteredReports.map((report) {
                  final point = report['point'] as LatLng;
                  final Color pinColor = report['pinColor'] as Color? ??
                      (report['status'] == 'Sedang Diproses'
                          ? const Color(0xFFF5A623)
                          : report['status'] == 'Menunggu'
                              ? const Color(0xFFE53935)
                              : AppColors.greenPrimary);

                  return Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        _mapController.move(point, 16.0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${report['title']} - ${report['address']}'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Detail',
                              textColor: Colors.amber,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/report-detail',
                                  arguments: report,
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: pinColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
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
                      Icon(Icons.search_rounded, color: AppColors.neutral500),
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

          // 3. DraggableScrollableSheet for Pull-Up Menu (Figma Node 185:554 & Node 107:1441)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.35,
            minChildSize: 0.18,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            '${_filteredReports.length} Laporan',
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

                    // List of Report Cards (Expanded View Node 107:1441)
                    ..._filteredReports.map((report) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMapReportCard(context, report),
                        )),

                    const SizedBox(height: 80), // Bottom padding for floating navbar
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapReportCard(
      BuildContext context, Map<String, dynamic> report) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/report-detail', arguments: report);
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
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                report['imageUrl'],
                width: 80,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 64,
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

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title + Date (Expanded Title to prevent overflow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report['title'],
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
                        report['date'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Address
                  Text(
                    report['address'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Support Count + Status Chip (Flexible text to prevent right overflow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report['supports'],
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
                              color: report['statusColor'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report['status'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: report['statusTextColor'],
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
  }
}
