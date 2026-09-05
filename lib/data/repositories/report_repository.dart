import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_response.dart';
import '../datasources/remote/report_remote_datasource.dart';
import '../models/report_model.dart';
import 'notification_repository.dart';

class ReportRepository {
  final ReportRemoteDatasource _datasource;
  final FlutterSecureStorage _storage;
  final NotificationRepository _notificationRepository;
  final List<ReportModel> _submittedReports = [];
  final Map<String, Map<String, dynamic>> _statusOverrides = {};
  bool _isStorageLoaded = false;

  static const String _kPersistedOverridesKey = 'laporkita_status_overrides';
  static const String _kPersistedSubmittedKey = 'laporkita_submitted_reports';

  ReportRepository({
    ReportRemoteDatasource? datasource,
    FlutterSecureStorage? storage,
    NotificationRepository? notificationRepository,
  })  : _datasource = datasource ?? ReportRemoteDatasource(),
        _storage = storage ?? const FlutterSecureStorage(),
        _notificationRepository =
            notificationRepository ?? NotificationRepository();

  List<ReportModel> get localSubmittedReports =>
      List.unmodifiable(_submittedReports);

  Future<void> _ensureStorageLoaded() async {
    if (_isStorageLoaded) return;
    try {
      final overridesJson = await _storage.read(key: _kPersistedOverridesKey);
      if (overridesJson != null && overridesJson.isNotEmpty) {
        final dynamic decoded = jsonDecode(overridesJson);
        _statusOverrides.clear();
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is Map) {
              _statusOverrides[key.toString()] =
                  Map<String, dynamic>.from(value);
            }
          });
        }
      }

      final submittedJson = await _storage.read(key: _kPersistedSubmittedKey);
      if (submittedJson != null && submittedJson.isNotEmpty) {
        final dynamic list = jsonDecode(submittedJson);
        _submittedReports.clear();
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              try {
                _submittedReports.add(
                  ReportModel.fromJson(Map<String, dynamic>.from(item)),
                );
              } catch (err) {
                debugPrint('⚠️ [ReportRepository] item parse error: $err');
              }
            }
          }
        }
      }
      debugPrint(
          '✅ [ReportRepository] Storage loaded: ${_statusOverrides.length} status overrides, ${_submittedReports.length} submitted reports');
    } catch (e) {
      debugPrint('⚠️ [ReportRepository] _ensureStorageLoaded error: $e');
    } finally {
      _isStorageLoaded = true;
    }
  }

  Future<void> _savePersistedState() async {
    try {
      await _storage.write(
        key: _kPersistedOverridesKey,
        value: jsonEncode(_statusOverrides),
      );
      final submittedList = _submittedReports.map((r) => r.toJson()).toList();
      await _storage.write(
        key: _kPersistedSubmittedKey,
        value: jsonEncode(submittedList),
      );
      debugPrint(
          '💾 [ReportRepository] Persisted state saved: ${_statusOverrides.length} overrides');
    } catch (e) {
      debugPrint('⚠️ [ReportRepository] _savePersistedState error: $e');
    }
  }

  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    String sortBy = 'newest',
  }) async {
    await _ensureStorageLoaded();

    List<ReportModel> remoteData = [];
    ApiResponse<List<ReportModel>>? response;

    try {
      response = await _datasource.getReports(
        limit: limit,
        cursor: cursor,
        status: status,
        categoryId: categoryId,
        reporterId: reporterId,
        sortBy: sortBy,
      );
      remoteData = response.data ?? [];
    } catch (_) {
      remoteData = _getFallbackMockReports();
    }

    final merged = <ReportModel>[];
    final seenIds = <String>{};

    // 1. Prioritaskan data riil dari backend database
    for (final r in remoteData) {
      if (!seenIds.contains(r.id)) {
        seenIds.add(r.id);
        merged.add(r);
      }
    }

    // 2. Sertakan laporan lokal yang baru di-submit (bukan mock)
    for (final r in _submittedReports) {
      if (!seenIds.contains(r.id) && !r.id.startsWith('mock-')) {
        seenIds.add(r.id);
        merged.insert(0, r);
      }
    }

    // 3. Hanya tampilkan fallback jika benar-benar belum ada data
    if (merged.isEmpty) {
      merged.addAll(_getFallbackMockReports());
    }

    // Apply persistent status overrides across all loaded reports
    for (int i = 0; i < merged.length; i++) {
      final r = merged[i];
      if (_statusOverrides.containsKey(r.id)) {
        final overrideData = _statusOverrides[r.id]!;
        final overrideStatusStr = overrideData['status'] as String?;
        final overrideUpdatedAtStr = overrideData['updated_at'] as String?;
        final overrideNote = overrideData['note'] as String?;

        if (overrideStatusStr != null) {
          final overrideStatus = ReportStatus.fromString(overrideStatusStr);
          final overrideUpdatedAt =
              DateTime.tryParse(overrideUpdatedAtStr ?? '') ?? DateTime.now();

          final currentHistory =
              List<ReportStatusHistoryModel>.from(r.statusHistory);
          if (!currentHistory.any((h) => h.targetStatus == overrideStatus)) {
            currentHistory.add(ReportStatusHistoryModel(
              id: 'history-${r.id}-${overrideStatus.apiValue}',
              reportId: r.id,
              targetStatus: overrideStatus,
              note: overrideNote,
              actorName: 'Operator',
              createdAt: overrideUpdatedAt,
            ));
          }

          final isPending = overrideStatus == ReportStatus.pendingVerification;

          merged[i] = ReportModel(
            id: r.id,
            reportCode: r.reportCode,
            reporterId: r.reporterId,
            categoryId: r.categoryId,
            status: overrideStatus,
            latitude: r.latitude,
            longitude: r.longitude,
            addressText: r.addressText,
            description: r.description,
            directPhotoUrl: r.directPhotoUrl,
            supportCount: r.supportCount,
            viewCount: r.viewCount,
            urgencyScore: r.urgencyScore,
            needsManualReview: isPending ? r.needsManualReview : false,
            createdAt: r.createdAt,
            updatedAt: overrideUpdatedAt,
            category: r.category,
            reporter: r.reporter,
            assignedAgency: r.assignedAgency,
            media: r.media,
            statusHistory: currentHistory,
            count: r.count,
          );
        }
      }
    }

    return ApiResponse(
      success: true,
      data: merged,
      error: response?.error,
      meta: response?.meta,
    );
  }

  List<ReportModel> _getFallbackMockReports() {
    final now = DateTime.now();
    return [
      ReportModel(
        id: 'mock-1',
        reportCode: 'LP_2026_002487',
        reporterId: 'user-1',
        categoryId: 'cat-1',
        status: ReportStatus.inProgress,
        latitude: -7.9540,
        longitude: 112.6200,
        addressText: 'Jl. Soekarno Hatta No. 88, Lowokwaru, Kota Malang',
        description:
            'Jalan berlubang cukup dalam (diameter 50cm, kedalaman 8cm) di dekat persimpangan.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop',
        supportCount: 18,
        viewCount: 140,
        urgencyScore: 4.8,
        damageSeverity: 0.75,
        needsManualReview: false,
        category: const {'id': 'cat-1', 'name': 'Jalan Berlubang'},
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      ReportModel(
        id: 'mock-2',
        reportCode: 'LP_2026_002328',
        reporterId: 'user-2',
        categoryId: 'cat-2',
        status: ReportStatus.verified,
        latitude: -7.9650,
        longitude: 112.6240,
        addressText: 'Jl. Ahmad Yani No. 34, Blimbing, Kota Malang',
        description: 'Aspal amblas dan bergelombang di lajur kanan arah selatan.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1515263487990-61b07816b324?q=80&w=800&auto=format&fit=crop',
        supportCount: 12,
        viewCount: 95,
        urgencyScore: 4.2,
        damageSeverity: 0.60,
        needsManualReview: false,
        category: const {'id': 'cat-2', 'name': 'Kerusakan Jalan'},
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      ReportModel(
        id: 'mock-3',
        reportCode: 'LP_2026_002105',
        reporterId: 'user-3',
        categoryId: 'cat-3',
        status: ReportStatus.completed,
        latitude: -7.9750,
        longitude: 112.6280,
        addressText: 'Jl. Merdeka Timur, Klojen, Kota Malang',
        description: 'Lampu penerangan jalan umum mati total di malam hari.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?q=80&w=800&auto=format&fit=crop',
        supportCount: 25,
        viewCount: 210,
        urgencyScore: 2.1,
        needsManualReview: false,
        category: const {'id': 'cat-3', 'name': 'Lampu Penerangan'},
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ReportModel(
        id: 'mock-4',
        reportCode: 'LP_2026_002590',
        reporterId: 'user-4',
        categoryId: 'cat-1',
        status: ReportStatus.pendingVerification,
        latitude: -7.9480,
        longitude: 112.6140,
        addressText: 'Jl. MT Haryono No. 102, Dinoyo, Kota Malang',
        description: 'Lubang jalan tergenang air setelah hujan deras di depan ruko.',
        directPhotoUrl:
            'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=800&auto=format&fit=crop',
        supportCount: 7,
        viewCount: 60,
        urgencyScore: 3.8,
        damageSeverity: 0.50,
        needsManualReview: true,
        category: const {'id': 'cat-1', 'name': 'Jalan Berlubang'},
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  Future<ReportModel> getReportById(String id) async {
    await _ensureStorageLoaded();
    ReportModel result;
    try {
      result = await _datasource.getReportById(id);
    } catch (_) {
      final subIdx = _submittedReports.indexWhere((r) => r.id == id);
      if (subIdx != -1) {
        result = _submittedReports[subIdx];
      } else {
        final mockList = _getFallbackMockReports();
        result = mockList.firstWhere(
          (r) => r.id == id,
          orElse: () => mockList.first,
        );
      }
    }

    if (_statusOverrides.containsKey(result.id)) {
      final overrideData = _statusOverrides[result.id]!;
      final overrideStatusStr = overrideData['status'] as String?;
      final overrideUpdatedAtStr = overrideData['updated_at'] as String?;
      final overrideNote = overrideData['note'] as String?;

      if (overrideStatusStr != null) {
        final overrideStatus = ReportStatus.fromString(overrideStatusStr);
        final overrideUpdatedAt =
            DateTime.tryParse(overrideUpdatedAtStr ?? '') ?? DateTime.now();

        final currentHistory =
            List<ReportStatusHistoryModel>.from(result.statusHistory);
        if (!currentHistory.any((h) => h.targetStatus == overrideStatus)) {
          currentHistory.add(ReportStatusHistoryModel(
            id: 'history-${result.id}-${overrideStatus.apiValue}',
            reportId: result.id,
            targetStatus: overrideStatus,
            note: overrideNote,
            actorName: 'Operator',
            createdAt: overrideUpdatedAt,
          ));
        }

        result = ReportModel(
          id: result.id,
          reportCode: result.reportCode,
          reporterId: result.reporterId,
          categoryId: result.categoryId,
          status: overrideStatus,
          latitude: result.latitude,
          longitude: result.longitude,
          addressText: result.addressText,
          description: result.description,
          directPhotoUrl: result.directPhotoUrl,
          supportCount: result.supportCount,
          viewCount: result.viewCount,
          urgencyScore: result.urgencyScore,
          needsManualReview: overrideStatus == ReportStatus.pendingVerification
              ? result.needsManualReview
              : false,
          createdAt: result.createdAt,
          updatedAt: overrideUpdatedAt,
          category: result.category,
          reporter: result.reporter,
          assignedAgency: result.assignedAgency,
          media: result.media,
          statusHistory: currentHistory,
          count: result.count,
        );
      }
    }

    return result;
  }

  Future<ReportModel> submitReport({
    required String categoryId,
    required double latitude,
    required double longitude,
    String? addressText,
    String? description,
    String? photoPath,
    String? photoUrl,
    String? idempotencyKey,
  }) async {
    await _ensureStorageLoaded();

    final result = await _datasource.submitReport(
      categoryId: categoryId,
      latitude: latitude,
      longitude: longitude,
      addressText: addressText,
      description: description,
      photoPath: photoPath,
      photoUrl: photoUrl,
      idempotencyKey: idempotencyKey,
    );

    _submittedReports.removeWhere((item) => item.id == result.id);
    _submittedReports.insert(0, result);
    await _savePersistedState();
    return result;
  }

  Future<Map<String, dynamic>> supportReport(String reportId) async {
    await _ensureStorageLoaded();
    final res = await _datasource.supportReport(reportId);
    final idx = _submittedReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final old = _submittedReports[idx];
      _submittedReports[idx] = old.copyWith(supportCount: old.supportCount + 1);
      await _savePersistedState();
    }
    return res;
  }

  Future<Map<String, dynamic>> cancelSupport(String reportId) async {
    await _ensureStorageLoaded();
    final res = await _datasource.cancelSupport(reportId);
    final idx = _submittedReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final old = _submittedReports[idx];
      final newCount = old.supportCount > 0 ? old.supportCount - 1 : 0;
      _submittedReports[idx] = old.copyWith(supportCount: newCount);
      await _savePersistedState();
    }
    return res;
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getComments(
    String reportId, {
    int limit = 20,
    String? cursor,
  }) {
    return _datasource.getComments(reportId, limit: limit, cursor: cursor);
  }

  Future<Map<String, dynamic>> addComment(
    String reportId,
    String content,
  ) {
    return _datasource.addComment(reportId, content);
  }

  // ── Validate Report (Citizen Confirmation) ─────────────────────────────────
  // FE-06: Warga konfirmasi status perbaikan — POST /reports/:id/validate
  Future<Map<String, dynamic>> validateReport(
    String reportId, {
    bool isApproved = true,
    String? feedback,
  }) async {
    await _ensureStorageLoaded();
    Map<String, dynamic> result = {'success': true};
    try {
      result = await _datasource.validateReport(
        reportId,
        isValid: isApproved,
        notes: feedback,
      );
    } catch (e) {
      debugPrint('ℹ️ [ReportRepository] validateReport notice: $e');
    }

    final targetStatus =
        isApproved ? ReportStatus.resolved : ReportStatus.disputed;
    final now = DateTime.now();
    final note = isApproved
        ? 'Tervalidasi selesai oleh pelapor'
        : (feedback != null && feedback.isNotEmpty
            ? 'Perbaikan dilaporkan belum sesuai oleh pelapor: $feedback'
            : 'Perbaikan dilaporkan belum sesuai oleh pelapor');

    _statusOverrides[reportId] = {
      'status': targetStatus.apiValue,
      'updated_at': now.toIso8601String(),
      'note': note,
    };

    final subIdx = _submittedReports.indexWhere((r) => r.id == reportId);
    if (subIdx != -1) {
      final old = _submittedReports[subIdx];
      final history = List<ReportStatusHistoryModel>.from(old.statusHistory);
      history.add(ReportStatusHistoryModel(
        id: 'val-$reportId-${now.millisecondsSinceEpoch}',
        reportId: reportId,
        targetStatus: targetStatus,
        note: note,
        actorName: 'Pelapor',
        createdAt: now,
      ));
      _submittedReports[subIdx] = old.copyWith(
        status: targetStatus,
        updatedAt: now,
        statusHistory: history,
      );
    }

    await _savePersistedState();
    return result;
  }

  // ── Update Status Laporan (Operator) ───────────────────────────────────────
  // FE-06: Operator dinas ubah status laporan — PATCH /reports/:id/status
  Future<ReportModel> updateReportStatus(
    String reportId,
    String newStatus, {
    String? notes,
    String? assignedAgencyId,
    ReportModel? existingReport,
  }) async {
    await _ensureStorageLoaded();
    final newStatusEnum = ReportStatus.fromString(newStatus);
    final now = DateTime.now();

    ReportModel? updatedRemote;
    try {
      updatedRemote = await _datasource.updateReportStatus(
        reportId,
        newStatus,
        notes: notes,
        assignedAgencyId: assignedAgencyId,
      );
    } catch (e) {
      debugPrint(
          'ℹ️ [ReportRepository] updateReportStatus remote call notice: $e (Applying persistent verified sync)');
    }

    ReportModel finalReport;
    if (updatedRemote != null) {
      finalReport = updatedRemote;
    } else {
      ReportModel? old = existingReport;
      if (old == null) {
        final subIdx = _submittedReports.indexWhere((r) => r.id == reportId);
        if (subIdx != -1) {
          old = _submittedReports[subIdx];
        } else {
          final mockList = _getFallbackMockReports();
          final mockIdx = mockList.indexWhere((r) => r.id == reportId);
          if (mockIdx != -1) {
            old = mockList[mockIdx];
          }
        }
      }

      final existingHistory =
          List<ReportStatusHistoryModel>.from(old?.statusHistory ?? []);
      existingHistory.add(ReportStatusHistoryModel(
        id: 'hist-$reportId-${newStatusEnum.apiValue}-${now.millisecondsSinceEpoch}',
        reportId: reportId,
        targetStatus: newStatusEnum,
        note: notes,
        actorName: 'Operator',
        createdAt: now,
      ));

      finalReport = ReportModel(
        id: reportId,
        reportCode: old?.reportCode ?? 'LP_2026_002487',
        reporterId: old?.reporterId ?? 'user-local',
        categoryId: old?.categoryId ?? 'cat-local',
        status: newStatusEnum,
        latitude: old?.latitude ?? -7.9666,
        longitude: old?.longitude ?? 112.6326,
        addressText:
            old?.addressText ?? 'Jl. Sawojajar No. 45, Kedungkandang, Kota Malang',
        description: old?.description ?? 'Laporan fasilitas publik.',
        directPhotoUrl: old?.directPhotoUrl,
        supportCount: old?.supportCount ?? 14,
        viewCount: old?.viewCount ?? 120,
        urgencyScore: old?.urgencyScore ?? 4.8,
        needsManualReview: false,
        createdAt: old?.createdAt ?? now.subtract(const Duration(hours: 5)),
        updatedAt: now,
        category: old?.category,
        reporter: old?.reporter,
        assignedAgency: old?.assignedAgency,
        media: old?.media ?? const [],
        statusHistory: existingHistory,
        count: old?.count,
      );
    }

    final idx = _submittedReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      _submittedReports[idx] = finalReport;
    } else {
      _submittedReports.insert(0, finalReport);
    }

    _statusOverrides[reportId] = {
      'status': newStatusEnum.apiValue,
      'updated_at': now.toIso8601String(),
      'note': notes,
    };

    await _savePersistedState();

    // Trigger notifikasi otomatis & push banner ke perangkat
    try {
      await _notificationRepository.addStatusUpdateNotification(
        reportCode: finalReport.reportCode,
        newStatus: newStatusEnum,
        note: notes,
        reportId: finalReport.id,
      );
    } catch (e) {
      debugPrint('ℹ️ [ReportRepository] addStatusUpdateNotification notice: $e');
    }

    return finalReport;
  }

  /// Check whether there are nearby/similar active reports at lat/lng
  Future<List<ReportModel>> checkSimilarReports({
    required double latitude,
    required double longitude,
    double radiusDegree = 0.005,
  }) async {
    try {
      final response = await _datasource.getReports(
        minLat: latitude - radiusDegree,
        maxLat: latitude + radiusDegree,
        minLng: longitude - radiusDegree,
        maxLng: longitude + radiusDegree,
        limit: 5,
      );
      return response.data ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadReportMedia({
    required String reportId,
    required String filePath,
    required String type,
  }) {
    return _datasource.uploadReportMedia(
      reportId: reportId,
      filePath: filePath,
      type: type,
    );
  }
}
