import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/routing_repository.dart';
import '../../reports/bloc/report_bloc.dart';
import 'widgets/location_picker_sheet.dart';
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

enum MapPickingTarget {
  none,
  origin,
  destination,
}

/// Layar Navigasi lengkap dengan kustomisasi Lokasi A dan B (Live OSRM).
class RoutePickerScreen extends StatefulWidget {
  final LatLng? initialOrigin;
  final String? initialOriginName;
  final LatLng? initialDestination;
  final String? initialDestinationName;

  const RoutePickerScreen({
    super.key,
    this.initialOrigin,
    this.initialOriginName,
    this.initialDestination,
    this.initialDestinationName,
  });

  @override
  State<RoutePickerScreen> createState() => _RoutePickerScreenState();
}

class _RoutePickerScreenState extends State<RoutePickerScreen> {
  final MapController _mapController = MapController();
  final TtsService _ttsService = TtsService();

  NavigationScreenMode _currentMode = NavigationScreenMode.routePlanning;
  MapPickingTarget _mapPickingTarget = MapPickingTarget.none;
  int _selectedRouteIndex = 0;
  bool _isSoundMuted = false;
  bool _isLoadingRoute = false;
  bool _isLocatingUser = false;
  bool _hasTriggeredHazardVoice = false;

  // Koordinat Asal (Titik A) & Tujuan (Titik B)
  late LatLng _origin;
  late LatLng _destination;

  late String _originName;
  late String _destinationName;

  List<RouteModel> _routes = [];
  RouteModel? _activeRoute;
  List<LatLng> _altRoutePoints = [];

  // Data peringatan jalan rusak backend yang sedang aktif/didekati
  ReportModel? _activeHazardReport;
  int _activeHazardDistance = 10;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _origin = widget.initialOrigin ?? const LatLng(-7.9443, 112.6156);
    _destination = widget.initialDestination ?? const LatLng(-7.9827, 112.6304);
    _originName = widget.initialOriginName ??
        (widget.initialOrigin != null ? 'Titik Awal' : 'Mendeteksi lokasi Anda...');
    _destinationName = widget.initialDestinationName ?? 'Alun Alun Malang';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportBloc>().add(const ReportLoadRequested());
      if (widget.initialOrigin == null) {
        _detectDefaultUserLocation();
      } else {
        _fetchRoutesFromOsrm();
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  /// Mendeteksi posisi GPS pengguna sebagai titik awal default saat pertama kali dibuka
  Future<void> _detectDefaultUserLocation() async {
    setState(() => _isLocatingUser = true);

    // Muat rute awal terlebih dahulu dengan koordinat default agar layar tidak kosong
    _fetchRoutesFromOsrm();

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _originName = 'Lokasi Anda (Jl. Soekarno Hatta)';
            _isLocatingUser = false;
          });
        }
        return;
      }

      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        if (mounted) {
          setState(() {
            _originName = 'Lokasi Anda (Jl. Soekarno Hatta)';
            _isLocatingUser = false;
          });
        }
        return;
      }

      // Cek posisi terakhir (last known) untuk update instan jika ada
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final lastPoint = LatLng(lastKnown.latitude, lastKnown.longitude);
        setState(() {
          _origin = lastPoint;
        });
        _fetchRoutesFromOsrm();
      }

      // Ambil posisi akurat real-time
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      if (!mounted) return;

      final currentPoint = LatLng(pos.latitude, pos.longitude);
      final placeName = await _reverseGeocode(currentPoint);
      final displayOrigin = placeName.startsWith('Titik Peta')
          ? 'Lokasi Anda Saat Ini'
          : 'Lokasi Anda ($placeName)';

      setState(() {
        _origin = currentPoint;
        _originName = displayOrigin;
        _isLocatingUser = false;
      });

      _fetchRoutesFromOsrm();
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_originName == 'Mendeteksi lokasi Anda...') {
            _originName = 'Lokasi Anda (Jl. Soekarno Hatta)';
          }
          _isLocatingUser = false;
        });
      }
    }
  }

  /// Menengahkan kamera dan memperbarui titik awal ke lokasi GPS terkini
  Future<void> _recenterToCurrentLocation() async {
    setState(() => _isLocatingUser = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      final currentPoint = LatLng(pos.latitude, pos.longitude);
      final placeName = await _reverseGeocode(currentPoint);
      final displayOrigin = placeName.startsWith('Titik Peta')
          ? 'Lokasi Anda Saat Ini'
          : 'Lokasi Anda ($placeName)';

      setState(() {
        _origin = currentPoint;
        _originName = displayOrigin;
        _isLocatingUser = false;
      });

      _mapController.move(currentPoint, 15.0);
      _fetchRoutesFromOsrm();
      _checkHazardProximity(currentPoint);
    } catch (_) {
      if (mounted) {
        setState(() => _isLocatingUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat memperoleh koordinat GPS terkini'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Memanggil endpoint live backend OSRM untuk mendapatkan rute utama dan alternatif
  Future<void> _fetchRoutesFromOsrm() async {
    setState(() => _isLoadingRoute = true);

    try {
      final repository = context.read<RoutingRepository>();
      final results = await repository.getRoutes(
        origin: _origin,
        destination: _destination,
        alternatives: true,
      );

      if (!mounted) return;

      setState(() {
        _routes = results;
        _activeRoute = results.isNotEmpty ? results.first : null;
        if (results.length > 1) {
          _altRoutePoints = results[1].points;
        } else if (_activeRoute != null && _activeRoute!.points.length > 1) {
          _generateSyntheticAlternative(_activeRoute!.points);
        }
        _isLoadingRoute = false;
      });

      _fitCameraToRoute();
    } catch (_) {
      if (!mounted) return;

      // Fallback jika demo server OSRM sedang offline
      final fallbackRoute = RouteModel(
        points: [_origin, _destination],
        distanceMeters: 4600.0,
        durationSeconds: 720.0,
        summary: 'Jl. Soekarno Hatta, Jl. Ahmad Yani',
        steps: const [
          RouteStep(
            name: 'Jl. Ahmad Habibi',
            distanceMeters: 150.0,
            durationSeconds: 25.0,
            maneuverType: 'turn',
            maneuverModifier: 'left',
          ),
          RouteStep(
            name: 'Jl. Soekarno Hatta',
            distanceMeters: 1200.0,
            durationSeconds: 160.0,
            maneuverType: 'new name',
            maneuverModifier: 'straight',
          ),
        ],
      );

      setState(() {
        _routes = [fallbackRoute];
        _activeRoute = fallbackRoute;
        _generateSyntheticAlternative(fallbackRoute.points);
        _isLoadingRoute = false;
      });

      _fitCameraToRoute();
    }
  }

  void _generateSyntheticAlternative(List<LatLng> mainPoints) {
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
            top: 180,
            bottom: 300,
            left: 48,
            right: 48,
          ),
        ),
      );
    } catch (_) {}
  }

  /// Buka dialog kustomisasi lokasi A atau B
  void _openLocationPicker(bool isOrigin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return LocationPickerSheet(
          title: isOrigin ? 'Pilih Titik Asal (A)' : 'Pilih Titik Tujuan (B)',
          isOrigin: isOrigin,
          onPlaceSelected: (place) {
            setState(() {
              if (isOrigin) {
                _origin = place.location;
                _originName = place.name;
              } else {
                _destination = place.location;
                _destinationName = place.name;
              }
              _mapPickingTarget = MapPickingTarget.none;
            });
            _fetchRoutesFromOsrm();
          },
          onPickOnMap: () {
            setState(() {
              _mapPickingTarget = isOrigin
                  ? MapPickingTarget.origin
                  : MapPickingTarget.destination;
            });
          },
        );
      },
    );
  }

  /// Reverse geocoding koordinat ke nama jalan/tempat
  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.trim().isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.first!;
      }
    } catch (_) {}
    return 'Titik Peta (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})';
  }

  /// Menangani interaksi tap peta untuk memilih titik asal/tujuan baru
  void _handleMapTap(LatLng point) async {
    if (_currentMode != NavigationScreenMode.routePlanning) return;

    final placeName = await _reverseGeocode(point);

    setState(() {
      if (_mapPickingTarget == MapPickingTarget.origin) {
        _origin = point;
        _originName = placeName;
        _mapPickingTarget = MapPickingTarget.none;
      } else {
        // Default tap mengubah tujuan (Titik B)
        _destination = point;
        _destinationName = placeName;
        _mapPickingTarget = MapPickingTarget.none;
      }
    });

    _fetchRoutesFromOsrm();
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
      _mapPickingTarget = MapPickingTarget.none;
    });
    _fetchRoutesFromOsrm();
  }

  /// Memilih salah satu rute dari kartu opsi
  void _selectRoute(int index) {
    setState(() {
      _selectedRouteIndex = index;
      if (index < _routes.length) {
        _activeRoute = _routes[index];
      }
    });
    _fitCameraToRoute();
  }

  /// Menghasilkan item kartu rute dinamis sesuai respons OSRM
  List<RouteOptionItem> _buildRouteOptionItems() {
    if (_routes.isEmpty) return NavigationRouteSheet.defaultRoutes;

    return List.generate(_routes.length, (i) {
      final route = _routes[i];
      final isFirst = i == 0;
      final warnings = isFirst ? 2 : (i == 1 ? 0 : 1);
      final riskColor = warnings >= 2
          ? AppColors.statusDanger
          : (warnings == 0 ? AppColors.greenPrimary : AppColors.statusPending);

      return RouteOptionItem(
        index: i,
        title: isFirst ? 'Rute Tercepat' : 'Rute Alternatif $i',
        riskTitle: isFirst
            ? 'Rute awal (ada resiko)'
            : (warnings == 0
                ? 'Rute Alternatif $i (lebih aman)'
                : 'Hindari Alternatif $i'),
        durationKm: '${route.durationMinutes} - ${route.distanceKm}',
        warningCountText: '$warnings peringatan',
        riskColor: riskColor,
        warnings: warnings,
      );
    });
  }

  /// Mulai navigasi aktif (Transisi ke Figma 462:126)
  void _startNavigation() {
    setState(() {
      _currentMode = NavigationScreenMode.activeNavigation;
      _mapPickingTarget = MapPickingTarget.none;
      _hasTriggeredHazardVoice = false;
    });
    _mapController.move(_origin, 16.5);

    if (!_isSoundMuted) {
      final firstStep =
          (_activeRoute?.steps.isNotEmpty ?? false) ? _activeRoute!.steps.first : null;
      if (firstStep != null) {
        _ttsService.speakInstruction(
          instruction: firstStep.instructionText,
          distanceText: '${firstStep.distanceMeters.round()} meter',
        );
      } else {
        _ttsService.speak('Mulai navigasi menuju $_destinationName. Ikuti rute yang ditandai di peta.');
      }
    }
  }

  /// Peringatan suara dan visual saat mendekati jalan rusak / berlubang (Figma 464:837)
  void _triggerHazardAlert({
    String hazard = 'Jalan Berlubang',
    int distance = 10,
    String? street,
  }) {
    _hasTriggeredHazardVoice = true;
    setState(() {
      _currentMode = NavigationScreenMode.hazardAlert;
    });

    if (!_isSoundMuted) {
      _ttsService.speakHazardAlert(
        hazardType: hazard,
        distanceMeters: distance,
        streetName: street ?? 'Jl. Soekarno Hatta',
      );
    }
  }

  /// Peringatan suara dan banner saat telah melewati titik bahaya (Figma 471:1467)
  void _triggerHazardPassed() {
    setState(() {
      _currentMode = NavigationScreenMode.hazardPassed;
    });

    if (!_isSoundMuted) {
      _ttsService.speakHazardPassed();
    }
  }

  /// Memeriksa jarak pengguna ke titik bahaya terdekat untuk memicu peringatan otomatis
  void _checkHazardProximity(LatLng currentPosition) {
    if (_currentMode != NavigationScreenMode.activeNavigation) return;
    if (_hasTriggeredHazardVoice) return;

    for (final hazard in _hazardPoints) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        hazard.latitude,
        hazard.longitude,
      );

      // Jika dalam radius 50 meter dari titik lubang, picu alert suara & visual otomatis
      if (distance <= 50.0) {
        _triggerHazardAlert(
          hazard: 'Jalan Berlubang',
          distance: distance.round() < 15 ? 10 : distance.round(),
          street: 'Jl. Soekarno Hatta',
        );
        break;
      }
    }
  }

  /// Keluar dari mode navigasi kembali ke perencanaan
  void _exitNavigation() {
    _ttsService.stop();
    setState(() {
      _currentMode = NavigationScreenMode.routePlanning;
    });
    _fitCameraToRoute();
  }

  /// Marker Puck Navigasi User (Lingkaran konsentris atau panah arah)
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
    final firstStep =
        (_activeRoute?.steps.isNotEmpty ?? false) ? _activeRoute!.steps.first : null;
    final nextStep =
        ((_activeRoute?.steps.length ?? 0) > 1) ? _activeRoute!.steps[1] : null;

    final stepName =
        (firstStep?.name.isNotEmpty ?? false) ? firstStep!.name : 'Jl. Ahmad Habibi';
    final nextStreet =
        (nextStep?.name.isNotEmpty ?? false) ? 'ke ${nextStep!.name}' : 'ke Jl. Soekarno Hatta';
    final stepDistance =
        firstStep != null ? '${firstStep.distanceMeters.round()}m' : '150m';
    final maneuverIcon = firstStep?.maneuverIcon ?? Icons.turn_left_rounded;

    final durationText = _activeRoute?.durationMinutes ?? '12 Menit';
    final etaText =
        '${_activeRoute?.distanceKm ?? "4,6 km"} - ${_activeRoute?.etaFormatted ?? "09.53"}';

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
              onTap: (tapPosition, point) => _handleMapTap(point),
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

              // Garis Rute Utama (Biru Navigasi OSRM, Figma 454:2 & 462:126)
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
                  // Posisi Asal (Titik A)
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

                  // Pin Tujuan Merah (Titik B)
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

                  // Marker Peringatan Bahaya Jalan Rusak
                  ..._hazardPoints.map(
                    (point) => Marker(
                      point: point,
                      width: 38,
                      height: 38,
                      child: GestureDetector(
                        onTap: () {
                          _triggerHazardAlert(
                            hazard: 'Jalan Berlubang',
                            distance: 10,
                            street: stepName,
                          );
                        },
                        child: const Icon(
                          Icons.warning_rounded,
                          color: AppColors.statusPending,
                          size: 34,
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
                isPickingOrigin: _mapPickingTarget == MapPickingTarget.origin,
                isPickingDestination:
                    _mapPickingTarget == MapPickingTarget.destination,
                isLocatingOrigin: _isLocatingUser,
                onBack: () => Navigator.of(context).maybePop(),
                onSwap: _swapLocations,
                onTapOrigin: () => _openLocationPicker(true),
                onTapDestination: () => _openLocationPicker(false),
              ),
            )
          else if (_currentMode == NavigationScreenMode.activeNavigation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavigationActiveTopBanner(
                state: NavigationBannerState.turnByTurn,
                distanceText: stepDistance,
                primaryText: stepName,
                secondaryText: nextStreet,
                maneuverIcon: maneuverIcon,
                onMicTap: () {
                  if (_isSoundMuted) {
                    setState(() => _isSoundMuted = false);
                    _ttsService.speak('Panduan suara diaktifkan');
                  } else {
                    final first = (_activeRoute?.steps.isNotEmpty ?? false)
                        ? _activeRoute!.steps.first
                        : null;
                    if (first != null) {
                      _ttsService.speakInstruction(
                        instruction: first.instructionText,
                        distanceText: '${first.distanceMeters.round()} meter',
                      );
                    } else {
                      _ttsService.speak('Lanjutkan mengikuti rute.');
                    }
                  }
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

          // 2b. Pill Panduan jika sedang mode "Pilih di Peta"
          if (_mapPickingTarget != MapPickingTarget.none &&
              _currentMode == NavigationScreenMode.routePlanning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.neutral900.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _mapPickingTarget == MapPickingTarget.origin
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      color: _mapPickingTarget == MapPickingTarget.origin
                          ? AppColors.statusInfo
                          : AppColors.statusDanger,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _mapPickingTarget == MapPickingTarget.origin
                            ? 'Ketuk peta untuk menentukan Titik Asal (A)'
                            : 'Ketuk peta untuk menentukan Titik Tujuan (B)',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _mapPickingTarget = MapPickingTarget.none);
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Kolom Tombol Mengapung di Sisi Kanan (Figma 454:2)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.22,
            child: NavigationFloatingTools(
              isSoundMuted: _isSoundMuted,
              onSearch: () => _openLocationPicker(false),
              onToggleSound: () {
                setState(() => _isSoundMuted = !_isSoundMuted);
                if (_isSoundMuted) {
                  _ttsService.stop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Suara panduan navigasi dinonaktifkan'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  _ttsService.speak('Suara panduan diaktifkan');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Suara panduan navigasi diaktifkan'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              onToggleLayers: () {
                setState(() {
                  _selectedRouteIndex =
                      (_selectedRouteIndex + 1) % (_routes.isEmpty ? 3 : _routes.length);
                  if (_selectedRouteIndex < _routes.length) {
                    _activeRoute = _routes[_selectedRouteIndex];
                  }
                });
                _fitCameraToRoute();
              },
              onCompass: () {
                _mapController.rotate(0);
              },
              onMyLocation: _recenterToCurrentLocation,
            ),
          ),

          // 4. Tombol "Mulai Navigasi" Mengapung di atas Bottom Sheet (Figma 454:2)
          if (_currentMode == NavigationScreenMode.routePlanning)
            Positioned(
              left: 24,
              right: 24,
              bottom: 290,
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
                customRoutes: _buildRouteOptionItems(),
                showRiskBadges: true,
                onSelectRoute: _selectRoute,
              ),
            )
          else if (_currentMode == NavigationScreenMode.activeNavigation)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationActiveBottomBar(
                durationText: durationText,
                distanceEtaText: etaText,
                onClose: _exitNavigation,
                onRoutesToggle: () {
                  _triggerHazardAlert(
                    hazard: 'Jalan Berlubang',
                    distance: 10,
                    street: stepName,
                  );
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
                streetName: stepName,
                severityLevel: 'Sedang',
                onDismiss: _triggerHazardPassed,
                onViewDetail: () {
                  _triggerHazardPassed();
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
