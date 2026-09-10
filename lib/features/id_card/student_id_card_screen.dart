import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../../core/utils/group_utils.dart';

class StudentIdCardScreen extends ConsumerStatefulWidget {
  const StudentIdCardScreen({super.key});

  @override
  ConsumerState<StudentIdCardScreen> createState() => _StudentIdCardScreenState();
}

class _StudentIdCardScreenState extends ConsumerState<StudentIdCardScreen> {
  // Default is Barcode (خط العرضي) as requested
  bool _showQrCode = false;
  bool _isHighBrightness = false;

  void _toggleCodeType() {
    SoundService.selectionClick();
    setState(() {
      _showQrCode = !_showQrCode;
    });
  }

  void _toggleBrightness() {
    SoundService.selectionClick();
    setState(() {
      _isHighBrightness = !_isHighBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(studentAuthProvider);
    final branding = ref.watch(brandingProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final student = profileAsync.value ?? auth.student ?? {};
    final cardData = student['card'] as Map<String, dynamic>?;
    final qrPayload = cardData?['qrPayload']?.toString() ?? student['studentCode']?.toString() ?? 'ST-0000';
    final studentCode = student['studentCode']?.toString() ?? auth.studentCode;
    final studentName = student['name']?.toString() ?? auth.studentName;
    final academicYear = student['academicYear']?['name']?.toString() ?? auth.academicYear;
    
    // Safely extract groups using provider
    final groups = ref.watch(liveStudentGroupsProvider);

    return Scaffold(
      backgroundColor: _isHighBrightness
          ? Colors.white
          : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC)),
      appBar: AppBar(
        title: Text(
          'كارت الحضور الذكي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isHighBrightness ? LucideIcons.sunMedium : LucideIcons.sun,
              color: _isHighBrightness ? Colors.orange : Colors.grey[700],
            ),
            tooltip: 'إضاءة الشاشة القصوى',
            onPressed: _toggleBrightness,
          ),
          IconButton(
            icon: Icon(
              _showQrCode ? LucideIcons.barcode : LucideIcons.qrCode,
              color: branding.primaryColor,
            ),
            tooltip: _showQrCode ? 'عرض الباركود الخطي' : 'عرض رمز QR',
            onPressed: _toggleCodeType,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Barcode / QR ID Card (VIP Plastic Finish)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    branding.primaryColor,
                    branding.primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: branding.primaryColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Card Top: Center Info & Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(branding.logoUrl!, width: 32, height: 32, fit: BoxFit.cover),
                              )
                            else
                              const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              branding.centerName,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'بطاقة حضور رسمية',
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Primary Display: Horizontal Barcode Box (Default) OR QR Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _showQrCode
                          ? Center(
                              child: QrImageView(
                                data: qrPayload,
                                version: QrVersions.auto,
                                size: 170.0,
                                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 6),
                                // Realistic 1D Barcode Graphic Lines
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    32,
                                    (i) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: (i % 4 == 0 || i % 7 == 0) ? 4.0 : 2.0,
                                      height: 65,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  studentCode,
                                  style: GoogleFonts.cairo(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Student Name & Stage
                    Text(
                      studentName,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      academicYear,
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Toggle Barcode / QR Switcher Button
            TextButton.icon(
              onPressed: _toggleCodeType,
              icon: Icon(_showQrCode ? LucideIcons.barcode : LucideIcons.qrCode, size: 16),
              label: Text(
                _showQrCode ? 'التبديل إلى الباركود الخطي الافتراضي' : 'التبديل إلى رمز QR المربع',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: branding.primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Enrolled Groups List Card (Normalized with GroupUtils)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.layers, size: 18, color: branding.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'المجموعات الدراسية المسجلة:',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        const Spacer(),
                        Text(
                          '${groups.length} مجموعة',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            'لم يتم تسكينك في مجموعات دراسية بعد',
                            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ...groups.map((item) {
                        final gName = GroupUtils.getName(item);
                        final sName = GroupUtils.getSubject(item);
                        final tName = GroupUtils.getTeacher(item);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131C31) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: branding.primaryColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.check, size: 14, color: branding.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gName,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (sName.isNotEmpty || tName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        [if (sName.isNotEmpty) sName, if (tName.isNotEmpty) 'أستاذ: $tName'].join(' • '),
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Share Card WhatsApp Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  SoundService.lightImpact();
                  final shareText = 'بيانات حضور الطالب في سنتر ${branding.centerName}:\n'
                      'الاسم: $studentName\n'
                      'الكود: $studentCode\n'
                      'المرحلة: $academicYear';
                  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(LucideIcons.share2, size: 16),
                label: Text(
                  'مشاركة بيانات الكارت عبر واتساب',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: branding.primaryColor,
                  side: BorderSide(color: branding.primaryColor, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
