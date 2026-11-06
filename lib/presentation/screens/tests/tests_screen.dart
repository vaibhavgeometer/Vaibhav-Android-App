import 'package:flutter/material.dart';
import '../../../core/models/mock_test.dart';
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
  String _selectedTab = 'ALL'; // 'ALL', 'cbt', 'classic', 'subtopics'
  String _searchQuery = '';
  Map<String, MockTest>? _allTests;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tests = await DataService.instance.loadMockTests();
    if (mounted) {
      setState(() {
        _allTests = tests;
        _isLoading = false;
      });
    }
  }

  void _startTest(MockTest test, {required bool isPractice}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CbtExamScreen(test: test, isPracticeMode: isPractice),
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

    final testsMap = _allTests ?? {};
    final testList = testsMap.values.where((test) {
      if (_selectedTab == 'cbt') {
        if (test.era != 'cbt' || test.year < 2015) return false;
      } else if (_selectedTab == 'classic') {
        if (test.year >= 2015 || test.year == 0) return false;
      } else if (_selectedTab == 'subtopics') {
        if (test.year > 0) return false; // Non-year based are subtopics
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return test.name.toLowerCase().contains(q) ||
            test.category.toLowerCase().contains(q) ||
            test.year.toString().contains(q);
      }
      return true;
    }).toList();

    // Sort: recent years first, then subtopics
    testList.sort((a, b) {
      if (a.year > 0 && b.year > 0) {
        return b.year.compareTo(a.year);
      }
      return a.name.compareTo(b.name);
    });

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
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _buildTabChip('ALL', 'All 22 Years (2005–2026)'),
                const SizedBox(width: 8),
                _buildTabChip('cbt', 'CBT Era (2015–2026)'),
                const SizedBox(width: 8),
                _buildTabChip('classic', 'Classic Era (2005–2014)'),
                const SizedBox(width: 8),
                _buildTabChip('subtopics', 'Subtopic Tests (27 Suites)'),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search mock tests (e.g. 2026, Linear Algebra, 2018)...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),

          // Tests List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: testList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final test = testList[idx];
                return _buildTestCard(test);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String key, String label) {
    final isSelected = _selectedTab == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTab = key;
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

  Widget _buildTestCard(MockTest test) {
    final isCbtEra = test.year >= 2015;

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
                '${test.totalQuestions} Questions',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
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
                  label: const Text('CBT Simulator'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _startTest(test, isPractice: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: const Text('Practice'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _startTest(test, isPractice: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

