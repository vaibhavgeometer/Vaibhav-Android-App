import 'package:flutter/material.dart';
import '../../../core/models/pyq_item.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/pdf_helper.dart';
import '../../../core/services/tracker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/difficulty_chip.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final TrackerService _trackerService = TrackerService.instance;
  List<PyqItem>? _questions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trackerService.addListener(_onTrackerUpdate);
    _loadData();
  }

  @override
  void dispose() {
    _trackerService.removeListener(_onTrackerUpdate);
    super.dispose();
  }

  void _onTrackerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    final qs = await DataService.instance.loadCategorizedPyqs();
    if (mounted) {
      setState(() {
        _questions = qs;
        _isLoading = false;
      });
    }
  }

  String _calculateForecast(int solved, int total) {
    final remaining = total - solved;
    if (remaining <= 0) return 'Complete! 🎉';

    final pace = _trackerService.solvedThisWeekCount / 7.0;
    if (pace < 0.2) return 'At current pace: ~${(remaining / 2).ceil()} days';

    final daysNeeded = (remaining / pace).ceil();
    final targetDate = DateTime.now().add(Duration(days: daysNeeded));
    return 'Est: ${targetDate.day}/${targetDate.month}/${targetDate.year} ($daysNeeded days)';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    final qs = _questions ?? [];
    final total = qs.length;
    final solved = _trackerService.solvedCount;

    // Topic stats
    final realAnalysisTotal = qs.where((q) => q.topic == 'Real Analysis').length;
    final realAnalysisSolved = qs.where((q) => q.topic == 'Real Analysis' && _trackerService.getProgress(q.id).solved).length;

    final multiTotal = qs.where((q) => q.topic == 'Multivariable Calculus and Differential Equations').length;
    final multiSolved = qs.where((q) => q.topic == 'Multivariable Calculus and Differential Equations' && _trackerService.getProgress(q.id).solved).length;

    final algebraTotal = qs.where((q) => q.topic == 'Linear Algebra and Algebra').length;
    final algebraSolved = qs.where((q) => q.topic == 'Linear Algebra and Algebra' && _trackerService.getProgress(q.id).solved).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Study Analytics & Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentCyan),
            tooltip: 'Download 22-Year Project Analytics PDF',
            onPressed: () {
              PdfHelper.openAssetPdf(
                'assets/IIT_JAM_MA_Project_Statistics_and_Analytics_Report.pdf',
                'IIT_JAM_MA_Project_Statistics_Report.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak & Daily Solving Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.primaryGold.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_trackerService.activeStreakDays} Day Streak',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today: +${_trackerService.solvedTodayCount} Qs • This Week: +${_trackerService.solvedThisWeekCount} Qs',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _calculateForecast(solved, total),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Topic Mastery Section
            const Text(
              'Topic Mastery Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            _buildTopicCard('Real Analysis', realAnalysisSolved, realAnalysisTotal, AppColors.accentCyan),
            const SizedBox(height: 10),
            _buildTopicCard('Multivariable & Diff Equations', multiSolved, multiTotal, AppColors.accentGreen),
            const SizedBox(height: 10),
            _buildTopicCard('Linear Algebra & Algebra', algebraSolved, algebraTotal, AppColors.primaryGold),

            const SizedBox(height: 22),

            // Difficulty Breakdown
            const Text(
              'Difficulty Level Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            _buildDifficultyDistribution(qs),

            const SizedBox(height: 20),

            // Official Statistics Report Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('📊', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        '22-Year Project Statistics Report',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Empirical distribution analysis across 22 years (2005–2026), topic weightings, cut-offs, and trend forecasting.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Open 22-Year Analytics Report (PDF)'),
                      onPressed: () {
                        PdfHelper.openAssetPdf(
                          'assets/IIT_JAM_MA_Project_Statistics_and_Analytics_Report.pdf',
                          'IIT_JAM_MA_Project_Statistics_Report.pdf',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(String topicName, int solved, int total, Color color) {
    final pct = total == 0 ? 0 : ((solved / total) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topicName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
              ),
              Text(
                '$solved / $total ($pct%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (solved / total),
              minHeight: 6,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyDistribution(List<PyqItem> qs) {
    final counts = <String, int>{};
    for (final q in qs) {
      final prog = _trackerService.getProgress(q.id, defaultDiff: q.defaultDifficulty);
      counts[prog.difficulty] = (counts[prog.difficulty] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: ['very_easy', 'easy', 'medium', 'hard', 'hardest'].map((diff) {
          final count = counts[diff] ?? 0;
          final pct = qs.isEmpty ? 0 : ((count / qs.length) * 100).toInt();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: DifficultyChip(difficulty: diff, isCompact: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: qs.isEmpty ? 0 : (count / qs.length),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHighlight,
                      valueColor: AlwaysStoppedAnimation<Color>(DifficultyChip.getColor(diff)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count ($pct%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

