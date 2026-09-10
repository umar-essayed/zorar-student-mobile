import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.zorar.student/security');

  /// Prevents screenshots and screen recording on the current screen
  static Future<void> enableSecureScreen() async {
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (_) {}
  }

  /// Restores normal screen capture if needed
  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (_) {}
  }

  /// Requests notification permission on Android 13+ (POST_NOTIFICATIONS)
  static Future<bool> requestNotificationPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }
}
