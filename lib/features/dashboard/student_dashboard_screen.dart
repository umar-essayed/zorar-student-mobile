import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../../core/utils/group_utils.dart';
import '../id_card/student_id_card_screen.dart';
import '../exams/student_exams_screen.dart';
import '../profile/student_profile_screen.dart';
import '../schedule/student_schedule_screen.dart';

class StudentDashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const StudentDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);
    final examsAsync = ref.watch(liveStudentExamsProvider);
    final groups = ref.watch(liveStudentGroupsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: branding.primaryColor,
          onRefresh: () async {
            ref.invalidate(liveStudentProfileProvider);
            ref.invalidate(liveStudentExamsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Header (Student Profile & Center Logo)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: _buildHeader(context, ref, auth, branding, isDark),
                ),
              ),

              // 2. Horizontal Barcode ID Card Banner (Direct Attendance Trigger)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _buildAttendanceCardBanner(context, ref, auth, branding),
                ),
              ),

              // 3. Overview KPI Stats (Attendances, Exams, Wallet)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildStatsGrid(profileAsync, examsAsync, branding, isDark),
                ),
              ),

              // 4. Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildQuickActions(context, onNavigateTab, branding, isDark),
                ),
              ),

              // 5. Enrolled Groups Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مجموعاتي الدراسية',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${groups.length} مجموعة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildGroupsList(groups, branding, isDark),
              ),

              // 6. Recent Attendance / Activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'آخر الحصص المسجلة',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (onNavigateTab != null)
                        TextButton(
                          onPressed: () => onNavigateTab!(3),
                          child: Text(
                            'عرض الكل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: branding.primaryColor,
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
                  child: _buildRecentActivity(profileAsync, branding, isDark),
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
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                SoundService.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                    backgroundImage: branding.logoUrl != null && branding.logoUrl!.isNotEmpty
                        ? NetworkImage(branding.logoUrl!)
                        : null,
                    child: branding.logoUrl == null || branding.logoUrl!.isEmpty
                        ? Icon(LucideIcons.user, color: branding.primaryColor, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.studentName.isNotEmpty ? auth.studentName : 'أهلاً بك 🎓',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: branding.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'كود: ${auth.studentCode}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: branding.primaryColor,
                                ),
                              ),
                            ),
                            if (auth.academicYear.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  auth.academicYear,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.settings,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
            tooltip: 'الإعدادات والملف الشخصي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCardBanner(
    BuildContext context,
    WidgetRef ref,
    StudentAuthState auth,
    BrandingState branding,
  ) {
    return InkWell(
      onTap: () {
        SoundService.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentIdCardScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              branding.primaryColor,
              branding.primaryColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: branding.primaryColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.barcode, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كارت الحضور والباركود الذكي',
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'اضغط لعرض الباركود لتسجيل الحضور بالقاعة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    AsyncValue<Map<String, dynamic>?> profileAsync,
    AsyncValue<List<Map<String, dynamic>>> examsAsync,
    BrandingState branding,
    bool isDark,
  ) {
    return profileAsync.when(
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final attendances = (profile?['attendances'] as List?)?.length ?? 0;
        final availableExams = examsAsync.value?.length ?? 0;
        final walletBalance = profile?['financialSummary']?['walletBalance'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'مرات الحضور',
                value: '$attendances',
                unit: 'حصة',
                icon: LucideIcons.calendarCheck,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatItem(
                label: 'امتحانات متاحة',
                value: '$availableExams',
                unit: 'امتحان',
                icon: LucideIcons.fileQuestion,
                color: Colors.orangeAccent,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatItem(
                label: 'الرصيد / المستحق',
                value: '${walletBalance.abs()}',
                unit: 'ج.م',
                icon: LucideIcons.wallet,
                color: walletBalance < 0 ? Colors.redAccent : branding.primaryColor,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
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
    bool isDark,
  ) {
    final actions = [
      {
        'icon': LucideIcons.fileText,
        'label': 'الامتحانات',
        'subtitle': 'أونلاين',
        'color': branding.primaryColor,
        'onTap': () {
          if (onNavigateTab != null) {
            onNavigateTab(1);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentExamsScreen()));
          }
        },
      },
      {
        'icon': LucideIcons.video,
        'label': 'المحاضرات',
        'subtitle': 'الشروحات',
        'color': const Color(0xFF2563EB),
        'onTap': () {
          if (onNavigateTab != null) onNavigateTab(2);
        },
      },
      {
        'icon': LucideIcons.calendarDays,
        'label': 'جدول الحصص',
        'subtitle': 'الأسبوعي',
        'color': const Color(0xFF7C3AED),
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentScheduleScreen()));
        },
      },
      {
        'icon': LucideIcons.award,
        'label': 'الدرجات',
        'subtitle': 'التقييمات',
        'color': const Color(0xFFD97706),
        'onTap': () {
          if (onNavigateTab != null) onNavigateTab(3);
        },
      },
      {
        'icon': LucideIcons.receipt,
        'label': 'الاشتراكات',
        'subtitle': 'والمحفظة',
        'color': const Color(0xFF0D9488),
        'onTap': () {
          if (onNavigateTab != null) onNavigateTab(4);
        },
      },
    ];

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final act = actions[index];
          final color = act['color'] as Color;

          return InkWell(
            onTap: () {
              SoundService.lightImpact();
              (act['onTap'] as VoidCallback)();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 86,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(act['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    act['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    act['subtitle'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 9.5,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsList(List<Map<String, dynamic>> groups, BrandingState branding, bool isDark) {
    if (groups.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            'لا توجد مجموعات دراسية مسجلة حالياً',
            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = groups[index];
          final name = GroupUtils.getName(item);
          final subject = GroupUtils.getSubject(item);
          final teacher = GroupUtils.getTeacher(item);

          return Container(
            width: 190,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: branding.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(LucideIcons.bookOpen, color: branding.primaryColor, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subject.isNotEmpty ? subject : 'مادة تعليمية',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: branding.primaryColor,
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
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  teacher.isNotEmpty ? 'أستاذ: $teacher' : 'السنتر التعليمي',
                  style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey[600]),
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
    bool isDark,
  ) {
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('تعذر تحميل السجل', style: GoogleFonts.cairo(color: Colors.redAccent)),
      ),
      data: (profile) {
        final attendances = (profile?['attendances'] as List?) ?? [];
        if (attendances.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Text(
                'لم يتم تسجيل حضور حتى الآن',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
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
            final groupName = GroupUtils.getName(att['group'] ?? att);
            final status = att['status']?.toString() ?? 'PRESENT';
            final isPresent = status == 'PRESENT';
            final assessment = att['assessment'];

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPresent ? LucideIcons.check : LucideIcons.x,
                      color: isPresent ? const Color(0xFF10B981) : Colors.redAccent,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionTitle,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (groupName.isNotEmpty)
                          Text(
                            groupName,
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (assessment != null && assessment['score'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: branding.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${assessment['score']}/${assessment['maxScore'] ?? 10}',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: branding.primaryColor,
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
