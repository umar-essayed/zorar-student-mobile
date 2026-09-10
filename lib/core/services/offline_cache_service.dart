import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const String _keyProfile = 'offline_cached_student_profile';
  static const String _keySchedule = 'offline_cached_schedule';
  static const String _keyCard = 'offline_cached_card';
  static const String _keyExams = 'offline_cached_exams';

  /// Save full profile to local cache
  static Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfile, jsonEncode(profile));
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  /// Get cached profile
  static Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyProfile);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached profile: $e');
    }
    return null;
  }

  /// Save student card & barcode to local cache
  static Future<void> cacheCard(Map<String, dynamic> card) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCard, jsonEncode(card));
    } catch (e) {
      debugPrint('Error caching card: $e');
    }
  }

  /// Get cached card
  static Future<Map<String, dynamic>?> getCachedCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyCard);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached card: $e');
    }
    return null;
  }

  /// Helper to convert "16:00" to "04:00 م" and "09:30" to "09:30 ص"
  static String format12Hour(String time24) {
    if (time24.isEmpty) return '';
    try {
      final parts = time24.trim().split(':');
      if (parts.length < 2) return time24;
      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final isPm = hour >= 12;
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      final hourStr = hour.toString().padLeft(2, '0');
      final period = isPm ? 'م' : 'ص';
      return '$hourStr:$minute $period';
    } catch (_) {
      return time24;
    }
  }
}
