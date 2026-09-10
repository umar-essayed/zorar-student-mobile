import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../id_card/student_id_card_screen.dart';
import '../exams/student_exams_screen.dart';

class StudentDashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const StudentDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);
    final examsAsync = ref.watch(liveStudentExamsProvider);

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: branding.accentColor,
          backgroundColor: StudentTheme.surfaceCard,
          onRefresh: () async {
            ref.invalidate(liveStudentProfileProvider);
            ref.invalidate(liveStudentExamsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Center Brand & Student Profile Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _buildHeader(context, ref, auth, branding),
                ),
              ),

              // 2. Digital ID Card Quick Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildIdCardBanner(context, ref, auth, branding),
                ),
              ),

              // 3. Overview KPI Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildStatsGrid(profileAsync, examsAsync, branding),
                ),
              ),

              // 4. Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildQuickActions(context, onNavigateTab, branding),
                ),
              ),

              // 5. Enrolled Subjects & Groups
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المجموعات الدراسية المسجلة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: StudentTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${auth.enrolledGroups.length} مجموعة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: StudentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildGroupsList(auth, branding),
              ),

              // 6. Recent Attendances & Activities
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سجل الحضور والتقييمات الأخيرة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: StudentTheme.textPrimary,
                        ),
                      ),
                      if (onNavigateTab != null)
                        TextButton(
                          onPressed: () => onNavigateTab!(3), // Navigate to attendance/grades tab
                          child: Text(
                            'عرض الكل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: branding.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: _buildRecentActivity(profileAsync, branding),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    StudentAuthState auth,
    BrandingState branding,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudentTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentTheme.borderDark),
      ),
      child: Row(
        children: [
          // Center Avatar / Student Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: branding.accentColor.withValues(alpha: 0.15),
            backgroundImage: branding.logoUrl != null && branding.logoUrl!.isNotEmpty
                ? NetworkImage(branding.logoUrl!)
                : null,
            child: branding.logoUrl == null || branding.logoUrl!.isEmpty
                ? Icon(LucideIcons.user, color: branding.accentColor, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.studentName.isNotEmpty ? auth.studentName : 'أهلاً بك يا بطل 🎓',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: StudentTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: StudentTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'كود: ${auth.studentCode}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: branding.accentColor,
                        ),
                      ),
                    ),
                    if (auth.academicYear.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        auth.academicYear,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: StudentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Logout or Theme button
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: StudentTheme.textMuted, size: 20),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: StudentTheme.surfaceCard,
                  title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟', style: GoogleFonts.cairo()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('إلغاء', style: GoogleFonts.cairo(color: StudentTheme.textMuted)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(studentAuthProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardBanner(
    BuildContext context,
    WidgetRef ref,
    StudentAuthState auth,
    BrandingState branding,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentIdCardScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              branding.accentColor,
              branding.accentColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: branding.accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.qrCode, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بطاقة الطالب الرقمية (QR حضور)',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'اضغط هنا لإظهار باركود تسجيل الحضور السريع',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    AsyncValue<Map<String, dynamic>?> profileAsync,
    AsyncValue<List<Map<String, dynamic>>> examsAsync,
    BrandingState branding,
  ) {
    return profileAsync.when(
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final attendances = (profile?['attendances'] as List?)?.length ?? 0;
        final assessments = (profile?['assessments'] as List?)?.length ?? 0;
        final availableExams = examsAsync.value?.length ?? 0;
        final walletBalance = profile?['financialSummary']?['walletBalance'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'مرات الحضور',
                value: '$attendances حصة',
                icon: LucideIcons.calendarCheck,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatItem(
                label: 'امتحانات متاحة',
                value: '$availableExams امتحان',
                icon: LucideIcons.fileQuestion,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatItem(
                label: 'الرصيد / المستحق',
                value: '${walletBalance.abs()} ج.م',
                icon: LucideIcons.wallet,
                color: walletBalance < 0 ? Colors.redAccent : branding.accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  static Color get _emerald => const Color(0xFF10B981);

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: StudentTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudentTheme.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: StudentTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: StudentTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    Function(int)? onNavigateTab,
    BrandingState branding,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: StudentTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentTheme.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: LucideIcons.fileText,
            label: 'الامتحانات',
            color: branding.accentColor,
            onTap: () {
              if (onNavigateTab != null) {
                onNavigateTab(1); // Exams Tab
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentExamsScreen()),
                );
              }
            },
          ),
          _buildActionButton(
            icon: LucideIcons.video,
            label: 'المحاضرات',
            color: Colors.blueAccent,
            onTap: () {
              if (onNavigateTab != null) {
                onNavigateTab(2); // Courses Tab
              }
            },
          ),
          _buildActionButton(
            icon: LucideIcons.award,
            label: 'الدرجات',
            color: Colors.amber,
            onTap: () {
              if (onNavigateTab != null) {
                onNavigateTab(3); // Attendance & Grades Tab
              }
            },
          ),
          _buildActionButton(
            icon: LucideIcons.receipt,
            label: 'الاشتراكات',
            color: Colors.tealAccent,
            onTap: () {
              if (onNavigateTab != null) {
                onNavigateTab(4); // Finance Tab
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: StudentTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(StudentAuthState auth, BrandingState branding) {
    if (auth.enrolledGroups.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: StudentTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StudentTheme.borderDark),
        ),
        child: Center(
          child: Text(
            'لا توجد مجموعات دراسية مسجلة حالياً',
            style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 125,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: auth.enrolledGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final g = auth.enrolledGroups[index];
          final name = g['name']?.toString() ?? 'مجموعة دراسية';
          final subject = g['subject']?['name']?.toString() ?? 'مادة تعليمية';
          final teacher = g['teacher']?['name']?.toString() ?? '';

          return Container(
            width: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudentTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: StudentTheme.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: branding.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(LucideIcons.bookOpen, color: branding.accentColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: StudentTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: StudentTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (teacher.isNotEmpty)
                  Text(
                    'أستاذ: $teacher',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: StudentTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity(
    AsyncValue<Map<String, dynamic>?> profileAsync,
    BrandingState branding,
  ) {
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('تعذر تحميل الأنشطة الأخيرة', style: GoogleFonts.cairo(color: Colors.redAccent)),
      ),
      data: (profile) {
        final attendances = (profile?['attendances'] as List?) ?? [];
        if (attendances.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: StudentTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: StudentTheme.borderDark),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.calendarX, color: StudentTheme.textMuted, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'لم يتم تسجيل حضور حتى الآن',
                    style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attendances.take(4).length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final att = attendances[index];
            final sessionTitle = att['session']?['title']?.toString() ??
                'حصة رقم ${att['session']?['sessionNumber'] ?? index + 1}';
            final groupName = att['group']?['name']?.toString() ?? '';
            final status = att['status']?.toString() ?? 'PRESENT';
            final isPresent = status == 'PRESENT';
            final assessment = att['assessment'];

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StudentTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StudentTheme.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPresent ? LucideIcons.check : LucideIcons.x,
                      color: isPresent ? const Color(0xFF10B981) : Colors.redAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionTitle,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: StudentTheme.textPrimary,
                          ),
                        ),
                        if (groupName.isNotEmpty)
                          Text(
                            groupName,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: StudentTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (assessment != null && assessment['score'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: branding.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'درجة: ${assessment['score']}/${assessment['maxScore'] ?? 10}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: branding.accentColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
