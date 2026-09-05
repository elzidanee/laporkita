import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/core/services/notification_service.dart';
import 'package:laporkita/data/datasources/remote/notification_remote_datasource.dart';
import 'package:laporkita/data/models/notification_model.dart';
import 'package:laporkita/data/models/report_model.dart';

class NotificationRepository {
  final NotificationRemoteDatasource _datasource;
  final FlutterSecureStorage _storage;
  static final List<NotificationModel> _inMemoryNotifications = [];
  bool _isStorageLoaded = false;

  static const String _kPersistedNotificationsKey = 'laporkita_notifications_list';

  NotificationRepository({
    NotificationRemoteDatasource? datasource,
    FlutterSecureStorage? storage,
  })  : _datasource = datasource ?? NotificationRemoteDatasource(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<void> _ensureStorageLoaded() async {
    if (_isStorageLoaded) return;
    try {
      final notifsJson = await _storage.read(key: _kPersistedNotificationsKey);
      if (notifsJson != null && notifsJson.isNotEmpty) {
        final list = jsonDecode(notifsJson) as List<dynamic>;
        _inMemoryNotifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _inMemoryNotifications.add(NotificationModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] _ensureStorageLoaded error: $e');
    } finally {
      _isStorageLoaded = true;
    }
  }

  Future<void> _savePersistedState() async {
    try {
      final notifsList = _inMemoryNotifications.map((n) => n.toJson()).toList();
      await _storage.write(
        key: _kPersistedNotificationsKey,
        value: jsonEncode(notifsList),
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] _savePersistedState error: $e');
    }
  }

  /// Menambahkan notifikasi otomatis saat ada perubahan status dan memicu push notification di HP
  Future<void> addStatusUpdateNotification({
    required String reportCode,
    required ReportStatus newStatus,
    String? note,
    String? reportId,
  }) async {
    await _ensureStorageLoaded();
    String title = 'Pembaruan Status Laporan';
    String message = 'Status laporan #$reportCode telah diperbarui.';
    String type = newStatus.name;

    switch (newStatus) {
      case ReportStatus.verified:
        title = 'Laporan Anda Diverifikasi';
        message = 'Laporan #$reportCode telah diverifikasi oleh petugas.';
        break;
      case ReportStatus.assigned:
        title = 'Laporan Ditugaskan';
        message = 'Laporan #$reportCode telah ditugaskan ke tim dinas terkait.';
        break;
      case ReportStatus.inProgress:
        title = 'Perbaikan Dimulai';
        message = 'Laporan #$reportCode sedang dikerjakan oleh petugas di lokasi.';
        break;
      case ReportStatus.completed:
      case ReportStatus.resolved:
        title = 'Perbaikan Selesai';
        message = 'Laporan #$reportCode telah selesai diperbaiki. Silakan cek dan beri validasi.';
        break;
      case ReportStatus.rejected:
        title = 'Laporan Ditolak / Dibatalkan';
        message = note != null && note.isNotEmpty
            ? 'Catatan petugas pada laporan #$reportCode: $note'
            : 'Laporan #$reportCode tidak dapat diproses lebih lanjut.';
        break;
      case ReportStatus.disputed:
        title = 'Hasil Perbaikan Belum Sesuai';
        message = note != null && note.isNotEmpty
            ? 'Catatan pada laporan #$reportCode: $note'
            : 'Hasil perbaikan laporan #$reportCode memerlukan peninjauan ulang.';
        break;
      default:
        break;
    }

    final newNotif = NotificationModel(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'me',
      title: title,
      message: message,
      isRead: false,
      type: type,
      data: {
        'report_code': reportCode,
        if (reportId != null) 'report_id': reportId,
      },
      createdAt: DateTime.now(),
    );

    _inMemoryNotifications.insert(0, newNotif);
    await _savePersistedState();

    // Munculkan notifikasi pop-up di system tray perangkat secara instan
    try {
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
        payload: reportCode,
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] showNotification error: $e');
    }
  }

  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    int limit = 20,
    String? cursor,
  }) async {
    await _ensureStorageLoaded();

    List<NotificationModel> remoteData = [];
    ApiResponse<List<NotificationModel>>? response;

    try {
      response = await _datasource.getNotifications(limit: limit, cursor: cursor);
      remoteData = response.data ?? [];
    } catch (_) {}

    final merged = <NotificationModel>[];
    final seenIds = <String>{};

    for (final item in _inMemoryNotifications) {
      if (!seenIds.contains(item.id)) {
        seenIds.add(item.id);
        merged.add(item);
      }
    }

    for (final item in remoteData) {
      if (!seenIds.contains(item.id)) {
        seenIds.add(item.id);
        merged.add(item);
      }
    }

    if (merged.isEmpty) {
      merged.addAll(_getInitialFallbackNotifications());
    }

    return ApiResponse(
      success: true,
      data: merged,
      error: response?.error,
      meta: response?.meta,
    );
  }

  Future<Map<String, dynamic>> markAsRead(String id) async {
    await _ensureStorageLoaded();
    final idx = _inMemoryNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final old = _inMemoryNotifications[idx];
      _inMemoryNotifications[idx] = NotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        message: old.message,
        isRead: true,
        type: old.type,
        data: old.data,
        createdAt: old.createdAt,
      );
      _savePersistedState();
    }
    try {
      return await _datasource.markAsRead(id);
    } catch (_) {
      return {'success': true};
    }
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    await _ensureStorageLoaded();
    for (int i = 0; i < _inMemoryNotifications.length; i++) {
      final old = _inMemoryNotifications[i];
      _inMemoryNotifications[i] = NotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        message: old.message,
        isRead: true,
        type: old.type,
        data: old.data,
        createdAt: old.createdAt,
      );
    }
    _savePersistedState();
    try {
      return await _datasource.markAllAsRead();
    } catch (_) {
      return {'success': true};
    }
  }

  List<NotificationModel> _getInitialFallbackNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'figma-1',
        userId: 'me',
        title: 'Perbaikan dimulai',
        message: 'Laporan #LP_2026_002487 sedang dikerjakan oleh petugas.',
        isRead: false,
        type: 'in_progress',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: 'figma-2',
        userId: 'me',
        title: 'Laporan anda diverifikasi',
        message: 'Laporan #LP_2026_002487 telah diverifikasi.',
        isRead: true,
        type: 'verified',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 23)),
      ),
      NotificationModel(
        id: 'figma-3',
        userId: 'me',
        title: 'Perbaikan selesai',
        message: 'Laporan #LP_2026_002328 telah selesai diperbaiki',
        isRead: true,
        type: 'completed',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'figma-4',
        userId: 'me',
        title: 'Permintaan informasi tambahan',
        message: 'Mohon lengkapi informasi pada laporan #LP_2026_002328',
        isRead: true,
        type: 'needs_info',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<Map<String, dynamic>> subscribeRouteAlert({
    required String deviceToken,
    double? lastLat,
    double? lastLng,
  }) {
    return _datasource.subscribeRouteAlert(
      deviceToken: deviceToken,
      lastLat: lastLat,
      lastLng: lastLng,
    );
  }

  Future<Map<String, dynamic>> unsubscribeRouteAlert() =>
      _datasource.unsubscribeRouteAlert();

  Future<Map<String, dynamic>> checkProximityAlert() =>
      _datasource.checkProximityAlert();
}
