import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../id_card/student_id_card_screen.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);

    final student = profileAsync.value ?? auth.student ?? {};
    final phone = student['phone']?.toString() ?? '';
    final guardianPhone = student['guardianPhone']?.toString() ?? '';
    final schoolName = student['schoolName']?.toString() ?? '';
    final walletBalance = student['walletBalance'] ?? 0;

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'الملف الشخصي والإعدادات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Avatar & Basic Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: StudentTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: StudentTheme.borderDark),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: branding.accentColor.withValues(alpha: 0.2),
                    backgroundImage: branding.logoUrl != null && branding.logoUrl!.isNotEmpty
                        ? NetworkImage(branding.logoUrl!)
                        : null,
                    child: branding.logoUrl == null || branding.logoUrl!.isEmpty
                        ? Icon(LucideIcons.userCheck, color: branding.accentColor, size: 36)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.studentName,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: StudentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: branding.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'كود الطالب: ${auth.studentCode}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: branding.accentColor,
                      ),
                    ),
                  ),
                  if (auth.academicYear.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      auth.academicYear,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: StudentTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Center & Platform Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudentTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StudentTheme.borderDark),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: LucideIcons.building,
                    label: 'السنتر التابع له',
                    value: branding.centerName,
                    iconColor: branding.accentColor,
                  ),
                  const Divider(color: StudentTheme.borderDark, height: 20),
                  _buildDetailRow(
                    icon: LucideIcons.phone,
                    label: 'رقم هاتف الطالب',
                    value: phone.isNotEmpty ? phone : 'غير مسجل',
                    iconColor: Colors.blueAccent,
                  ),
                  const Divider(color: StudentTheme.borderDark, height: 20),
                  _buildDetailRow(
                    icon: LucideIcons.userPlus,
                    label: 'هاتف ولي الأمر',
                    value: guardianPhone.isNotEmpty ? guardianPhone : 'غير مسجل',
                    iconColor: Colors.tealAccent,
                  ),
                  if (schoolName.isNotEmpty) ...[
                    const Divider(color: StudentTheme.borderDark, height: 20),
                    _buildDetailRow(
                      icon: LucideIcons.school,
                      label: 'المدرسة',
                      value: schoolName,
                      iconColor: Colors.amber,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Digital ID Card Direct Action
            InkWell(
              onTap: () {
                SoundService.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentIdCardScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StudentTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: branding.accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: branding.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.qrCode, color: branding.accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عرض كارت الطالب الرقمي (ID)',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: StudentTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'الباركود الذكي لتسجيل الحضور ببوابات السنتر',
                            style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronLeft, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. System Settings & Toggles
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudentTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StudentTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعدادات التطبيق',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: StudentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'الوضع الليلي الداكن (Dark Mode)',
                      style: GoogleFonts.cairo(fontSize: 13, color: StudentTheme.textPrimary),
                    ),
                    subtitle: Text(
                      'مريح للعين وموفر لاستهلاك البطارية',
                      style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
                    ),
                    value: branding.isDarkMode,
                    activeColor: branding.accentColor,
                    onChanged: (val) {
                      ref.read(brandingProvider.notifier).toggleDarkMode();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Secure Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: StudentTheme.surfaceCard,
                      title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      content: Text('هل ترغب حقاً في تسجيل الخروج من حساب الطالب؟', style: GoogleFonts.cairo()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('إلغاء', style: GoogleFonts.cairo(color: StudentTheme.textMuted)),
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
                icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
                label: Text(
                  'تسجيل الخروج من الحساب',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
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
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: StudentTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
