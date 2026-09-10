import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_cache_service.dart';

class ScheduleAlarmService {
  static const String _keyReminders = 'offline_scheduled_reminders';

  /// Syncs weekly group schedules into local offline reminders
  static Future<void> syncScheduleReminders(List<Map<String, dynamic>> groups) async {
    try {
      final reminders = <Map<String, dynamic>>[];

      for (final item in groups) {
        final g = item['group'] is Map ? item['group'] as Map<String, dynamic> : item;
        final subject = g['subject']?['name']?.toString() ?? 'مادة دراسية';
        final teacher = g['teacher']?['name']?.toString() ?? '';
        final classroom = g['classroom']?['name']?.toString() ?? '';
        final startTime = g['startTime']?.toString() ?? '';
        final days = g['dayOfWeek'] as List?;

        if (days == null || days.isEmpty || startTime.isEmpty) continue;

        final formattedTime = OfflineCacheService.format12Hour(startTime);

        for (final d in days) {
          final dayIndex = int.tryParse(d.toString());
          if (dayIndex == null) continue;

          // 1. Morning 8 AM Reminder
          reminders.add({
            'type': 'MORNING_CLASS_DAY',
            'dayOfWeek': dayIndex,
            'time': '08:00',
            'title': 'تذكير بحصتك اليوم 📚',
            'body': 'لديك اليوم حصة $subject ${teacher.isNotEmpty ? "مع أستاذ $teacher" : ""} الساعة $formattedTime ${classroom.isNotEmpty ? "بقاعة $classroom" : ""}',
          });

          // 2. 2-Hour Before Class Reminder
          reminders.add({
            'type': 'TWO_HOURS_BEFORE',
            'dayOfWeek': dayIndex,
            'classTime': startTime,
            'title': 'اقترب موعد حصتك بالسنتر ⏱️',
            'body': 'تذكير: تبدأ حصة $subject بعد ساعتين (الساعة $formattedTime) ${classroom.isNotEmpty ? "بقاعة $classroom" : ""}. استعد للتحرك!',
          });
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyReminders, jsonEncode(reminders));
      debugPrint('Successfully synced ${reminders.length} offline schedule alarms.');
    } catch (e) {
      debugPrint('Error syncing schedule reminders: $e');
    }
  }

  /// Get list of active reminders
  static Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyReminders);
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
