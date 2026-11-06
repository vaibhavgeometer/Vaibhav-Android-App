import 'question.dart';

class TestResult {
  final String testId;
  final String testName;
  final num totalScore;
  final num maxScore;
  final int totalQuestions;
  final int attempted;
  final int correct;
  final int incorrect;
  final int unattempted;
  final int timeSpentSeconds;
  final DateTime completedAt;
  final Map<int, dynamic> responses;
  final List<QuestionReviewItem> reviewItems;

  const TestResult({
    required this.testId,
    required this.testName,
    required this.totalScore,
    required this.maxScore,
    required this.totalQuestions,
    required this.attempted,
    required this.correct,
    required this.incorrect,
    required this.unattempted,
    required this.timeSpentSeconds,
    required this.completedAt,
    required this.responses,
    required this.reviewItems,
  });

  double get accuracyPercent => attempted == 0 ? 0.0 : ((correct / attempted) * 100);
  double get scorePercent => maxScore == 0 ? 0.0 : ((totalScore / maxScore) * 100);
}

class QuestionReviewItem {
  final int index;
  final Question question;
  final dynamic userResponse;
  final bool isAttempted;
  final bool isCorrect;
  final num marksAwarded;

  const QuestionReviewItem({
    required this.index,
    required this.question,
    required this.userResponse,
    required this.isAttempted,
    required this.isCorrect,
    required this.marksAwarded,
  });
}

