import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:laporkita/core/theme/app_colors.dart';
import '../map/map_tab_screen.dart';
import 'tabs/citizen_dashboard_tab.dart';
import 'tabs/citizen_lapor_tab.dart';
import 'tabs/citizen_notifikasi_tab.dart';
import 'tabs/citizen_profile_tab.dart';

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
            children: const [
              CitizenDashboardTab(),
              CitizenPetaTab(),
              CitizenLaporTab(),
              CitizenNotifikasiTab(),
              CitizenProfileTab(),
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
