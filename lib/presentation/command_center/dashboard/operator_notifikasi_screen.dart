import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OperatorNotifikasiScreen extends StatelessWidget {
  const OperatorNotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          children: [
            // 1. Laporan baru masuk (Highlighted card, Node 676:2095)
            _buildNotificationCard(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFF2AE01),
              title: 'Laporan baru masuk',
              subtitle: 'Laporan #LP_2026_0028349',
              time: '09.20',
              isHighlighted: true,
            ),
            const SizedBox(height: 12),

            // 2. AI Verification selesai (Node 676:2095)
            _buildNotificationCard(
              icon: Icons.auto_awesome_outlined,
              iconColor: const Color(0xFF1976D2),
              title: 'AI Verification selesai',
              subtitle: 'Confidence : 98%',
              time: '09.18',
            ),
            const SizedBox(height: 12),

            // 3. Laporan diteruskan ke Dinas PUPR (Node 676:2095)
            _buildNotificationCard(
              icon: Icons.format_list_bulleted_rounded,
              iconColor: const Color(0xFFF2AE01),
              title: 'Laporan diteruskan ke Dinas PUPR',
              subtitle: '#LP-2026-7268712',
              time: 'Kemarin',
            ),
            const SizedBox(height: 12),

            // 4. Petugas mulai mengerjakan (Node 676:2095)
            _buildNotificationCard(
              icon: Icons.build_outlined,
              iconColor: const Color(0xFF1976D2),
              title: 'Petugas mulai mengerjakan',
              subtitle: '#LP-2026-8231791',
              time: '1 hari lalu',
            ),
            const SizedBox(height: 12),

            // 5. Laporan selesai dikerjakan (Node 676:2095)
            _buildNotificationCard(
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Laporan selesai dikerjakan',
              subtitle: 'Menunggu validasi warga\n#LP_2026_002328',
              time: '3 hari lalu',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFE8F4FD) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFB8E1FF) : const Color(0xFFE0DFDF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}
