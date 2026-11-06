import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/mock_test.dart';
import '../../../core/models/pyq_item.dart';
import '../../../core/models/question.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/pdf_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../simulator/cbt_exam_screen.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  // Top level section: 'YEARS' (22-Year Papers), 'SUBTOPICS' (27 Subtopic Tests), 'CUSTOM' (Custom Generator)
  String _activeSection = 'YEARS';

  // Sub-filters for 22-Year Papers
  String _yearFilter = 'ALL'; // 'ALL', 'cbt', 'classic'

  // Sub-filters for Subtopics
  String _subtopicEraFilter = 'ALL'; // 'ALL', '2022-2026', '2015-2021', '2005-2014', 'archive'
  String _subtopicCategoryFilter = 'ALL'; // 'ALL', 'Real Analysis', 'Multivariable', 'Linear Algebra'

  String _searchQuery = '';
  Map<String, MockTest>? _allTests;
  List<PyqItem>? _allPyqs;
  bool _isLoading = true;

  // Custom Generator State
  final Set<String> _selectedCustomTopics = {
    'Sequences and Series of Real Numbers',
    'Functions of One Real Variable',
    'Linear Algebra',
    'Group Theory',
  };
  int _customQuestionCount = 20;
  String _customDifficulty = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tests = await DataService.instance.loadMockTests();
    final pyqs = await DataService.instance.loadCategorizedPyqs();
    if (mounted) {
      setState(() {
        _allTests = tests;
        _allPyqs = pyqs;
        _isLoading = false;
      });
    }
  }

  void _startTest(MockTest test, {required bool isPractice}) {
    if (test.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${test.name} has 0 questions in this syllabus era.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CbtExamScreen(test: test, isPracticeMode: isPractice),
      ),
    );
  }

  void _launchCustomTest({required bool isPractice}) {
    final pyqs = _allPyqs ?? [];
    final matching = pyqs.where((q) {
      if (_selectedCustomTopics.isNotEmpty && !_selectedCustomTopics.contains(q.subTopic)) {
        return false;
      }
      if (_customDifficulty != 'ALL' && q.defaultDifficulty != _customDifficulty) {
        return false;
      }
      return true;
    }).toList();

    if (matching.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions match your chosen topic and difficulty criteria.')),
      );
      return;
    }

    // Shuffle and pick
    matching.shuffle(Random());
    final count = min(_customQuestionCount, matching.length);
    final chosen = matching.take(count).toList();

    final questions = chosen.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final q = entry.value;

      return Question(
        id: q.id,
        year: q.year.toString(),
        qNum: idx,
        type: q.type,
        marks: q.marks,
        negativeMarks: q.type == 'MCQ' ? (q.marks == 1 ? 0.33 : 0.66) : 0.0,
        image: q.imagePath,
        answerKey: q.answer,
        explanation: 'IIT JAM ${q.year} MA — Q${q.questionNumber} (${q.subTopic})',
      );
    }).toList();

    final totalMarks = questions.fold<num>(0, (sum, q) => sum + q.marks);
    final duration = (questions.length * 3).clamp(15, 180);

    final customMockTest = MockTest(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      fileId: 'custom_drill',
      year: 0,
      name: 'Custom Mock Drill ($count Questions)',
      category: 'Custom Practice',
      era: 'cbt',
      totalQuestions: questions.length,
      totalMarks: totalMarks,
      durationMinutes: duration,
      pattern: '$count Qs • Mixed Syllabus Topics',
      paperPdf: '',
      questions: questions,
    );

    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CbtExamScreen(test: customMockTest, isPracticeMode: isPractice),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mock Test Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentCyan),
            tooltip: '22-Year PYQ Archive PDF',
            onPressed: () {
              PdfHelper.openAssetPdf(
                'assets/MA2005-2026_Original_PYQs.pdf',
                'IIT_JAM_22_Year_PYQ_Archive.pdf',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Segmented Switcher (Exact 3 sections of the live website)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSectionTab('YEARS', '🏛 22-Year Papers'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildSectionTab('SUBTOPICS', '⚡ 27 Subtopics'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildSectionTab('CUSTOM', '🛠️ Custom Test'),
                ),
              ],
            ),
          ),

          // Body Content depending on active section
          Expanded(
            child: _buildActiveSectionContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab(String key, String title) {
    final isSelected = _activeSection == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeSection = key;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActiveSectionContent() {
    switch (_activeSection) {
      case 'YEARS':
        return _buildYearTestsSection();
      case 'SUBTOPICS':
        return _buildSubtopicTestsSection();
      case 'CUSTOM':
        return _buildCustomGeneratorSection();
      default:
        return _buildYearTestsSection();
    }
  }

  // --- SECTION 1: 22-YEAR MOCK TESTS (2005–2026) ---
  Widget _buildYearTestsSection() {
    final testsMap = _allTests ?? {};

    // Filter STRICTLY to the 22 annual exam papers
    final yearTests = testsMap.values.where((test) {
      // Must be a year test (key is the year string, year between 2005 and 2026)
      if (test.year < 2005 || test.year > 2026 || test.id != '${test.year}') {
        return false;
      }

      // Sub-filter
      if (_yearFilter == 'cbt' && test.year < 2015) return false;
      if (_yearFilter == 'classic' && test.year >= 2015) return false;

      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return test.name.toLowerCase().contains(q) || test.year.toString().contains(q);
      }
      return true;
    }).toList();

    // Sort strictly recent years first: 2026 down to 2005
    yearTests.sort((a, b) => b.year.compareTo(a.year));

    return Column(
      children: [
        // Year Sub-Filter Tabs (Matching website: All Papers 22 Yrs, CBT Era, Classic Era)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Papers (22 Years: 2005–2026)',
                isSelected: _yearFilter == 'ALL',
                onSelected: () => setState(() => _yearFilter = 'ALL'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'CBT Era (2015–2026 • 60 Qs)',
                isSelected: _yearFilter == 'cbt',
                onSelected: () => setState(() => _yearFilter = 'cbt'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Classic Era (2005–2014)',
                isSelected: _yearFilter == 'classic',
                onSelected: () => setState(() => _yearFilter = 'classic'),
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
              hintText: 'Search 22-year examination papers (e.g. 2026, 2018)...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
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
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: yearTests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _buildTestCard(yearTests[idx]),
          ),
        ),
      ],
    );
  }

  // --- SECTION 2: 27 SUBTOPIC MOCK TESTS (3 ERAS × 9 TOPICS) ---
  Widget _buildSubtopicTestsSection() {
    final testsMap = _allTests ?? {};

    // Filter to subtopic tests (i.e. not the 22 annual tests)
    final subtopicTests = testsMap.values.where((test) {
      if (test.id == '${test.year}' && test.year >= 2005) {
        return false; // Skip the 22 full-year annual tests
      }

      // Era filter
      if (_subtopicEraFilter == '2022-2026' && !test.id.startsWith('2022-2026')) return false;
      if (_subtopicEraFilter == '2015-2021' && !test.id.startsWith('2015-2021')) return false;
      if (_subtopicEraFilter == '2005-2014' && !test.id.startsWith('2005-2014')) return false;
      if (_subtopicEraFilter == 'archive' && test.id.contains('-')) return false; // '1.1'..'3.4'

      // Category filter
      if (_subtopicCategoryFilter != 'ALL') {
        if (!test.category.toLowerCase().contains(_subtopicCategoryFilter.toLowerCase())) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return test.name.toLowerCase().contains(q) || test.category.toLowerCase().contains(q);
      }

      return true;
    }).toList();

    // Sort subtopics nicely
    subtopicTests.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        // Sub-filter row 1: Eras
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Eras',
                isSelected: _subtopicEraFilter == 'ALL',
                onSelected: () => setState(() => _subtopicEraFilter = 'ALL'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: 'CBT (2022–2026)',
                isSelected: _subtopicEraFilter == '2022-2026',
                onSelected: () => setState(() => _subtopicEraFilter = '2022-2026'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: 'Early CBT (2015–2021)',
                isSelected: _subtopicEraFilter == '2015-2021',
                onSelected: () => setState(() => _subtopicEraFilter = '2015-2021'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: 'Classic (2005–2014)',
                isSelected: _subtopicEraFilter == '2005-2014',
                onSelected: () => setState(() => _subtopicEraFilter = '2005-2014'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: '2005–2026 Archive',
                isSelected: _subtopicEraFilter == 'archive',
                onSelected: () => setState(() => _subtopicEraFilter = 'archive'),
              ),
            ],
          ),
        ),

        // Sub-filter row 2: Subjects
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              _buildCategoryChip('ALL', 'All Topics'),
              const SizedBox(width: 6),
              _buildCategoryChip('Real Analysis', 'Real Analysis'),
              const SizedBox(width: 6),
              _buildCategoryChip('Calculus', 'Calculus & ODE'),
              const SizedBox(width: 6),
              _buildCategoryChip('Algebra', 'Linear Algebra & Groups'),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search subtopic tests (e.g. Sequences, Differential, Groups)...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: subtopicTests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _buildTestCard(subtopicTests[idx]),
          ),
        ),
      ],
    );
  }

  // --- SECTION 3: CUSTOM TEST & PDF GENERATOR ---
  Widget _buildCustomGeneratorSection() {
    final pyqs = _allPyqs ?? [];

    final availableTopics = [
      'Sequences and Series of Real Numbers',
      'Functions of One Real Variable',
      'Functions of Two or Three Real Variables',
      'Integral Calculus',
      'Differential Equations',
      'Basic Algebra',
      'Linear Algebra',
      'Group Theory',
      'Out of Syllabus',
    ];

    final matching = pyqs.where((q) {
      if (_selectedCustomTopics.isNotEmpty && !_selectedCustomTopics.contains(q.subTopic)) {
        return false;
      }
      if (_customDifficulty != 'ALL' && q.defaultDifficulty != _customDifficulty) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.primaryGold.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🛠️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Text(
                      'Custom Mock Test Generator',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Select syllabus topics, adjust question count and difficulty, and launch a tailored CBT Exam with official timer and calculator.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Step 1: Select Topics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1. Select Topics',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCustomTopics.addAll(availableTopics);
                      });
                    },
                    child: const Text('Select All', style: TextStyle(fontSize: 11.5, color: AppColors.primaryGold)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCustomTopics.clear();
                      });
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ],
          ),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: availableTopics.map((topic) {
              final isSelected = _selectedCustomTopics.contains(topic);
              return FilterChip(
                label: Text(topic, style: const TextStyle(fontSize: 11.5)),
                selected: isSelected,
                selectedColor: AppColors.primaryGold.withValues(alpha: 0.25),
                checkmarkColor: AppColors.primaryGold,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedCustomTopics.add(topic);
                    } else {
                      _selectedCustomTopics.remove(topic);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Step 2: Question Count
          const Text(
            '2. Question Count',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [10, 20, 30, 45, 60].map((cnt) {
              final isSel = _customQuestionCount == cnt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$cnt Qs'),
                  selected: isSel,
                  selectedColor: AppColors.accentCyan,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _customQuestionCount = cnt),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Step 3: Difficulty
          const Text(
            '3. Target Difficulty',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _buildDiffChoice('ALL', 'All Tiers'),
              _buildDiffChoice('easy', 'Easy Drill'),
              _buildDiffChoice('medium', 'Medium'),
              _buildDiffChoice('hard', 'Hard & Challenging'),
            ],
          ),

          const SizedBox(height: 20),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Matching Pool:', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    Text(
                      '${matching.length} Available Questions',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Test Size: ${min(_customQuestionCount, matching.length)} Qs',
                    style: const TextStyle(color: AppColors.accentGreen, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Launch CBT Simulator'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: matching.isEmpty ? null : () => _launchCustomTest(isPractice: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: const Text('Practice Drill'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: matching.isEmpty ? null : () => _launchCustomTest(isPractice: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffChoice(String key, String label) {
    final isSel = _customDifficulty == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppColors.accentPurple,
      labelStyle: TextStyle(
        color: isSel ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 11.5,
      ),
      onSelected: (_) => setState(() => _customDifficulty = key),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryGold,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.black : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _subtopicCategoryFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _subtopicCategoryFilter = key),
      selectedColor: AppColors.accentCyan,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.black : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTestCard(MockTest test) {
    final isCbtEra = test.year >= 2015;
    final hasQuestions = test.questions.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCbtEra
                      ? AppColors.primaryGold.withValues(alpha: 0.15)
                      : AppColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCbtEra
                        ? AppColors.primaryGold.withValues(alpha: 0.3)
                        : AppColors.accentPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  test.category,
                  style: TextStyle(
                    color: isCbtEra ? AppColors.primaryGold : AppColors.accentPurple,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                hasQuestions ? '${test.totalQuestions} Questions' : '0 Questions (Not in Syllabus)',
                style: TextStyle(
                  fontSize: 11,
                  color: hasQuestions ? AppColors.textSecondary : AppColors.accentRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            test.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),

          const SizedBox(height: 4),

          Text(
            test.pattern.isNotEmpty
                ? test.pattern
                : '${test.totalMarks} Marks • ${test.durationMinutes} Minutes',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: Text(hasQuestions ? 'CBT Simulator' : '0 Questions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: hasQuestions ? AppColors.primaryGold : AppColors.surfaceElevated,
                    foregroundColor: hasQuestions ? Colors.black : AppColors.textMuted,
                  ),
                  onPressed: hasQuestions ? () => _startTest(test, isPractice: false) : () => _startTest(test, isPractice: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: const Text('Practice'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: hasQuestions ? AppColors.accentCyan : AppColors.textMuted,
                  ),
                  onPressed: hasQuestions ? () => _startTest(test, isPractice: true) : () => _startTest(test, isPractice: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
