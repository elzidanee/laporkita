import 'dart:io';
import '../../core/config/app_config.dart';

enum ReportStatus {
  pendingVerification,
  verified,
  rejected,
  assigned,
  inProgress,
  completed,
  resolved,
  disputed;

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'verified':
        return ReportStatus.verified;
      case 'rejected':
        return ReportStatus.rejected;
      case 'assigned':
        return ReportStatus.assigned;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'completed':
        return ReportStatus.completed;
      case 'resolved':
        return ReportStatus.resolved;
      case 'disputed':
        return ReportStatus.disputed;
      default:
        return ReportStatus.pendingVerification;
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.pendingVerification:
        return 'Menunggu Verifikasi';
      case ReportStatus.verified:
        return 'Terverifikasi';
      case ReportStatus.rejected:
        return 'Ditolak';
      case ReportStatus.assigned:
        return 'Ditugaskan';
      case ReportStatus.inProgress:
        return 'Sedang Diproses';
      case ReportStatus.completed:
        return 'Selesai';
      case ReportStatus.resolved:
        return 'Terselesaikan';
      case ReportStatus.disputed:
        return 'Diperdebatkan';
    }
  }

  String get label => displayName;
}

class ReportMediaModel {
  final String id;
  final String reportId;
  final String type;
  final String url;
  final String? uploadedBy;
  final DateTime createdAt;

  const ReportMediaModel({
    required this.id,
    required this.reportId,
    required this.type,
    required this.url,
    this.uploadedBy,
    required this.createdAt,
  });

  factory ReportMediaModel.fromJson(Map<String, dynamic> json) {
    return ReportMediaModel(
      id: json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? '',
      type: json['type'] as String? ?? 'initial_photo',
      url: json['url'] as String? ?? '',
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ReportStatusHistoryModel {
  final String id;
  final String reportId;
  final ReportStatus targetStatus;
  final String? note;
  final String? actorId;
  final String? actorName;
  final DateTime createdAt;

  const ReportStatusHistoryModel({
    required this.id,
    required this.reportId,
    required this.targetStatus,
    this.note,
    this.actorId,
    this.actorName,
    required this.createdAt,
  });

  factory ReportStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    final changer = json['changer'] as Map<String, dynamic>?;
    return ReportStatusHistoryModel(
      id: json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? '',
      targetStatus: ReportStatus.fromString(
          json['target_status'] as String? ?? json['to_status'] as String? ?? ''),
      note: json['note'] as String?,
      actorId: json['actor_id'] as String? ?? json['changer_id'] as String?,
      actorName: changer?['full_name'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ReportModel {
  final String id;
  final String reportCode;
  final String reporterId;
  final String categoryId;
  final ReportStatus status;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? description;
  final String? directPhotoUrl;
  final int supportCount;
  final int viewCount;
  final double? urgencyScore;
  final bool needsManualReview;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? reporter;
  final Map<String, dynamic>? assignedAgency;
  final List<ReportMediaModel> media;
  final List<ReportStatusHistoryModel> statusHistory;
  final Map<String, int>? count;

  const ReportModel({
    required this.id,
    required this.reportCode,
    required this.reporterId,
    required this.categoryId,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.addressText,
    this.description,
    this.directPhotoUrl,
    required this.supportCount,
    required this.viewCount,
    this.urgencyScore,
    required this.needsManualReview,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.reporter,
    this.assignedAgency,
    this.media = const [],
    this.statusHistory = const [],
    this.count,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final List<ReportMediaModel> mediaList = [];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map<String, dynamic>) {
          mediaList.add(ReportMediaModel.fromJson(m));
        }
      }
    }

    final rawHistory = json['status_history'];
    final List<ReportStatusHistoryModel> historyList = [];
    if (rawHistory is List) {
      for (final h in rawHistory) {
        if (h is Map<String, dynamic>) {
          historyList.add(ReportStatusHistoryModel.fromJson(h));
        }
      }
    }

    final countData = json['_count'] is Map<String, dynamic>
        ? json['_count'] as Map<String, dynamic>
        : null;

    return ReportModel(
      id: json['id']?.toString() ?? '',
      reportCode: json['report_code']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      status: ReportStatus.fromString(json['status']?.toString() ?? ''),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      addressText: json['address_text']?.toString(),
      description: json['description']?.toString(),
      directPhotoUrl: json['photo_url']?.toString(),
      supportCount: json['support_count'] is int
          ? json['support_count'] as int
          : (countData?['supports'] is int
              ? countData!['supports'] as int
              : (int.tryParse(json['support_count']?.toString() ?? '0') ?? 0)),
      viewCount: json['view_count'] is int
          ? json['view_count'] as int
          : (int.tryParse(json['view_count']?.toString() ?? '0') ?? 0),
      urgencyScore: json['urgency_score'] != null
          ? double.tryParse(json['urgency_score'].toString())
          : null,
      needsManualReview: json['needs_manual_review'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      category: json['category'] is Map<String, dynamic>
          ? json['category'] as Map<String, dynamic>
          : null,
      reporter: json['reporter'] is Map<String, dynamic>
          ? json['reporter'] as Map<String, dynamic>
          : null,
      assignedAgency: json['assigned_agency'] is Map<String, dynamic>
          ? json['assigned_agency'] as Map<String, dynamic>
          : null,
      media: mediaList,
      statusHistory: historyList,
      count: countData != null
          ? {
              'supports': countData['supports'] is int ? countData['supports'] as int : 0,
              'comments': countData['comments'] is int ? countData['comments'] as int : 0,
              'validations': countData['validations'] is int ? countData['validations'] as int : 0,
            }
          : null,
    );
  }

  /// URL foto utama laporan (fallback dari photo_url -> media.first.url)
  String? get photoUrl {
    if (directPhotoUrl != null && directPhotoUrl!.isNotEmpty) {
      return directPhotoUrl;
    }
    if (media.isNotEmpty) return media.first.url;
    return null;
  }

  /// Map category to realistic high-quality public image URL if backend returns dummy/unreachable URLs
  static String getCategoryFallbackImage(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('rambu') || lower.contains('lalu lintas')) {
      return 'https://images.unsplash.com/photo-1572949645841-094f3a9c4c94?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('lampu') || lower.contains('penerangan')) {
      return 'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('drainase') || lower.contains('selokan') || lower.contains('banjir')) {
      return 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('trotoar') || lower.contains('pedestrian')) {
      return 'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=800&auto=format&fit=crop';
    } else {
      // Jalan Berlubang / Umum
      return 'https://images.unsplash.com/photo-1584463699966-224424368146?q=80&w=800&auto=format&fit=crop';
    }
  }

  /// URL foto terformat (mengubah URL relatif menjadi URL absolut, mempertahankan file lokal dan URL server asli)
  String? get formattedPhotoUrl {
    final raw = photoUrl;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    // Berkas lokal (kamera/galeri user)
    if (!raw.startsWith('http')) {
      try {
        if (File(raw).existsSync()) return raw;
      } catch (_) {}
    }
    // Domain dummy test suite QA
    if (raw.contains('storage.example.com')) {
      return getCategoryFallbackImage(categoryName);
    }
    // Sudah absolute URL
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    // URL relatif — bangun URL absolut dari host base (tanpa /api/v1)
    try {
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final host =
          '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      final path = raw.startsWith('/') ? raw : '/$raw';
      return '$host$path';
    } catch (_) {
      return raw;
    }
  }

  /// Nama kategori
  String get categoryName => category?['name'] as String? ?? 'Umum';

  /// Nama pelapor
  String get reporterName => reporter?['full_name'] as String? ?? 'Anonim';
}
