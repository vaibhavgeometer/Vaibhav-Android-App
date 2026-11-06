import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DifficultyChip extends StatelessWidget {
  final String difficulty;
  final bool isCompact;

  const DifficultyChip({
    super.key,
    required this.difficulty,
    this.isCompact = false,
  });

  static Color getColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'very_easy':
        return AppColors.diffVeryEasy;
      case 'easy':
        return AppColors.diffEasy;
      case 'medium':
        return AppColors.diffMedium;
      case 'hard':
        return AppColors.diffHard;
      case 'hardest':
        return AppColors.diffHardest;
      default:
        return AppColors.diffMedium;
    }
  }

  static String getLabel(String diff) {
    switch (diff.toLowerCase()) {
      case 'very_easy':
        return 'Very Easy';
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      case 'hardest':
        return 'Hardest';
      default:
        return 'Medium';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor(difficulty);
    final label = getLabel(difficulty);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 9,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: isCompact ? 10.5 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

