import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';

class StudentIdCardScreen extends ConsumerWidget {
  const StudentIdCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(studentAuthProvider);
    final branding = ref.watch(studentBrandingProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);

    final student = profileAsync.value ?? auth.student ?? {};
    final cardData = student['card'] as Map<String, dynamic>?;
    final qrPayload = cardData?['qrPayload']?.toString() ?? student['studentCode']?.toString() ?? 'ST-0000';
    final studentCode = student['studentCode']?.toString() ?? auth.studentCode;
    final studentName = student['name']?.toString() ?? auth.studentName;
    final academicYear = student['academicYear']?['name']?.toString() ?? auth.academicYearName;

    final groups = (student['groups'] is List) ? (student['groups'] as List) : auth.enrolledGroups;

    return Scaffold(
      appBar: AppBar(
        title: Text('كارت الطالب الذكي (ID)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.scanLine, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'أبرز هذا الكود لمسؤول الاستقبال لتسجيل حضورك الفوري بالقاعة ودخول السنتر',
                          style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Digital Plastic ID Card (VIP Design)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        branding.primaryColor,
                        const Color(0xFF0F172A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Center Info Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(branding.logoUrl!, width: 34, height: 34, fit: BoxFit.cover),
                                  )
                                else
                                  const Icon(LucideIcons.graduationCap, color: Colors.white, size: 30),
                                const SizedBox(width: 10),
                                Text(
                                  branding.centerName,
                                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'بطاقة طالب معتمدة',
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // QR Code Container (High Contrast White Box)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Student Name & Code
                        Text(
                          studentName,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'كود الطالب: $studentCode',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),

                        // Academic Year & Groups Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              academicYear,
                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '${groups.length} مجموعات مسجلة',
                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Enrolled Groups List Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.layers, size: 18, color: branding.primaryColor),
                            const SizedBox(width: 8),
                            Text('المجموعات والقاعات الدراسية المسجل بها:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ],
                        ),
                        const Divider(height: 20),
                        if (groups.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('لم يتم تسكينك في أي مجموعة دراسية بعد.', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                          )
                        else
                          ...groups.map((item) {
                            final g = (item['group'] is Map) ? (item['group'] as Map<String, dynamic>) : item;
                            final gName = g['name']?.toString() ?? 'مجموعة دراسية';
                            final sName = g['subject']?['name']?.toString() ?? '';
                            final tName = g['teacher']?['name']?.toString() ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                                    child: Icon(LucideIcons.check, size: 14, color: branding.primaryColor),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(gName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                                        if (sName.isNotEmpty || tName.isNotEmpty)
                                          Text(
                                            [if (sName.isNotEmpty) sName, if (tName.isNotEmpty) tName].join(' • '),
                                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
