import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/repositories/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print('FCM Background Message: ${message.messageId}');
    }
  } catch (_) {}
}

class FcmService {
  static final FcmService instance = FcmService._internal();
  FcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Inisialisasi Firebase & FCM Service dengan fallback aman
  Future<void> initialize({
    FirebaseOptions? options,
    NotificationRepository? notificationRepo,
  }) async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }

      // 2. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup Local Notifications Channel (for Android foreground popups)
      await _setupLocalNotifications();

      // 4. Request Permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM Permission status: ${settings.authorizationStatus}');
      }

      // 5. Get FCM Device Token
      _fcmToken = await messaging.getToken();
      if (kDebugMode) {
        print('FCM Device Token: $_fcmToken');
      }

      // 6. Send token to NestJS Backend if available
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        final repo = notificationRepo ?? NotificationRepository();
        try {
          await repo.subscribeRouteAlert(deviceToken: _fcmToken!);
        } catch (_) {}
      }

      // 7. Listen to Token Refresh
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        final repo = notificationRepo ?? NotificationRepository();
        try {
          await repo.subscribeRouteAlert(deviceToken: newToken);
        } catch (_) {}
      });

      // 8. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // 9. Message Opened App Listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM Notification Clicked: ${message.data}');
        }
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('FCM Initialization fallback (Firebase config pending): $e');
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotificationsPlugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'laporkita_status_channel',
      'Update Status LaporKita',
      description:
          'Notifikasi real-time update status penanganan laporan warga',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'laporkita_status_channel',
      'Update Status LaporKita',
      channelDescription:
          'Notifikasi real-time update status penanganan laporan warga',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title ?? 'LaporKita Update',
      notification.body ?? 'Status laporan Anda telah diperbarui oleh petugas.',
      platformDetails,
    );
  }
}
