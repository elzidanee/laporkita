import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/data/datasources/remote/notification_remote_datasource.dart';
import 'package:laporkita/data/models/notification_model.dart';

class NotificationRepository {
  final NotificationRemoteDatasource _datasource;

  NotificationRepository({NotificationRemoteDatasource? datasource})
      : _datasource = datasource ?? NotificationRemoteDatasource();

  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    int limit = 20,
    String? cursor,
  }) {
    return _datasource.getNotifications(limit: limit, cursor: cursor);
  }

  Future<Map<String, dynamic>> markAsRead(String id) =>
      _datasource.markAsRead(id);

  Future<Map<String, dynamic>> markAllAsRead() =>
      _datasource.markAllAsRead();

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
