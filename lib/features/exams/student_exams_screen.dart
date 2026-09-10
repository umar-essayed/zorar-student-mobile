import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import 'exam_room_screen.dart';

class StudentExamsScreen extends ConsumerWidget {
  const StudentExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(studentBrandingProvider);
    final examsAsync = ref.watch(liveStudentExamsProvider);
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('امتحاناتي الإلكترونية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(liveStudentExamsProvider),
          ),
        ],
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              Text('تعذر تحميل قائمة الامتحانات', style: GoogleFonts.cairo(fontSize: 15)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('إعادة المحاولة'),
                onPressed: () => ref.invalidate(liveStudentExamsProvider),
              ),
            ],
          ),
        ),
        data: (exams) {
          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileCheck, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لا توجد امتحانات متاحة لمجموعتك حالياً', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('سيظهر أي امتحان جديد يحدده مدرسك هنا فور نشره', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, idx) {
              final exam = exams[idx];
              final title = exam['title']?.toString() ?? 'امتحان إلكتروني';
              final duration = exam['durationMinutes'] ?? exam['duration'] ?? 30;
              final questionsCount = exam['questionsCount'] ?? (exam['questions'] is List ? (exam['questions'] as List).length : 0);
              final totalScore = exam['totalScore'] ?? exam['totalMarks'] ?? 100;

              final availableFrom = exam['availableFrom'] != null ? DateTime.tryParse(exam['availableFrom'].toString()) : null;
              final availableUntil = exam['availableUntil'] != null ? DateTime.tryParse(exam['availableUntil'].toString()) : null;

              final isExpired = availableUntil != null && availableUntil.isBefore(now);
              final isUpcoming = availableFrom != null && availableFrom.isAfter(now);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.red.withOpacity(0.12)
                                  : (isUpcoming ? Colors.blue.withOpacity(0.12) : Colors.green.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isExpired ? 'منتهي' : (isUpcoming ? 'مجدول' : 'متاح للحل الآن'),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isExpired ? Colors.red[800] : (isUpcoming ? Colors.blue[800] : Colors.green[800]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Meta Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChip(LucideIcons.clock, '$duration دقيقة'),
                          _buildChip(LucideIcons.helpCircle, '$questionsCount سؤال'),
                          _buildChip(LucideIcons.award, '$totalScore درجة'),
                        ],
                      ),

                      if (availableUntil != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 13, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'آخر موعد للتسليم: ${dateFormat.format(availableUntil)}',
                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpired ? Colors.grey : branding.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(LucideIcons.play, size: 16),
                          label: Text(
                            isExpired ? 'انتهت فترة الامتحان' : (isUpcoming ? 'لم يبدأ بعد' : 'بدء الاختبار الآن'),
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: (isExpired || isUpcoming)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => ExamRoomScreen(
                                        examId: exam['id'].toString(),
                                        examTitle: title,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[800])),
        ],
      ),
    );
  }
}
