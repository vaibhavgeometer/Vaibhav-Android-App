import 'question.dart';

class MockTest {
  final String id;
  final String fileId;
  final int year;
  final String name;
  final String category;
  final String era; // 'classic', 'cbt', 'topic'
  final int totalQuestions;
  final num totalMarks;
  final int durationMinutes;
  final String pattern;
  final String paperPdf;
  final List<Question> questions;

  const MockTest({
    required this.id,
    required this.fileId,
    required this.year,
    required this.name,
    required this.category,
    required this.era,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    required this.pattern,
    required this.paperPdf,
    required this.questions,
  });

  factory MockTest.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    final questionsList = rawQuestions
        .whereType<Map<String, dynamic>>()
        .map((q) => Question.fromJson(q))
        .toList();

    return MockTest(
      id: json['id']?.toString() ?? '',
      fileId: json['file_id']?.toString() ?? '',
      year: json['year'] is int ? json['year'] as int : int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      era: json['era']?.toString() ?? 'cbt',
      totalQuestions: json['total_questions'] is int
          ? json['total_questions'] as int
          : questionsList.length,
      totalMarks: json['total_marks'] is num
          ? json['total_marks'] as num
          : num.tryParse(json['total_marks']?.toString() ?? '100') ?? 100,
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse(json['duration_minutes']?.toString() ?? '180') ?? 180,
      pattern: json['pattern']?.toString() ?? '',
      paperPdf: json['paper_pdf']?.toString() ?? '',
      questions: questionsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_id': fileId,
    'year': year,
    'name': name,
    'category': category,
    'era': era,
    'total_questions': totalQuestions,
    'total_marks': totalMarks,
    'duration_minutes': durationMinutes,
    'pattern': pattern,
    'paper_pdf': paperPdf,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}

