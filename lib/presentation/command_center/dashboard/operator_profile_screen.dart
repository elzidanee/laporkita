import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/bloc/auth_bloc.dart';

class OperatorProfileScreen extends StatelessWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const OperatorProfileScreen({
    super.key,
    this.isTab = false,
    this.onBackToDashboard,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar dari Aplikasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Petugas OPD?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                  context, '/get-started', (route) => false);
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'OPD';
    String userEmail = 'petugasopd@laporkita.go.id';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName.isNotEmpty ? authState.user.fullName : 'OPD';
      userEmail = authState.user.email ?? 'petugasopd@laporkita.go.id';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
          onPressed: () {
            if (isTab) {
              onBackToDashboard?.call();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Picture & User Info (Node 676:1992)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE2E8F0),
                        border: Border.all(color: const Color(0xFFBEC4BD), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 74,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. Section: Pengaturan Sistem (Node 676:1992)
              Text(
                'Pengaturan Sistem',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.people_outline_rounded,
                title: 'Wilayah Tugas',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wilayah Tugas: Kota Malang (Kec. Lowokwaru & Klojen)')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildSettingCard(
                icon: Icons.notifications_none_outlined,
                title: 'Pengaturan Notifikasi',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi tugas baru aktif')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildSettingCard(
                icon: Icons.inbox_outlined,
                title: 'Pengingat Pekerjaan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengingat pekerjaan disetel aktif')),
                  );
                },
              ),
              const SizedBox(height: 26),

              // 3. Section: Lainnya (Node 676:1992)
              Text(
                'Lainnya',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.motion_photos_on_outlined,
                title: 'Log Aktivitas',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menampilkan riwayat pengerjaan')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildSettingCard(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'LaporKita Operator OPD',
                    applicationVersion: 'v2.1.0',
                    applicationLegalese: '© 2026 Pemerintah Kota Malang',
                  );
                },
              ),
              const SizedBox(height: 36),

              // 4. Button Keluar (Node 676:1992)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F1),
                    side: const BorderSide(color: Color(0xFFFF5722), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF5722),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keluar',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0DFDF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
