import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/student_auth_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../navigation/student_shell_screen.dart';

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final _codeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final rem = prefs.getBool(AppConstants.keyRememberMe) ?? true;
    final savedCode = prefs.getString(AppConstants.keySavedCode);
    final savedPhone = prefs.getString(AppConstants.keySavedPhone);

    if (mounted) {
      setState(() {
        _rememberMe = rem;
        if (savedCode != null) _codeCtrl.text = savedCode;
        if (savedPhone != null) _phoneCtrl.text = savedPhone;
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final code = _codeCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (code.isEmpty || phone.isEmpty) {
      SoundService.errorFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال كود الطالب ورقم الهاتف المسجل بالسنتر',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    SoundService.lightImpact();
    final success = await ref.read(studentAuthProvider.notifier).login(
      studentCode: code,
      phone: phone,
      rememberMe: _rememberMe,
    );

    if (success) {
      SoundService.successFeedback();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentShellScreen()),
      );
    } else {
      SoundService.errorFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(studentAuthProvider);
    final branding = ref.watch(brandingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App / Center Brand Header
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: branding.primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                branding.logoUrl!,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  LucideIcons.graduationCap,
                                  size: 36,
                                  color: branding.primaryColor,
                                ),
                              ),
                            )
                          : Icon(
                              LucideIcons.graduationCap,
                              size: 36,
                              color: branding.primaryColor,
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    branding.centerName,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'بوابة الطالب الإلكترونية الذكية',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Form Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.logIn, size: 18, color: branding.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'تسجيل الدخول',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Student Code Field
                          Text(
                            'كود الطالب *',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _codeCtrl,
                            keyboardType: TextInputType.text,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'أدخل كودك (مثال: ST-1002 أو 1024)',
                              prefixIcon: Icon(LucideIcons.scanLine, size: 18, color: branding.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone Number Field
                          Text(
                            'رقم الهاتف المسجل بالسنتر *',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: '010xxxxxxxx',
                              prefixIcon: Icon(LucideIcons.phone, size: 18, color: branding.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Remember Me Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: branding.primaryColor,
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                              Text(
                                'تذكر بيانات دخولي على هذا الهاتف',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),

                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.red[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Login Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: branding.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.arrowRight, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'دخول إلى حسابي',
                                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
