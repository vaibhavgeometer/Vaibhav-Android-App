import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/pdf_helper.dart';
import '../../../core/theme/app_colors.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  // Target: Sunday, 14 Feb 2027 09:30 AM IST (04:00 UTC)
  final DateTime _targetDate = DateTime.utc(2027, 2, 14, 4, 0, 0);
  late Duration _remaining;
  Timer? _countdownTimer;

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

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final mins = _remaining.inMinutes % 60;
    final secs = _remaining.inSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Study Materials & Resource Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Padding(
              padding: EdgeInsets.only(bottom: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 Study Materials Hub',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comprehensive collection of official question banks, syllabus, 22-year project analytics article, and past year question paper archives.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),

            // Card 1: IIT JAM 2027 Live Countdown
            _buildCountdownCard(days, hours, mins, secs),

            const SizedBox(height: 14),

            // Card 2: 22-Year Project Statistics & Analytics Article
            _buildResourceCard(
              icon: '📊',
              title: 'Project Statistics & Analytics (2005–2026)',
              desc:
                  'Full comprehensive analytical report with empirical breakdown of all 885 questions, 22 examination years, topic weightages, era evolutions, cognitive difficulty distributions, and CBT ecosystem metrics.',
              badge: 'Comprehensive Report • 22 Yrs',
              badgeColor: AppColors.primaryGold,
              actionLabel: 'Read Report (PDF) →',
              onTap: () {
                HapticFeedback.lightImpact();
                PdfHelper.openAssetPdf(
                  'assets/IIT_JAM_MA_Project_Statistics_and_Analytics_Report.pdf',
                  'IIT_JAM_Project_Statistics_Analytics_Report.pdf',
                );
              },
            ),

            const SizedBox(height: 14),

            // Card 3: Official IIT JAM Syllabus
            _buildResourceCard(
              icon: '📜',
              title: 'Official IIT JAM Syllabus',
              desc:
                  'Official syllabus document detailing all topics across Real Analysis, Multivariable Calculus, Ordinary Differential Equations, Linear Algebra, and Group Theory.',
              badge: 'Official Document',
              badgeColor: AppColors.accentCyan,
              actionLabel: 'View Syllabus PDF →',
              onTap: () {
                HapticFeedback.lightImpact();
                PdfHelper.openAssetPdf('assets/Syllabus.pdf', 'IIT_JAM_Official_Syllabus.pdf');
              },
            ),

            const SizedBox(height: 14),

            // Card 4: 22-Year PYQ Archive (2005–2026 Original Papers)
            _buildResourceCard(
              icon: '🏛️',
              title: '22-Year PYQ Archive (2005–2026)',
              desc:
                  'Comprehensive historical archive of original IIT JAM Mathematics examination papers spanning 2005 through 2026 with master answer keys.',
              badge: '2005–2026 Complete Archive',
              badgeColor: AppColors.accentPurple,
              actionLabel: 'Open 22-Year Archive (PDF) →',
              onTap: () {
                HapticFeedback.lightImpact();
                PdfHelper.openAssetPdf(
                  'assets/MA2005-2026_Original_PYQs.pdf',
                  'IIT_JAM_MA_22_Year_PYQ_Archive.pdf',
                );
              },
            ),

            const SizedBox(height: 20),

            // Card 5: CUET-PG Mathematics Archive Section
            Container(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🎓', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUET-PG Mathematics Archive',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Official master question papers for CUET-PG Mathematics.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _buildCuetRow('CUET-PG 2026 Examination Paper', 'assets/CUET-PG/2026.pdf', 'CUET_PG_2026.pdf'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildCuetRow('CUET-PG 2025 Examination Paper', 'assets/CUET-PG/2025.pdf', 'CUET_PG_2025.pdf'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildCuetRow('CUET-PG 2024 Examination Paper', 'assets/CUET-PG/2024.pdf', 'CUET_PG_2024.pdf'),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCard(int days, int hours, int mins, int secs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.accentCyan.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('⏳', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'IIT JAM 2027 Live Countdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Live Timer',
                  style: TextStyle(color: AppColors.accentCyan, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Target Exam: Sunday, 14 February 2027 (09:30 AM IST)',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Countdown Blocks
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
    );
  }

  Widget _buildResourceCard({
    required String icon,
    required String title,
    required String desc,
    required String badge,
    required Color badgeColor,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: Text(actionLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
                side: const BorderSide(color: AppColors.primaryGold),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuetRow(String title, String assetPath, String exportName) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        PdfHelper.openAssetPdf(assetPath, exportName);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.accentCyan, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
            const Text(
              'PDF →',
              style: TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBox(String value, String label) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
