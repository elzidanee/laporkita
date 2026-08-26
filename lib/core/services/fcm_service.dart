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
    debugPrint('=== FCM Background Message: ${message.messageId} ===');
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

  /// Inisialisasi Firebase & FCM Service dengan fallback aman & log terang
  Future<void> initialize({
    FirebaseOptions? options,
    NotificationRepository? notificationRepo,
  }) async {
    if (_isInitialized) return;

    debugPrint('--------------------------------------------------');
    debugPrint('🚀 MEMULAI INISIALISASI FIREBASE CLOUD MESSAGING (FCM)...');
    debugPrint('--------------------------------------------------');

    try {
      // 1. Initialize Firebase Core
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
      debugPrint('✅ Firebase.initializeApp() Berhasil!');

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

      debugPrint('🔔 Status Izin FCM: ${settings.authorizationStatus}');

      // 5. Get FCM Device Token
      _fcmToken = await messaging.getToken();
      
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        _fcmToken = 'fcm-device-token-malang-citizen-01';
      }

      debugPrint('==================================================');
      debugPrint('🔑 FCM DEVICE TOKEN KAMU:');
      debugPrint(_fcmToken);
      debugPrint('==================================================');

      // 6. Send token to NestJS Backend if available
      final repo = notificationRepo ?? NotificationRepository();
      try {
        await repo.subscribeRouteAlert(deviceToken: _fcmToken!);
        debugPrint('✅ FCM Token terdaftar ke Backend NestJS (/notifications/subscribe-route-alert)');
      } catch (e) {
        debugPrint('⚠️ Notifikasi backend subscription info: $e');
      }

      // 7. Listen to Token Refresh
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token Diperbarui: $newToken');
        try {
          await repo.subscribeRouteAlert(deviceToken: newToken);
        } catch (_) {}
      });

      // 8. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 FCM Foreground Message Diterima: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 9. Message Opened App Listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 FCM Notifikasi Di-klik Pengguna: ${message.data}');
      });

      _isInitialized = true;
    } catch (e) {
      // Fallback token jika Google Play Services di emulator belum siap
      _fcmToken = 'fcm-device-token-malang-citizen-01';
      debugPrint('--------------------------------------------------');
      debugPrint('ℹ️ FCM Service Running in Fallback Mode');
      debugPrint('🔑 FALLBACK FCM TOKEN: $_fcmToken');
      debugPrint('--------------------------------------------------');
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
