import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import 'lesson_player_screen.dart';

class StudentCoursesScreen extends ConsumerWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final coursesAsync = ref.watch(liveStudentCoursesProvider);

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'الكورسات والمحاضرات الرقمية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
      ),
      body: coursesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: branding.accentColor)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.videoOff, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'تعذر تحميل الكورسات',
                style: GoogleFonts.cairo(color: StudentTheme.textPrimary, fontSize: 16),
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
                  Icon(LucideIcons.film, color: StudentTheme.textMuted, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد محاضرات رقمية متاحة حالياً',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: StudentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'عند قيام المعلم بنشر دروس جديدة ستظهر هنا مباشرة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: StudentTheme.textSecondary,
                    ),
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
                          child: Icon(LucideIcons.playCircle, color: branding.accentColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: StudentTheme.textPrimary,
                                ),
                              ),
                              if (teacher.isNotEmpty || subject.isNotEmpty)
                                Text(
                                  [if (subject.isNotEmpty) subject, if (teacher.isNotEmpty) 'أستاذ: $teacher'].join(' • '),
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: StudentTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        desc,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: StudentTheme.textMuted,
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
                            color: StudentTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.layers, size: 12, color: StudentTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '$lessonsCount درس تعليمي',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: StudentTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showChaptersBottomSheet(context, c, branding);
                          },
                          icon: const Icon(LucideIcons.eye, size: 14),
                          label: Text(
                            'عرض المحتوى',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: branding.accentColor,
                            foregroundColor: Colors.black,
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
  ) {
    final chapters = (course['chapters'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: StudentTheme.surfaceCard,
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
                  Text(
                    course['title']?.toString() ?? 'فصول الكورس',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: StudentTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: StudentTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: StudentTheme.borderDark),
              Expanded(
                child: chapters.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد فصول مضافة بعد لهذا الكورس',
                          style: GoogleFonts.cairo(color: StudentTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: chapters.length,
                        itemBuilder: (ctx, i) {
                          final ch = chapters[i];
                          final chTitle = ch['title']?.toString() ?? 'الفصل ${i + 1}';
                          final lessons = (ch['lessons'] as List?) ?? [];

                          return ExpansionTile(
                            leading: Icon(LucideIcons.folder, color: branding.accentColor, size: 20),
                            title: Text(
                              chTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: StudentTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${lessons.length} دروس',
                              style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
                            ),
                            children: lessons.map<Widget>((l) {
                              final lTitle = l['title']?.toString() ?? 'درس';
                              final videoUrl = l['videoUrl']?.toString();

                              return ListTile(
                                dense: true,
                                leading: const Icon(LucideIcons.play, color: Colors.blueAccent, size: 16),
                                title: Text(
                                  lTitle,
                                  style: GoogleFonts.cairo(fontSize: 13, color: StudentTheme.textPrimary),
                                ),
                                subtitle: Text(
                                  'اضغط للمشاهدة في المشغل المحمي 🔒',
                                  style: GoogleFonts.cairo(fontSize: 10, color: StudentTheme.textSecondary),
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
                                trailing: const Icon(LucideIcons.chevronLeft, size: 16, color: Colors.white70),
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
