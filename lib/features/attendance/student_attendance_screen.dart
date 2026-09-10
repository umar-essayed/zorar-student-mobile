import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';

class StudentAttendanceGradesScreen extends ConsumerStatefulWidget {
  const StudentAttendanceGradesScreen({super.key});

  @override
  ConsumerState<StudentAttendanceGradesScreen> createState() =>
      _StudentAttendanceGradesScreenState();
}

class _StudentAttendanceGradesScreenState
    extends ConsumerState<StudentAttendanceGradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);
    final groups = ref.watch(liveStudentGroupsProvider);

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'سجل الحضور والتقييمات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white70, size: 20),
            tooltip: 'مشاركة التقرير عبر واتساب',
            onPressed: () async {
              final auth = ref.read(studentAuthProvider);
              final student = profileAsync.value ?? auth.student ?? {};
              final attList = (student['attendances'] as List?) ?? [];
              final presentCount = attList.where((a) => a['status'] == 'PRESENT').length;
              final absentCount = attList.where((a) => a['status'] == 'ABSENT').length;
              final guardianPhone = student['guardianPhone']?.toString() ?? '';

              final reportText = 'تقرير متابعة الطالب من منظومة ${branding.centerName}:\n'
                  'اسم الطالب: ${auth.studentName}\n'
                  'كود الطالب: ${auth.studentCode}\n'
                  'المرحلة: ${auth.academicYear}\n'
                  'عدد الحصص الكلية: ${attList.length}\n'
                  'مرات الحضور: $presentCount\n'
                  'مرات الغياب: $absentCount\n'
                  'نتمنى له دوام التفوق والنجاح 🌟';

              final url = guardianPhone.isNotEmpty
                  ? 'https://wa.me/2$guardianPhone?text=${Uri.encodeComponent(reportText)}'
                  : 'https://wa.me/?text=${Uri.encodeComponent(reportText)}';

              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: branding.accentColor,
          labelColor: branding.accentColor,
          unselectedLabelColor: StudentTheme.textSecondary,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.calendarCheck, size: 18),
              text: 'سجل الحضور والغياب',
            ),
            Tab(
              icon: Icon(LucideIcons.award, size: 18),
              text: 'الدرجات والتقييمات',
            ),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: branding.accentColor)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                'تعذر تحميل السجلات',
                style: GoogleFonts.cairo(color: StudentTheme.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(liveStudentProfileProvider),
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
        data: (profile) {
          final allAttendances = (profile?['attendances'] as List?) ?? [];
          final allAssessments = (profile?['assessments'] as List?) ?? [];

          // Filter by group if selected
          final attendances = _selectedGroupId == null
              ? allAttendances
              : allAttendances.where((a) => a['groupId'] == _selectedGroupId).toList();

          final assessments = _selectedGroupId == null
              ? allAssessments
              : allAssessments.where((a) => a['groupId'] == _selectedGroupId).toList();

          return Column(
            children: [
              // Group Filter Bar (if more than 1 group)
              if (groups.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: StudentTheme.surfaceCard,
                  child: Row(
                    children: [
                      Text(
                        'المجموعة:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: StudentTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
                                selected: _selectedGroupId == null,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedGroupId = null);
                                },
                                selectedColor: branding.accentColor.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: _selectedGroupId == null
                                      ? branding.accentColor
                                      : StudentTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ...groups.map((g) {
                                final gid = g['id']?.toString() ?? '';
                                final gname = g['name']?.toString() ?? 'مجموعة';
                                final isSel = _selectedGroupId == gid;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(gname, style: GoogleFonts.cairo(fontSize: 12)),
                                    selected: isSel,
                                    onSelected: (sel) {
                                      setState(() => _selectedGroupId = sel ? gid : null);
                                    },
                                    selectedColor: branding.accentColor.withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: isSel ? branding.accentColor : StudentTheme.textSecondary,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // TabBar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Attendance History
                    _buildAttendanceTab(attendances, branding),
                    // Tab 2: Grades & Assessments
                    _buildGradesTab(assessments, attendances, branding),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceTab(List<dynamic> attendances, BrandingState branding) {
    if (attendances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarX, color: StudentTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'لا يوجد سجل حضور حتى الآن',
              style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final presentCount = attendances.where((a) => a['status'] == 'PRESENT').length;
    final absentCount = attendances.where((a) => a['status'] == 'ABSENT').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // KPI Summary Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudentTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StudentTheme.borderDark),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBadge('إجمالي الحصص', '${attendances.length}', Colors.blueAccent),
              _buildMetricBadge('حضور', '$presentCount', const Color(0xFF10B981)),
              _buildMetricBadge('غياب', '$absentCount', Colors.redAccent),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Attendance List
        ...attendances.map((att) {
          final isPresent = att['status'] == 'PRESENT';
          final session = att['session'];
          final sessionTitle = session?['title']?.toString() ??
              'حصة رقم ${session?['sessionNumber'] ?? ''}';
          final groupName = att['group']?['name']?.toString() ?? '';
          
          DateTime? date;
          if (att['scannedAt'] != null) {
            date = DateTime.tryParse(att['scannedAt'].toString());
          } else if (session?['scheduledDate'] != null) {
            date = DateTime.tryParse(session['scheduledDate'].toString());
          }

          final dateStr = date != null
              ? DateFormat('EEEE, d MMMM yyyy - hh:mm a', 'ar').format(date)
              : 'تاريخ الحصة غير محدد';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudentTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: StudentTheme.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPresent ? LucideIcons.checkCheck : LucideIcons.xCircle,
                    color: isPresent ? const Color(0xFF10B981) : Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sessionTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: StudentTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPresent
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : Colors.redAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPresent ? 'حاضر' : 'غائب',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPresent ? const Color(0xFF10B981) : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (groupName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          groupName,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: branding.accentColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 12, color: StudentTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: StudentTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGradesTab(
    List<dynamic> assessments,
    List<dynamic> attendances,
    BrandingState branding,
  ) {
    // Collect assessments attached to attendances as well
    final combinedAssessments = <Map<String, dynamic>>[];
    for (final a in assessments) {
      if (a is Map<String, dynamic>) combinedAssessments.add(a);
    }
    for (final att in attendances) {
      if (att is Map<String, dynamic> && att['assessment'] != null) {
        final a = Map<String, dynamic>.from(att['assessment']);
        a['sessionTitle'] = att['session']?['title'];
        a['sessionNumber'] = att['session']?['sessionNumber'];
        a['groupName'] = att['group']?['name'];
        if (!combinedAssessments.any((item) => item['id'] == a['id'])) {
          combinedAssessments.add(a);
        }
      }
    }

    if (combinedAssessments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.award, color: StudentTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'لم يتم رصد درجات أو كويزات بعد',
              style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: combinedAssessments.length,
      itemBuilder: (context, index) {
        final item = combinedAssessments[index];
        final score = item['score'] ?? item['quizScore'] ?? 0;
        final maxScore = item['maxScore'] ?? 10;
        final homeworkDone = item['homeworkDone'] ?? item['isHomeworkDone'] ?? false;
        final notes = item['notes']?.toString() ?? '';
        final title = item['sessionTitle']?.toString() ??
            (item['sessionNumber'] != null ? 'كويز حصة ${item['sessionNumber']}' : 'تقييم دراسي');
        final group = item['groupName']?.toString() ?? item['group']?['name']?.toString() ?? '';

        final ratio = maxScore > 0 ? (score / maxScore) : 0.0;
        final scoreColor = ratio >= 0.85
            ? const Color(0xFF10B981)
            : ratio >= 0.60
                ? Colors.amber
                : Colors.redAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudentTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StudentTheme.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: StudentTheme.textPrimary,
                          ),
                        ),
                        if (group.isNotEmpty)
                          Text(
                            group,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: StudentTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$score / $maxScore',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Linear Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: StudentTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: homeworkDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.orangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          homeworkDone ? LucideIcons.check : LucideIcons.x,
                          size: 13,
                          color: homeworkDone ? const Color(0xFF10B981) : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          homeworkDone ? 'تم حل الواجب' : 'لم يسلم الواجب',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: homeworkDone ? const Color(0xFF10B981) : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة: $notes',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: StudentTheme.textMuted,
                          fontStyle: FontStyle.italic,
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
        );
      },
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: StudentTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
