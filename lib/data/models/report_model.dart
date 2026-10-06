import 'dart:io';
import 'package:flutter/material.dart';
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
    final lower = value.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (lower.contains('pending')) return ReportStatus.pendingVerification;
    if (lower.contains('verifi')) return ReportStatus.verified;
    if (lower.contains('reject')) return ReportStatus.rejected;
    if (lower.contains('assign')) return ReportStatus.assigned;
    if (lower.contains('progress')) return ReportStatus.inProgress;
    if (lower.contains('complet')) return ReportStatus.completed;
    if (lower.contains('resolv')) return ReportStatus.resolved;
    if (lower.contains('disput')) return ReportStatus.disputed;

    return ReportStatus.pendingVerification;
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

  String get apiValue {
    switch (this) {
      case ReportStatus.pendingVerification:
        return 'pending_verification';
      case ReportStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }
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
      url: json['url'] as String? ??
          json['file_url'] as String? ??
          json['photo_url'] as String? ??
          json['path'] as String? ??
          '',
      uploadedBy: json['uploaded_by'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'type': type,
      'url': url,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// URL foto yang sudah diformat absolut dan aman ditampilkan
  String get formattedUrl {
    if (url.isEmpty) return '';
    // Berkas lokal
    if (!url.startsWith('http')) {
      try {
        if (File(url).existsSync()) return url;
      } catch (_) {}
    }
    // URL dummy
    if (url.contains('storage.example.com') ||
        url.contains('images.unsplash.com') ||
        url.contains('storage.laporkita.malangkota.go.id')) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // URL relatif
    try {
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final host =
          '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      final path = url.startsWith('/') ? url : '/$url';
      return '$host$path';
    } catch (_) {
      return url;
    }
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
          json['status'] as String? ??
          json['target_status'] as String? ??
          json['to_status'] as String? ??
          ''),
      note: json['note'] as String?,
      actorId: json['changed_by'] as String? ??
          json['actor_id'] as String? ??
          json['changer_id'] as String?,
      actorName: changer?['full_name'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'target_status': targetStatus.apiValue,
      if (note != null) 'note': note,
      if (actorId != null) 'actor_id': actorId,
      if (actorName != null) 'changer': {'full_name': actorName},
      'created_at': createdAt.toIso8601String(),
    };
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

  final double? rawAiConfidenceScore;
  final double? damageSeverity;
  final DateTime? estimatedCompletionAt;
  final String? directPriority;
  final double? progressPercentage;

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
    this.rawAiConfidenceScore,
    this.damageSeverity,
    this.estimatedCompletionAt,
    this.directPriority,
    this.progressPercentage,
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

    ReportMediaModel? initialMedia;
    if (mediaList.isNotEmpty) {
      try {
        initialMedia = mediaList.firstWhere(
          (m) =>
              m.type == 'initial_photo' &&
              m.url.isNotEmpty &&
              !m.url.contains('storage.example.com') &&
              !m.url.contains('images.unsplash.com'),
          orElse: () => mediaList.firstWhere(
            (m) =>
                m.url.isNotEmpty &&
                !m.url.contains('storage.example.com') &&
                !m.url.contains('images.unsplash.com'),
            orElse: () => mediaList.first,
          ),
        );
      } catch (_) {
        initialMedia = mediaList.first;
      }
    }

    final rawPhoto = json['photo_url']?.toString();
    final String? serverPhotoUrl = (rawPhoto != null &&
            rawPhoto.isNotEmpty &&
            !rawPhoto.contains('storage.example.com') &&
            !rawPhoto.contains('images.unsplash.com') &&
            !rawPhoto.contains('storage.laporkita.malangkota.go.id'))
        ? rawPhoto
        : (initialMedia != null &&
                initialMedia.url.isNotEmpty &&
                !initialMedia.url.contains('storage.example.com') &&
                !initialMedia.url.contains('images.unsplash.com') &&
                !initialMedia.url.contains('storage.laporkita.malangkota.go.id')
            ? initialMedia.url
            : null);

    double? progressVal;
    if (json['progress_percentage'] is num) {
      progressVal = (json['progress_percentage'] as num).toDouble();
    } else if (json['progress'] is num) {
      progressVal = (json['progress'] as num).toDouble();
      if (progressVal <= 1.0 && progressVal > 0) {
        progressVal = progressVal * 100.0;
      }
    } else if (json['progress_percentage'] != null) {
      progressVal = double.tryParse(json['progress_percentage'].toString());
    } else if (json['progress'] != null) {
      progressVal = double.tryParse(json['progress'].toString());
      if (progressVal != null && progressVal <= 1.0 && progressVal > 0) {
        progressVal = progressVal * 100.0;
      }
    }

    return ReportModel(
      id: json['id']?.toString() ?? '',
      reportCode: json['report_code']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      status: ReportStatus.fromString(json['status']?.toString() ?? ''),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      addressText: json['address_text']?.toString() ??
          json['address']?.toString() ??
          json['location']?.toString(),
      description: (json['description'] != null && json['description'].toString().trim().isNotEmpty)
          ? json['description'].toString().trim()
          : (json['notes'] != null && json['notes'].toString().trim().isNotEmpty)
              ? json['notes'].toString().trim()
              : (json['note'] != null && json['note'].toString().trim().isNotEmpty)
                  ? json['note'].toString().trim()
                  : (json['catatan'] != null && json['catatan'].toString().trim().isNotEmpty)
                      ? json['catatan'].toString().trim()
                      : null,
      directPhotoUrl: serverPhotoUrl,
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
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      rawAiConfidenceScore: json['ai_confidence_score'] != null
          ? double.tryParse(json['ai_confidence_score'].toString())
          : null,
      damageSeverity: json['damage_severity'] != null
          ? double.tryParse(json['damage_severity'].toString())
          : null,
      estimatedCompletionAt: json['estimated_completion_at'] != null
          ? DateTime.tryParse(json['estimated_completion_at'].toString())
              ?.toLocal()
          : null,
      directPriority: json['priority']?.toString() ??
          json['priority_level']?.toString() ??
          json['urgency_level']?.toString(),
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
      progressPercentage: progressVal,
      count: countData != null
          ? {
              'supports': countData['supports'] is int ? countData['supports'] as int : 0,
              'comments': countData['comments'] is int ? countData['comments'] as int : 0,
              'validations': countData['validations'] is int ? countData['validations'] as int : 0,
            }
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_code': reportCode,
      'reporter_id': reporterId,
      'category_id': categoryId,
      'status': status.apiValue,
      'latitude': latitude,
      'longitude': longitude,
      'address_text': addressText,
      'description': description,
      if (directPhotoUrl != null) 'photo_url': directPhotoUrl,
      'support_count': supportCount,
      'view_count': viewCount,
      if (urgencyScore != null) 'urgency_score': urgencyScore,
      'needs_manual_review': needsManualReview,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (rawAiConfidenceScore != null) 'ai_confidence_score': rawAiConfidenceScore,
      if (damageSeverity != null) 'damage_severity': damageSeverity,
      if (estimatedCompletionAt != null)
        'estimated_completion_at': estimatedCompletionAt!.toIso8601String(),
      if (directPriority != null) 'priority': directPriority,
      if (progressPercentage != null) 'progress_percentage': progressPercentage,
      if (category != null) 'category': category,
      if (reporter != null) 'reporter': reporter,
      if (assignedAgency != null) 'assigned_agency': assignedAgency,
      'media': media.map((m) => m.toJson()).toList(),
      'status_history': statusHistory.map((h) => h.toJson()).toList(),
      if (count != null) '_count': count,
    };
  }

  ReportModel copyWith({
    String? id,
    String? reportCode,
    String? reporterId,
    String? categoryId,
    ReportStatus? status,
    double? latitude,
    double? longitude,
    String? addressText,
    String? description,
    String? directPhotoUrl,
    int? supportCount,
    int? viewCount,
    double? urgencyScore,
    bool? needsManualReview,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rawAiConfidenceScore,
    double? damageSeverity,
    DateTime? estimatedCompletionAt,
    String? directPriority,
    double? progressPercentage,
    Map<String, dynamic>? category,
    Map<String, dynamic>? reporter,
    Map<String, dynamic>? assignedAgency,
    List<ReportMediaModel>? media,
    List<ReportStatusHistoryModel>? statusHistory,
    Map<String, int>? count,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportCode: reportCode ?? this.reportCode,
      reporterId: reporterId ?? this.reporterId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressText: addressText ?? this.addressText,
      description: description ?? this.description,
      directPhotoUrl: directPhotoUrl ?? this.directPhotoUrl,
      supportCount: supportCount ?? this.supportCount,
      viewCount: viewCount ?? this.viewCount,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      needsManualReview: needsManualReview ?? this.needsManualReview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rawAiConfidenceScore: rawAiConfidenceScore ?? this.rawAiConfidenceScore,
      damageSeverity: damageSeverity ?? this.damageSeverity,
      estimatedCompletionAt: estimatedCompletionAt ?? this.estimatedCompletionAt,
      directPriority: directPriority ?? this.directPriority,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      category: category ?? this.category,
      reporter: reporter ?? this.reporter,
      assignedAgency: assignedAgency ?? this.assignedAgency,
      media: media ?? this.media,
      statusHistory: statusHistory ?? this.statusHistory,
      count: count ?? this.count,
    );
  }

  /// Persentase progres saat ini (0.0 sampai 1.0)
  double get currentProgress {
    if (progressPercentage != null && progressPercentage! > 0) {
      return (progressPercentage! / 100.0).clamp(0.0, 1.0);
    }
    final regex = RegExp(
      r'(?:\[PROGRESS:\s*|Progress\s*|progres\s*)(\d+)\s*%?\]?',
      caseSensitive: false,
    );
    for (final h in statusHistory.reversed) {
      if (h.note != null && h.note!.isNotEmpty) {
        final match = regex.firstMatch(h.note!);
        if (match != null) {
          final pct = double.tryParse(match.group(1)!);
          if (pct != null && pct >= 0 && pct <= 100) {
            return (pct / 100.0).clamp(0.0, 1.0);
          }
        }
      }
    }
    switch (status) {
      case ReportStatus.pendingVerification:
        return 0.15;
      case ReportStatus.verified:
        return 0.30;
      case ReportStatus.assigned:
        return 0.40;
      case ReportStatus.inProgress:
        return 0.50;
      case ReportStatus.completed:
        return 0.95;
      case ReportStatus.resolved:
        return 1.0;
      case ReportStatus.rejected:
        return 0.0;
      case ReportStatus.disputed:
        return 0.50;
    }
  }

  /// Confidence score hasil verifikasi AI server-side (null jika backend tidak kirim).
  double? get aiConfidenceScore => rawAiConfidenceScore;

  /// URL foto utama laporan (fallback dari photo_url -> media.first.url)
  String? get photoUrl {
    // 1. Cek directPhotoUrl jika merupakan URL remote valid
    if (directPhotoUrl != null && directPhotoUrl!.isNotEmpty) {
      if ((directPhotoUrl!.startsWith('http://') ||
              directPhotoUrl!.startsWith('https://')) &&
          !directPhotoUrl!.contains('images.unsplash.com') &&
          !directPhotoUrl!.contains('storage.example.com') &&
          !directPhotoUrl!.contains('storage.laporkita.malangkota.go.id')) {
        return directPhotoUrl;
      }
      // 2. Jika merupakan file lokal, pastikan file fisik benar-benar ada di perangkat ini
      if (!directPhotoUrl!.startsWith('http')) {
        try {
          if (File(directPhotoUrl!).existsSync()) {
            return directPhotoUrl;
          }
        } catch (_) {}
      }
    }

    // 3. Ambil foto riil dari media backend (prioritaskan type: initial_photo dari server/Supabase)
    if (media.isNotEmpty) {
      final initialMedia = media.where(
        (m) =>
            m.type == 'initial_photo' &&
            m.url.isNotEmpty &&
            !m.url.contains('storage.example.com') &&
            !m.url.contains('images.unsplash.com') &&
            !m.url.contains('storage.laporkita.malangkota.go.id'),
      );
      if (initialMedia.isNotEmpty) {
        return initialMedia.first.url;
      }
      for (final m in media) {
        if (m.url.isNotEmpty &&
            !m.url.contains('storage.example.com') &&
            !m.url.contains('images.unsplash.com') &&
            !m.url.contains('storage.laporkita.malangkota.go.id')) {
          return m.url;
        }
      }
    }

    // 4. Fallback jika ada directPhotoUrl yang bukan dummy
    if (directPhotoUrl != null &&
        directPhotoUrl!.isNotEmpty &&
        !directPhotoUrl!.contains('images.unsplash.com') &&
        !directPhotoUrl!.contains('storage.example.com') &&
        !directPhotoUrl!.contains('storage.laporkita.malangkota.go.id')) {
      return directPhotoUrl;
    }

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
      return 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop';
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
    // Domain dummy test suite QA atau dummy Unsplash atau domain internal unreachable
    if (raw.contains('storage.example.com') ||
        raw.contains('images.unsplash.com') ||
        raw.contains('storage.laporkita.malangkota.go.id')) {
      return null;
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
  String get categoryName {
    final name = category?['name'] as String?;
    if (name != null && name.trim().isNotEmpty && name.toLowerCase() != 'umum') {
      return name;
    }
    // Fallback dari categoryId jika backend mengembalikan baris tanpa relational join
    switch (categoryId) {
      case 'c1000000-0000-4000-8000-000000000001':
        return 'Jalan Berlubang';
      case 'c2000000-0000-4000-8000-000000000002':
        return 'Lampu Jalan';
      case 'c3000000-0000-4000-8000-000000000003':
        return 'Rambu Lalu Lintas';
      case 'c4000000-0000-4000-8000-000000000004':
        return 'Trotoar';
      case 'c5000000-0000-4000-8000-000000000005':
        return 'Drainase';
      case 'cat-sampah':
        return 'Sampah & Kebersihan';
      case 'cat-fasilitas':
        return 'Fasilitas Umum';
      default:
        if (name != null && name.trim().isNotEmpty) return name;
        return 'Fasilitas Umum';
    }
  }

  /// Nama pelapor
  String get reporterName => reporter?['full_name'] as String? ?? 'Anonim';

  /// Label prioritas laporan disesuaikan secara dinamis dengan input & metrik backend
  String get priorityLabel {
    // 1. Cek prioritas langsung (eksplisit) dari payload backend atau input operator
    if (directPriority != null && directPriority!.isNotEmpty) {
      final p = directPriority!.toLowerCase();
      if (p.contains('tinggi') || p == 'high' || p == 'urgent') return 'Prioritas Tinggi';
      if (p.contains('perlu penanganan') || p.contains('manual')) return 'Perlu Penanganan';
      if (p.contains('sedang') || p == 'medium') return 'Sedang';
      if (p.contains('rendah') || p == 'low') return 'Rendah';
    }

    // 2. Cek riwayat status / catatan penugasan backend (input manual operator/admin)
    // Gunakan urutan reversed agar input paling mutakhir yang diprioritaskan
    for (final h in statusHistory.reversed) {
      final note = (h.note ?? '').toLowerCase();
      if (note.contains('prioritas:') ||
          note.contains('prioritas :') ||
          note.contains('prioritas')) {
        if (note.contains('tinggi')) return 'Prioritas Tinggi';
        if (note.contains('perlu penanganan')) return 'Perlu Penanganan';
        if (note.contains('sedang')) return 'Sedang';
        if (note.contains('rendah')) return 'Rendah';
      }
    }

    // 3. Cek apakah laporan memerlukan review manual (needs_manual_review)
    if (needsManualReview) {
      return 'Perlu Penanganan';
    }

    // 4. Cek tingkat keparahan kerusakan (damage_severity) dari AI backend.
    // Normalisasi ke skala 0-100 agar konsisten apapun format backend.
    final damage = damageSeverity;
    if (damage != null) {
      final d100 = damage <= 1.0 ? damage * 100 : damage;
      if (d100 >= 70) {
        return 'Prioritas Tinggi';
      } else if (d100 >= 40) {
        return 'Sedang';
      } else if (d100 > 0) {
        return 'Rendah';
      }
    }

    // 5. Cek skor urgensi (urgency_score) dari formula backend (aiservice.md §1.3).
    // Normalisasi ke skala 0-100 yang sama.
    final urgency = urgencyScore;
    if (urgency != null) {
      final u100 = urgency <= 1.0 ? urgency * 100 : urgency;
      if (u100 >= 70) {
        return 'Prioritas Tinggi';
      } else if (u100 >= 40) {
        return 'Perlu Penanganan';
      } else if (u100 >= 20) {
        if ((damage ?? 0) >= 0.50 ||
            categoryName.toLowerCase().contains('jalan')) {
          return 'Prioritas Tinggi';
        }
        return 'Sedang';
      } else if (u100 > 0) {
        return 'Rendah';
      }
    }

    // 6. Fallback representatif berdasarkan kategori
    final cat = categoryName.toLowerCase();
    if (cat.contains('trotoar')) {
      return 'Perlu Penanganan';
    } else if (cat.contains('jalan') || cat.contains('lubang')) {
      return 'Prioritas Tinggi';
    } else if (cat.contains('halte') || cat.contains('lampu')) {
      return 'Sedang';
    }

    return 'Sedang';
  }

  /// Warna teks badge prioritas
  Color get priorityColor {
    final p = priorityLabel;
    if (p == 'Prioritas Tinggi') return const Color(0xFFC60D05);
    if (p == 'Perlu Penanganan' || p == 'Sedang') return const Color(0xFFF2AE01);
    return const Color(0xFF1D9C51);
  }

  /// Warna latar belakang badge prioritas
  Color get priorityBgColor {
    final p = priorityLabel;
    if (p == 'Prioritas Tinggi') return const Color(0xFFFFE9E9);
    if (p == 'Perlu Penanganan' || p == 'Sedang') return const Color(0xFFFFF9E9);
    return const Color(0xFFE8F5E9);
  }

  /// Skor prioritas berbasis skala 100 untuk ringkasan AI di detail laporan
  int get priorityScoreOutOf100 {
    final p = priorityLabel;
    if (p == 'Prioritas Tinggi') {
      if (damageSeverity != null && damageSeverity! > 0) {
        return (damageSeverity! <= 1.0 ? damageSeverity! * 100 : damageSeverity!)
            .round()
            .clamp(75, 98);
      }
      return 85;
    }
    if (p == 'Perlu Penanganan') return 70;
    if (p == 'Sedang') {
      if (damageSeverity != null && damageSeverity! > 0) {
        return (damageSeverity! <= 1.0 ? damageSeverity! * 100 : damageSeverity!)
            .round()
            .clamp(45, 69);
      }
      return 60;
    }
    if (damageSeverity != null && damageSeverity! > 0) {
      return (damageSeverity! <= 1.0 ? damageSeverity! * 100 : damageSeverity!)
          .round()
          .clamp(15, 40);
    }
    return 35;
  }

  /// Formatted report code with leading '#'
  String get formattedReportCode =>
      reportCode.startsWith('#') ? reportCode : '#$reportCode';

  /// Primary photo url of the report
  String? get primaryPhotoUrl {
    if (directPhotoUrl != null && directPhotoUrl!.isNotEmpty) {
      return formattedPhotoUrl ?? directPhotoUrl;
    }
    if (media.isNotEmpty) {
      try {
        final initial = media.firstWhere(
          (m) => m.formattedUrl.isNotEmpty || m.url.isNotEmpty,
          orElse: () => media.first,
        );
        if (initial.formattedUrl.isNotEmpty) return initial.formattedUrl;
        if (initial.url.isNotEmpty) return initial.url;
      } catch (_) {}
    }
    return null;
  }

  /// URL foto bukti penyelesaian (completion_photo / validation_photo)
  String? get completionPhotoUrl {
    if (media.isNotEmpty) {
      final completion = media.where(
        (m) =>
            (m.type == 'completion_photo' ||
             m.type == 'validation_photo' ||
             m.type == 'completed' ||
             m.type == 'completion') &&
            m.url.isNotEmpty &&
            !m.url.contains('storage.example.com'),
      );
      if (completion.isNotEmpty) {
        return completion.last.formattedUrl.isNotEmpty
            ? completion.last.formattedUrl
            : completion.last.url;
      }
      final anyCompletion = media.where((m) =>
          (m.type == 'completion_photo' || m.type == 'validation_photo') &&
          m.url.isNotEmpty);
      if (anyCompletion.isNotEmpty) {
        return anyCompletion.last.formattedUrl.isNotEmpty
            ? anyCompletion.last.formattedUrl
            : anyCompletion.last.url;
      }
    }
    return null;
  }
}
