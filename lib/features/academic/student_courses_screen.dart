import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import 'lesson_player_screen.dart';

class StudentCoursesScreen extends ConsumerWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final coursesAsync = ref.watch(liveStudentCoursesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'المحاضرات الرقمية والكورسات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: coursesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: branding.primaryColor)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.videoOff, color: Colors.orange, size: 40),
              const SizedBox(height: 12),
              Text(
                'تعذر تحميل الكورسات والمحاضرات',
                style: GoogleFonts.cairo(fontSize: 15),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(liveStudentCoursesProvider),
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.film, color: Colors.grey[400], size: 54),
                  const SizedBox(height: 14),
                  Text(
                    'لا توجد محاضرات رقمية متاحة حالياً',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ستظهر المحاضرات والدروس هنا فور نشرها من قبل المعلم',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = courses[index];
              final title = c['title']?.toString() ?? 'كورس تعليمي';
              final desc = c['description']?.toString() ?? '';
              final subject = c['subject']?['name']?.toString() ?? '';
              final teacher = c['teacher']?['name']?.toString() ?? '';
              final lessonsCount = (c['chapters'] as List?)?.fold<int>(
                    0,
                    (sum, ch) => sum + ((ch['lessons'] as List?)?.length ?? 0),
                  ) ??
                  0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: branding.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.playCircle, color: branding.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.cairo(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (teacher.isNotEmpty || subject.isNotEmpty)
                                Text(
                                  [if (subject.isNotEmpty) subject, if (teacher.isNotEmpty) 'أستاذ: $teacher'].join(' • '),
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
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131C31) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.layers, size: 12, color: branding.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '$lessonsCount درس تعليمي',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            SoundService.lightImpact();
                            _showChaptersBottomSheet(context, c, branding, isDark);
                          },
                          icon: const Icon(LucideIcons.eye, size: 14),
                          label: Text(
                            'عرض المحتوى',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: branding.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showChaptersBottomSheet(
    BuildContext context,
    Map<String, dynamic> course,
    BrandingState branding,
    bool isDark,
  ) {
    final chapters = (course['chapters'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course['title']?.toString() ?? 'فصول الكورس',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: chapters.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد فصول مضافة بعد لهذا الكورس',
                          style: GoogleFonts.cairo(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: chapters.length,
                        itemBuilder: (ctx, i) {
                          final ch = chapters[i];
                          final chTitle = ch['title']?.toString() ?? 'الفصل ${i + 1}';
                          final lessons = (ch['lessons'] as List?) ?? [];

                          return ExpansionTile(
                            leading: Icon(LucideIcons.folder, color: branding.primaryColor, size: 20),
                            title: Text(
                              chTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${lessons.length} دروس',
                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                            ),
                            children: lessons.map<Widget>((l) {
                              final lTitle = l['title']?.toString() ?? 'درس';
                              final hasPdf = l['pdfAttachmentUrl'] != null &&
                                  l['pdfAttachmentUrl'].toString().trim().isNotEmpty;
                              final isFree = l['isFreePreview'] == true;

                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: (isFree || l['id'] != null)
                                        ? branding.primaryColor.withOpacity(0.12)
                                        : Colors.grey.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    (isFree || l['id'] != null) ? LucideIcons.play : LucideIcons.lock,
                                    color: (isFree || l['id'] != null) ? branding.primaryColor : Colors.grey[600],
                                    size: 14,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lTitle,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasPdf) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.fileText, size: 10, color: Colors.redAccent),
                                            const SizedBox(width: 2),
                                            Text(
                                              'PDF',
                                              style: GoogleFonts.cairo(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  'اضغط للمشاهدة في المشغل المحمي 🔒',
                                  style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LessonPlayerScreen(
                                        lesson: Map<String, dynamic>.from(l),
                                        courseTitle: course['title']?.toString() ?? '',
                                      ),
                                    ),
                                  );
                                },
                                trailing: const Icon(LucideIcons.chevronLeft, size: 16),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
