import 'dart:math';
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

class StudentIdCardScreen extends ConsumerStatefulWidget {
  const StudentIdCardScreen({super.key});

  @override
  ConsumerState<StudentIdCardScreen> createState() => _StudentIdCardScreenState();
}

class _StudentIdCardScreenState extends ConsumerState<StudentIdCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  bool _isHighBrightness = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    SoundService.lightImpact();
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _toggleHighBrightness() {
    SoundService.selectionClick();
    setState(() {
      _isHighBrightness = !_isHighBrightness;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isHighBrightness ? 'تم تفعيل وضع التباين العالي للقراءة السريعة ☀️' : 'تم استعادة الوضع الطبيعي',
          style: GoogleFonts.cairo(),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isHighBrightness ? Colors.amber[800] : StudentTheme.surfaceCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(studentAuthProvider);
    final branding = ref.watch(brandingProvider);
    final profileAsync = ref.watch(liveStudentProfileProvider);

    final student = profileAsync.value ?? auth.student ?? {};
    final cardData = student['card'] as Map<String, dynamic>?;
    final qrPayload = cardData?['qrPayload']?.toString() ?? student['studentCode']?.toString() ?? 'ST-0000';
    final studentCode = student['studentCode']?.toString() ?? auth.studentCode;
    final studentName = student['name']?.toString() ?? auth.studentName;
    final academicYear = student['academicYear']?['name']?.toString() ?? auth.academicYear;
    final groups = (student['groups'] is List) ? (student['groups'] as List) : auth.enrolledGroups;

    return Scaffold(
      backgroundColor: _isHighBrightness ? Colors.black : StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'كارت الطالب الذكي (ID)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isHighBrightness ? LucideIcons.sunMedium : LucideIcons.sun,
              color: _isHighBrightness ? Colors.amber : Colors.white70,
            ),
            tooltip: 'وضع التباين العالي للقارئ',
            onPressed: _toggleHighBrightness,
          ),
          IconButton(
            icon: const Icon(LucideIcons.repeat, color: Colors.white70),
            tooltip: 'قلب الكارت',
            onPressed: _toggleFlip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Quick Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: branding.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: branding.accentColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.scanLine, color: branding.accentColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'وجه الكارت أمام ماسح الاستقبال عند البوابة لتسجيل الحضور الفوري ودخول القاعة',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: StudentTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3D Flippable Card
            GestureDetector(
              onTap: _toggleFlip,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isUnder = _flipAnimation.value > 0.5;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isUnder
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: _buildCardBack(studentName, studentCode, branding),
                          )
                        : _buildCardFront(
                            studentName,
                            studentCode,
                            academicYear,
                            qrPayload,
                            groups.length,
                            branding,
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Flip Card Action Hint Button
            TextButton.icon(
              onPressed: _toggleFlip,
              icon: const Icon(LucideIcons.repeat, size: 16),
              label: Text(
                _isFront ? 'اضغط لعرض ظهر الكارت والباركود الخطي' : 'اضغط للعودة إلى وجه الكارت ورمز QR',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: branding.accentColor,
              ),
            ),
            const SizedBox(height: 10),

            // WhatsApp Share & Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      SoundService.lightImpact();
                      final shareText = 'بطاقة الطالب الرسمية في سنتر ${branding.centerName}\nالطالب: $studentName\nكود الطالب: $studentCode\nالمرحلة: $academicYear';
                      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: Text(
                      'مشاركة بيانات الكارت',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentTheme.surfaceCard,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: StudentTheme.borderDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Enrolled Groups Summary
            Container(
              width: double.infinity,
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
                      Icon(LucideIcons.layers, size: 18, color: branding.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'المجموعات والقاعات الدراسية المسجل بها:',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: StudentTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: StudentTheme.borderDark, height: 20),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'لم يتم تسكينك في أي مجموعة دراسية بعد.',
                        style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 12),
                      ),
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
                              radius: 12,
                              backgroundColor: branding.accentColor.withValues(alpha: 0.15),
                              child: Icon(LucideIcons.check, size: 13, color: branding.accentColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gName,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: StudentTheme.textPrimary,
                                    ),
                                  ),
                                  if (sName.isNotEmpty || tName.isNotEmpty)
                                    Text(
                                      [if (sName.isNotEmpty) sName, if (tName.isNotEmpty) tName].join(' • '),
                                      style: GoogleFonts.cairo(fontSize: 11, color: StudentTheme.textSecondary),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront(
    String studentName,
    String studentCode,
    String academicYear,
    String qrPayload,
    int groupsCount,
    BrandingState branding,
  ) {
    return Container(
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
            color: branding.primaryColor.withValues(alpha: 0.35),
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
            // Center Header
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
                      const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      branding.centerName,
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'بطاقة طالب معتمدة',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // High Contrast QR Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 190.0,
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
            const SizedBox(height: 16),

            // Student Name & Code
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
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'كود الطالب: $studentCode',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 6),

            // Academic Year & Groups Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  academicYear,
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '$groupsCount مجموعات مسجلة',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(
    String studentName,
    String studentCode,
    BrandingState branding,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            branding.primaryColor,
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.35),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تعليمات وإرشادات الطالب',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Icon(LucideIcons.shieldCheck, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 14),

            // Barcode Box (Representation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  // Simulated barcode lines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      24,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: (i % 3 == 0 || i % 5 == 0) ? 4 : 2,
                        height: 38,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '* $studentCode *',
                    style: GoogleFonts.cairo(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rules & Center Instructions
            _buildRuleItem('1. يُرجى إبراز الكارت الذكي لمسؤول البوابة قبل دخول القاعة.'),
            _buildRuleItem('2. الكارت شخصي وخاص بالطالب المسجل فقط ولا يجوز استخدامه لغيره.'),
            _buildRuleItem('3. يتم رصد الحضور إلكترونياً وإرسال إشعار فوري لولي الأمر.'),
            _buildRuleItem('4. في حال فقدان الكود يُرجى مراجعة إدارة السنتر فوراً.'),

            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 6),

            Text(
              'سنتر ${branding.centerName} • معاً نحو التفوق 🌟',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.dot, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              rule,
              style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
