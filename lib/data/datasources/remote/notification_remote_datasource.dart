import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/data/models/notification_model.dart';

/// Notification & Route Alert Remote Datasource
/// STATUS: VERIFIED — endpoints:
///   GET /notifications
///   PATCH /notifications/:id/read
///   PATCH /notifications/read-all
///   POST /route-alerts/subscribe
///   DELETE /route-alerts/unsubscribe
///   POST /route-alerts/check
class NotificationRemoteDatasource {
  final DioClient _dioClient;

  NotificationRemoteDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  // ── Get User Notifications ──────────────────────────────────────────────────
  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    int limit = 20,
    String? cursor,
  }) async {
    return _dioClient.get<List<NotificationModel>>(
      '/notifications',
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map((e) => NotificationModel.fromJson(e))
              .toList();
        } else if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['notifications'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map((e) => NotificationModel.fromJson(e))
                .toList();
          }
        }
        return <NotificationModel>[];
      },
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
  }

  // ── Mark Single Notification as Read ────────────────────────────────────────
  Future<Map<String, dynamic>> markAsRead(String id) async {
    final response = await _dioClient.patch<Map<String, dynamic>>(
      '/notifications/$id/read',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response.data!;
  }

  // ── Mark All Notifications as Read ──────────────────────────────────────────
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await _dioClient.patch<Map<String, dynamic>>(
      '/notifications/read-all',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response.data!;
  }

  // ── Route Alert: Subscribe ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> subscribeRouteAlert({
    required String deviceToken,
    double? lastLat,
    double? lastLng,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/route-alerts/subscribe',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {
        'device_token': deviceToken,
        if (lastLat != null) 'last_lat': lastLat,
        if (lastLng != null) 'last_long': lastLng,
      },
    );
    return response.data!;
  }

  // ── Route Alert: Unsubscribe ────────────────────────────────────────────────
  Future<Map<String, dynamic>> unsubscribeRouteAlert() async {
    final response = await _dioClient.delete<Map<String, dynamic>>(
      '/route-alerts/unsubscribe',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response.data!;
  }

  // ── Route Alert: Trigger Manual Check ───────────────────────────────────────
  Future<Map<String, dynamic>> checkProximityAlert() async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/route-alerts/check',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {},
    );
    return response.data!;
  }
}
