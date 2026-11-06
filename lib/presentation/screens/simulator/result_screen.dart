import 'package:flutter/material.dart';
import '../../../core/models/mock_test.dart';
import '../../../core/models/test_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/question_image_viewer.dart';
import 'cbt_exam_screen.dart';

class ResultScreen extends StatefulWidget {
  final TestResult result;
  final MockTest test;

  const ResultScreen({
    super.key,
    required this.result,
    required this.test,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String _filter = 'ALL'; // 'ALL', 'CORRECT', 'INCORRECT', 'UNATTEMPTED'

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;

    final filteredItems = res.reviewItems.where((item) {
      if (_filter == 'CORRECT') return item.isCorrect;
      if (_filter == 'INCORRECT') return item.isAttempted && !item.isCorrect;
      if (_filter == 'UNATTEMPTED') return !item.isAttempted;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Examination Results & Review'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.surfaceHighlight.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    res.testName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        res.totalScore.toStringAsFixed(res.totalScore is int || res.totalScore == res.totalScore.roundToDouble() ? 0 : 2),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${res.maxScore}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Accuracy', '${res.accuracyPercent.toStringAsFixed(1)}%', AppColors.accentCyan),
                      _buildStatColumn('Time Taken', _formatDuration(res.timeSpentSeconds), AppColors.textPrimary),
                      _buildStatColumn('Attempted', '${res.attempted}/${res.totalQuestions}', AppColors.accentPurple),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Correct, Incorrect, Unattempted Pills
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Correct',
                    count: res.correct,
                    color: AppColors.accentGreen,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Incorrect',
                    count: res.incorrect,
                    color: AppColors.accentRed,
                    icon: Icons.cancel_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Skipped',
                    count: res.unattempted,
                    color: AppColors.textMuted,
                    icon: Icons.remove_circle_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Actions: Retake Test & Home
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retake Test'),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CbtExamScreen(test: widget.test),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Return Home'),
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Filter Tabs for Review
            const Text(
              'Detailed Question Review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All (${res.totalQuestions})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CORRECT', 'Correct (${res.correct})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('INCORRECT', 'Incorrect (${res.incorrect})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('UNATTEMPTED', 'Skipped (${res.unattempted})'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Questions Review List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, idx) {
                final item = filteredItems[idx];
                return _buildReviewCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = key;
        });
      },
      selectedColor: AppColors.primaryGold,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.black : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildReviewCard(QuestionReviewItem item) {
    Color statusColor = AppColors.textMuted;
    String statusText = 'Skipped (0 Marks)';
    IconData statusIcon = Icons.remove_circle_outline;

    if (item.isAttempted) {
      if (item.isCorrect) {
        statusColor = AppColors.accentGreen;
        statusText = 'Correct (+${item.marksAwarded} Marks)';
        statusIcon = Icons.check_circle_outline;
      } else {
        statusColor = AppColors.accentRed;
        statusText = 'Incorrect (${item.marksAwarded} Marks)';
        statusIcon = Icons.cancel_outlined;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${item.index + 1} (${item.question.type})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Screenshot
          QuestionImageViewer(
            imagePath: item.question.image,
            maxHeight: 300,
          ),

          const SizedBox(height: 12),

          // User Response vs Key
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Answer:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        item.userResponse == null ? 'None (Skipped)' : item.userResponse.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.isCorrect ? AppColors.accentGreen : (item.isAttempted ? AppColors.accentRed : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Official Key:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        item.question.answerKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

