import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/mock_test.dart';
import '../../../core/models/question.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/pdf_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../simulator/cbt_exam_screen.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  // IIT JAM 2027 Target: Feb 14, 2027 09:30 AM IST
  final DateTime _targetDate = DateTime.utc(2027, 2, 14, 4, 0, 0); // 04:00 UTC = 09:30 IST
  late Duration _remaining;
  Timer? _countdownTimer;

  final List<Map<String, String>> _cheatSheets = const [
    {
      'title': 'Linear Algebra Master Sheet',
      'sub': 'Matrices, Rank, Eigenvalues, Cayley-Hamilton',
      'path': 'assets/cheat-sheets/Linear_Algebra_Master_Cheat_Sheet.pdf',
    },
    {
      'title': 'Vector Spaces & Transformations',
      'sub': 'Basis, Dimension, Linear Transformations',
      'path': 'assets/cheat-sheets/Linear_Algebra_Vector_Spaces_Cheat_Sheet.pdf',
    },
    {
      'title': 'Sequences of Real Numbers',
      'sub': 'Convergence, Monotone, Subsequences, Bolzano',
      'path': 'assets/cheat-sheets/Sequence_of_Real_Numbers_Cheat_Sheet.pdf',
    },
    {
      'title': 'Series of Real Numbers',
      'sub': 'Series Convergence, Absolute & Conditional',
      'path': 'assets/cheat-sheets/Series_of_Real_Numbers_Cheat_Sheet.pdf',
    },
    {
      'title': 'Series Convergence Tests',
      'sub': 'Ratio, Root, Raabe, Gauss, Leibniz Tests',
      'path': 'assets/cheat-sheets/Series_Convergence_Tests_Cheat_Sheet.pdf',
    },
    {
      'title': 'Continuity & Differentiability',
      'sub': 'Mean Value Theorems, Taylor Series, L’Hôpital',
      'path': 'assets/cheat-sheets/Continuity_and_Differentiability_Cheat_Sheet.pdf',
    },
    {
      'title': 'Riemann Integration',
      'sub': 'Partitions, Upper/Lower Sums, Fundamental Theorem',
      'path': 'assets/cheat-sheets/Riemann_Integration_Cheat_Sheet.pdf',
    },
    {
      'title': 'Functions of Several Variables',
      'sub': 'Limits, Partial Derivatives, Directional, Extrema',
      'path': 'assets/cheat-sheets/Functions_of_Several_Variables_Cheat_Sheet.pdf',
    },
    {
      'title': 'Multivariable & Power Series',
      'sub': 'Jacobians, Radius of Convergence, Taylor in 2 Vars',
      'path': 'assets/cheat-sheets/Multivariable_and_Power_Series_Supplemental.pdf',
    },
    {
      'title': 'Differential Equations Master Sheet',
      'sub': 'Exact, Integrating Factors, Wronskian, Higher Order',
      'path': 'assets/cheat-sheets/Differential_Equations_Cheat_Sheet.pdf',
    },
    {
      'title': 'Integral Calculus Sheet',
      'sub': 'Double/Triple Integrals, Surface, Green, Stokes, Gauss',
      'path': 'assets/cheat-sheets/Integral_Calculus_Cheat_Sheet.pdf',
    },
    {
      'title': 'Group Theory Master Sheet',
      'sub': 'Subgroups, Cyclic Groups, Lagrange, Permutations',
      'path': 'assets/cheat-sheets/Group_Theory_Master_Cheat_Sheet.pdf',
    },
    {
      'title': 'Group Theory Summary',
      'sub': 'Normal Subgroups, Homomorphisms, Sylow, Isomorphisms',
      'path': 'assets/cheat-sheets/Group_Theory_Summary.pdf',
    },
    {
      'title': 'Basic Algebra Sheet',
      'sub': 'Polynomials, Complex Numbers, Basic Ring Concepts',
      'path': 'assets/cheat-sheets/Basic_Algebra_Cheat_Sheet.pdf',
    },
  ];

  @override
  void initState() {
    super.initState();
    _remaining = _targetDate.difference(DateTime.now().toUtc());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _targetDate.difference(DateTime.now().toUtc());
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _openCustomTestGenerator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CustomTestModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final mins = _remaining.inMinutes % 60;
    final secs = _remaining.inSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Study Materials & Archive'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // JAM 2027 Countdown Widget
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.accentCyan.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('⏳', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'IIT JAM 2027 Examination Countdown',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Target: Sunday, 14 February 2027 (09:30 AM IST)',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Timer Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimerBox('$days', 'DAYS'),
                      _buildTimerBox('$hours', 'HOURS'),
                      _buildTimerBox('$mins', 'MINS'),
                      _buildTimerBox('$secs', 'SECS'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Custom Test Generator Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🛠️', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Custom Test Generator',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Select your favorite topics & question counts to generate tailored mock tests.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Generate Custom Test', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: _openCustomTestGenerator,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // CUET-PG Mathematics Archive Section
            const Text(
              'CUET-PG Mathematics Archive',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Official Central Universities Entrance Test Postgraduate master papers.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildCuetCard('CUET-PG 2026', 'assets/CUET-PG/2026.pdf', 'CUET_PG_2026.pdf'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCuetCard('CUET-PG 2025', 'assets/CUET-PG/2025.pdf', 'CUET_PG_2025.pdf'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCuetCard('CUET-PG 2024', 'assets/CUET-PG/2024.pdf', 'CUET_PG_2024.pdf'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Official Syllabus Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Text('📜', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official IIT JAM MA Syllabus',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Comprehensive syllabus including core topics & guidelines.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      PdfHelper.openAssetPdf('assets/Syllabus.pdf', 'IIT_JAM_MA_Syllabus.pdf');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('View PDF', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formula Cheat Sheets Section (14 sheets)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '14 Formula Cheat Sheets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '${_cheatSheets.length} Sheets',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cheatSheets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, idx) {
                final sheet = _cheatSheets[idx];
                final fileName = sheet['path']!.split('/').last;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: const Text('📑', style: TextStyle(fontSize: 22)),
                    title: Text(
                      sheet['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      sheet['sub']!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentCyan, size: 20),
                      tooltip: 'Open PDF',
                      onPressed: () {
                        PdfHelper.openAssetPdf(sheet['path']!, fileName);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBox(String value, String label) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCuetCard(String title, String path, String fileName) {
    return InkWell(
      onTap: () {
        PdfHelper.openAssetPdf(path, fileName);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf, color: AppColors.accentPurple, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            const Text('Download', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CustomTestModal extends StatefulWidget {
  const _CustomTestModal();

  @override
  State<_CustomTestModal> createState() => _CustomTestModalState();
}

class _CustomTestModalState extends State<_CustomTestModal> {
  final Set<String> _selectedTopics = {
    'Real Analysis',
    'Multivariable Calculus and Differential Equations',
    'Linear Algebra and Algebra',
  };
  int _questionCount = 30;
  int _durationMinutes = 90;
  bool _isGenerating = false;

  final List<String> _availableTopics = const [
    'Real Analysis',
    'Multivariable Calculus and Differential Equations',
    'Linear Algebra and Algebra',
  ];

  Future<void> _generateAndStart() async {
    setState(() => _isGenerating = true);
    final allTests = await DataService.instance.loadMockTests();

    // Pool questions from year tests matching selected topics
    final candidateQuestions = <Question>[];
    for (final test in allTests.values) {
      if (test.year >= 2015) {
        for (final q in test.questions) {
          candidateQuestions.add(q);
        }
      }
    }

    candidateQuestions.shuffle();
    final chosen = candidateQuestions.take(_questionCount).toList();

    final customTest = MockTest(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      fileId: 'JAM_CUSTOM',
      year: 0,
      name: 'Custom Mock Test ($_questionCount Questions)',
      category: 'Custom Test',
      era: 'custom',
      totalQuestions: chosen.length,
      totalMarks: chosen.fold<num>(0, (sum, q) => sum + q.marks),
      durationMinutes: _durationMinutes,
      pattern: 'Custom Generated Exam',
      paperPdf: '',
      questions: chosen,
    );

    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CbtExamScreen(test: customTest),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Custom Mock Test',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Select Topics:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableTopics.map((top) {
              final isSel = _selectedTopics.contains(top);
              return FilterChip(
                label: Text(top, style: const TextStyle(fontSize: 11)),
                selected: isSel,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedTopics.add(top);
                    } else if (_selectedTopics.length > 1) {
                      _selectedTopics.remove(top);
                    }
                  });
                },
                selectedColor: AppColors.primaryGold,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          const Text('Number of Questions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [15, 30, 45, 60].map((count) {
              final isSel = _questionCount == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$count Qs', style: const TextStyle(fontSize: 12)),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _questionCount = count;
                          _durationMinutes = count * 3;
                        });
                      }
                    },
                    selectedColor: AppColors.primaryGold,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          Text('Duration: $_durationMinutes Minutes', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.flash_on, size: 18),
              label: const Text('Start Custom Test Now'),
              onPressed: _isGenerating ? null : _generateAndStart,
            ),
          ),
        ],
      ),
    );
  }
}

