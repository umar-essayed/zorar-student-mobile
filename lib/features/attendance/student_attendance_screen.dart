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
import '../../core/utils/group_utils.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'سجل الحضور والتقييمات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 18),
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
                  'عدد الحصص: ${attList.length} (حضور: $presentCount - غياب: $absentCount)\n'
                  'مع تحيات إدارة السنتر 🌟';

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
          indicatorColor: branding.primaryColor,
          labelColor: branding.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13.5),
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.calendarCheck, size: 16),
              text: 'سجل الحضور والغياب',
            ),
            Tab(
              icon: Icon(LucideIcons.award, size: 16),
              text: 'الدرجات والكويزات',
            ),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: branding.primaryColor)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.orange, size: 36),
              const SizedBox(height: 10),
              Text(
                'تعذر تحميل السجلات',
                style: GoogleFonts.cairo(fontSize: 15),
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
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Row(
                    children: [
                      Text(
                        'المجموعة:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
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
                                selectedColor: branding.primaryColor.withOpacity(0.15),
                              ),
                              const SizedBox(width: 6),
                              ...groups.map((g) {
                                final gid = g['id']?.toString() ?? g['groupId']?.toString() ?? '';
                                final gname = GroupUtils.getName(g);
                                final isSel = _selectedGroupId == gid;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(gname, style: GoogleFonts.cairo(fontSize: 12)),
                                    selected: isSel,
                                    onSelected: (sel) {
                                      setState(() => _selectedGroupId = sel ? gid : null);
                                    },
                                    selectedColor: branding.primaryColor.withOpacity(0.15),
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

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttendanceTab(attendances, branding, isDark),
                    _buildGradesTab(assessments, attendances, branding, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceTab(List<dynamic> attendances, BrandingState branding, bool isDark) {
    if (attendances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarX, color: Colors.grey[400], size: 48),
            const SizedBox(height: 10),
            Text(
              'لا يوجد سجل حضور مسجل حتى الآن',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
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
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBadge('إجمالي الحصص', '${attendances.length}', Colors.blue, isDark),
              _buildMetricBadge('حضور', '$presentCount', const Color(0xFF10B981), isDark),
              _buildMetricBadge('غياب', '$absentCount', Colors.redAccent, isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Attendance Cards List
        ...attendances.map((att) {
          final isPresent = att['status'] == 'PRESENT';
          final session = att['session'];
          final sessionTitle = session?['title']?.toString() ??
              'حصة رقم ${session?['sessionNumber'] ?? ''}';
          final groupName = GroupUtils.getName(att['group'] ?? att);

          DateTime? date;
          if (att['scannedAt'] != null) {
            date = DateTime.tryParse(att['scannedAt'].toString());
          } else if (session?['scheduledDate'] != null) {
            date = DateTime.tryParse(session['scheduledDate'].toString());
          }

          final dateStr = date != null
              ? DateFormat('EEEE, d MMM yyyy - hh:mm a', 'ar').format(date)
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPresent ? LucideIcons.checkCheck : LucideIcons.x,
                    color: isPresent ? const Color(0xFF10B981) : Colors.redAccent,
                    size: 18,
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (groupName.isNotEmpty)
                        Text(
                          groupName,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: branding.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : Colors.redAccent.withOpacity(0.12),
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
          );
        }),
      ],
    );
  }

  Widget _buildGradesTab(
    List<dynamic> assessments,
    List<dynamic> attendances,
    BrandingState branding,
    bool isDark,
  ) {
    final combinedAssessments = <Map<String, dynamic>>[];
    for (final a in assessments) {
      if (a is Map<String, dynamic>) combinedAssessments.add(a);
    }
    for (final att in attendances) {
      if (att is Map<String, dynamic> && att['assessment'] != null) {
        final a = Map<String, dynamic>.from(att['assessment']);
        a['sessionTitle'] = att['session']?['title'];
        a['sessionNumber'] = att['session']?['sessionNumber'];
        a['groupName'] = GroupUtils.getName(att['group'] ?? att);
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
            Icon(LucideIcons.award, color: Colors.grey[400], size: 48),
            const SizedBox(height: 10),
            Text(
              'لم يتم رصد درجات أو كويزات بعد',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: combinedAssessments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = combinedAssessments[index];
        final score = item['score'] ?? item['quizScore'] ?? 0;
        final maxScore = item['maxScore'] ?? 10;
        final homeworkDone = item['homeworkDone'] ?? item['isHomeworkDone'] ?? false;
        final notes = item['notes']?.toString() ?? '';
        final title = item['sessionTitle']?.toString() ??
            (item['sessionNumber'] != null ? 'كويز حصة ${item['sessionNumber']}' : 'تقييم دراسي');
        final group = GroupUtils.getName(item['groupName'] ?? item['group'] ?? item);

        final ratio = maxScore > 0 ? (score / maxScore) : 0.0;
        final scoreColor = ratio >= 0.85
            ? const Color(0xFF10B981)
            : ratio >= 0.60
                ? Colors.amber[700]!
                : Colors.redAccent;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
            ),
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (group.isNotEmpty)
                          Text(
                            group,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score / $maxScore',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: isDark ? const Color(0xFF131C31) : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: homeworkDone
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          homeworkDone ? LucideIcons.check : LucideIcons.x,
                          size: 12,
                          color: homeworkDone ? const Color(0xFF10B981) : Colors.orange[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          homeworkDone ? 'سلم الواجب' : 'لم يسلم الواجب',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: homeworkDone ? const Color(0xFF10B981) : Colors.orange[800],
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
                          color: Colors.grey[600],
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

  Widget _buildMetricBadge(String label, String value, Color color, bool isDark) {
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
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
