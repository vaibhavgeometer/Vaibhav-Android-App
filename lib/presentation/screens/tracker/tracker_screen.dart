import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/pyq_item.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/tracker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/question_image_viewer.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final TrackerService _trackerService = TrackerService.instance;
  List<PyqItem>? _allQuestions;
  bool _isLoading = true;

  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'SOLVED', 'UNSOLVED', 'OOS'
  String _topicFilter = 'ALL';
  String _difficultyFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _trackerService.addListener(_onTrackerUpdate);
    _loadQuestions();
  }

  @override
  void dispose() {
    _trackerService.removeListener(_onTrackerUpdate);
    super.dispose();
  }

  void _onTrackerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadQuestions() async {
    await _trackerService.init();
    final questions = await DataService.instance.loadCategorizedPyqs();
    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _isLoading = false;
      });
    }
  }

  void _openQuestionDetail(PyqItem q, QuestionProgress prog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildQuestionModal(q, prog),
    );
  }

  Widget _buildQuestionModal(PyqItem q, QuestionProgress prog) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${q.year} — Question ${q.questionNumber}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${q.topic} • ${q.subTopic}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Question Screenshot Viewer
            QuestionImageViewer(
              imagePath: q.imagePath,
              maxHeight: 350,
            ),

            const SizedBox(height: 14),

            // Official Answer Key Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Official Answer Key:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(
                    q.answer,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Difficulty Picker
            const Text('Change Difficulty:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['very_easy', 'easy', 'medium', 'hard', 'hardest'].map((diff) {
                final isCur = prog.difficulty == diff;
                return ChoiceChip(
                  label: Text(DifficultyChip.getLabel(diff), style: const TextStyle(fontSize: 11)),
                  selected: isCur,
                  onSelected: (val) {
                    if (val) {
                      _trackerService.setDifficulty(q.id, diff);
                      Navigator.pop(context);
                    }
                  },
                  selectedColor: DifficultyChip.getColor(diff),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Solved Toggle Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(prog.solved ? Icons.check_circle : Icons.radio_button_unchecked, size: 18),
                label: Text(prog.solved ? 'Mark as Unsolved' : 'Mark as Solved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: prog.solved ? AppColors.accentRed.withValues(alpha: 0.8) : AppColors.accentGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _trackerService.toggleSolved(q.id, _allQuestions ?? []);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    final questions = _allQuestions ?? [];
    final filtered = questions.where((q) {
      final prog = _trackerService.getProgress(q.id, defaultDiff: q.defaultDifficulty);

      // Status filter
      if (_statusFilter == 'SOLVED' && !prog.solved) return false;
      if (_statusFilter == 'UNSOLVED' && prog.solved) return false;
      if (_statusFilter == 'OOS' && !q.isOutOfSyllabus) return false;

      // Topic filter
      if (_topicFilter != 'ALL' && q.topic != _topicFilter) return false;

      // Difficulty filter
      if (_difficultyFilter != 'ALL' && prog.difficulty != _difficultyFilter) return false;

      // Search query
      if (_searchQuery.isNotEmpty) {
        final qry = _searchQuery.toLowerCase();
        final matchYearQ = '${q.year} ${q.questionNumber}'.contains(qry) ||
            '${q.year} q${q.questionNumber}'.contains(qry) ||
            'q${q.questionNumber} ${q.year}'.contains(qry);
        final matchTopic = q.topic.toLowerCase().contains(qry) ||
            q.subTopic.toLowerCase().contains(qry);
        final matchId = q.id.toLowerCase().contains(qry);
        if (!matchYearQ && !matchTopic && !matchId) return false;
      }

      return true;
    }).toList();

    final solved = _trackerService.solvedCount;
    final total = questions.length;
    final pct = total == 0 ? 0 : ((solved / total) * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PYQ Tracker (885 Questions)'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'oos_toggle') {
                _trackerService.markAllOosAsUnnecessary(questions, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked 87 Out of Syllabus questions as unnecessary')),
                );
              } else if (val == 'reset') {
                _confirmReset();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'oos_toggle',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 18, color: AppColors.accentRed),
                    SizedBox(width: 8),
                    Text('Mark OOS Unnecessary (87 Qs)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text('Reset All Progress', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Progress Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '$solved / $total Solved',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : (solved / total),
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceHighlight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniBadge('🔥 Streak: ${_trackerService.activeStreakDays}d', AppColors.primaryGold),
                    _buildMiniBadge('📅 Today: +${_trackerService.solvedTodayCount}', AppColors.accentGreen),
                    _buildMiniBadge('🚫 OOS: ${_trackerService.unnecessaryCount}', AppColors.accentPurple),
                  ],
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search 885 PYQs (e.g. 2013 Q17, differential equation)...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                _buildStatusChip('ALL', 'All ($total)'),
                const SizedBox(width: 6),
                _buildStatusChip('SOLVED', 'Solved ($solved)'),
                const SizedBox(width: 6),
                _buildStatusChip('UNSOLVED', 'Unsolved (${total - solved})'),
                const SizedBox(width: 6),
                _buildStatusChip('OOS', 'Out of Syllabus (87)'),
                const SizedBox(width: 10),
                Container(width: 1, height: 20, color: AppColors.border),
                const SizedBox(width: 10),
                _buildTopicChip('ALL', 'All Topics'),
                const SizedBox(width: 6),
                _buildTopicChip('Real Analysis', 'Real Analysis'),
                const SizedBox(width: 6),
                _buildTopicChip('Multivariable Calculus and Differential Equations', 'Multivariable & Diff Eq'),
                const SizedBox(width: 6),
                _buildTopicChip('Linear Algebra and Algebra', 'Linear Algebra & Algebra'),
                const SizedBox(width: 10),
                Container(width: 1, height: 20, color: AppColors.border),
                const SizedBox(width: 10),
                _buildDifficultyFilterChip('ALL', 'All Difficulties'),
                const SizedBox(width: 6),
                _buildDifficultyFilterChip('very_easy', 'Very Easy'),
                const SizedBox(width: 6),
                _buildDifficultyFilterChip('easy', 'Easy'),
                const SizedBox(width: 6),
                _buildDifficultyFilterChip('medium', 'Medium'),
                const SizedBox(width: 6),
                _buildDifficultyFilterChip('hard', 'Hard'),
                const SizedBox(width: 6),
                _buildDifficultyFilterChip('hardest', 'Hardest'),
              ],
            ),
          ),

          // Question List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final q = filtered[idx];
                final prog = _trackerService.getProgress(q.id, defaultDiff: q.defaultDifficulty);

                return _buildQuestionTile(q, prog);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _statusFilter = key);
      },
      selectedColor: AppColors.primaryGold,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.black : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTopicChip(String key, String label) {
    final isSelected = _topicFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _topicFilter = key);
      },
      selectedColor: AppColors.accentCyan,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDifficultyFilterChip(String key, String label) {
    final isSelected = _difficultyFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _difficultyFilter = key);
      },
      selectedColor: AppColors.accentPurple,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildQuestionTile(PyqItem q, QuestionProgress prog) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: prog.solved ? AppColors.accentGreen.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: () => _openQuestionDetail(q, prog),
        leading: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _trackerService.toggleSolved(q.id, _allQuestions ?? []);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              prog.solved ? Icons.check_circle : Icons.radio_button_unchecked,
              color: prog.solved ? AppColors.accentGreen : AppColors.textMuted,
              size: 24,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${q.year} Q${q.questionNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            DifficultyChip(difficulty: prog.difficulty, isCompact: true),
          ],
        ),
        subtitle: Text(
          '${q.topic} • ${q.subTopic}',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text('This will clear all marked solved questions, difficulty tags, and streaks. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () {
              Navigator.pop(ctx);
              _trackerService.resetAll();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
