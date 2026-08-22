import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const ReportDetailScreen({super.key, this.reportData});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSupported = false;
  int _supportCount = 360;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback/Default values if no specific report object passed
    final title = widget.reportData?['title'] as String? ?? 'Jalan Rusak';
    final address =
        widget.reportData?['address'] as String? ?? 'Jl. Ahmad Yani no. 15';
    final fullAddress =
        widget.reportData?['fullAddress'] as String? ??
        'Jl. ahmad yani no. 15 sawojajar kota Malang';
    final reportId = widget.reportData?['id'] as String? ?? '#LP-2026-002487';
    final statusText =
        widget.reportData?['status'] as String? ?? 'Sedang Diproses';
    final dateText =
        widget.reportData?['date'] as String? ??
        'Dibuat : 12 Mei 2026 | 10.30 WIB';
    final description =
        widget.reportData?['description'] as String? ??
        'Jalan sudah tidak layak karena banyak retakan dan lubang disepanjang jalan.';
    final confidence = widget.reportData?['confidence'] as String? ?? '98%';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.neutral900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Terdekat',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.neutral900,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan laporan berhasil disalin!'),
                  backgroundColor: AppColors.greenPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top ID & Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reportId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE68A00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Title & Address
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              address,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),

            // 2. Main Report Photo with Camera Metadata Overlay Stamp
            _buildReportImageWithOverlay(),
            const SizedBox(height: 12),

            // Created Date Text
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                dateText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE68A00),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Description Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deskripsi :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. AI Verification Card
            _buildAiVerificationCard(),
            const SizedBox(height: 16),

            // 4. Confidence Score Bar Card
            _buildConfidenceCard(confidence),
            const SizedBox(height: 16),

            // 5. 3 Stat Boxes Row (Dukungan, Dilihat, Komentar)
            _buildThreeStatBoxes(),
            const SizedBox(height: 20),

            // 6. Primary Action Buttons (Dukung & Comment Icon)
            _buildActionButtonsRow(),
            const SizedBox(height: 24),

            // 7. 3-Tab Bar (Timeline, Detail, Komentar)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF3B82C4),
                indicatorWeight: 3,
                labelColor: const Color(0xFF3B82C4),
                unselectedLabelColor: AppColors.neutral500,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                tabs: const [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Detail'),
                  Tab(text: 'Komentar'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 8. Tab Bar Views Content
            SizedBox(
              height: _calculateTabHeight(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimelineTab(),
                  _buildDetailTab(fullAddress, reportId),
                  _buildKomentarTab(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  double _calculateTabHeight() {
    // Dynamic height estimate per tab view so nested scroll feels natural
    switch (_tabController.index) {
      case 0:
        return 580; // Timeline tab height
      case 1:
        return 680; // Detail tab height
      case 2:
        return 620; // Komentar tab height
      default:
        return 580;
    }
  }

  /// Main Report Image with Camera Metadata Stamp Overlay (Matching photo in Screenshot 1)
  Widget _buildReportImageWithOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background damaged road image container
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=800&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Camera AI Timestamp & Location Overlay Stamp (Bottom Left Overlay)
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LaporKita',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '#LP-2026-002487',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '📍 Jl. Ahmad Yani No. 15 Sawojajar',
                    style: TextStyle(color: AppColors.white, fontSize: 8.5),
                  ),
                  const Text(
                    '🕒 12 Mei 2026, 10.30 | 102.5° SE',
                    style: TextStyle(color: AppColors.white, fontSize: 8.5),
                  ),
                  const Text(
                    '🌐 -7.982121, 112.631883',
                    style: TextStyle(color: AppColors.white, fontSize: 8.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI Verification Card (Foto Valid, GPS Valid, Timestamp Valid, Metadata lengkap)
  Widget _buildAiVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Verification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckItem('Foto Valid'),
          const SizedBox(height: 8),
          _buildCheckItem('GPS Valid'),
          const SizedBox(height: 8),
          _buildCheckItem('Timestamp Valid'),
          const SizedBox(height: 8),
          _buildCheckItem('Metadata lengkap'),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: AppColors.greenPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: AppColors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  /// Confidence Score Card (98% green progress bar)
  Widget _buildConfidenceCard(String confidence) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confidence',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                confidence,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.98,
              minHeight: 8,
              backgroundColor: AppColors.neutral100,
              color: AppColors.greenPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 3 Stat Boxes Row (Dukungan 360, Dilihat 512, Komentar 5)
  Widget _buildThreeStatBoxes() {
    return Row(
      children: [
        Expanded(child: _buildStatBox('Dukungan', '$_supportCount')),
        const SizedBox(width: 10),
        Expanded(child: _buildStatBox('Dilihat', '512')),
        const SizedBox(width: 10),
        Expanded(child: _buildStatBox('komentar', '5')),
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
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
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  /// Action Buttons (Dukung button + Chat icon button)
  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // Dukung Button
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isSupported = !_isSupported;
                _supportCount += _isSupported ? 1 : -1;
              });
            },
            icon: Icon(
              _isSupported
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_off_alt_rounded,
              size: 20,
            ),
            label: Text(
              _isSupported ? 'Didukung' : 'Dukung',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenPrimary,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Green Chat Bubble Icon Button
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFC7F3D6), // Light green tint
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () {
              _tabController.animateTo(2); // Jump to comments tab
            },
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.greenPrimary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 1 CONTENT: TIMELINE TAB (Matching Screenshot 1)
  // ===========================================================================
  Widget _buildTimelineTab() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        // Item 1: Laporan dibuat (Green check)
        _buildTimelineItem(
          title: 'Laporan dibuat',
          time: '12 Mei 2026 | 10.30',
          desc: 'Laporan berhasil dibuat oleh masyarakat',
          isDone: true,
          icon: Icons.check,
          iconBgColor: AppColors.greenPrimary,
          isFirst: true,
        ),

        // Item 2: Diverifikasi Admin (Green check)
        _buildTimelineItem(
          title: 'Diverifikasi Admin',
          time: '12 Mei 2026 | 10.42',
          desc: 'Laporan telah diverifikasi dan sesuai ketentuan.',
          isDone: true,
          icon: Icons.check,
          iconBgColor: AppColors.greenPrimary,
        ),

        // Item 3: Diteruskan keDinas PUPR (Blue arrow)
        _buildTimelineItem(
          title: 'Diteruskan keDinas PUPR',
          time: '12 Mei 2026 | 11.54',
          desc: 'Laporan diteruskan keDinas PUPR Malang.',
          isDone: true,
          icon: Icons.shortcut_rounded,
          iconBgColor: const Color(0xFF2B82C4),
        ),

        // Item 4: Sedang Diproses (Blue gear/active + Progress Photo card)
        _buildTimelineItem(
          title: 'Sedang Diproses',
          time: '13 Mei 2026 | 12.43',
          desc: 'Petugas Dinas PUPR sedang menangani laporan ini.',
          isDone: true,
          icon: Icons.build_rounded,
          iconBgColor: const Color(0xFF2B82C4),
          customChild: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 50,
                    color: Colors.amber.shade100,
                    child: const Icon(
                      Icons.construction_rounded,
                      color: Color(0xFFE68A00),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Foto Progres',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '13 Mei 2026. 12.43',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Item 5: Estimasi selesai (Grey check)
        _buildTimelineItem(
          title: 'Estimasi selesai',
          time: '18 Mei 2026',
          desc: '',
          isDone: false,
          icon: Icons.check,
          iconBgColor: AppColors.neutral500,
        ),

        // Item 6: Selesai (Grey check)
        _buildTimelineItem(
          title: 'Selesai',
          time: '',
          desc: 'Menunggu konfirmasi penyelesaian pekerjaan.',
          isDone: false,
          icon: Icons.check,
          iconBgColor: AppColors.neutral500,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required String desc,
    required bool isDone,
    required IconData icon,
    required Color iconBgColor,
    bool isFirst = false,
    bool isLast = false,
    Widget? customChild,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line & Dot Column
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: AppColors.white),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 14),

          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? AppColors.neutral900
                              : AppColors.neutral500,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral500,
                          ),
                        ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                        height: 1.3,
                      ),
                    ),
                  ],
                  ?customChild,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 CONTENT: DETAIL TAB (Matching Screenshot 2)
  // ===========================================================================
  Widget _buildDetailTab(String fullAddress, String reportId) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _buildDetailCard(
          icon: Icons.location_on_outlined,
          label: 'Lokasi',
          value: fullAddress,
        ),
        _buildDetailCard(
          icon: Icons.grid_view_rounded,
          label: 'Kategori',
          value: 'Jalan',
        ),
        _buildDetailCard(
          icon: Icons.flag_outlined,
          label: 'Prioritas',
          value: 'Tinggi',
          valueColor: AppColors.statusDanger,
        ),
        _buildDetailCard(
          icon: Icons.warning_amber_rounded,
          label: 'Jenis kerusakan',
          value: 'Jalan retak dan berlubang',
        ),
        _buildDetailCard(
          icon: Icons.thumb_up_off_alt_rounded,
          label: 'Dukungan',
          value: '178 Orang',
        ),
        _buildDetailCard(
          icon: Icons.remove_red_eye_outlined,
          label: 'Dilihat',
          value: '200 Orang',
        ),
        _buildDetailCard(
          icon: Icons.account_balance_outlined,
          label: 'Petugas',
          value: 'Dinas PUPR Kota Malang',
        ),
        _buildDetailCard(
          icon: Icons.calendar_today_outlined,
          label: 'Estimasi Selesai',
          value: '18 Mei 2026',
        ),
        _buildDetailCard(
          icon: Icons.access_time_outlined,
          label: 'Dibuat Pada',
          value: '12 Mei 2026',
        ),
        _buildDetailCard(
          icon: Icons.info_outline_rounded,
          label: 'ID Laporan',
          value: reportId,
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.neutral900),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: valueColor ?? AppColors.neutral500,
                    fontWeight: valueColor != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.neutral900,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3 CONTENT: KOMENTAR TAB (Matching Screenshot 3)
  // ===========================================================================
  Widget _buildKomentarTab() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _buildCommentCard(
          name: 'Kalandra Garendra',
          time: '2 jam yang lalu',
          comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
          likes: 12,
        ),
        _buildCommentCard(
          name: 'Kalandra Garendra',
          time: '2 jam yang lalu',
          comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
          likes: 12,
        ),
        _buildCommentCard(
          name: 'Kalandra Garendra',
          time: '2 jam yang lalu',
          comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
          likes: 12,
        ),
        _buildCommentCard(
          name: 'Kalandra Garendra',
          time: '2 jam yang lalu',
          comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
          likes: 12,
        ),
        _buildCommentCard(
          name: 'Kalandra Garendra',
          time: '2 jam yang lalu',
          comment: 'Semoga cepat diperbaiki, karena sangat membahayakan',
          likes: 12,
        ),
      ],
    );
  }

  Widget _buildCommentCard({
    required String name,
    required String time,
    required String comment,
    required int likes,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.greenLight,
            child: Icon(Icons.person, color: AppColors.greenPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_rounded,
                      size: 16,
                      color: Color(0xFF2B82C4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B82C4),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'Balas',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
