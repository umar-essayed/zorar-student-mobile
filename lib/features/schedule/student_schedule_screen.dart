import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';

class StudentScheduleScreen extends ConsumerStatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  ConsumerState<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends ConsumerState<StudentScheduleScreen> {
  // Day mapping: 6=السبت, 0=الأحد, 1=الإثنين, 2=الثلاثاء, 3=الأربعاء, 4=الخميس, 5=الجمعة
  final List<Map<String, dynamic>> _days = const [
    {'name': 'السبت', 'index': 6},
    {'name': 'الأحد', 'index': 0},
    {'name': 'الإثنين', 'index': 1},
    {'name': 'الثلاثاء', 'index': 2},
    {'name': 'الأربعاء', 'index': 3},
    {'name': 'الخميس', 'index': 4},
    {'name': 'الجمعة', 'index': 5},
  ];

  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    // Default to today's weekday
    final now = DateTime.now();
    _selectedDayIndex = now.weekday == DateTime.saturday
        ? 6
        : now.weekday == DateTime.sunday
            ? 0
            : now.weekday; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final groups = ref.watch(liveStudentGroupsProvider);

    // Filter groups for the selected day
    final dayGroups = groups.where((item) {
      final g = (item['group'] is Map) ? (item['group'] as Map<String, dynamic>) : item;
      final days = g['dayOfWeek'] as List?;
      if (days == null || days.isEmpty) return false;
      return days.contains(_selectedDayIndex);
    }).toList();

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'جدول الحصص والمواعيد الأسبوعية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Days of Week Horizontal Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: StudentTheme.surfaceCard,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = day['index'] == _selectedDayIndex;

                  return ChoiceChip(
                    label: Text(
                      day['name'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.black : StudentTheme.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: branding.accentColor,
                    backgroundColor: StudentTheme.surfaceLight,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDayIndex = day['index'] as int;
                        });
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? branding.accentColor : StudentTheme.borderDark,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: dayGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendarX, size: 54, color: StudentTheme.textMuted),
                        const SizedBox(height: 14),
                        Text(
                          'لا توجد حصص مجدولة في هذا اليوم 🌴',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: StudentTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'استغل اليوم في المذاكرة ومراجعة المحاضرات المسجلة',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: StudentTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: dayGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = dayGroups[index];
                      final g = (item['group'] is Map) ? (item['group'] as Map<String, dynamic>) : item;
                      final gName = g['name']?.toString() ?? 'مجموعة دراسية';
                      final subject = g['subject']?['name']?.toString() ?? 'مادة دراسية';
                      final teacher = g['teacher']?['name']?.toString() ?? '';
                      final teacherPhone = g['teacher']?['phone']?.toString() ?? '';
                      final classroom = g['classroom']?['name']?.toString() ?? 'القاعة الرئيسية';
                      final startTime = g['startTime']?.toString() ?? '';
                      final endTime = g['endTime']?.toString() ?? '';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: StudentTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: StudentTheme.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: branding.accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(LucideIcons.bookOpen, color: branding.accentColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject,
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: StudentTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        gName,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: StudentTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (startTime.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: StudentTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: branding.accentColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.clock, size: 12, color: branding.accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          startTime,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: branding.accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(color: StudentTheme.borderDark, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.user, size: 14, color: StudentTheme.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      teacher.isNotEmpty ? 'أستاذ: $teacher' : 'المدرس المسؤول',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: StudentTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 14, color: Colors.orangeAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      classroom,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (teacherPhone.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse('https://wa.me/2$teacherPhone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(LucideIcons.messageCircle, size: 14, color: Color(0xFF10B981)),
                                  label: Text(
                                    'تواصل مع المدرس عبر واتساب',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: const Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
