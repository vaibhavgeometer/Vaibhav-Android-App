import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/mock_test.dart';
import '../../../core/models/question.dart';
import '../../../core/models/test_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/question_image_viewer.dart';
import 'calculator_sheet.dart';
import 'result_screen.dart';

enum QuestionStatus {
  notVisited,
  notAnswered,
  answered,
  review,
  answeredReview,
}

class CbtExamScreen extends StatefulWidget {
  final MockTest test;
  final bool isPracticeMode;

  const CbtExamScreen({
    super.key,
    required this.test,
    this.isPracticeMode = false,
  });

  @override
  State<CbtExamScreen> createState() => _CbtExamScreenState();
}

class _CbtExamScreenState extends State<CbtExamScreen> {
  int _currentIndex = 0;
  late int _timeRemainingSeconds;
  late int _totalDurationSeconds;
  Timer? _timer;
  bool _isSubmitted = false;

  final Map<int, dynamic> _responses = {};
  final Map<int, QuestionStatus> _statuses = {};
  final TextEditingController _natController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalDurationSeconds = widget.test.durationMinutes * 60;
    _timeRemainingSeconds = widget.isPracticeMode ? 0 : _totalDurationSeconds;

    for (int i = 0; i < widget.test.questions.length; i++) {
      _statuses[i] = QuestionStatus.notVisited;
    }
    if (widget.test.questions.isNotEmpty) {
      _statuses[0] = QuestionStatus.notAnswered;
      _loadCurrentResponseIntoInput();
    }

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _natController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (widget.isPracticeMode) {
          _timeRemainingSeconds++;
        } else {
          if (_timeRemainingSeconds > 0) {
            _timeRemainingSeconds--;
          } else {
            _timer?.cancel();
            _submitExam(autoSubmit: true);
          }
        }
      });
    });
  }

  void _loadCurrentResponseIntoInput() {
    if (widget.test.questions.isEmpty || _currentIndex < 0 || _currentIndex >= widget.test.questions.length) return;
    final currentQ = widget.test.questions[_currentIndex];
    if (currentQ.type == 'NAT') {
      final resp = _responses[_currentIndex];
      _natController.text = resp?.toString() ?? '';
    }
  }

  void _saveCurrentInputToResponse() {
    if (widget.test.questions.isEmpty || _currentIndex < 0 || _currentIndex >= widget.test.questions.length) return;
    final currentQ = widget.test.questions[_currentIndex];
    if (currentQ.type == 'NAT') {
      final text = _natController.text.trim();
      if (text.isNotEmpty) {
        _responses[_currentIndex] = text;
      } else {
        _responses.remove(_currentIndex);
      }
    }
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= widget.test.questions.length) return;
    _saveCurrentInputToResponse();

    setState(() {
      _currentIndex = index;
      if (_statuses[_currentIndex] == QuestionStatus.notVisited) {
        _statuses[_currentIndex] = QuestionStatus.notAnswered;
      }
      _loadCurrentResponseIntoInput();
    });
  }

  void _saveAndNext() {
    HapticFeedback.lightImpact();
    _saveCurrentInputToResponse();

    final hasAnswer = _hasAnswered(_currentIndex);
    setState(() {
      if (hasAnswer) {
        _statuses[_currentIndex] = QuestionStatus.answered;
      } else {
        _statuses[_currentIndex] = QuestionStatus.notAnswered;
      }

      if (_currentIndex < widget.test.questions.length - 1) {
        _goToQuestion(_currentIndex + 1);
      }
    });
  }

  void _markForReviewAndNext() {
    HapticFeedback.lightImpact();
    _saveCurrentInputToResponse();

    final hasAnswer = _hasAnswered(_currentIndex);
    setState(() {
      if (hasAnswer) {
        _statuses[_currentIndex] = QuestionStatus.answeredReview;
      } else {
        _statuses[_currentIndex] = QuestionStatus.review;
      }

      if (_currentIndex < widget.test.questions.length - 1) {
        _goToQuestion(_currentIndex + 1);
      }
    });
  }

  void _clearResponse() {
    HapticFeedback.mediumImpact();
    setState(() {
      _responses.remove(_currentIndex);
      _natController.clear();
      _statuses[_currentIndex] = QuestionStatus.notAnswered;
    });
  }

  bool _hasAnswered(int index) {
    final resp = _responses[index];
    if (resp == null) return false;
    if (resp is List && resp.isEmpty) return false;
    if (resp is String && resp.trim().isEmpty) return false;
    return true;
  }

  void _openCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CalculatorSheet(),
    );
  }

  void _openPaletteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPaletteModal(),
    );
  }

  void _submitExam({bool autoSubmit = false}) {
    if (_isSubmitted) return;

    if (!autoSubmit) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('Submit Examination?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Questions: ${widget.test.questions.length}'),
              Text('Answered: ${_countStatus(QuestionStatus.answered) + _countStatus(QuestionStatus.answeredReview)}',
                  style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
              Text('Marked for Review: ${_countStatus(QuestionStatus.review) + _countStatus(QuestionStatus.answeredReview)}',
                  style: const TextStyle(color: AppColors.accentPurple)),
              Text('Not Answered: ${_countStatus(QuestionStatus.notAnswered) + _countStatus(QuestionStatus.notVisited)}',
                  style: const TextStyle(color: AppColors.accentRed)),
              const SizedBox(height: 12),
              const Text('Are you sure you want to finish and review your result?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Resume Test', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _finalizeSubmission();
              },
              child: const Text('Yes, Submit'),
            ),
          ],
        ),
      );
    } else {
      _finalizeSubmission();
    }
  }

  void _finalizeSubmission() {
    _timer?.cancel();
    _saveCurrentInputToResponse();
    _isSubmitted = true;

    // Calculate score
    num totalScore = 0;
    int attempted = 0;
    int correct = 0;
    int incorrect = 0;
    int unattempted = 0;
    final reviewItems = <QuestionReviewItem>[];

    for (int i = 0; i < widget.test.questions.length; i++) {
      final q = widget.test.questions[i];
      final userResp = _responses[i];
      final isAtt = _hasAnswered(i);

      if (isAtt) {
        attempted++;
        final isCorr = q.isAnswerCorrect(userResp);
        if (isCorr) {
          correct++;
          totalScore += q.marks;
          reviewItems.add(QuestionReviewItem(
            index: i,
            question: q,
            userResponse: userResp,
            isAttempted: true,
            isCorrect: true,
            marksAwarded: q.marks,
          ));
        } else {
          incorrect++;
          totalScore -= q.negativeMarks;
          reviewItems.add(QuestionReviewItem(
            index: i,
            question: q,
            userResponse: userResp,
            isAttempted: true,
            isCorrect: false,
            marksAwarded: -q.negativeMarks,
          ));
        }
      } else {
        unattempted++;
        reviewItems.add(QuestionReviewItem(
          index: i,
          question: q,
          userResponse: null,
          isAttempted: false,
          isCorrect: false,
          marksAwarded: 0,
        ));
      }
    }

    final timeSpent = widget.isPracticeMode
        ? _timeRemainingSeconds
        : (_totalDurationSeconds - _timeRemainingSeconds);

    final result = TestResult(
      testId: widget.test.id,
      testName: widget.test.name,
      totalScore: totalScore < 0 ? 0 : totalScore,
      maxScore: widget.test.totalMarks,
      totalQuestions: widget.test.questions.length,
      attempted: attempted,
      correct: correct,
      incorrect: incorrect,
      unattempted: unattempted,
      timeSpentSeconds: timeSpent,
      completedAt: DateTime.now(),
      responses: _responses,
      reviewItems: reviewItems,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, test: widget.test),
      ),
    );
  }

  int _countStatus(QuestionStatus status) {
    return _statuses.values.where((s) => s == status).length;
  }

  String _formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.test.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.test.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.info_outline, size: 48, color: AppColors.primaryGold),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.test.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.test.pattern.isNotEmpty
                      ? widget.test.pattern
                      : '0 Questions Available (Not in this syllabus era)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This syllabus era did not contain separate examination questions for this specific subtopic.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Return to Mock Tests'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = widget.test.questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _submitExam(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.test.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Q ${_currentIndex + 1} of ${widget.test.questions.length} • ${q.type} • +${q.marks} / -${q.negativeMarks}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Timer Widget
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _timeRemainingSeconds < 300 && !widget.isPracticeMode
                  ? AppColors.accentRed.withValues(alpha: 0.2)
                  : AppColors.accentCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _timeRemainingSeconds < 300 && !widget.isPracticeMode
                    ? AppColors.accentRed
                    : AppColors.accentCyan.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: _timeRemainingSeconds < 300 && !widget.isPracticeMode
                      ? AppColors.accentRed
                      : AppColors.accentCyan,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimer(_timeRemainingSeconds),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: _timeRemainingSeconds < 300 && !widget.isPracticeMode
                        ? AppColors.accentRed
                        : AppColors.accentCyan,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Text('🖩', style: TextStyle(fontSize: 20)),
            tooltip: 'Virtual Scientific Calculator',
            onPressed: _openCalculator,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: AppColors.primaryGold),
            tooltip: 'Question Palette',
            onPressed: _openPaletteSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Question Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Screenshot
                    QuestionImageViewer(
                      imagePath: q.image,
                      maxHeight: 400,
                    ),

                    const SizedBox(height: 16),

                    // Answer Input Controls
                    _buildAnswerControls(q),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Navigation and Action Buttons
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerControls(Question q) {
    if (q.type == 'MCQ') {
      final selected = _responses[_currentIndex] as String?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Option (Single Choice):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['A', 'B', 'C', 'D'].map((opt) {
              final isChosen = selected == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _responses[_currentIndex] = opt;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isChosen ? AppColors.primaryGold : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChosen ? AppColors.primaryGold : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '($opt)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isChosen ? Colors.black : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    if (q.type == 'MSQ') {
      List<String> chosenList = [];
      final raw = _responses[_currentIndex];
      if (raw is List) {
        chosenList = raw.map((e) => e.toString()).toList();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select One or More Options (No Partial Marks):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['A', 'B', 'C', 'D'].map((opt) {
              final isChosen = chosenList.contains(opt);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        final list = List<String>.from(chosenList);
                        if (list.contains(opt)) {
                          list.remove(opt);
                        } else {
                          list.add(opt);
                        }
                        list.sort();
                        _responses[_currentIndex] = list;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isChosen ? AppColors.accentCyan : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChosen ? AppColors.accentCyan : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '[$opt]',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isChosen ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // NAT (Numerical Answer Type)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Numerical Answer:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _natController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. 2.35 or -1 or 4',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textMuted),
              onPressed: () {
                _natController.clear();
                _responses.remove(_currentIndex);
              },
            ),
          ),
          onChanged: (val) {
            _responses[_currentIndex] = val.trim();
          },
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: _clearResponse,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _markForReviewAndNext,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentPurple,
                    side: const BorderSide(color: AppColors.accentPurple),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Mark & Next', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveAndNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Save & Next', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_ios, size: 12),
                label: const Text('Previous'),
                onPressed: _currentIndex > 0 ? () => _goToQuestion(_currentIndex - 1) : null,
              ),
              TextButton(
                onPressed: () => _submitExam(),
                style: TextButton.styleFrom(foregroundColor: AppColors.accentGreen),
                child: const Row(
                  children: [
                    Text('Submit Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.check_circle_outline, size: 16),
                  ],
                ),
              ),
              TextButton.icon(
                label: const Text('Next'),
                icon: const Icon(Icons.arrow_forward_ios, size: 12),
                onPressed: _currentIndex < widget.test.questions.length - 1
                    ? () => _goToQuestion(_currentIndex + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteModal() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Question Palette',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Palette Status Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendPill(AppColors.paletteAnswered, 'Answered (${_countStatus(QuestionStatus.answered)})'),
              _buildLegendPill(AppColors.paletteNotAnswered, 'Not Answered (${_countStatus(QuestionStatus.notAnswered)})'),
              _buildLegendPill(AppColors.paletteReview, 'Review (${_countStatus(QuestionStatus.review)})'),
              _buildLegendPill(AppColors.paletteAnsReview, 'Ans & Review (${_countStatus(QuestionStatus.answeredReview)})'),
              _buildLegendPill(AppColors.paletteNotVisited, 'Not Visited (${_countStatus(QuestionStatus.notVisited)})'),
            ],
          ),
          const SizedBox(height: 16),

          // Questions Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.test.questions.length,
              itemBuilder: (ctx, idx) {
                final status = _statuses[idx] ?? QuestionStatus.notVisited;
                final isCurrent = idx == _currentIndex;

                Color bg = AppColors.paletteNotVisited;
                if (status == QuestionStatus.answered) bg = AppColors.paletteAnswered;
                if (status == QuestionStatus.notAnswered) bg = AppColors.paletteNotAnswered;
                if (status == QuestionStatus.review) bg = AppColors.paletteReview;
                if (status == QuestionStatus.answeredReview) bg = AppColors.paletteAnsReview;

                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _goToQuestion(idx);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(Color c, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

