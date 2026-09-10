import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../id_card/student_id_card_screen.dart';
import '../schedule/student_schedule_screen.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final student = profileAsync.value ?? auth.student ?? {};
    final phone = student['phone']?.toString() ?? '';
    final guardianPhone = student['guardianPhone']?.toString() ?? '';
    final schoolName = student['schoolName']?.toString() ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'الملف الشخصي والإعدادات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Avatar & Basic Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                    backgroundImage: branding.logoUrl != null && branding.logoUrl!.isNotEmpty
                        ? NetworkImage(branding.logoUrl!)
                        : null,
                    child: branding.logoUrl == null || branding.logoUrl!.isEmpty
                        ? Icon(LucideIcons.user, color: branding.primaryColor, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auth.studentName,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'كود الطالب: ${auth.studentCode}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: branding.primaryColor,
                      ),
                    ),
                  ),
                  if (auth.academicYear.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      auth.academicYear,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Personal & Center Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: LucideIcons.building,
                    label: 'السنتر التابع له',
                    value: branding.centerName,
                    iconColor: branding.primaryColor,
                    isDark: isDark,
                  ),
                  const Divider(height: 18),
                  _buildDetailRow(
                    icon: LucideIcons.phone,
                    label: 'هاتف الطالب',
                    value: phone.isNotEmpty ? phone : 'غير مسجل',
                    iconColor: Colors.blue,
                    isDark: isDark,
                  ),
                  const Divider(height: 18),
                  _buildDetailRow(
                    icon: LucideIcons.userCheck,
                    label: 'هاتف ولي الأمر',
                    value: guardianPhone.isNotEmpty ? guardianPhone : 'غير مسجل',
                    iconColor: Colors.teal,
                    isDark: isDark,
                  ),
                  if (schoolName.isNotEmpty) ...[
                    const Divider(height: 18),
                    _buildDetailRow(
                      icon: LucideIcons.school,
                      label: 'المدرسة',
                      value: schoolName,
                      iconColor: Colors.amber[800]!,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Quick Links (ID Card & Timetable)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      SoundService.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentIdCardScreen()));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.barcode, color: branding.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'كارت الحضور',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      SoundService.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentScheduleScreen()));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendarDays, color: Colors.purpleAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'جدول الحصص',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. System Settings (Dark Mode & WhatsApp Support)
            Container(
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
                  Text(
                    'الإعدادات والتفضيلات',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'الوضع الليلي (Dark Mode)',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      'مريح للعين وموفر للبطارية',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                    value: branding.isDarkMode,
                    activeColor: branding.primaryColor,
                    onChanged: (val) {
                      ref.read(brandingProvider.notifier).toggleDarkMode();
                    },
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.messageCircle, color: Color(0xFF10B981), size: 20),
                    title: Text(
                      'الدعم الفني للسنتر عبر واتساب',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(LucideIcons.chevronLeft, size: 16),
                    onTap: () async {
                      final centerPhone = (branding.supportPhone ?? branding.phone ?? '').replaceAll(RegExp(r'\D'), '');
                      final targetPhone = centerPhone.isNotEmpty
                          ? (centerPhone.startsWith('0') ? '2$centerPhone' : centerPhone)
                          : '';

                      final message = 'مرحبا، أود الاستفسار بخصوص حساب الطالب ${auth.studentName} كود ${auth.studentCode}';
                      final url = targetPhone.isNotEmpty
                          ? 'https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}'
                          : 'https://wa.me/?text=${Uri.encodeComponent(message)}';

                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Secure Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج من هذا الجهاز؟', style: GoogleFonts.cairo()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('إلغاء', style: GoogleFonts.cairo()),
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
                icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 16),
                label: Text(
                  'تسجيل الخروج من الحساب',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
