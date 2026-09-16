import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/bloc/auth_bloc.dart';

class AdminProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const AdminProfileScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const Color _borderColor = Color(0xFFE0DFDF);
  static const Color _textGrey = Color(0xFF565657);
  static const Color _logoutBg = Color(0xFFFFEFEB);
  static const Color _logoutBorder = Color(0xFFFF3D00);

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showFeatureDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF1D9C51),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF424242),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D9C51),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari sesi Admin Command Center LaporKita?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF515151),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/get-started',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _logoutBorder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String adminName = 'Admin Utama';
    String adminEmail = 'admin@laporkita.go.id';

    if (authState is AuthAuthenticated) {
      if (authState.user.fullName.isNotEmpty) {
        adminName = authState.user.fullName;
      }
      final email = authState.user.email;
      if (email != null && email.isNotEmpty) {
        adminEmail = email;
      }
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(28, topPadding + 14, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── TOP APP BAR ──────────────────────────────────────────
              _buildTopAppBar(),

              const SizedBox(height: 28),

              // ── AVATAR (Figma size 202x202) ───────────────────────────
              _buildAvatar(),

              const SizedBox(height: 18),

              // ── NAME & EMAIL ─────────────────────────────────────────
              Text(
                adminName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                adminEmail,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textGrey,
                ),
              ),

              const SizedBox(height: 32),

              // ── SECTION 1: PENGATURAN SISTEM ──────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pengaturan Sistem',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildMenuCard(
                icon: Icons.people_alt_outlined,
                title: 'Manajemen Pengguna',
                onTap: () => _showFeatureDialog(
                  'Manajemen Pengguna',
                  'Kelola akun operator OPD, petugas lapangan, dan akun warga yang terdaftar pada sistem LaporKita.',
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.lock_outline_rounded,
                title: 'Role & Permission',
                onTap: () => _showFeatureDialog(
                  'Role & Permission',
                  'Konfigurasi hak akses hak istimewa Super Admin, Operator Dinas, dan Petugas Teknis.',
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.account_balance_outlined,
                title: 'OPD & Wilayah',
                onTap: () => _showFeatureDialog(
                  'OPD & Wilayah',
                  'Daftar instansi penanggung jawab (DPUPR, Dishub, Diskominfo) dan pemetaan wilayah kerja se-Kota Malang.',
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.fact_check_outlined,
                title: 'Kategori & Prioritas',
                onTap: () => _showFeatureDialog(
                  'Kategori & Prioritas',
                  'Pengaturan taksonomi kategori laporan, SLA waktu respon, dan bobot prioritas kegawatan laporan warga.',
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.notifications_none_rounded,
                title: 'Pengaturan Notifikasi',
                onTap: () => _showFeatureDialog(
                  'Pengaturan Notifikasi',
                  'Konfigurasi notifikasi push Firebase, alert darurat, dan ringkasan harian laporan untuk admin.',
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.hub_outlined,
                title: 'Integrasi & API',
                onTap: () => _showFeatureDialog(
                  'Integrasi & API',
                  'Status koneksi API backend LaporKita, webhook dispatcher, dan layanan AI duplicate detector.',
                ),
              ),

              const SizedBox(height: 30),

              // ── SECTION 2: LAINNYA ───────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lainnya',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildMenuCard(
                icon: Icons.history_rounded,
                title: 'Log Aktivitas',
                onTap: () => _showFeatureDialog(
                  'Log Aktivitas',
                  'Audit trail seluruh tindakan verifikasi, penerusan disposisi, dan perubahan status laporan oleh admin.',
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () => _showFeatureDialog(
                  'Tentang Aplikasi',
                  'LaporKita Command Center v1.0.0 (Production Build)\nPlatform Pengaduan dan Respons Cepat Kota Malang.',
                ),
              ),

              const SizedBox(height: 36),

              // ── TOMBOL KELUAR ────────────────────────────────────────
              _buildLogoutButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── TOP APP BAR (Matching Figma node 568:2831) ─────────────────
  Widget _buildTopAppBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEDEDED),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── AVATAR (Matching Figma node 568:2836) ───────────────────────
  Widget _buildAvatar() {
    return Container(
      width: 202,
      height: 202,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/admin_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE6F7ED),
            child: const Icon(
              Icons.person_rounded,
              size: 100,
              color: Color(0xFF1D9C51),
            ),
          ),
        ),
      ),
    );
  }

  // ── MENU CARD (Matching Figma node 568:2842) ───────────────────
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 53,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF262626),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF565657),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOGOUT BUTTON (Matching Figma node 568:2896) ───────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        height: 53,
        decoration: BoxDecoration(
          color: _logoutBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _logoutBorder, width: 1.0),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: _logoutBorder,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _logoutBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
