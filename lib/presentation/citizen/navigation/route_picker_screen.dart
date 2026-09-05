import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/routing_repository.dart';
import 'widgets/route_summary_card.dart';

/// Layar pemilihan rute A → B menggunakan OSRM dan flutter_map.
class RoutePickerScreen extends StatefulWidget {
  const RoutePickerScreen({super.key});

  @override
  State<RoutePickerScreen> createState() => _RoutePickerScreenState();
}

class _RoutePickerScreenState extends State<RoutePickerScreen> {
  final MapController _mapController = MapController();

  LatLng? _origin;
  LatLng? _destination;
  RouteModel? _route;
  bool _isLoading = false;

  // Koordinat pusat awal (Kota Malang)
  static const LatLng _initialCenter = LatLng(-7.9827, 112.6304);

  /// Menangani interaksi tap pada peta:
  /// - Tap 1: Set titik asal
  /// - Tap 2: Set titik tujuan & mulai kalkulasi rute
  /// - Tap 3: Reset dan jadikan tap baru sebagai titik asal baru
  void _handleMapTap(LatLng point) {
    if (_isLoading) return;

    if (_origin == null) {
      setState(() {
        _origin = point;
      });
    } else if (_destination == null) {
      setState(() {
        _destination = point;
      });
      _fetchRoute();
    } else {
      // Tap ke-3: Reset dan mulai ulang dari titik asal baru
      setState(() {
        _origin = point;
        _destination = null;
        _route = null;
      });
    }
  }

  /// Reset semua titik rute
  void _resetPoints() {
    setState(() {
      _origin = null;
      _destination = null;
      _route = null;
      _isLoading = false;
    });
  }

  /// Panggil OSRM via RoutingRepository
  Future<void> _fetchRoute() async {
    if (_origin == null || _destination == null) return;

    setState(() {
      _isLoading = true;
      _route = null;
    });

    try {
      final repository = context.read<RoutingRepository>();
      final result = await repository.getRoute(
        origin: _origin!,
        destination: _destination!,
      );

      if (!mounted) return;

      setState(() {
        _route = result;
        _isLoading = false;
      });

      // Sesuaikan zoom dan pusat kamera agar seluruh rute terlihat
      if (result.points.isNotEmpty) {
        _fitBoundsToRoute(result.points);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Penanganan error jujur: tampilkan pesan gagal yang jelas (merah)
      final errorMessage = e is RouteNotFoundException
          ? e.message
          : 'Gagal mendapatkan rute. Periksa koneksi internet Anda.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.statusDanger,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Menyesuaikan kamera peta mengikuti titik-titik rute
  void _fitBoundsToRoute(List<LatLng> points) {
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 130,
            bottom: 220,
            left: 48,
            right: 48,
          ),
        ),
      );
    } catch (_) {
      // Fallback jika perhitungan bounds gagal
      if (points.isNotEmpty) {
        _mapController.move(points.first, 14.0);
      }
    }
  }

  /// Marker dekoratif untuk titik asal dan tujuan
  Widget _buildMarkerPin({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(
          icon,
          color: color,
          size: 32,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ],
    );
  }

  /// Banner instruksi di bagian atas layar
  Widget _buildInstructionPill() {
    String instruction;
    Color dotColor;

    if (_isLoading) {
      instruction = 'Menghitung rute via OSRM...';
      dotColor = AppColors.statusPending;
    } else if (_origin == null) {
      instruction = 'Ketuk peta untuk menentukan Titik Asal';
      dotColor = AppColors.greenPrimary;
    } else if (_destination == null) {
      instruction = 'Ketuk peta untuk menentukan Titik Tujuan';
      dotColor = AppColors.statusDanger;
    } else {
      instruction = 'Rute terbentuk. Ketuk peta untuk rute baru.';
      dotColor = AppColors.statusInfo;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenPrimary),
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 1. Peta FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14.0,
              minZoom: 9.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) => _handleMapTap(point),
            ),
            children: [
              // Lapisan OpenStreetMap Tile
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.laporkita.app',
              ),

              // Garis Rute (Polyline)
              if (_route != null && _route!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.points,
                      strokeWidth: 5.0,
                      color: AppColors.greenPrimary,
                    ),
                  ],
                ),

              // Marker Asal & Tujuan
              MarkerLayer(
                markers: [
                  if (_origin != null)
                    Marker(
                      point: _origin!,
                      width: 70,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: _buildMarkerPin(
                        label: 'Asal',
                        color: AppColors.greenPrimary,
                        icon: Icons.location_on_rounded,
                      ),
                    ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 70,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: _buildMarkerPin(
                        label: 'Tujuan',
                        color: AppColors.statusDanger,
                        icon: Icons.location_on_rounded,
                      ),
                    ),
                ],
              ),

              // Atribusi wajib OpenStreetMap
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // 2. Header Bagian Atas (Tombol Kembali, Judul, Pill Status)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Kembali
                    Material(
                      color: AppColors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.neutral900,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    // Label Judul Halaman
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            color: AppColors.greenPrimary,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Peta Rute Navigasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Reset / Bersihkan
                    Material(
                      color: AppColors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _resetPoints,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.neutral700,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                _buildInstructionPill(),
              ],
            ),
          ),

          // 3. Loading Indicator Overlay
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.greenPrimary),
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Menghitung rute...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Kartu Ringkasan Rute di Bagian Bawah
          if (_route != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: RouteSummaryCard(
                route: _route!,
                onReset: _resetPoints,
              ),
            ),
        ],
      ),
    );
  }
}
