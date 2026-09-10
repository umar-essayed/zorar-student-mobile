import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/student_api_service.dart';
import 'student_auth_provider.dart';

// 1. Live Student Full Profile Provider
final liveStudentProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final auth = ref.watch(studentAuthProvider);
  final sId = auth.studentId;
  if (sId.isEmpty) return null;
  return await StudentApiService().getStudentProfile(sId);
});

// 2. Live Student Enrolled Groups & Subjects
final liveStudentGroupsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final profileAsync = ref.watch(liveStudentProfileProvider);
  final groups = profileAsync.value?['groups'];
  if (groups is List) {
    return List<Map<String, dynamic>>.from(groups);
  }
  final auth = ref.watch(studentAuthProvider);
  return List<Map<String, dynamic>>.from(auth.enrolledGroups);
});

// 3. Live Student Attendance Provider
final liveStudentAttendanceProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final profileAsync = ref.watch(liveStudentProfileProvider);
  final attendances = profileAsync.value?['attendances'];
  if (attendances is List) {
    return List<Map<String, dynamic>>.from(attendances);
  }
  return [];
});

// 4. Live Student Assessments / Grades Provider
final liveStudentAssessmentsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final profileAsync = ref.watch(liveStudentProfileProvider);
  final assessments = profileAsync.value?['assessments'];
  if (assessments is List) {
    return List<Map<String, dynamic>>.from(assessments);
  }
  return [];
});

// 5. Live Student Financial & Subscriptions Provider
final liveStudentFinanceProvider = Provider<Map<String, dynamic>>((ref) {
  final profileAsync = ref.watch(liveStudentProfileProvider);
  final profile = profileAsync.value;
  if (profile == null) {
    return {
      'transactions': [],
      'monthlySubs': [],
      'summary': {},
    };
  }
  return {
    'transactions': List<Map<String, dynamic>>.from(profile['transactions'] ?? []),
    'monthlySubs': List<Map<String, dynamic>>.from(profile['monthlySubs'] ?? []),
    'summary': Map<String, dynamic>.from(profile['financialSummary'] ?? {}),
  };
});

// 6. Live Past Exam Submissions Provider
final liveStudentPastExamsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final profileAsync = ref.watch(liveStudentProfileProvider);
  final submissions = profileAsync.value?['examSubmissions'];
  if (submissions is List) {
    return List<Map<String, dynamic>>.from(submissions);
  }
  return [];
});

// 7. Live Student Available Online Exams Provider
final liveStudentExamsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(studentAuthProvider);
  if (!auth.isAuthenticated) return [];

  return await StudentApiService().getAvailableExams();
});

// 8. Live Student Online Courses Provider
final liveStudentCoursesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(studentAuthProvider);
  if (!auth.isAuthenticated) return [];

  return await StudentApiService().getCourses();
});

// 9. Live Student Digital ID Card Provider
final liveStudentCardProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final auth = ref.watch(studentAuthProvider);
  final sId = auth.studentId;
  if (sId.isEmpty) return null;

  return await StudentApiService().getStudentCard(sId);
});
