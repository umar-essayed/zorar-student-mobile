class GroupUtils {
  /// Safely extracts the group data object whether it is wrapped in { group: { ... } } or flat
  static Map<String, dynamic> extractGroup(dynamic item) {
    if (item is! Map) return {};
    if (item['group'] is Map) {
      return Map<String, dynamic>.from(item['group'] as Map);
    }
    return Map<String, dynamic>.from(item);
  }

  /// Extracts Group Name safely with fallback
  static String getName(dynamic item, {String fallback = 'مجموعة دراسية'}) {
    final g = extractGroup(item);
    final name = g['name']?.toString()?.trim();
    if (name != null && name.isNotEmpty) return name;
    return fallback;
  }

  /// Extracts Subject Name safely with fallback
  static String getSubject(dynamic item, {String fallback = ''}) {
    final g = extractGroup(item);
    final subjectObj = g['subject'];
    if (subjectObj is Map) {
      final name = subjectObj['name']?.toString()?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    final directSubject = g['subjectName']?.toString()?.trim();
    if (directSubject != null && directSubject.isNotEmpty) return directSubject;
    return fallback;
  }

  /// Extracts Teacher Name safely with fallback
  static String getTeacher(dynamic item, {String fallback = ''}) {
    final g = extractGroup(item);
    final teacherObj = g['teacher'];
    if (teacherObj is Map) {
      final name = teacherObj['name']?.toString()?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    final directTeacher = g['teacherName']?.toString()?.trim();
    if (directTeacher != null && directTeacher.isNotEmpty) return directTeacher;
    return fallback;
  }

  /// Extracts Classroom Name safely with fallback
  static String getClassroom(dynamic item, {String fallback = 'القاعة الرئيسية'}) {
    final g = extractGroup(item);
    final classroomObj = g['classroom'];
    if (classroomObj is Map) {
      final name = classroomObj['name']?.toString()?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    final directClassroom = g['classroomName']?.toString()?.trim();
    if (directClassroom != null && directClassroom.isNotEmpty) return directClassroom;
    return fallback;
  }
}
