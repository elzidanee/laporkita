import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/routing_repository.dart';
import '../../reports/bloc/report_bloc.dart';
import 'widgets/navigation_active_bottom_bar.dart';
import 'widgets/navigation_active_top_banner.dart';
import 'widgets/navigation_floating_tools.dart';
import 'widgets/navigation_hazard_dialog.dart';
import 'widgets/navigation_route_sheet.dart';
import 'widgets/navigation_top_bar.dart';

enum NavigationScreenMode {
  routePlanning,
  activeNavigation,
  hazardAlert,
  hazardPassed,
}

/// Layar Navigasi lengkap yang mengimplementasikan 5 desain Figma:
/// - Figma 454:2 & 471:4186: Peta perencanaan rute, pilihan resiko jalan rusak, tombol "Mulai Navigasi".
/// - Figma 462:126: Navigasi aktif turn-by-turn.
/// - Figma 464:837: Proximity alert bahaya jalan berlubang.
/// - Figma 471:1467: Lokasi bahaya telah dilewati.
class RoutePickerScreen extends StatefulWidget {
  const RoutePickerScreen({super.key});

  @override
  State<RoutePickerScreen> createState() => _RoutePickerScreenState();
}

class _RoutePickerScreenState extends State<RoutePickerScreen> {
  final MapController _mapController = MapController();

  NavigationScreenMode _currentMode = NavigationScreenMode.routePlanning;
  int _selectedRouteIndex = 0;
  bool _isSoundMuted = false;
  bool _isLoadingRoute = false;

  // Koordinat Asal (Jl. Soekarno Hatta) & Tujuan (Alun-Alun Malang)
  LatLng _origin = const LatLng(-7.9443, 112.6156);
  LatLng _destination = const LatLng(-7.9827, 112.6304);

  String _originName = 'Lokasi Anda (Jl. Soekarno Hatta)';
  String _destinationName = 'Alun Alun Malang';

  RouteModel? _activeRoute;
  List<LatLng> _altRoutePoints = [];

  // Peringatan jalan rusak di sepanjang rute
  final List<LatLng> _hazardPoints = const [
    LatLng(-7.9540, 112.6200),
    LatLng(-7.9650, 112.6240),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportBloc>().add(const ReportLoadRequested());
      _fetchInitialRoute();
    });
  }

  /// Kalkulasi rute riil via OSRM
  Future<void> _fetchInitialRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      final repository = context.read<RoutingRepository>();
      final result = await repository.getRoute(
        origin: _origin,
        destination: _destination,
      );

      if (!mounted) return;

      setState(() {
        _activeRoute = result;
        _generateAlternativePath(result.points);
        _isLoadingRoute = false;
      });

      _fitCameraToRoute();
    } catch (_) {
      // Fallback jika demo server OSRM offline/timeout
      if (!mounted) return;
      setState(() {
        _activeRoute = RouteModel(
          points: [
            _origin,
            const LatLng(-7.9520, 112.6180),
            const LatLng(-7.9620, 112.6230),
            const LatLng(-7.9720, 112.6270),
            _destination,
          ],
          distanceMeters: 4600.0,
          durationSeconds: 720.0,
        );
        _generateAlternativePath(_activeRoute!.points);
        _isLoadingRoute = false;
      });
      _fitCameraToRoute();
    }
  }

  /// Menghasilkan jalur rute alternatif untuk visualisasi peta (Figma 471:4186)
  void _generateAlternativePath(List<LatLng> mainPoints) {
    if (mainPoints.length < 2) return;
    _altRoutePoints = mainPoints.map((p) {
      return LatLng(p.latitude - 0.003, p.longitude + 0.004);
    }).toList();
  }

  void _fitCameraToRoute() {
    if (_activeRoute == null || _activeRoute!.points.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints(_activeRoute!.points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 170,
            bottom: 300,
            left: 48,
            right: 48,
          ),
        ),
      );
    } catch (_) {}
  }

  /// Tukar lokasi asal dan tujuan
  void _swapLocations() {
    setState(() {
      final tempLoc = _origin;
      _origin = _destination;
      _destination = tempLoc;

      final tempName = _originName;
      _originName = _destinationName;
      _destinationName = tempName;
    });
    _fetchInitialRoute();
  }

  /// Mulai navigasi aktif (Transisi ke Figma 462:126)
  void _startNavigation() {
    setState(() {
      _currentMode = NavigationScreenMode.activeNavigation;
    });
    _mapController.move(_origin, 16.5);
  }

  /// Keluar dari mode navigasi kembali ke perencanaan
  void _exitNavigation() {
    setState(() {
      _currentMode = NavigationScreenMode.routePlanning;
    });
    _fitCameraToRoute();
  }

  /// Marker Puck Navigasi User (Lingkaran konsentris biru atau panah arah)
  Widget _buildUserPuck() {
    if (_currentMode == NavigationScreenMode.routePlanning) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.navPuckBorder.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.navRouteBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Puck navigasi aktif dengan panah arah (Figma 462:126)
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navPuckBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.navigation_rounded,
          color: AppColors.navRouteBlue,
          size: 26,
        ),
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
              initialCenter: _origin,
              initialZoom: 14.5,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // Lapisan OpenStreetMap Tile
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.laporkita.app',
              ),

              // Garis Rute Alternatif (Abu-abu, Figma 471:4186)
              if (_altRoutePoints.isNotEmpty &&
                  _currentMode == NavigationScreenMode.routePlanning)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _altRoutePoints,
                      strokeWidth: 5.0,
                      color: AppColors.navRouteAlt.withValues(alpha: 0.75),
                    ),
                  ],
                ),

              // Garis Rute Utama (Biru Navigasi, Figma 454:2 & 462:126)
              if (_activeRoute != null && _activeRoute!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _activeRoute!.points,
                      strokeWidth: 6.0,
                      color: AppColors.navRouteBlue,
                    ),
                  ],
                ),

              // Marker Layer: User Puck, Pin Tujuan & Segitiga Bahaya
              MarkerLayer(
                markers: [
                  // Posisi User
                  Marker(
                    point: _currentMode == NavigationScreenMode.hazardPassed
                        ? (_activeRoute?.points.length ?? 0) > 3
                            ? _activeRoute!.points[2]
                            : _origin
                        : _origin,
                    width: 44,
                    height: 44,
                    child: _buildUserPuck(),
                  ),

                  // Pin Tujuan Merah (Figma 454:2)
                  Marker(
                    point: _destination,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.statusDanger,
                      size: 40,
                    ),
                  ),

                  // Marker Peringatan Bahaya (Figma 462:126 & 464:837)
                  ..._hazardPoints.map(
                    (point) => Marker(
                      point: point,
                      width: 38,
                      height: 38,
                      child: GestureDetector(
                        onTap: () {
                          // Klik marker bahaya memunculkan modal peringatan (Figma 464:837)
                          setState(() {
                            _currentMode = NavigationScreenMode.hazardAlert;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: AppColors.statusPending,
                            size: 34,
                          ),
                        ),
                      ),
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

          // 2. Header Atas: Sesuai Mode Aktif
          if (_currentMode == NavigationScreenMode.routePlanning)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavigationTopBar(
                originText: _originName,
                destinationText: _destinationName,
                onBack: () => Navigator.of(context).maybePop(),
                onSwap: _swapLocations,
              ),
            )
          else if (_currentMode == NavigationScreenMode.activeNavigation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavigationActiveTopBanner(
                state: NavigationBannerState.turnByTurn,
                distanceText: '150m',
                primaryText: 'Jl. Ahmad Habibi',
                secondaryText: 'ke Jl. Soekarno Hatta',
                onMicTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Panduan suara diaktifkan')),
                  );
                },
              ),
            )
          else if (_currentMode == NavigationScreenMode.hazardAlert)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const NavigationActiveTopBanner(
                state: NavigationBannerState.hazardApproaching,
                distanceText: '10 meter',
                primaryText: '10 meter',
                secondaryText: 'Jalan Berlubang',
              ),
            )
          else if (_currentMode == NavigationScreenMode.hazardPassed)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const NavigationActiveTopBanner(
                state: NavigationBannerState.hazardPassed,
                distanceText: '450m',
                primaryText: 'Lokasi telah dilewati',
                secondaryText:
                    'Tetap berhati-hati dan perhatikan kondisi jalan di depan.',
                maneuverIcon: Icons.turn_right_rounded,
              ),
            ),

          // 3. Kolom Tombol Mengapung di Sisi Kanan (Figma 454:2)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.22,
            child: NavigationFloatingTools(
              isSoundMuted: _isSoundMuted,
              onSearch: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pencarian fasilitas rute')),
                );
              },
              onToggleSound: () {
                setState(() => _isSoundMuted = !_isSoundMuted);
              },
              onToggleLayers: () {
                setState(() {
                  _selectedRouteIndex = (_selectedRouteIndex + 1) % 3;
                });
              },
              onCompass: () {
                _mapController.rotate(0);
              },
            ),
          ),

          // 4. Tombol "Mulai Navigasi" Mengapung di atas Bottom Sheet (Figma 454:2)
          if (_currentMode == NavigationScreenMode.routePlanning)
            Positioned(
              left: 24,
              right: 24,
              bottom: 300,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoadingRoute ? null : _startNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenPrimary,
                    foregroundColor: AppColors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoadingRoute
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white),
                          ),
                        )
                      : const Text(
                          'Mulai Navigasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),

          // 5. Panel Bagian Bawah Sesuai Mode
          if (_currentMode == NavigationScreenMode.routePlanning)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationRouteSheet(
                selectedIndex: _selectedRouteIndex,
                showRiskBadges: true,
                onSelectRoute: (idx) {
                  setState(() => _selectedRouteIndex = idx);
                },
              ),
            )
          else if (_currentMode == NavigationScreenMode.activeNavigation)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationActiveBottomBar(
                durationText: '12 Menit',
                distanceEtaText: '4,6 km - 09.53',
                onClose: _exitNavigation,
                onRoutesToggle: () {
                  // Simulasi mendekati bahaya jalan rusak (Figma 464:837)
                  setState(() {
                    _currentMode = NavigationScreenMode.hazardAlert;
                  });
                },
              ),
            )
          else if (_currentMode == NavigationScreenMode.hazardAlert)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationHazardDialog(
                title: 'Jalan Berlubang',
                distanceRemaining: '10 meter lagi',
                streetName: 'Jl. Soekarno Hatta',
                severityLevel: 'Sedang',
                onDismiss: () {
                  setState(() {
                    _currentMode = NavigationScreenMode.hazardPassed;
                  });
                },
                onViewDetail: () {
                  setState(() {
                    _currentMode = NavigationScreenMode.hazardPassed;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka detail laporan fasilitas rusak...'),
                    ),
                  );
                },
              ),
            )
          else if (_currentMode == NavigationScreenMode.hazardPassed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationActiveBottomBar(
                durationText: '8 Menit',
                distanceEtaText: '3,2 km - 09.49',
                onClose: _exitNavigation,
                onRoutesToggle: () {
                  setState(() {
                    _currentMode = NavigationScreenMode.activeNavigation;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
