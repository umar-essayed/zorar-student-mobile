import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/student_api_service.dart';
import '../../core/providers/student_data_providers.dart';
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
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

      final qList = (exam['questions'] is List)
          ? List<Map<String, dynamic>>.from(exam['questions'])
          : <Map<String, dynamic>>[];

      final durationMin = (exam['durationMinutes'] ?? exam['duration'] ?? 30) as int;

      setState(() {
        _exam = exam;
        _questions = qList;
        _secondsRemaining = durationMin * 60;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('انتهت')
            ? 'انتهت فترة إتاحة هذا الامتحان'
            : 'تعذر فتح الامتحان، يرجى المحاولة لاحقاً أو مراجعة إدارة السنتر';
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

    try {
      final res = await StudentApiService().submitExam(widget.examId, _selectedAnswers);
      SoundService.successFeedback();
      ref.invalidate(liveStudentExamsProvider);

      setState(() {
        _isSubmitting = false;
        _submissionResult = res;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      SoundService.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تسليم الامتحان: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
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
    final branding = ref.watch(studentBrandingProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examTitle, style: GoogleFonts.cairo())),
        body: const Center(child: CircularProgressIndicator()),
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
                  onPressed: () => Navigator.pop(context),
                  child: Text('العودة لقائمة الامتحانات', style: GoogleFonts.cairo()),
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

    return WillPopScope(
      onWillPop: () async {
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
                child: const Text('مغادرة'),
              ),
            ],
          ),
        );
        return leave ?? false;
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
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              // Previous button
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: Text('السابق', style: GoogleFonts.cairo()),
                    onPressed: () => setState(() => _currentIndex--),
                  ),
                )
              else
                const Spacer(),

              const SizedBox(width: 12),

              // Next or Finish button
              if (_currentIndex < _questions.length - 1)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor),
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: Text('التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => _currentIndex++),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(LucideIcons.checkCheck, size: 18),
                    label: Text('تسليم الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
    final score = res['score'] ?? 0;
    final total = res['total'] ?? 100;
    final percentage = res['percentage'] ?? 0;
    final passed = res['passed'] ?? false;
    final review = res['review'] as List?;

    return Scaffold(
      appBar: AppBar(
        title: Text('نتيجة الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Celebration / Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: passed ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: passed ? Colors.green : Colors.red),
            ),
            child: Column(
              children: [
                Icon(
                  passed ? LucideIcons.award : LucideIcons.alertCircle,
                  size: 64,
                  color: passed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  passed ? 'مبروك! لقد اجتزت الامتحان بنجاح' : 'للأسف لم تتجاوز درجة النجاح هذه المرة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green[800] : Colors.red[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: passed ? Colors.green : Colors.red),
                    ),
                    Text(
                      ' / $total',
                      style: GoogleFonts.cairo(fontSize: 22, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Text(
                  'النسبة المئوية: $percentage%',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Return Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(context),
              child: Text('العودة إلى شاشة الامتحانات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
