import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk menangani Push & Local Notifications di perangkat
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi lokal (Android & iOS)
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle tap pada notifikasi
        },
      );
      _isInitialized = true;
    } catch (_) {}
  }

  /// Tampilkan notifikasi popup lokal di perangkat
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'laporkita_channel_id',
      'LaporKita Notifikasi',
      channelDescription: 'Notifikasi status laporan dan Route Alert LaporKita',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (_) {}
  }
}
