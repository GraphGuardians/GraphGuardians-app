// lib/modules/services/fcm_service.dart
// lib/modules/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer';
import 'api_service.dart'; // ← ADD

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  log("Background message: ${message.data}");
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  static bool _tokenListenerAttached = false;

  static const _channel = AndroidNotificationChannel(
    'smartsync_alerts',
    'Vulnerability Alerts',
    importance: Importance.high,
  );

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifs.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        log("Notification tapped — foreground");
        _navigateToAlert(response.payload);
      },
    );

    await _localNotifs
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _handleForeground();
    _handleBackground();
    await _handleTerminated();
    await _initToken();
  }

  static void _handleForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      log("Foreground FCM: ${message.notification?.title}");

      final notif = message.notification;
      if (notif == null) return;

      _localNotifs.show(
        notif.hashCode,
        notif.title,
        notif.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'smartsync_alerts',
            'Vulnerability Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['repoId'],
      );
    });
  }

  static void _handleBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log("Notification tapped — background");
      _navigateToAlert(message.data['repoId']);
    });
  }

  static Future<void> _handleTerminated() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      log("App opened from terminated state");
      GetStorage().write('pending_notif_repo_id', message.data['repoId']);
    }
  }

  static Future<void> _initToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        log("FCM Token: $token");
        GetStorage().write('fcm_token', token);
      }

      if (!_tokenListenerAttached) {
        _tokenListenerAttached = true;
        _messaging.onTokenRefresh.listen((newToken) {
          log("Token refreshed: $newToken");
          GetStorage().write('fcm_token', newToken);
          _sendTokenToBackend(newToken);
        });
      }
    } catch (e) {
      log("FCM Token Error: $e");
    }
  }

  static Future<void> sendTokenAfterLogin() async {
    final token = GetStorage().read<String>('fcm_token');
    if (token != null) await _sendTokenToBackend(token);
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiService.saveDeviceToken(token);
      log("Token sent to backend: $token");
    } catch (e) {
      log("Token send error: $e");
    }
  }

  static void _navigateToAlert(String? repoId) {
    if (repoId == null || repoId.isEmpty) return;
    Get.toNamed('/alert-detail', arguments: repoId);
  }
}
