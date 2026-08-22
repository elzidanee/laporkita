import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../report_detail/report_detail_screen.dart';
import '../map/map_tab_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenPrimary,
      body: Stack(
        children: [
          // Screen body tab content
          IndexedStack(
            index: _currentIndex,
            children: [
              const CitizenDashboardTab(),
              const CitizenPetaTab(),
              const CitizenLaporTab(),
              const CitizenNotifikasiTab(),
              const CitizenProfileTab(),
            ],
          ),

          // Custom Floating Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCustomBottomNavBar(),
          ),
        ],
      ),
    );
  }

  /// Custom Bottom Navigation Bar matching Screenshot 2
  Widget _buildCustomBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, math.max(10.0, bottomPadding)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. Dashboard
          _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Dashboard'),

          // 2. Peta
          _buildNavItem(index: 1, icon: Icons.map_outlined, label: 'Peta'),

          // 3. Lapor (Center Prominent Green Camera Button)
          _buildCenterLaporItem(),

          // 4. Notifikasi
          _buildNavItem(
            index: 3,
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
          ),

          // 5. Profile
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Regular Nav Item (Icon + Text)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.greenPrimary : AppColors.neutral500;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Center Floating Camera Button ("Lapor")
  Widget _buildCenterLaporItem() {
    final isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/camera');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Circular Green Camera Button
          Transform.translate(
            offset: const Offset(0, -14), // Lift button above bottom navbar
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.greenPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenPrimary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              'Lapor',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: AppColors.greenPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 0: CITIZEN DASHBOARD (Matching Screenshot 1)
// =============================================================================
class CitizenDashboardTab extends StatefulWidget {
  const CitizenDashboardTab({super.key});

  @override
  State<CitizenDashboardTab> createState() => _CitizenDashboardTabState();
}

class _CitizenDashboardTabState extends State<CitizenDashboardTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Top Green Header Section
        SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.greenPrimary,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hallo!, selamat datang',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kalandra !',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ayo jaga kota kita bersama!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo LK Top Right
                Image.asset(
                  'assets/images/logoLK.png',
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'LK',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. White Curved Container with Dashboard Widgets
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar & Hamburger Menu Row
                    _buildSearchBarRow(),
                    const SizedBox(height: 16),

                    // Urban Health Score Gauge Card
                    _buildUrbanHealthScoreCard(),
                    const SizedBox(height: 16),

                    // 3 Stat Cards Row (12 Laporan Saya, 8 Sedang diproses, 5 Laporan selesai)
                    _buildStatCardsRow(),
                    const SizedBox(height: 24),

                    // Kategori Section Header & Grid/Row
                    _buildKategoriSection(),
                    const SizedBox(height: 24),

                    // Laporan Terdekat Section Header & List Cards
                    _buildLaporanTerdekatSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Search Bar + Green Hamburger Button Row
  Widget _buildSearchBarRow() {
    return Row(
      children: [
        // Search TextField Input
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari laporan, kategori, lokasi..',
                hintStyle: TextStyle(color: AppColors.neutral500, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.neutral500,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Green Hamburger Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.greenPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /// Urban Health Score Card with Arc Gauge Meter
  Widget _buildUrbanHealthScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Left City Dropdown
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Kota Malang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.neutral900,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Arc Gauge Gauge Meter (Semi circle arc gauge painter)
          SizedBox(
            width: 180,
            height: 95,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(180, 90),
                  painter: UrbanHealthArcPainter(percentage: 0.78),
                ),
                Positioned(
                  bottom: 2,
                  child: Text(
                    '78',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title: Urban Health Score
          const Text(
            'Urban Health Score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),

          // Status Chip Badge: Status : Sehat & Terkendali
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: AppColors.greenPrimary,
              ),
              SizedBox(width: 4),
              Text(
                'Status : Sehat & Terkendali',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3 Stat Cards Row: 12 Laporan Saya, 8 Sedang diproses, 5 Laporan selesai
  Widget _buildStatCardsRow() {
    return Row(
      children: [
        // Card 1: 12 Laporan Saya (Blue)
        Expanded(
          child: _buildStatItem(
            value: '12',
            label: 'Laporan Saya',
            color: const Color(0xFF2B82C4),
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: 8 Sedang diproses (Orange/Amber)
        Expanded(
          child: _buildStatItem(
            value: '8',
            label: 'Sedang diproses',
            color: const Color(0xFFE68A00),
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: 5 Laporan selesai (Green)
        Expanded(
          child: _buildStatItem(
            value: '5',
            label: 'Laporan selesai',
            color: AppColors.greenPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Kategori Section Header + 4 Category Items Row
  Widget _buildKategoriSection() {
    return Column(
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Category Cards Row
        Row(
          children: [
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/route.png',
                label: 'Routes',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/trotoar.png',
                label: 'Trotoar',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/laluLintas.png',
                label: 'Lalu Lintas',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKategoriCard(
                imagePath: 'assets/images/fasilitasUmum.png',
                label: 'Fasilitas\nUmum',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKategoriCard({
    required String imagePath,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.grid_view_rounded,
              size: 36,
              color: AppColors.greenPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Laporan Terdekat Section Header & List Cards
  Widget _buildLaporanTerdekatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Terdekat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 12),

        // Report 1: Jembatan rusak
        _buildReportListItem(
          title: 'Jembatan rusak',
          date: '18 juli 2026',
          address: 'Jl. toyiban no.13 f5',
          supports: '1.208 Dukungan',
          statusText: 'Menunggu verifikasi',
          statusBgColor: const Color(0xFFE6F2FF),
          statusTextColor: const Color(0xFF2B82C4),
          iconData: Icons.water_rounded,
          placeholderColor: Colors.blue.shade100,
        ),
        const SizedBox(height: 12),

        // Report 2: Jalan Rusak
        _buildReportListItem(
          title: 'Jalan Rusak',
          date: '12 Mei 2026',
          address: 'Jl. Ahmad Yani no. 15',
          supports: '360 Dukungan',
          statusText: 'Sedang Diproses',
          statusBgColor: const Color(0xFFFFF8E6),
          statusTextColor: const Color(0xFFE68A00),
          iconData: Icons.alt_route_rounded,
          placeholderColor: Colors.amber.shade100,
        ),
        const SizedBox(height: 12),

        // Report 3: Halte rusak
        _buildReportListItem(
          title: 'Halte rusak',
          date: '4 april 2026',
          address: 'Jl. soekarno hatta no.20 A',
          supports: '268 Dukungan',
          statusText: 'Sedang Diproses',
          statusBgColor: const Color(0xFFFFF8E6),
          statusTextColor: const Color(0xFFE68A00),
          iconData: Icons.directions_bus_rounded,
          placeholderColor: Colors.orange.shade100,
        ),
        const SizedBox(height: 12),

        // Report 4: Kursi tidak layak
        _buildReportListItem(
          title: 'Kursi tidak layak',
          date: '31 Maret 2026',
          address: 'Jl. simpang ibrahim',
          supports: '129 Dukungan',
          statusText: 'Selesai',
          statusBgColor: const Color(0xFFE6F7ED),
          statusTextColor: AppColors.greenPrimary,
          iconData: Icons.chair_alt_rounded,
          placeholderColor: Colors.green.shade100,
        ),
      ],
    );
  }

  Widget _buildReportListItem({
    required String title,
    required String date,
    required String address,
    required String supports,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required IconData iconData,
    required Color placeholderColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(
              reportData: {
                'title': title,
                'date': date,
                'address': address,
                'status': statusText,
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail with realistic visual container
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 72,
              color: placeholderColor,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      iconData,
                      size: 32,
                      color: AppColors.neutral500,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FOTO',
                        style: TextStyle(
                          fontSize: 8,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      date,
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
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.neutral900,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 3: Support Count + Status Chip + Chevron Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Support Count Text
                    Text(
                      supports,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greenPrimary,
                      ),
                    ),

                    Row(
                      children: [
                        // Status Badge Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Chevron Right Arrow
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

/// Custom Painter for Arc Gauge Meter ("Urban Health Score")
class UrbanHealthArcPainter extends CustomPainter {
  final double percentage; // e.g. 0.78 for 78

  UrbanHealthArcPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - (strokeWidth / 2);

    // 1. Background Arc (Light Grey)
    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // start at left (180 degrees)
      math.pi, // sweep 180 degrees to right
      false,
      bgPaint,
    );

    // 2. Active Arc (Green)
    final activePaint = Paint()
      ..color = AppColors.greenPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * percentage,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant UrbanHealthArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

// =============================================================================
// TAB 1: PETA TAB
// =============================================================================


// =============================================================================
// TAB 2: LAPOR / CAMERA VISION TAB
// =============================================================================
class CitizenLaporTab extends StatelessWidget {
  const CitizenLaporTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 64,
                color: AppColors.greenPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Citizen Vision AI Camera',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ambil foto masalah publik di sekitarmu, AI LaporKita akan mendeteksi otomatis kategori & lokasimu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              icon: const Icon(Icons.camera),
              label: const Text('Buka Kamera Lapor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 3: NOTIFIKASI TAB
// =============================================================================
// =============================================================================
// TAB 3: NOTIFIKASI TAB (Figma Node 111:2983)
// =============================================================================
class CitizenNotifikasiTab extends StatelessWidget {
  const CitizenNotifikasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Card 1: Perbaikan dimulai (Blue Container)
            _buildNotifCard(
              title: 'Perbaikan dimulai',
              message: 'Laporan #LP_2026_002487 sedang dikerjakan oleh petugas.',
              time: '10.46',
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF1976D2),
              bgColor: const Color(0xFFE4F2FF),
              borderColor: const Color(0xFFABD5FF),
              isUnread: true,
            ),
            const SizedBox(height: 12),

            // Card 2: Laporan anda diverifikasi
            _buildNotifCard(
              title: 'Laporan anda diverifikasi',
              message: 'Laporan #LP_2026_002487 telah diverifikasi.',
              time: '07.23',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.greenPrimary,
              bgColor: AppColors.white,
              borderColor: const Color(0xFFE0DFDF),
              isUnread: false,
            ),
            const SizedBox(height: 12),

            // Card 3: Perbaikan selesai
            _buildNotifCard(
              title: 'Perbaikan selesai',
              message: 'Laporan #LP_2026_002328 telah selesai diperbaiki',
              time: 'Kemarin',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.greenPrimary,
              bgColor: AppColors.white,
              borderColor: const Color(0xFFE0DFDF),
              isUnread: false,
            ),
            const SizedBox(height: 12),

            // Card 4: Permintaan informasi tambahan
            _buildNotifCard(
              title: 'Permintaan informasi tambahan',
              message: 'Mohon lengkapi informasi pada laporan #LP_2026_002328',
              time: '3 hari lalu',
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFE68A00),
              bgColor: AppColors.white,
              borderColor: const Color(0xFFE0DFDF),
              isUnread: false,
            ),
            const SizedBox(height: 80), // Padding for floating navbar
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF565657),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF565657),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 4: PROFILE TAB (Figma Node 113:3320)
// =============================================================================
class CitizenProfileTab extends StatelessWidget {
  const CitizenProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Profile',
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
            children: [
              // Avatar & Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.greenPrimary.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.greenLight,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: AppColors.greenPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kalandra Garendra',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'kalandra.garendra@gmail.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF565657),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu Item 1: Riwayat Laporan
              _buildProfileMenuItem(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Riwayat Laporan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka Riwayat Laporan...'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Menu Item 2: Dukungan Saya
              _buildProfileMenuItem(
                icon: Icons.thumb_up_alt_outlined,
                title: 'Dukungan Saya',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka Dukungan Saya...'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Menu Item 3: Pengaturan
              _buildProfileMenuItem(
                icon: Icons.settings_outlined,
                title: 'Pengaturan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka Pengaturan...'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Menu Item 4: Pusat Bantuan
              _buildProfileMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Pusat Bantuan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka Pusat Bantuan...'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Menu Item 5: Tentang LaporKita
              _buildProfileMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'Tentang LaporanKita',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('LaporKita v1.0.0'),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout Button (Red Outlined Container)
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFEB),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFFF3D00)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF3D00),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF3D00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80), // Padding for floating navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Icon(
              icon,
              size: 24,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.neutral900,
            ),
          ],
        ),
      ),
    );
  }
}
