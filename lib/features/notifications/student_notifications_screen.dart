import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/student_api_service.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../exams/exam_room_screen.dart';

class StudentNotificationsScreen extends ConsumerStatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  ConsumerState<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends ConsumerState<StudentNotificationsScreen> {
  String _activeFilter = 'الكل'; // 'الكل', 'امتحانات', 'حصص', 'طارئ'

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final notifsAsync = ref.watch(liveStudentNotificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('مركز الإشعارات والتنبيهات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديد الكل كمقروء',
            icon: const Icon(LucideIcons.checkCheck, size: 20),
            onPressed: () async {
              await StudentApiService().markAllNotificationsAsRead();
              ref.invalidate(liveStudentNotificationsProvider);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(liveStudentNotificationsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['الكل', 'امتحانات', 'حصص', 'طارئ'].map((filter) {
                  final isSel = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSel,
                      selectedColor: branding.primaryColor,
                      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                      onSelected: (val) {
                        if (val) setState(() => _activeFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content List
          Expanded(
            child: notifsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: branding.primaryColor)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text('تعذر جلب الإشعارات حالياً', style: GoogleFonts.cairo(fontSize: 15)),
                  ],
                ),
              ),
              data: (notifs) {
                // Apply filter
                final filtered = notifs.where((n) {
                  if (_activeFilter == 'امتحانات') return n['type'] == 'EXAM';
                  if (_activeFilter == 'حصص') return n['type'] == 'LESSON' || n['type'] == 'SCHEDULE';
                  if (_activeFilter == 'طارئ') return n['isUrgent'] == true || n['type'] == 'URGENT';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bellOff, size: 54, color: Colors.grey[400]),
                        const SizedBox(height: 14),
                        Text(
                          'لا توجد إشعارات جديدة 🔕',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text('ستظهر هنا تنبيهات الامتحانات ومواعيد الحصص والرسائل الإدارية', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    final id = item['id']?.toString() ?? '';
                    final title = item['title']?.toString() ?? 'إشعار جديد';
                    final body = item['body']?.toString() ?? '';
                    final isUrgent = item['isUrgent'] == true;
                    final isRead = item['isRead'] == true;
                    final type = item['type']?.toString() ?? 'GENERAL';
                    final groupName = item['groupName']?.toString();
                    final createdAt = item['createdAt'] != null ? DateTime.tryParse(item['createdAt'].toString()) : null;
                    final payload = item['actionPayload'] is Map ? item['actionPayload'] as Map<String, dynamic> : null;

                    IconData iconData = LucideIcons.bell;
                    Color iconColor = branding.primaryColor;
                    if (isUrgent) {
                      iconData = LucideIcons.alertTriangle;
                      iconColor = Colors.red;
                    } else if (type == 'EXAM') {
                      iconData = LucideIcons.fileQuestion;
                      iconColor = Colors.amber[800]!;
                    } else if (type == 'LESSON') {
                      iconData = LucideIcons.video;
                      iconColor = Colors.blue;
                    } else if (type == 'SCHEDULE') {
                      iconData = LucideIcons.calendar;
                      iconColor = Colors.teal;
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        if (!isRead && id.isNotEmpty) {
                          await StudentApiService().markNotificationAsRead(id);
                          ref.invalidate(liveStudentNotificationsProvider);
                        }

                        // Action Routing
                        if (payload != null && payload['screen'] == 'exam' && payload['examId'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExamRoomScreen(
                                examId: payload['examId'].toString(),
                                examTitle: payload['examTitle']?.toString() ?? 'امتحان',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isRead ? const Color(0xFF1E293B) : const Color(0xFF273549))
                              : (isRead ? Colors.white : const Color(0xFFEFF6FF)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUrgent
                                ? Colors.red.withOpacity(0.5)
                                : (!isRead ? branding.primaryColor.withOpacity(0.4) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                            width: !isRead ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: iconColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: branding.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (groupName != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: branding.primaryColor.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            groupName,
                                            style: GoogleFonts.cairo(fontSize: 10, color: branding.primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (createdAt != null)
                                        Text(
                                          timeFormat.format(createdAt),
                                          style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}
