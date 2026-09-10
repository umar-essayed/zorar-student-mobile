import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/student_api_service.dart';
import '../../core/providers/student_auth_provider.dart';
import '../../core/services/security_service.dart';
import '../../core/services/sound_service.dart';
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
  bool _isLoadingToken = false;
  String? _resolvedVideoUrl;
  String? _youtubeId;
  String? _pdfAttachmentUrl;
  String? _lockMessage;

  @override
  void initState() {
    super.initState();
    SecurityService.enableSecureScreen();
    _initVideo();

    // Dynamic anti-piracy floating watermark shifts every 5 seconds
    _watermarkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _watermarkX = 0.05 + _random.nextDouble() * 0.7;
          _watermarkY = 0.05 + _random.nextDouble() * 0.7;
        });
      }
    });
  }

  @override
  void dispose() {
    _watermarkTimer?.cancel();
    SecurityService.disableSecureScreen();
    super.dispose();
  }

  void _initVideo() {
    final directUrl = widget.lesson['videoUrl']?.toString() ??
        widget.lesson['url']?.toString() ??
        widget.lesson['encryptedVideoId']?.toString() ??
        '';

    _pdfAttachmentUrl = widget.lesson['pdfAttachmentUrl']?.toString() ??
        widget.lesson['attachmentUrl']?.toString() ??
        widget.lesson['fileUrl']?.toString();

    _youtubeId = _extractYouTubeId(directUrl);
    _resolvedVideoUrl = directUrl;

    // Request secure token in background if lesson ID is available
    final lessonId = widget.lesson['id']?.toString();
    if (lessonId != null && lessonId.isNotEmpty) {
      _fetchPlayerToken(lessonId);
    }
  }

  Future<void> _fetchPlayerToken(String lessonId) async {
    setState(() => _isLoadingToken = true);
    try {
      final data = await StudentApiService().getLessonPlayerToken(lessonId);
      if (data != null && mounted) {
        final rawId = data['rawVideoId']?.toString();
        final pdf = data['pdfAttachmentUrl']?.toString();
        setState(() {
          if (rawId != null && rawId.isNotEmpty) {
            _resolvedVideoUrl = rawId;
            _youtubeId = _extractYouTubeId(rawId) ?? _youtubeId;
          }
          if (pdf != null && pdf.isNotEmpty) {
            _pdfAttachmentUrl = pdf;
          }
          _lockMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lockMessage = 'هذه المحاضرة مغلقة أو تتطلب اشتراكاً سارياً بالسنتر';
        });
      }
    }
    if (mounted) setState(() => _isLoadingToken = false);
  }

  String? _extractYouTubeId(String urlOrId) {
    if (urlOrId.isEmpty) return null;
    final trimmed = urlOrId.trim();
    if (trimmed.length == 11 && !trimmed.contains('/') && !trimmed.contains('.') && !trimmed.contains('?')) {
      return trimmed;
    }
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    return match?.group(1);
  }

  Future<void> _playVideo() async {
    SoundService.lightImpact();
    final id = _youtubeId;
    String targetUrl = '';

    if (id != null && id.isNotEmpty) {
      targetUrl = 'https://www.youtube.com/watch?v=$id';
    } else if (_resolvedVideoUrl != null && _resolvedVideoUrl!.isNotEmpty) {
      targetUrl = _resolvedVideoUrl!.startsWith('http')
          ? _resolvedVideoUrl!
          : 'https://$_resolvedVideoUrl';
    }

    if (targetUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lockMessage ?? 'المحاضرة قيد التجهيز ولم يتم إتاحة الفيديو بعد',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    final uri = Uri.parse(targetUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      // Log watch progress in background
      final lessonId = widget.lesson['id']?.toString();
      if (lessonId != null) {
        StudentApiService().logWatchProgress(lessonId: lessonId, watchedSeconds: 300, isCompleted: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تشغيل الفيديو: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.lesson['title']?.toString() ?? 'المحاضرة الرقمية';
    final desc = widget.lesson['description']?.toString() ?? '';
    final pdfUrl = _pdfAttachmentUrl ??
        widget.lesson['pdfAttachmentUrl']?.toString() ??
        widget.lesson['attachmentUrl']?.toString() ??
        '';
    final attachments = (widget.lesson['attachments'] as List?) ?? [];
    final quiz = widget.lesson['quiz'] as Map<String, dynamic>?;

    final isVideoAvailable = (_youtubeId != null && _youtubeId!.isNotEmpty) ||
        (_resolvedVideoUrl != null && _resolvedVideoUrl!.isNotEmpty);

    final thumbnailUrl = _youtubeId != null
        ? 'https://img.youtube.com/vi/$_youtubeId/hqdefault.jpg'
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive Video Player Container with Real Thumbnail & Security
            Container(
              height: 230,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail Image
                  if (thumbnailUrl != null)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E293B)),
                    )
                  else
                    Container(
                      color: const Color(0xFF1E293B),
                      child: Center(
                        child: Icon(LucideIcons.video, color: Colors.white24, size: 64),
                      ),
                    ),

                  // Dark Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Play or Lock Center Button
                  Center(
                    child: InkWell(
                      onTap: _playVideo,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isVideoAvailable ? branding.primaryColor : Colors.black87,
                          shape: BoxShape.circle,
                          border: isVideoAvailable ? null : Border.all(color: Colors.amber, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: (isVideoAvailable ? branding.primaryColor : Colors.black).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          isVideoAvailable ? LucideIcons.play : LucideIcons.lock,
                          color: isVideoAvailable ? Colors.white : Colors.amber,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Play / Lock Hint
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVideoAvailable ? LucideIcons.shieldCheck : LucideIcons.lock,
                                color: isVideoAvailable ? const Color(0xFF10B981) : Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVideoAvailable
                                    ? 'اضغط للتشغيل • مشغل مؤمّن بحقوق الطالب 🔒'
                                    : (_lockMessage ?? 'المحاضرة قيد التجهيز أو مغلقة 🔒'),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dynamic Anti-Piracy Floating Watermark
                  AnimatedAlign(
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    alignment: FractionalOffset(_watermarkX, _watermarkY),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${auth.studentName} • ${auth.studentCode}',
                        style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Primary Play / Status Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVideoAvailable ? branding.primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    isVideoAvailable ? LucideIcons.playCircle : LucideIcons.lock,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    isVideoAvailable ? 'مشاهدة المحاضرة الآن 🎥' : 'المحاضرة مغلقة أو قيد الرفع 🔒',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: isVideoAvailable
                      ? _playVideo
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _lockMessage ?? 'هذه المحاضرة قيد التجهيز ولم يتم إتاحتها بعد',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.orange[800],
                            ),
                          );
                        },
                ),
              ),
            ),

            // 2. Course & Lesson Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.courseTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        widget.courseTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: branding.primaryColor,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // 3. Lesson Quiz Action
            if (quiz != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: branding.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: branding.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.fileQuestion, color: branding.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz['title']?.toString() ?? 'كويز الحصة',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'اختبر فهمك للشرح الآن',
                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
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
                          backgroundColor: branding.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: Text(
                          'بدء الكويز',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. PDF Attachment / Worksheets
            if (pdfUrl.isNotEmpty || attachments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(LucideIcons.fileText, size: 18, color: branding.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'المرفقات ومذكرات الشرح 📑',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              if (pdfUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.fileText, color: Colors.redAccent, size: 20),
                      ),
                      title: Text(
                        'مذكرة الحصة الشاملة (PDF)',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'اضغط للتحميل والمطالعة',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.download, size: 20, color: Colors.redAccent),
                        onPressed: () async {
                          final uri = Uri.tryParse(pdfUrl);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ),
                ),

              ...attachments.map((att) {
                final attTitle = att['title']?.toString() ?? 'ملف إضافي';
                final fileUrl = att['url']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.paperclip, color: Colors.blue, size: 20),
                      ),
                      title: Text(
                        attTitle,
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.download, size: 18),
                        onPressed: () async {
                          final uri = Uri.tryParse(fileUrl);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
