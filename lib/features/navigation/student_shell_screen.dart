import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    final screens = [
      StudentDashboardScreen(onNavigateTab: _onSelectTab),
      const StudentExamsScreen(),
      const StudentCoursesScreen(),
      const StudentAttendanceGradesScreen(),
      const StudentLedgerScreen(),
    ];

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: StudentTheme.surfaceCard,
          border: const Border(top: BorderSide(color: StudentTheme.borderDark, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
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
          selectedItemColor: branding.accentColor,
          unselectedItemColor: StudentTheme.textMuted,
          selectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 20),
              activeIcon: Icon(LucideIcons.home, size: 22),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.fileQuestion, size: 20),
              activeIcon: Icon(LucideIcons.fileQuestion, size: 22),
              label: 'الامتحانات',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.video, size: 20),
              activeIcon: Icon(LucideIcons.video, size: 22),
              label: 'المحاضرات',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendarCheck, size: 20),
              activeIcon: Icon(LucideIcons.calendarCheck, size: 22),
              label: 'الحضور والدرجات',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.receipt, size: 20),
              activeIcon: Icon(LucideIcons.receipt, size: 22),
              label: 'الاشتراكات',
            ),
          ],
        ),
      ),
    );
  }
}
