import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/services/security_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../dashboard/student_dashboard_screen.dart';
import '../exams/student_exams_screen.dart';
import '../academic/student_courses_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../finance/student_ledger_screen.dart';

class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SecurityService.requestNotificationPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(studentAuthProvider);
      if (auth.isAuthenticated) {
        final groupIds = auth.enrolledGroups
            .map((g) => g['groupId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        PushNotificationService().syncStudentTopics(
          tenantId: auth.tenantId,
          studentId: auth.studentId,
          groupIds: groupIds,
        );
      }
    });
  }

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      StudentDashboardScreen(onNavigateTab: _onSelectTab),
      const StudentExamsScreen(),
      const StudentCoursesScreen(),
      const StudentAttendanceGradesScreen(),
      const StudentLedgerScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onSelectTab,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: branding.primaryColor,
            unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            selectedLabelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.home, size: 20),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.home, size: 20, color: branding.primaryColor),
                ),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.fileQuestion, size: 20),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.fileQuestion, size: 20, color: branding.primaryColor),
                ),
                label: 'الامتحانات',
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.video, size: 20),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.video, size: 20, color: branding.primaryColor),
                ),
                label: 'المحاضرات',
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.calendarCheck, size: 20),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.calendarCheck, size: 20, color: branding.primaryColor),
                ),
                label: 'الحضور والدرجات',
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.receipt, size: 20),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.receipt, size: 20, color: branding.primaryColor),
                ),
                label: 'الاشتراكات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
