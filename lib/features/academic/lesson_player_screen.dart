import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/network/student_api_service.dart';
import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/services/security_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../exams/exam_room_screen.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> lesson;
  final String courseTitle;
  final List<Map<String, dynamic>> chapterLessons;

  const LessonPlayerScreen({
    super.key,
    required this.lesson,
    this.courseTitle = '',
    this.chapterLessons = const [],
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  late Map<String, dynamic> _currentLesson;
  Timer? _watermarkTimer;
  double _watermarkX = 0.3;
  double _watermarkY = 0.3;
  final Random _random = Random();
  bool _isLoadingToken = false;
  String? _resolvedVideoUrl;
  String? _youtubeId;
  String? _pdfAttachmentUrl;
  String? _lockMessage;

  // In-app embedded player & watch progress
  WebViewController? _webViewController;
  bool _isPlayingInApp = false;
  bool _isFullscreen = false;
  int _watchedSeconds = 0;
  int _totalDurationSeconds = 0;
  int _watchPercent = 0;
  bool _isMarkedCompleted = false;
  int _completionThreshold = 40;
  List<Map<String, dynamic>> _nextLessons = [];

  @override
  void initState() {
    super.initState();
    _currentLesson = Map<String, dynamic>.from(widget.lesson);
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

  Future<void> _toggleFullscreen() async {
    final nextState = !_isFullscreen;
    if (nextState) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (mounted) {
      setState(() => _isFullscreen = nextState);
    }
  }

  @override
  void dispose() {
    _watermarkTimer?.cancel();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    SecurityService.disableSecureScreen();
    super.dispose();
  }

  String _resolveMediaUrl(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;
    final trimmed = rawUrl.trim();
    if (trimmed.contains('media.zorar-code.com')) return trimmed;

    final uploadFileIdx = trimmed.indexOf('/api/v1/uploads/file/');
    if (uploadFileIdx != -1) {
      final s3Key = trimmed.substring(uploadFileIdx + '/api/v1/uploads/file/'.length);
      return 'https://media.zorar-code.com/$s3Key';
    }

    if (trimmed.startsWith('tenants/')) {
      return 'https://media.zorar-code.com/$trimmed';
    }

    if (trimmed.startsWith('/tenants/')) {
      return 'https://media.zorar-code.com${trimmed.substring(1)}';
    }

    return trimmed;
  }

  void _initVideo() {
    final directUrl = _currentLesson['videoUrl']?.toString() ??
        _currentLesson['url']?.toString() ??
        _currentLesson['encryptedVideoId']?.toString() ??
        '';

    final rawPdf = _currentLesson['pdfAttachmentUrl']?.toString() ??
        _currentLesson['attachmentUrl']?.toString() ??
        _currentLesson['fileUrl']?.toString();
    if (rawPdf != null && rawPdf.isNotEmpty) {
      _pdfAttachmentUrl = _resolveMediaUrl(rawPdf);
    }

    _youtubeId = _extractYouTubeId(directUrl);
    _resolvedVideoUrl = directUrl;
    _isPlayingInApp = false;
    _webViewController = null;

    if (widget.chapterLessons.isNotEmpty) {
      _nextLessons = widget.chapterLessons
          .where((l) => l['id']?.toString() != _currentLesson['id']?.toString())
          .toList();
    }

    // Request secure token in background if lesson ID is available
    final lessonId = _currentLesson['id']?.toString();
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
        final threshold = (data['completionThreshold'] as num?)?.toInt() ?? 40;
        final prevLog = data['previousWatchLog'] as Map?;
        final nexts = (data['nextLessons'] as List?)
            ?.whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();

        setState(() {
          if (rawId != null && rawId.isNotEmpty) {
            _resolvedVideoUrl = rawId;
            _youtubeId = _extractYouTubeId(rawId) ?? _youtubeId;
          }
          if (pdf != null && pdf.isNotEmpty) {
            _pdfAttachmentUrl = _resolveMediaUrl(pdf);
          }
          _completionThreshold = threshold;
          if (prevLog != null) {
            _watchedSeconds = (prevLog['watchedSeconds'] as num?)?.toInt() ?? 0;
            _isMarkedCompleted = prevLog['isCompleted'] == true;
            if (_currentLesson['durationSeconds'] != null && (_currentLesson['durationSeconds'] as num) > 0) {
              final dur = (_currentLesson['durationSeconds'] as num).toInt();
              _watchPercent = min(100, ((_watchedSeconds / dur) * 100).round());
            }
          }
          if (nexts != null && nexts.isNotEmpty) {
            _nextLessons = nexts;
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

  void _startInAppPlayer() {
    SoundService.lightImpact();
    final isVideoAvailable = (_youtubeId != null && _youtubeId!.isNotEmpty) ||
        (_resolvedVideoUrl != null && _resolvedVideoUrl!.isNotEmpty);

    if (!isVideoAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lockMessage ?? 'المحاضرة قيد التجهيز أو مغلقة حالياً',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Block navigation to external YouTube or app-switching links
            final url = request.url.toLowerCase();
            if (url.contains('youtube.com/watch') ||
                url.contains('youtu.be/') ||
                url.startsWith('intent:') ||
                url.startsWith('vnd.youtube:')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'VideoProgressChannel',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            final current = (data['currentTime'] as num?)?.toInt() ?? 0;
            final duration = (data['duration'] as num?)?.toInt() ?? 0;
            final percent = (data['percent'] as num?)?.toInt() ?? 0;

            if (mounted) {
              setState(() {
                _watchedSeconds = current;
                if (duration > 0) _totalDurationSeconds = duration;
                _watchPercent = max(_watchPercent, percent);
              });

              // Check if completed threshold reached (e.g. 40%)
              if (_watchPercent >= _completionThreshold && !_isMarkedCompleted) {
                _isMarkedCompleted = true;
                final lessonId = _currentLesson['id']?.toString() ?? '';
                if (lessonId.isNotEmpty) {
                  StudentApiService().logWatchProgress(
                    lessonId: lessonId,
                    watchedSeconds: current,
                    isCompleted: true,
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'رائع! تم تسجيل حضورك واكتمال مشاهدة المحاضرة بنجاح 🎓',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          } catch (_) {}
        },
      );

    final html = _buildPlayerHtml();
    controller.loadHtmlString(html, baseUrl: 'https://zoraredu-backend.vercel.app');

    setState(() {
      _webViewController = controller;
      _isPlayingInApp = true;
    });
  }

  String _buildPlayerHtml() {
    final yId = _youtubeId;
    if (yId != null && yId.isNotEmpty) {
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; background: #000; overflow: hidden; -webkit-user-select: none; user-select: none; }
    html, body { width: 100%; height: 100%; background: #000; }
    .video-container { position: relative; width: 100%; height: 100%; }
    iframe { width: 100%; height: 100%; border: 0; }
    /* Security overlays to prevent clicking channel, title, share button, and external links */
    .top-security-bar {
      position: absolute; top: 0; left: 0; right: 0; height: 50px;
      background: transparent; z-index: 9999; pointer-events: auto;
    }
    .logo-blocker {
      position: absolute; bottom: 0; right: 0; width: 75px; height: 48px;
      background: transparent; z-index: 9999; pointer-events: auto;
    }
  </style>
</head>
<body>
  <div class="video-container">
    <div class="top-security-bar" onclick="event.stopPropagation();"></div>
    <div class="logo-blocker" onclick="event.stopPropagation();"></div>
    <div id="player"></div>
  </div>
  <script src="https://www.youtube.com/iframe_api"></script>
  <script>
    var player;
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: '$yId',
        playerVars: {
          'autoplay': 1,
          'controls': 1,
          'modestbranding': 1,
          'rel': 0,
          'iv_load_policy': 3,
          'playsinline': 1,
          'fs': 1,
          'disablekb': 0
        },
        events: {
          'onReady': onPlayerReady,
          'onStateChange': onPlayerStateChange
        }
      });
    }
    function onPlayerReady(event) {
      event.target.playVideo();
      setInterval(reportProgress, 2500);
    }
    function reportProgress() {
      try {
        if (player && player.getCurrentTime && player.getDuration) {
          var current = Math.floor(player.getCurrentTime());
          var total = Math.floor(player.getDuration());
          if (total > 0 && window.VideoProgressChannel) {
            var pct = Math.min(100, Math.floor((current / total) * 100));
            window.VideoProgressChannel.postMessage(JSON.stringify({
              currentTime: current,
              duration: total,
              percent: pct
            }));
          }
        }
      } catch(e) {}
    }
    function onPlayerStateChange(event) {
      reportProgress();
    }
  </script>
</body>
</html>
''';
    }

    // Direct MP4 / HLS / Custom video host
    String raw = _resolvedVideoUrl ?? '';
    if (!raw.startsWith('http')) raw = 'https://$raw';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; background: #000; overflow: hidden; }
    html, body { width: 100%; height: 100%; background: #000; }
    video { width: 100%; height: 100%; object-fit: contain; }
  </style>
</head>
<body>
  <video id="vplayer" src="$raw" controls autoplay playsinline controlsList="nodownload"></video>
  <script>
    var vid = document.getElementById('vplayer');
    if (vid) {
      vid.addEventListener('timeupdate', function() {
        if (vid.duration > 0 && window.VideoProgressChannel) {
          var current = Math.floor(vid.currentTime);
          var total = Math.floor(vid.duration);
          var pct = Math.min(100, Math.floor((current / total) * 100));
          window.VideoProgressChannel.postMessage(JSON.stringify({
            currentTime: current,
            duration: total,
            percent: pct
          }));
        }
      });
    }
  </script>
</body>
</html>
''';
  }

  Future<void> _handleOpenFile(BuildContext context, String fileUrl, String title) async {
    final resolved = _resolveMediaUrl(fileUrl);
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رابط الملف غير متاح حالياً', style: GoogleFonts.cairo())),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.cloudDownload, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'جاري فتح $title...',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الملف: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _switchLesson(Map<String, dynamic> nextLesson) {
    SoundService.lightImpact();
    setState(() {
      _currentLesson = Map<String, dynamic>.from(nextLesson);
      _initVideo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = _currentLesson['title']?.toString() ?? 'تفاصيل المحاضرة';
    final desc = _currentLesson['description']?.toString() ??
        _currentLesson['homeworkDetails']?.toString() ??
        '';
    final attachments = (_currentLesson['attachments'] as List?) ?? [];

    // Strictly resolve quiz only if explicitly attached to this lesson
    final rawQuiz = _currentLesson['quiz'] ?? _currentLesson['exam'];
    Map<String, dynamic>? resolvedQuiz;
    if (rawQuiz is Map) {
      resolvedQuiz = Map<String, dynamic>.from(rawQuiz);
    } else if (_currentLesson['quizId'] != null || _currentLesson['examId'] != null) {
      resolvedQuiz = {
        'id': (_currentLesson['quizId'] ?? _currentLesson['examId']).toString(),
        'title': _currentLesson['quizTitle']?.toString() ?? 'كويز المحاضرة التفاعلي',
      };
    } else {
      final exams = ref.watch(liveStudentExamsProvider).value ?? [];
      final lessonId = _currentLesson['id']?.toString() ?? '';
      if (lessonId.isNotEmpty) {
        final found = exams.firstWhere(
          (e) => e['lessonId']?.toString() == lessonId,
          orElse: () => <String, dynamic>{},
        );
        if (found.isNotEmpty) {
          resolvedQuiz = found;
        }
      }
    }

    final isVideoAvailable = (_youtubeId != null && _youtubeId!.isNotEmpty) ||
        (_resolvedVideoUrl != null && _resolvedVideoUrl!.isNotEmpty);

    final thumbnailUrl = _youtubeId != null
        ? 'https://img.youtube.com/vi/$_youtubeId/hqdefault.jpg'
        : null;

    final isCompleted = _isMarkedCompleted || _watchPercent >= _completionThreshold;

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullscreen) {
          _toggleFullscreen();
        }
      },
      child: _isFullscreen
          ? _buildFullscreenPlayer(auth, branding, thumbnailUrl, isVideoAvailable)
          : Scaffold(
              backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Text(
                  title,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Embedded In-App Player Container
                    Container(
                      height: 235,
                      width: double.infinity,
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_isPlayingInApp && _webViewController != null)
                            WebViewWidget(controller: _webViewController!)
                          else ...[
                            // Thumbnail
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

                            // Dark Gradient
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

                            // Center Play Button
                            Center(
                              child: InkWell(
                                onTap: _startInAppPlayer,
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

                            // Hint at bottom of thumbnail
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
                                              ? 'مشغل داخلي مؤمّن بحقوق الطالب 🔒'
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
                          ],

                          // Fullscreen Expand Button (Available in portrait)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: _toggleFullscreen,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.maximize2, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ملء الشاشة',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Dynamic Anti-Piracy Floating Watermark (Always Active on Top)
                          AnimatedAlign(
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            alignment: FractionalOffset(_watermarkX, _watermarkY),
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${auth.studentName} • ${auth.studentCode} • ${auth.studentPhone}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),


            // 2. Watch Progress & Completion Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF131C31) : const Color(0xFFF1F5F9),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompleted ? LucideIcons.checkCircle : LucideIcons.clock,
                            size: 15,
                            color: isCompleted ? const Color(0xFF10B981) : Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompleted
                                ? 'تم احتساب الحضور والمشاهدة بنجاح ✅'
                                : 'نسبة المشاهدة الحالية: $_watchPercent%',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted
                              ? 'حضور مسجل 🎓'
                              : 'يلزم $_completionThreshold% لاحتساب الحضور',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? const Color(0xFF10B981) : Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_watchPercent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? const Color(0xFF10B981) : branding.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Play / Replay Action Button
            if (!_isPlayingInApp)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVideoAvailable
                          ? branding.primaryColor
                          : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      isVideoAvailable ? LucideIcons.playCircle : LucideIcons.lock,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      isVideoAvailable ? 'تشغيل المحاضرة الآن 🎥' : 'المحاضرة مغلقة أو قيد الرفع 🔒',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: isVideoAvailable ? _startInAppPlayer : null,
                  ),
                ),
              ),

            // 4. Course & Lesson Details
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

            // 5. Lesson Quiz Action (Shown strictly if attached to this lesson)
            if (resolvedQuiz != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: branding.primaryColor.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                              resolvedQuiz['title']?.toString() ?? 'كويز الحصة التفاعلي',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'كويز تفاعلي مرتبط بهذه الحصة (تصحيح وتوقيت مباشر) 🎯',
                              style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          SoundService.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExamRoomScreen(
                                examId: resolvedQuiz!['id']?.toString() ?? '',
                                examTitle: resolvedQuiz['title']?.toString() ?? 'كويز الحصة',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: branding.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

            // 6. PDF Attachments Section
            if (_pdfAttachmentUrl != null && _pdfAttachmentUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.fileText, color: Colors.redAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مذكرة وشيت أسئلة الحصة 📄',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ملف PDF رسمي متاح للتحميل والدراسة',
                              style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.download, size: 14),
                        label: Text('فتح الملف', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _handleOpenFile(context, _pdfAttachmentUrl!, 'مذكرة الحصة'),
                      ),
                    ],
                  ),
                ),
              ),

            // 7. Upcoming Sessions in the Same Chapter (قايمة بالسيشنز التالية في نفس الفصل)
            if (_nextLessons.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Icon(LucideIcons.listVideo, color: branding.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'الحصص والسيشنز التالية في هذا الفصل 📚',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _nextLessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final nextL = _nextLessons[idx];
                  final nTitle = nextL['title']?.toString() ?? 'حصة ${idx + 1}';
                  final nCompleted = nextL['isCompleted'] == true;
                  final durSec = (nextL['durationSeconds'] as num?)?.toInt() ?? 0;
                  final durMin = durSec > 0 ? (durSec / 60).round() : 0;

                  return InkWell(
                    onTap: () => _switchLesson(nextL),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: nCompleted
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : branding.primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              nCompleted ? LucideIcons.check : LucideIcons.play,
                              color: nCompleted ? const Color(0xFF10B981) : branding.primaryColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nTitle,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    if (durMin > 0) ...[
                                      Text(
                                        '$durMin دقيقة',
                                        style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      nCompleted ? 'مكتمل المشاهدة ✅' : 'لم تشاهد بعد',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10.5,
                                        color: nCompleted ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronLeft, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenPlayer(
    dynamic auth,
    BrandingState branding,
    String? thumbnailUrl,
    bool isVideoAvailable,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Embedded Player or Video Surface
          if (_isPlayingInApp && _webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else ...[
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(LucideIcons.video, color: Colors.white24, size: 80),
                ),
              ),

            Center(
              child: InkWell(
                onTap: _startInAppPlayer,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isVideoAvailable ? branding.primaryColor : Colors.black87,
                    shape: BoxShape.circle,
                    border: isVideoAvailable ? null : Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Icon(
                    isVideoAvailable ? LucideIcons.play : LucideIcons.lock,
                    color: isVideoAvailable ? Colors.white : Colors.amber,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],

          // 2. Dynamic Anti-Piracy Floating Watermark (Always Active on Top in Fullscreen)
          AnimatedAlign(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            alignment: FractionalOffset(_watermarkX, _watermarkY),
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${auth.studentName} • ${auth.studentCode} • ${auth.studentPhone}',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 3. Exit Fullscreen Floating Button (Safe area top-left)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: _toggleFullscreen,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.minimize2, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'تصغير الشاشة',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

