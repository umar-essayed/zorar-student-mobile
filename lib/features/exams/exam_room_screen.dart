import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/student_api_service.dart';
import '../../core/providers/student_data_providers.dart';
import '../../core/services/security_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class ExamRoomScreen extends ConsumerStatefulWidget {
  final String examId;
  final String examTitle;

  const ExamRoomScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  ConsumerState<ExamRoomScreen> createState() => _ExamRoomScreenState();
}

class _ExamRoomScreenState extends ConsumerState<ExamRoomScreen> {
  Map<String, dynamic>? _exam;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {}; // { questionId: selectedOptionId }

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;

  // Post-submission review state
  Map<String, dynamic>? _submissionResult;

  @override
  void initState() {
    super.initState();
    SecurityService.enableSecureScreen();
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    SecurityService.disableSecureScreen();
    super.dispose();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exam = await StudentApiService().getExamForTaking(widget.examId);
      if (exam == null) throw Exception('تعذر تحميل بيانات الامتحان');

      // 1. فحص فوري للمحاولات المتبقية قبل بدء الامتحان
      if (exam['isExhausted'] == true || (exam['remainingAttempts'] != null && (exam['remainingAttempts'] as num) <= 0)) {
        final lastSub = exam['lastSubmission'] as Map?;
        final score = num.tryParse(lastSub?['score']?.toString() ?? '0') ?? 0;
        final total = num.tryParse(lastSub?['total']?.toString() ?? exam['totalScore']?.toString() ?? '100') ?? 100;
        final passing = num.tryParse(exam['passingScore']?.toString() ?? '50') ?? 50;
        final percentage = total > 0 ? ((score / total) * 100).round() : 0;
        setState(() {
          _isLoading = false;
          _submissionResult = {
            'score': score,
            'total': total,
            'percentage': percentage,
            'passed': score >= passing,
            'isExhausted': true,
            'message': 'لقد استنفدت جميع المحاولات المسموحة لهذا الامتحان (${exam['maxAttempts'] ?? 1} محاولة)',
          };
        });
        return;
      }

      final qList = (exam['questions'] is List)
          ? List<Map<String, dynamic>>.from(exam['questions'])
          : <Map<String, dynamic>>[];

      final durationMin = (exam['durationMinutes'] ?? exam['duration'] ?? 30) as int;
      final totalExamSeconds = durationMin * 60;

      // Timer Persistence using SharedPreferences:
      // Even if the student exits and re-enters, the real elapsed time continues ticking
      final prefs = await SharedPreferences.getInstance();
      final timerKey = 'exam_start_time_${widget.examId}';
      int remainingSeconds = totalExamSeconds;

      final storedStartTime = prefs.getInt(timerKey);
      if (storedStartTime == null) {
        await prefs.setInt(timerKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - storedStartTime) ~/ 1000;
        remainingSeconds = totalExamSeconds - elapsedSeconds;
      }

      setState(() {
        _exam = exam;
        _questions = qList;
        _secondsRemaining = remainingSeconds > 0 ? remainingSeconds : 0;
        _isLoading = false;
      });

      if (_secondsRemaining <= 0) {
        _autoSubmitOnTimeUp();
      } else {
        _startTimer();
      }
    } catch (e) {
      String msg = 'تعذر فتح الامتحان، يرجى المحاولة لاحقاً أو مراجعة إدارة السنتر';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      } else if (e.toString().contains('انتهت')) {
        msg = 'انتهت فترة إتاحة هذا الامتحان';
      } else if (e.toString().contains('استنفدت')) {
        msg = 'لقد استنفدت جميع محاولاتك لهذا الامتحان';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _autoSubmitOnTimeUp();
      }
    });
  }

  Future<void> _autoSubmitOnTimeUp() async {
    SoundService.warningFeedback();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('انتهى الوقت المحدد للامتحان! جاري تسليم إجاباتك تلقائياً...', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
    }
    _submitExam(isAuto: true);
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _questions.length - _selectedAnswers.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد تسليم الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من إنهاء وتسليم إجاباتك؟', style: GoogleFonts.cairo()),
            const SizedBox(height: 10),
            if (unanswered > 0)
              Text(
                'تنبيه: يوجد لديك $unanswered أسئلة لم تقم بالإجابة عليها بعد!',
                style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              )
            else
              Text(
                'أحسنت! قمت بالإجابة على جميع الأسئلة (${_questions.length} سؤال).',
                style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('متابعة الحل', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تسليم نهائي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitExam(isAuto: false);
    }
  }

  Future<void> _submitExam({bool isAuto = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    // Prepare complete answers payload ensuring every question has a value
    final answersToSend = <String, String>{};
    for (final q in _questions) {
      final qId = q['id']?.toString() ?? '';
      if (qId.isNotEmpty) {
        answersToSend[qId] = _selectedAnswers[qId] ?? '';
      }
    }

    try {
      final res = await StudentApiService().submitExam(widget.examId, answersToSend);
      SoundService.successFeedback();
      ref.invalidate(liveStudentExamsProvider);
      ref.invalidate(liveStudentProfileProvider);

      // Clean timer persistence upon successful submission
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('exam_start_time_${widget.examId}');

      setState(() {
        _isSubmitting = false;
        _submissionResult = res;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      SoundService.errorFeedback();

      String friendlyMessage = 'تم تسجيل إجاباتك بنجاح. إذا واجهت أي استفسار يرجى مراجعة إدارة السنتر.';
      if (e is DioException) {
        final serverData = e.response?.data;
        if (serverData is Map && serverData['message'] != null) {
          final m = serverData['message'];
          if (m is String) friendlyMessage = m;
          else if (m is List && m.isNotEmpty) friendlyMessage = m.first.toString();
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(LucideIcons.alertCircle, color: Colors.orange, size: 40),
            title: Text('تنبيه', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text(
              friendlyMessage,
              style: GoogleFonts.cairo(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0143A3)),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (friendlyMessage.contains('استنفدت') || friendlyMessage.contains('انتهت')) {
                    Navigator.pop(context);
                  }
                },
                child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTime(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(color: branding.primaryColor, strokeWidth: 3.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'جاري تسليم وتصحيح الامتحان ذكياً...',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى الانتظار لحظات لرصد درجتك 🌟',
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examTitle, style: GoogleFonts.cairo())),
        body: Center(child: CircularProgressIndicator(color: branding.primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examTitle, style: GoogleFonts.cairo())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 56, color: Colors.orange),
                const SizedBox(height: 16),
                Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor),
                  onPressed: () => Navigator.pop(context),
                  child: Text('العودة لقائمة الامتحانات', style: GoogleFonts.cairo(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If submitted, show result screen!
    if (_submissionResult != null) {
      return _buildResultView(branding.primaryColor);
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examTitle, style: GoogleFonts.cairo())),
        body: Center(
          child: Text('لا توجد أسئلة في هذا الامتحان', style: GoogleFonts.cairo()),
        ),
      );
    }

    final currentQ = _questions[_currentIndex];
    final qId = currentQ['id']?.toString() ?? 'q_$_currentIndex';
    final options = (currentQ['options'] is List) ? (currentQ['options'] as List) : [];
    final selectedOpt = _selectedAnswers[qId];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('هل تريد مغادرة الامتحان؟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text('الخروج من الصفحة لا يوقف عداد الوقت. هل أنت متأكد؟', style: GoogleFonts.cairo()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('البقاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('مغادرة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.examTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _secondsRemaining < 300 ? Colors.red.withOpacity(0.15) : branding.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _secondsRemaining < 300 ? Colors.red : branding.primaryColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: _secondsRemaining < 300 ? Colors.red : branding.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _secondsRemaining < 300 ? Colors.red : branding.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              // Previous button: only visible if past question 0
              if (_currentIndex > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: Text(
                      'السابق',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    onPressed: () => setState(() => _currentIndex--),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Next or Submit button
              if (_currentIndex < _questions.length - 1)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
                    label: Text('التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () => setState(() => _currentIndex++),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                    label: Text('تسليم الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: _confirmSubmit,
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Question Progress Bar & Numbers
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).cardColor,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _questions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final itemQ = _questions[idx];
                  final itemId = itemQ['id']?.toString() ?? 'q_$idx';
                  final isAnswered = _selectedAnswers.containsKey(itemId);
                  final isCurrent = idx == _currentIndex;

                  Color bg = Theme.of(context).dividerColor.withOpacity(0.1);
                  Color textCol = Colors.grey;

                  if (isCurrent) {
                    bg = branding.primaryColor;
                    textCol = Colors.white;
                  } else if (isAnswered) {
                    bg = Colors.green.withOpacity(0.15);
                    textCol = Colors.green[800]!;
                  }

                  return InkWell(
                    onTap: () => setState(() => _currentIndex = idx),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent ? Border.all(color: branding.primaryColor, width: 2) : null,
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Active Question Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Question Number and Points Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السؤال ${_currentIndex + 1} من ${_questions.length}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: branding.primaryColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${currentQ['points'] ?? 1} درجات',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Question Text
                  Text(
                    currentQ['text']?.toString() ?? '',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                  ),

                  // Question Image if available
                  if ((currentQ['imageUrl']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        currentQ['imageUrl'].toString(),
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text('اختر الإجابة الصحيحة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),

                  // Options List
                  ...options.asMap().entries.map((entry) {
                    final optObj = entry.value;
                    final optText = (optObj is Map) ? (optObj['text']?.toString() ?? '') : optObj.toString();
                    final optId = (optObj is Map)
                        ? (optObj['id']?.toString() ?? String.fromCharCode(65 + entry.key))
                        : optText;

                    final isSelected = selectedOpt == optId || selectedOpt == optText;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? branding.primaryColor.withOpacity(0.08) : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? branding.primaryColor : Theme.of(context).dividerColor.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? branding.primaryColor : Theme.of(context).dividerColor.withOpacity(0.2),
                          child: isSelected
                              ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                              : Text(
                                  String.fromCharCode(65 + entry.key),
                                  style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                        ),
                        title: Text(
                          optText,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? branding.primaryColor : null,
                          ),
                        ),
                        onTap: () {
                          SoundService.lightImpact();
                          setState(() {
                            _selectedAnswers[qId] = optId;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(Color primaryColor) {
    final res = _submissionResult!;
    final score = num.tryParse(res['score']?.toString() ?? '0') ?? 0;
    final total = num.tryParse(res['total']?.toString() ?? '100') ?? 100;
    final percentage = num.tryParse(res['percentage']?.toString() ?? '0') ?? 0;
    final passed = res['passed'] == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Safely parse review list whether server sends List or Map
    List<Map<String, dynamic>> reviewList = [];
    if (res['review'] is List) {
      reviewList = (res['review'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } else if (res['review'] is Map) {
      reviewList = (res['review'] as Map).values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } else if (res['reviewMap'] is Map) {
      reviewList = (res['reviewMap'] as Map).values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('نتيجة الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // Celebration / Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: passed
                  ? (isDark ? const Color(0xFF064E3B).withOpacity(0.4) : const Color(0xFFECFDF5))
                  : (isDark ? const Color(0xFF7F1D1D).withOpacity(0.4) : const Color(0xFFFEF2F2)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  passed ? LucideIcons.award : LucideIcons.alertCircle,
                  size: 64,
                  color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                Text(
                  passed ? 'مبروك! لقد اجتزت الامتحان بنجاح 🌟' : 'حاول مرة أخرى! يمكنك تحسين درجتك القادمة 💪',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.cairo(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: (passed ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'النسبة المئوية: $percentage%',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Review of questions if available
          if (reviewList.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(LucideIcons.fileCheck, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'مراجعة الإجابات والنموذج 📝',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reviewList.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final q = entry.value;
              final qText = q['questionText']?.toString() ?? 'سؤال $idx';
              final studentAns = q['studentAnswer']?.toString() ?? '';
              final correctAns = q['correctAnswer']?.toString() ?? '';
              final isCorrect = q['isCorrect'] == true;
              final points = q['pointsAwarded'] ?? 0;
              final explanation = q['explanation']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.3)
                        : Colors.redAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: isCorrect ? Colors.green : Colors.red,
                          child: Icon(
                            isCorrect ? Icons.check : Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$idx. $qText',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isCorrect ? Colors.green : Colors.grey).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+$points',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('إجابتك: ', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
                        Text(
                          studentAns.isEmpty ? 'لم تُجب' : studentAns,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (!isCorrect && correctAns.isNotEmpty)
                      Row(
                        children: [
                          Text('الإجابة الصحيحة: ', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
                          Text(
                            correctAns,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    if (explanation != null && explanation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'توضيح: $explanation',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 24),

          // Return Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: Text(
                'العودة إلى قائمة الامتحانات',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
