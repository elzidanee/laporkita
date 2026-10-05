import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
  final Map<String, ReportModel> _cachedReports = {};
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

  void cacheReport(ReportModel report) {
    _cachedReports[report.id] = report;
  }

  void cacheReports(Iterable<ReportModel> list) {
    for (final r in list) {
      _cachedReports[r.id] = r;
    }
  }

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
    bool? needsManualReview,
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
        needsManualReview: needsManualReview,
        sortBy: sortBy,
      );
      remoteData = response.data ?? [];
    } catch (e) {
      // API gagal — gunakan data yang sudah di-cache/_submittedReports saja.
      // Jangan fallback ke mock agar production tidak menampilkan data palsu.
      debugPrint('⚠️ [ReportRepository] getReports error: $e');
      remoteData = [];
    }

    final merged = <ReportModel>[];
    final seenIds = <String>{};

    // 1. Prioritaskan data riil dari backend database
    for (final r in remoteData) {
      ReportModel reportToAdd = r;
      // Periksa apakah perangkat lokal memiliki berkas foto asli dari kamera untuk laporan ini
      final existingLocal = _submittedReports.cast<ReportModel?>().firstWhere(
        (sub) =>
            sub != null &&
            (sub.id == r.id ||
                (sub.reportCode.isNotEmpty && sub.reportCode == r.reportCode)),
        orElse: () => null,
      );
      if (existingLocal?.directPhotoUrl != null) {
        final localPath = existingLocal!.directPhotoUrl!;
        if (!localPath.startsWith('http')) {
          try {
            if (File(localPath).existsSync()) {
              reportToAdd = reportToAdd.copyWith(directPhotoUrl: localPath);
            }
          } catch (_) {}
        }
      }
      if (existingLocal?.description != null &&
          existingLocal!.description!.isNotEmpty &&
          (reportToAdd.description == null || reportToAdd.description!.isEmpty)) {
        reportToAdd = reportToAdd.copyWith(description: existingLocal.description);
      }

      _cachedReports[reportToAdd.id] = reportToAdd;
      if (!seenIds.contains(reportToAdd.id)) {
        seenIds.add(reportToAdd.id);
        merged.add(reportToAdd);
      }
    }

    // 2. Sertakan laporan lokal yang baru di-submit (bukan mock)
    for (final r in _submittedReports) {
      _cachedReports[r.id] = r;
      if (!seenIds.contains(r.id) && !r.id.startsWith('mock-')) {
        seenIds.add(r.id);
        merged.insert(0, r);
      }
    }

    // 3. Fallback mock HANYA untuk development/debug — tidak boleh tampil di production
    // tanpa user mengetahui bahwa ini adalah data simulasi.
    // Jika API gagal dan tidak ada data tersimpan, biarkan list kosong
    // agar UI menampilkan empty state yang sesungguhnya.
    if (merged.isEmpty && kDebugMode) {
      debugPrint('⚠️ [ReportRepository] Tidak ada data dari server maupun lokal. '
          'Menampilkan mock fallback (DEBUG only) — pastikan koneksi ke backend normal di production.');
      final mockReports = _getFallbackMockReports();
      for (final m in mockReports) {
        _cachedReports[m.id] = m;
      }
      merged.addAll(mockReports);
    }

    // _statusOverrides HANYA diterapkan ke laporan lokal yang belum dikonfirmasi server.
    // Laporan yang status-nya baru diterima dari API TIDAK boleh dioverride.
    // Backend adalah single source of truth — server status selalu menang.
    final serverIds = remoteData.map((r) => r.id).toSet();

    for (int i = 0; i < merged.length; i++) {
      final r = merged[i];
      // Skip: laporan dari server — gunakan status backend apa adanya
      if (serverIds.contains(r.id)) continue;

      // Hanya terapkan override untuk laporan lokal (_submittedReports)
      // yang belum ada di server response (misalnya baru di-submit, belum sync)
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
            damageSeverity: r.damageSeverity,
            rawAiConfidenceScore: r.rawAiConfidenceScore,
            directPriority: r.directPriority,
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
        directPhotoUrl: null,
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
        directPhotoUrl: null,
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
        directPhotoUrl: null,
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
        directPhotoUrl: null,
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

    // Resolusi jika ID yang dioper adalah report_code (misal #LP-2026-000007 atau LP-2026-000007)
    if (id.startsWith('#') || id.startsWith('LP-') || id.startsWith('LP_')) {
      final codeToMatch = id.toLowerCase();
      final localMatch = _cachedReports.values.cast<ReportModel?>().firstWhere(
            (r) =>
                r?.reportCode.toLowerCase() == codeToMatch ||
                r?.formattedReportCode.toLowerCase() == codeToMatch,
            orElse: () => _submittedReports.cast<ReportModel?>().firstWhere(
                  (r) =>
                      r?.reportCode.toLowerCase() == codeToMatch ||
                      r?.formattedReportCode.toLowerCase() == codeToMatch,
                  orElse: () => null,
                ),
          );
      if (localMatch != null) {
        id = localMatch.id;
      } else {
        try {
          final res = await getReports(limit: 50);
          final match = res.data?.firstWhere(
            (r) =>
                r.reportCode.toLowerCase() == codeToMatch ||
                r.formattedReportCode.toLowerCase() == codeToMatch,
            orElse: () => res.data!.first,
          );
          if (match != null) id = match.id;
        } catch (_) {}
      }
    }

    ReportModel result;
    bool fromServer = false;
    try {
      result = await _datasource.getReportById(id);
      _cachedReports[id] = result;
      fromServer = true;
    } catch (e) {
      debugPrint('⚠️ [ReportRepository] getReportById error: $e');
      // Fallback ke data yang sudah di-cache (data riil dari request sebelumnya)
      final subIdx = _submittedReports.indexWhere((r) => r.id == id);
      if (subIdx != -1) {
        result = _submittedReports[subIdx];
      } else if (_cachedReports.containsKey(id)) {
        result = _cachedReports[id]!;
      } else {
        // Tidak ada cache riil — rethrow agar UI menampilkan error/retry
        // dan tidak menampilkan data mock sebagai data asli production
        rethrow;
      }
    }

    // _statusOverrides hanya diterapkan jika data TIDAK berasal dari server.
    // Jika data fresh dari API, backend adalah source of truth — override diabaikan.
    if (!fromServer && _statusOverrides.containsKey(result.id)) {
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
          damageSeverity: result.damageSeverity,
          rawAiConfidenceScore: result.rawAiConfidenceScore,
          directPriority: result.directPriority,
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

    if (result.directPhotoUrl == null || result.directPhotoUrl!.startsWith('http')) {
      final existingLocal = _submittedReports.cast<ReportModel?>().firstWhere(
        (sub) =>
            sub != null &&
            (sub.id == result.id ||
                (sub.reportCode.isNotEmpty && sub.reportCode == result.reportCode)),
        orElse: () => null,
      );
      if (existingLocal?.directPhotoUrl != null &&
          !existingLocal!.directPhotoUrl!.startsWith('http')) {
        try {
          if (File(existingLocal.directPhotoUrl!).existsSync()) {
            result = result.copyWith(directPhotoUrl: existingLocal.directPhotoUrl);
          }
        } catch (_) {}
      }
      if ((result.description == null || result.description!.isEmpty) &&
          existingLocal?.description != null &&
          existingLocal!.description!.isNotEmpty) {
        result = result.copyWith(description: existingLocal.description);
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

    var result = await _datasource.submitReport(
      categoryId: categoryId,
      latitude: latitude,
      longitude: longitude,
      addressText: addressText,
      description: description,
      photoPath: photoPath,
      photoUrl: photoUrl,
      idempotencyKey: idempotencyKey,
    );

    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      try {
        if (File(photoPath).existsSync()) {
          result = result.copyWith(directPhotoUrl: photoPath);
        }
      } catch (_) {}
    }

    if ((result.description == null || result.description!.isEmpty) &&
        description != null &&
        description.isNotEmpty) {
      result = result.copyWith(description: description);
    }

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
  // Backend menentukan status akhir (resolved / in_progress / disputed).
  // Frontend TIDAK boleh menentukan status sendiri.
  Future<Map<String, dynamic>> validateReport(
    String reportId, {
    bool isApproved = true,
    String? feedback,
    double? latitude,
    double? longitude,
  }) async {
    await _ensureStorageLoaded();

    if (reportId.startsWith('mock-')) {
      final old = _cachedReports[reportId] ??
          _submittedReports.firstWhere(
            (r) => r.id == reportId,
            orElse: () => _getFallbackMockReports().firstWhere(
              (r) => r.id == reportId,
              orElse: () => _getFallbackMockReports().first,
            ),
          );
      final newStatus = isApproved ? ReportStatus.resolved : ReportStatus.disputed;
      final history = List<ReportStatusHistoryModel>.from(old.statusHistory);
      history.add(ReportStatusHistoryModel(
        id: 'hist-${DateTime.now().millisecondsSinceEpoch}',
        reportId: reportId,
        targetStatus: newStatus,
        note: (isApproved
                ? 'Validasi warga: perbaikan selesai'
                : 'Validasi warga: perbaikan belum sesuai') +
            (feedback != null && feedback.isNotEmpty ? ' - $feedback' : ''),
        createdAt: DateTime.now(),
      ));
      final updated = old.copyWith(
        status: newStatus,
        statusHistory: history,
      );
      _cachedReports[reportId] = updated;
      _statusOverrides[reportId] = {
        'status': newStatus.apiValue,
        'updated_at': DateTime.now().toIso8601String(),
        'note': feedback,
      };
      await _savePersistedState();
      return {
        'id': reportId,
        'status': newStatus.apiValue,
        'is_approved': isApproved,
      };
    }

    // Kirim ke API — biarkan exception naik jika gagal agar caller bisa handle
    final result = await _datasource.validateReport(
      reportId,
      isValid: isApproved,
      notes: feedback,
      latitude: latitude,
      longitude: longitude,
    );

    // Setelah API berhasil, hapus override lokal (jika ada) agar data fresh dari backend
    _statusOverrides.remove(reportId);

    // Refresh laporan dari server agar status mengikuti backend (source of truth)
    try {
      final refreshed = await _datasource.getReportById(reportId);
      _cachedReports[reportId] = refreshed;
      final subIdx = _submittedReports.indexWhere((r) => r.id == reportId);
      if (subIdx != -1) {
        _submittedReports[subIdx] = refreshed;
      }
    } catch (_) {
      // Gagal refresh tidak menghalangi flow sukses — UI akan refresh sendiri
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

    ReportModel? old = existingReport ?? _cachedReports[reportId];
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

    // Catatan: Tidak ada guard lokal di sini karena backend adalah source of truth.
    // Backend yang menentukan apakah transisi status valid atau tidak.

    // Kirim ke API — jika gagal, rethrow agar UI menampilkan error.
    // Tidak boleh mengubah status lokal jika backend tidak konfirmasi.
    ReportModel updatedRemote;
    try {
      updatedRemote = await _datasource.updateReportStatus(
        reportId,
        newStatus,
        notes: notes,
        assignedAgencyId: assignedAgencyId,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final statusLower = newStatus.toLowerCase();
      // Idempotensi: jika status di backend sudah sesuai target newStatus
      // Backend merespons: "Tidak dapat mengubah status dari '<status>' ke '<status>'"
      if (errStr.contains('tidak dapat mengubah status dari \'$statusLower\' ke \'$statusLower\'') ||
          (errStr.contains('tidak dapat mengubah status') && errStr.contains(statusLower))) {
        debugPrint('ℹ️ [ReportRepository] Status laporan di server sudah $newStatus: $e');
        try {
          updatedRemote = await _datasource.getReportById(reportId);
        } catch (_) {
          updatedRemote = (old ?? _cachedReports[reportId] ?? _getFallbackMockReports().first)
              .copyWith(status: newStatusEnum);
        }
      } else {
        rethrow;
      }
    }

    String? inputPriority = old?.directPriority;
    if (notes != null && notes.isNotEmpty) {
      final lowerNote = notes.toLowerCase();
      if (lowerNote.contains('prioritas: tinggi') || lowerNote.contains('prioritas:tinggi')) {
        inputPriority = 'Prioritas Tinggi';
      } else if (lowerNote.contains('prioritas: perlu penanganan') || lowerNote.contains('prioritas:perlu penanganan')) {
        inputPriority = 'Perlu Penanganan';
      } else if (lowerNote.contains('prioritas: sedang') || lowerNote.contains('prioritas:sedang')) {
        inputPriority = 'Sedang';
      } else if (lowerNote.contains('prioritas: rendah') || lowerNote.contains('prioritas:rendah')) {
        inputPriority = 'Rendah';
      }
    }

    // API berhasil — bangun finalReport dari response server (source of truth)
    final hasRemotePhoto = (updatedRemote.directPhotoUrl != null &&
            updatedRemote.directPhotoUrl!.isNotEmpty) ||
        updatedRemote.media.isNotEmpty;

    final existingHistory =
        List<ReportStatusHistoryModel>.from(updatedRemote.statusHistory.isNotEmpty
            ? updatedRemote.statusHistory
            : (old?.statusHistory ?? []));

    if (!existingHistory.any((h) => h.targetStatus == newStatusEnum)) {
      existingHistory.add(ReportStatusHistoryModel(
        id: 'hist-$reportId-${newStatusEnum.apiValue}-${now.millisecondsSinceEpoch}',
        reportId: reportId,
        targetStatus: newStatusEnum,
        note: notes,
        actorName: 'Operator',
        createdAt: now,
      ));
    }

    final finalReport = updatedRemote.copyWith(
      directPhotoUrl: hasRemotePhoto
          ? updatedRemote.directPhotoUrl
          : (old?.directPhotoUrl ?? old?.photoUrl),
      media: updatedRemote.media.isNotEmpty
          ? updatedRemote.media
          : (old?.media ?? const []),
      damageSeverity: updatedRemote.damageSeverity ?? old?.damageSeverity,
      rawAiConfidenceScore:
          updatedRemote.rawAiConfidenceScore ?? old?.rawAiConfidenceScore,
      urgencyScore: updatedRemote.urgencyScore ?? old?.urgencyScore,
      directPriority: inputPriority ?? updatedRemote.directPriority,
      category: updatedRemote.category ?? old?.category,
      reporter: updatedRemote.reporter ?? old?.reporter,
      assignedAgency: updatedRemote.assignedAgency ?? old?.assignedAgency,
      statusHistory: existingHistory,
    );

    _cachedReports[reportId] = finalReport;
    final idx = _submittedReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      _submittedReports[idx] = finalReport;
    } else {
      _submittedReports.insert(0, finalReport);
    }

    // Backend berhasil — simpan override agar status tetap konsisten saat offline
    // (hanya sebagai cache sementara; akan di-replace oleh server response berikutnya)
    _statusOverrides[reportId] = {
      'status': finalReport.status.apiValue, // gunakan status DARI server, bukan newStatus lokal
      'updated_at': finalReport.updatedAt.toIso8601String(),
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

  /// Hitung jarak geografis akurat antar dua pasang koordinat dalam meter (Haversine formula).
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == 0.0 || lat2 == 0.0 || lon1 == 0.0 || lon2 == 0.0) {
      return 999999.0;
    }
    const p = 0.017453292519943295; // pi / 180
    final c = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(c));
  }

  /// Check whether there are nearby/similar active reports at lat/lng
  /// Hanya dianggap laporan duplikat jika:
  /// 1. Koordinat valid (tidak bernilai 0.0)
  /// 2. Jarak geografis sangat dekat (maksimal maxDistanceMeters, default 100 meter)
  /// 3. Kategori kerusakan sama atau beririsan erat
  /// 4. Status laporan masih aktif (bukan ditolak atau sudah selesai)
  Future<List<ReportModel>> checkSimilarReports({
    required double latitude,
    required double longitude,
    double maxDistanceMeters = 100.0,
    String? categoryId,
    String? categoryName,
    String? excludeReportId,
  }) async {
    // Jika koordinat tidak valid (0.0), jangan pernah masukkan ke laporan duplikat
    if (latitude == 0.0 || longitude == 0.0) {
      return [];
    }

    try {
      final response = await getReports(limit: 50);
      final all = response.data ?? [];

      return all.where((r) {
        if (excludeReportId != null && r.id == excludeReportId) return false;

        // Jangan masukkan laporan yang sudah ditolak atau sudah selesai diperbaiki
        if (r.status == ReportStatus.rejected ||
            r.status == ReportStatus.completed ||
            r.status == ReportStatus.resolved) {
          return false;
        }

        // Koordinat pembanding harus valid
        if (r.latitude == 0.0 || r.longitude == 0.0) return false;

        // Hitung jarak geografis riil
        final distanceMeters = calculateDistanceMeters(
          latitude,
          longitude,
          r.latitude,
          r.longitude,
        );

        // Jika tempatnya berbeda / koordinatnya berbeda (> maxDistanceMeters), BUKAN DUPLIKAT!
        if (distanceMeters > maxDistanceMeters) {
          return false;
        }

        // Validasi kesesuaian kategori jika disediakan
        if (categoryId != null && categoryId.isNotEmpty && r.categoryId.isNotEmpty) {
          if (r.categoryId != categoryId) {
            if (categoryName != null && categoryName.isNotEmpty && r.categoryName.isNotEmpty) {
              final cat1 = categoryName.toLowerCase();
              final cat2 = r.categoryName.toLowerCase();
              if (cat1 != cat2 && !cat1.contains(cat2) && !cat2.contains(cat1)) {
                return false;
              }
            } else {
              return false;
            }
          }
        } else if (categoryName != null && categoryName.isNotEmpty && r.categoryName.isNotEmpty) {
          final cat1 = categoryName.toLowerCase();
          final cat2 = r.categoryName.toLowerCase();
          if (cat1 != cat2 && !cat1.contains(cat2) && !cat2.contains(cat1)) {
            return false;
          }
        }

        return true;
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [ReportRepository] checkSimilarReports error: $e');
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
