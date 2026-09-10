import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/student_api_service.dart';
import 'in_app_banner_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Background message initialization error: $e');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Call once during app startup
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // 1. Request notifications permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // 2. Enable foreground display on Android/iOS
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Fetch device token
      _fcmToken = await messaging.getToken();
      debugPrint('Device FCM Token: $_fcmToken');

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        _sendTokenToBackend(_fcmToken!);
      }

      // 4. Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // 5. Handle foreground notifications with rich in-app top banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground notification: ${message.notification?.title}');
        final title = message.notification?.title ?? 'تنبيه جديد من السنتر 🔔';
        final body = message.notification?.body ?? '';
        InAppBannerService.show(
          title: title,
          body: body,
          data: message.data,
        );
      });

      // 6. Handle notification click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Opened app from notification: ${message.data}');
      });

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing Firebase Push Notifications: $e');
    }
  }

  /// Subscribe student to center, personal, and group notification topics
  Future<void> syncStudentTopics({
    required String tenantId,
    required String studentId,
    List<String> groupIds = const [],
  }) async {
    if (!_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      if (tenantId.isNotEmpty) {
        final cleanTenant = tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        await messaging.subscribeToTopic('tenant_$cleanTenant');
      }

      if (studentId.isNotEmpty) {
        final cleanStudent = studentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        await messaging.subscribeToTopic('student_$cleanStudent');
      }

      for (final gid in groupIds) {
        if (gid.isNotEmpty) {
          final cleanGroup = gid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
          await messaging.subscribeToTopic('group_$cleanGroup');
        }
      }

      if (_fcmToken != null) {
        _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error subscribing to student FCM topics: $e');
    }
  }

  void _sendTokenToBackend(String token) {
    StudentApiService().registerFcmToken(token);
  }
}
