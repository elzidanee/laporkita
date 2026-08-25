import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laporkita/core/theme/app_colors.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';

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
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String fullName = 'Warga LaporKita';
            String emailOrPhone = '-';
            int points = 0;
            String? avatarUrl;

            if (authState is AuthAuthenticated) {
              fullName = authState.user.fullName;
              emailOrPhone = authState.user.email ??
                  authState.user.phoneNumber ??
                  '-';
              points = authState.user.contributionPoints;
              avatarUrl = authState.user.avatarUrl;
            }

            return SingleChildScrollView(
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
                              color: AppColors.greenPrimary
                                  .withValues(alpha: 0.3),
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
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: AppColors.greenLight,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 54,
                                        color: AppColors.greenPrimary,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.greenLight,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 54,
                                      color: AppColors.greenPrimary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emailOrPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 16,
                                color: AppColors.greenPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$points Poin Kontribusi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.greenPrimary,
                                ),
                              ),
                            ],
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
                    title: 'Tentang LaporKita',
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
                      context
                          .read<AuthBloc>()
                          .add(const AuthLogoutRequested());
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/get-started', (route) => false);
                    },
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFEB),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.statusDanger),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.statusDanger,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusDanger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
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
          border: Border.all(color: AppColors.neutral200),
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
