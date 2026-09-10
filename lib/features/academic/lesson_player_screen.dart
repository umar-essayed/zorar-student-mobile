import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../exams/exam_room_screen.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> lesson;
  final String courseTitle;

  const LessonPlayerScreen({
    super.key,
    required this.lesson,
    this.courseTitle = '',
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  Timer? _watermarkTimer;
  double _watermarkX = 0.3;
  double _watermarkY = 0.3;
  final Random _random = Random();
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // Dynamic floating anti-piracy watermark moves every 6 seconds
    _watermarkTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _watermarkX = 0.1 + _random.nextDouble() * 0.6;
          _watermarkY = 0.1 + _random.nextDouble() * 0.6;
        });
      }
    });
  }

  @override
  void dispose() {
    _watermarkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);

    final title = widget.lesson['title']?.toString() ?? 'المحاضرة الرقمية';
    final desc = widget.lesson['description']?.toString() ?? '';
    final videoUrl = widget.lesson['videoUrl']?.toString() ?? '';
    final attachments = (widget.lesson['attachments'] as List?) ?? [];
    final quiz = widget.lesson['quiz'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Protected Video Player Screen with Anti-Piracy Watermark
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  // Video Placeholder / Webview / External Link Banner
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: branding.accentColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? LucideIcons.play : LucideIcons.pause,
                            color: branding.accentColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'بث فيديو مشفر ومحمي من النسخ 🔒',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (videoUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.tryParse(videoUrl);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(LucideIcons.externalLink, size: 14),
                            label: Text('فتح في المشغل الآمن', style: GoogleFonts.cairo(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: branding.accentColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. Dynamic Floating Anti-Piracy Watermark
                  AnimatedAlign(
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    alignment: FractionalOffset(_watermarkX, _watermarkY),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        '${auth.studentName} | ${auth.studentCode}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Lesson Header & Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: branding.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.courseTitle.isNotEmpty ? widget.courseTitle : 'المحاضرة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: branding.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: StudentTheme.textPrimary,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: StudentTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: StudentTheme.borderDark),

            // 3. Lesson Quiz Action (اختبار الحصة)
            if (quiz != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      branding.accentColor.withValues(alpha: 0.2),
                      StudentTheme.surfaceCard,
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: branding.accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: branding.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.fileCheck, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz['title']?.toString() ?? 'كويز واختبار الحصة',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: StudentTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'اختبر فهمك لمحتوى المحاضرة وتأكد من استيعابك',
                            style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamRoomScreen(
                              examId: quiz['id']?.toString() ?? '',
                              examTitle: quiz['title']?.toString() ?? 'اختبار الحصة',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: branding.accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text('ابدأ الكويز', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // 4. Attachments & Lesson Materials (مرفقات ومذكرات الحصة)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'مرفقات وملفات المحاضرة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: StudentTheme.textPrimary,
                ),
              ),
            ),

            if (attachments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StudentTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudentTheme.borderDark),
                  ),
                  child: Center(
                    child: Text(
                      'لا توجد ملفات مرفقة إضافية لهذه المحاضرة',
                      style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ),
              )
            else
              ...attachments.map((att) {
                final attTitle = att['title']?.toString() ?? 'ملف مرفق';
                final fileUrl = att['url']?.toString() ?? '';
                final isPdf = fileUrl.toLowerCase().endsWith('.pdf');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          color: isPdf ? Colors.redAccent.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPdf ? LucideIcons.fileText : LucideIcons.download,
                          color: isPdf ? Colors.redAccent : Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: StudentTheme.textPrimary,
                              ),
                            ),
                            Text(
                              isPdf ? 'مذكرة أو ورقة عمل PDF' : 'مرفق تعليمي',
                              style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.downloadCloud, color: Colors.white70, size: 20),
                        onPressed: () async {
                          if (fileUrl.isNotEmpty) {
                            final uri = Uri.tryParse(fileUrl);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
