import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

class PlaceItem {
  final String name;
  final String address;
  final LatLng location;
  final IconData icon;

  const PlaceItem({
    required this.name,
    required this.address,
    required this.location,
    this.icon = Icons.location_on_outlined,
  });
}

/// Bottom Sheet untuk memilih lokasi A atau B secara kustom:
/// - Pencarian teks / geocoding
/// - Deteksi GPS lokasi saat ini
/// - Pemilihan langsung di peta
/// - Daftar tempat populer di Kota Malang
class LocationPickerSheet extends StatefulWidget {
  final String title;
  final bool isOrigin;
  final ValueChanged<PlaceItem> onPlaceSelected;
  final VoidCallback onPickOnMap;

  const LocationPickerSheet({
    super.key,
    required this.title,
    required this.isOrigin,
    required this.onPlaceSelected,
    required this.onPickOnMap,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingGps = false;
  bool _isSearching = false;
  List<PlaceItem> _searchResults = [];

  // Tempat populer default di Kota Malang
  static const List<PlaceItem> _popularPlaces = [
    PlaceItem(
      name: 'Alun-Alun Kota Malang',
      address: 'Jl. Merdeka Selatan, Klojen, Kota Malang',
      location: LatLng(-7.9827, 112.6304),
      icon: Icons.park_outlined,
    ),
    PlaceItem(
      name: 'Stasiun Malang Kota Baru',
      address: 'Jl. Trunojoyo No.10, Klojen, Kota Malang',
      location: LatLng(-7.9772, 112.6385),
      icon: Icons.train_outlined,
    ),
    PlaceItem(
      name: 'Universitas Brawijaya (UB)',
      address: 'Jl. Veteran, Ketawanggede, Lowokwaru',
      location: LatLng(-7.9525, 112.6144),
      icon: Icons.school_outlined,
    ),
    PlaceItem(
      name: 'Jl. Soekarno Hatta (Suhat)',
      address: 'Kec. Lowokwaru, Kota Malang',
      location: LatLng(-7.9443, 112.6156),
      icon: Icons.alt_route_rounded,
    ),
    PlaceItem(
      name: 'Malang Town Square (MATOS)',
      address: 'Jl. Veteran No.2, Penanggungan, Klojen',
      location: LatLng(-7.9575, 112.6186),
      icon: Icons.shopping_bag_outlined,
    ),
    PlaceItem(
      name: 'Balai Kota Malang',
      address: 'Jl. Tugu No.1, Kiduldalem, Klojen',
      location: LatLng(-7.9786, 112.6343),
      icon: Icons.account_balance_outlined,
    ),
    PlaceItem(
      name: 'Terminal Arjosari',
      address: 'Arjosari, Blimbing, Kota Malang',
      location: LatLng(-7.9318, 112.6583),
      icon: Icons.directions_bus_outlined,
    ),
    PlaceItem(
      name: 'Pasar Besar Malang',
      address: 'Jl. Pasar Besar, Sukoharjo, Klojen',
      location: LatLng(-7.9870, 112.6315),
      icon: Icons.storefront_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = _popularPlaces;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cari tempat berdasarkan input pengguna
  Future<void> _handleSearch(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      setState(() {
        _searchResults = _popularPlaces;
        _isSearching = false;
      });
      return;
    }

    // 1. Filter dari daftar populer lokal
    final localMatches = _popularPlaces.where((p) {
      return p.name.toLowerCase().contains(clean) ||
          p.address.toLowerCase().contains(clean);
    }).toList();

    setState(() {
      _searchResults = localMatches;
      _isSearching = true;
    });

    // 2. Geocoding online jika hasil lokal sedikit
    if (clean.length > 3) {
      try {
        final locations = await Geocoding().locationFromAddress('$query, Malang');
        if (locations.isNotEmpty && mounted) {
          final first = locations.first;
          final geoItem = PlaceItem(
            name: query,
            address: 'Hasil pencarian lokasi di Malang',
            location: LatLng(first.latitude, first.longitude),
            icon: Icons.search_rounded,
          );

          setState(() {
            _searchResults = [geoItem, ...localMatches];
          });
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isSearching = false);
  }

  /// Deteksi posisi GPS terkini perangkat
  Future<void> _useCurrentGpsLocation() async {
    setState(() => _isLoadingGps = true);

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

      String addressName = 'Lokasi Saya Saat Ini';
      try {
        final marks = await Geocoding().placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (marks.isNotEmpty) {
          final p = marks.first;
          final parts = [p.street, p.subLocality, p.locality]
              .where((s) => s != null && s.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) addressName = parts.join(', ');
        }
      } catch (_) {}

      if (!mounted) return;

      final place = PlaceItem(
        name: 'Lokasi Saya (GPS)',
        address: addressName,
        location: LatLng(pos.latitude, pos.longitude),
        icon: Icons.my_location_rounded,
      );

      widget.onPlaceSelected(place);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat mengambil lokasi GPS saat ini.'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Judul & Tombol Tutup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.neutral500),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.neutral500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      decoration: const InputDecoration(
                        hintText: 'Cari alamat, jalan, atau nama tempat...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral500,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: AppColors.neutral400,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Opsi Cepat: Gunakan GPS & Pilih di Peta
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Tombol GPS
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isLoadingGps ? null : _useCurrentGpsLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInfo,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.statusInfo.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoadingGps)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.statusInfo),
                              ),
                            )
                          else
                            const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.statusInfo,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          const Text(
                            'Lokasi Saya',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusInfo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Pilih di Peta
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onPickOnMap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSuccess,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.greenPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: AppColors.greenPrimary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pilih di Peta',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),

          // Daftar Tempat Populer / Hasil Pencarian
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.greenPrimary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, index) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neutral50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: widget.isOrigin
                                ? AppColors.statusInfo
                                : AppColors.statusDanger,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        subtitle: Text(
                          item.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.neutral400,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onPlaceSelected(item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
