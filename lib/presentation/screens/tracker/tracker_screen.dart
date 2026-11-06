import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/mock_test.dart';
import '../../../core/models/pyq_item.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/tracker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/question_image_viewer.dart';
import '../simulator/cbt_exam_screen.dart';
import 'cloud_sync_modal.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final TrackerService _trackerService = TrackerService.instance;
  final CloudSyncService _cloudSync = CloudSyncService.instance;
  List<PyqItem>? _allQuestions;
  Map<String, MockTest>? _mockTests;
  bool _isLoading = true;

  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'SOLVED', 'UNSOLVED', 'OOS'
  String _topicFilter = 'ALL';
  String _difficultyFilter = 'ALL';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _trackerService.addListener(_onTrackerUpdate);
    _cloudSync.addListener(_onTrackerUpdate);
    _loadQuestions();
  }

  @override
  void dispose() {
    _trackerService.removeListener(_onTrackerUpdate);
    _cloudSync.removeListener(_onTrackerUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _openCloudSyncModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CloudSyncModal(),
    );
  }

  void _onTrackerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadQuestions() async {
    await _trackerService.init();
    final questions = await DataService.instance.loadCategorizedPyqs();
    final tests = await DataService.instance.loadMockTests();
    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _mockTests = tests;
        _isLoading = false;
      });
    }
  }

  void _launchCbtForYear(int year) {
    final test = _mockTests?['$year'];
    if (test != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CbtExamScreen(test: test, isPracticeMode: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mock test paper for JAM $year not found.')),
      );
    }
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

    // Unique topics
    final topics = <String>{'ALL'};
    for (final q in questions) {
      if (q.topic.isNotEmpty) topics.add(q.topic);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PYQ Tracker (885 Questions)'),
        actions: [
          IconButton(
            icon: Icon(
              _cloudSync.isLinked ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined,
              color: _cloudSync.isLinked ? AppColors.accentGreen : AppColors.accentCyan,
            ),
            tooltip: _cloudSync.isLinked ? 'Cloud Sync (${_cloudSync.syncCode})' : 'Instant Cloud Sync',
            onPressed: _openCloudSyncModal,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'cloud_sync') {
                _openCloudSyncModal();
              } else if (val == 'oos_toggle') {
                _trackerService.markAllOosAsUnnecessary(questions, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked 87 Out of Syllabus questions as unnecessary')),
                );
              } else if (val == 'reset') {
                _confirmReset();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'cloud_sync',
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync, size: 18, color: AppColors.accentCyan),
                    SizedBox(width: 8),
                    Text('Cloud Sync (6-Digit PIN)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oos_toggle',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 18, color: AppColors.accentRed),
                    SizedBox(width: 8),
                    Text('Mark OOS Unnecessary (87 Qs)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
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
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.all(12),
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
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '$solved / $total Solved',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : solved / total,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryGold),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Analytics Row
                Row(
                  children: [
                    _buildMiniBadge('🔥 Streak: ${_trackerService.activeStreakDays}d', AppColors.primaryGold),
                    const SizedBox(width: 8),
                    _buildMiniBadge('📅 Today: +${_trackerService.solvedTodayCount}', AppColors.accentGreen),
                    const SizedBox(width: 8),
                    _buildMiniBadge('🚫 OOS: 87', AppColors.accentPurple),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search 885 PYQs (e.g. 2013 Q17, differential, 2026 5)...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryGold),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          // Filter Row 1: Status & Topics
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                _buildStatusChip('ALL', 'All Questions'),
                const SizedBox(width: 6),
                _buildStatusChip('SOLVED', '✓ Solved ($solved)'),
                const SizedBox(width: 6),
                _buildStatusChip('UNSOLVED', '○ Unsolved (${total - solved})'),
                const SizedBox(width: 6),
                _buildStatusChip('OOS', '⚠️ Out of Syllabus'),
                const SizedBox(width: 12),
                Container(height: 16, width: 1, color: AppColors.border),
                const SizedBox(width: 12),
                ...topics.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildTopicChip(t, t == 'ALL' ? 'All Subjects' : t),
                    )),
              ],
            ),
          ),

          // Filter Row 2: Difficulty Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
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

          // Question Count & Feed Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} of $total official PYQs',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
                if (_searchQuery.isNotEmpty || _statusFilter != 'ALL' || _difficultyFilter != 'ALL' || _topicFilter != 'ALL')
                  InkWell(
                    onTap: () {
                      setState(() {
                        _searchQuery = '';
                        _statusFilter = 'ALL';
                        _difficultyFilter = 'ALL';
                        _topicFilter = 'ALL';
                      });
                    },
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(fontSize: 11.5, color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Question List with Images Visible by Default
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No matching questions found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try clearing search keywords or resetting status/topic filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _statusFilter = 'ALL';
                                _difficultyFilter = 'ALL';
                                _topicFilter = 'ALL';
                              });
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final q = filtered[idx];
                      final prog = _trackerService.getProgress(q.id, defaultDiff: q.defaultDifficulty);

                      return PyqQuestionCard(
                        key: ValueKey(q.id),
                        question: q,
                        progress: prog,
                        onToggleSolved: () {
                          _trackerService.toggleSolved(q.id, _allQuestions ?? []);
                        },
                        onSetDifficulty: (diff) {
                          _trackerService.setDifficulty(q.id, diff);
                        },
                        onLaunchCbt: () {
                          _launchCbtForYear(q.year);
                        },
                      );
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

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will clear all marked solved questions, difficulty tags, and streaks. This action cannot be undone.',
        ),
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

class PyqQuestionCard extends StatefulWidget {
  final PyqItem question;
  final QuestionProgress progress;
  final VoidCallback onToggleSolved;
  final ValueChanged<String> onSetDifficulty;
  final VoidCallback onLaunchCbt;

  const PyqQuestionCard({
    super.key,
    required this.question,
    required this.progress,
    required this.onToggleSolved,
    required this.onSetDifficulty,
    required this.onLaunchCbt,
  });

  @override
  State<PyqQuestionCard> createState() => _PyqQuestionCardState();
}

class _PyqQuestionCardState extends State<PyqQuestionCard> {
  bool _isKeyRevealed = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final prog = widget.progress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: prog.solved ? AppColors.accentGreen.withValues(alpha: 0.5) : AppColors.border,
          width: prog.solved ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${q.year}_Q${q.questionNumber}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JAM ${q.year} • Q${q.questionNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildTypeBadge(q.type),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '+${q.marks}M',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tags row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '📁 ${q.subTopic}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ),
              DifficultyChip(difficulty: prog.difficulty, isCompact: true),
              if (q.isOutOfSyllabus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '⚠️ Out of Syllabus',
                    style: TextStyle(fontSize: 10, color: AppColors.accentRed, fontWeight: FontWeight.bold),
                  ),
                ),
              if (prog.solved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '✓ Solved${prog.solvedDate != null ? ' (${prog.solvedDate})' : ''}',
                    style: const TextStyle(fontSize: 10, color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Question Screenshot (VISIBLE BY DEFAULT!)
          QuestionImageViewer(
            imagePath: q.imagePath,
            maxHeight: 360,
            enableFullScreen: true,
            enableInlineZoom: false,
          ),

          const SizedBox(height: 12),

          // Interactive Controls Row 1: Solved & Difficulty
          Row(
            children: [
              // Solved Toggle Button
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onToggleSolved();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: prog.solved ? AppColors.accentGreen : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: prog.solved ? AppColors.accentGreen : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          prog.solved ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 15,
                          color: prog.solved ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prog.solved ? '✓ Solved' : '○ Mark Solved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: prog.solved ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Difficulty Dropdown Selector
              Expanded(
                flex: 4,
                child: PopupMenuButton<String>(
                  tooltip: 'Set Difficulty Tag',
                  initialValue: prog.difficulty,
                  onSelected: (newDiff) {
                    HapticFeedback.selectionClick();
                    widget.onSetDifficulty(newDiff);
                  },
                  itemBuilder: (_) => [
                    _diffMenuItem('very_easy', '🟢 Very Easy'),
                    _diffMenuItem('easy', '🔵 Easy'),
                    _diffMenuItem('medium', '🟡 Medium'),
                    _diffMenuItem('hard', '🟠 Hard'),
                    _diffMenuItem('hardest', '🟣 Hardest'),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DifficultyChip.getLabel(prog.difficulty),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: DifficultyChip.getColor(prog.difficulty),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Second Action Row: Show Key & Open CBT
          Row(
            children: [
              // Show / Hide Key Button
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isKeyRevealed = !_isKeyRevealed;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isKeyRevealed
                        ? AppColors.primaryGold.withValues(alpha: 0.15)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isKeyRevealed
                          ? AppColors.primaryGold.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isKeyRevealed ? Icons.visibility_off_outlined : Icons.vpn_key_outlined,
                        size: 14,
                        color: _isKeyRevealed ? AppColors.primaryGold : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isKeyRevealed ? 'Hide Key' : 'Show Key',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _isKeyRevealed ? AppColors.primaryGold : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isKeyRevealed) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Master Key: ${q.answer}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              // Launch CBT Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onLaunchCbt();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, size: 14, color: AppColors.primaryGold),
                      SizedBox(width: 4),
                      Text(
                        'Open CBT',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _diffMenuItem(String val, String text) {
    return PopupMenuItem(
      value: val,
      child: Text(text, style: const TextStyle(fontSize: 12.5)),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    switch (type.toUpperCase()) {
      case 'MCQ':
        color = AppColors.accentCyan;
        break;
      case 'MSQ':
        color = AppColors.accentPurple;
        break;
      case 'NAT':
        color = AppColors.primaryGold;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
