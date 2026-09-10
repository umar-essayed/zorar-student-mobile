import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/student_auth_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final _codeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subdomainCtrl = TextEditingController();
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
    final savedSlug = prefs.getString(AppConstants.keySavedCenterSlug);

    if (mounted) {
      setState(() {
        _rememberMe = rem;
        if (savedCode != null) _codeCtrl.text = savedCode;
        if (savedPhone != null) _phoneCtrl.text = savedPhone;
        if (savedSlug != null) _subdomainCtrl.text = savedSlug;
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _subdomainCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final code = _codeCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final slug = _subdomainCtrl.text.trim();

    if (code.isEmpty || phone.isEmpty) {
      SoundService.errorFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال كود الطالب ورقم الهاتف المسجل بالسنتر', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    SoundService.lightImpact();
    final success = await ref.read(studentAuthProvider.notifier).login(
      studentCode: code,
      phone: phone,
      subdomain: slug.isNotEmpty ? slug : null,
      rememberMe: _rememberMe,
    );

    if (success) {
      SoundService.successFeedback();
    } else {
      SoundService.errorFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(studentAuthProvider);
    final branding = ref.watch(studentBrandingProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App / Center Brand Header
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: branding.primaryColor.withOpacity(0.2), width: 2),
                    ),
                    child: Center(
                      child: (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                branding.logoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(LucideIcons.graduationCap, size: 40, color: branding.primaryColor),
                              ),
                            )
                          : Icon(LucideIcons.graduationCap, size: 40, color: branding.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    branding.centerName,
                    style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'بوابة الطالب الإلكترونية الذكية',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.logIn, size: 20, color: branding.primaryColor),
                              const SizedBox(width: 8),
                              Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),

                          // Student Code Field
                          Text('كود الطالب الخاص بك *', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _codeCtrl,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: 'مثال: ST-2026 أو 1024',
                              prefixIcon: const Icon(LucideIcons.qrCode, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone Number Field
                          Text('رقم الهاتف المسجل بالسنتر *', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'مثال: 01012345678',
                              prefixIcon: const Icon(LucideIcons.phone, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Center Subdomain (Optional)
                          Text('معرف السنتر / الرابط (اختياري)', style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700])),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _subdomainCtrl,
                            decoration: InputDecoration(
                              hintText: 'مثال: al-awael أو اتركه فارغاً',
                              prefixIcon: const Icon(LucideIcons.building, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Remember Me Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: branding.primaryColor,
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                              Text('تذكر بيانات دخولي على هذا الجهاز', style: GoogleFonts.cairo(fontSize: 12)),
                            ],
                          ),

                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
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

                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: branding.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: auth.isLoading ? null : _handleLogin,
                              child: auth.isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('دخول إلى حسابي', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'إذا لم تكن تملك كود الطالب، يرجى مراجعة إدارة السنتر لاستلام كارتك',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
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
