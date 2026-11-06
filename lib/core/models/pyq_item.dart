class PyqItem {
  final int year;
  final int questionNumber;
  final String answer;
  final String topic;
  final String subTopic;
  
  // Computed or state fields
  String get id => 'JAM_${year}_Q$questionNumber';
  String get imagePath => 'assets/PYQs_Screenshots/$year/JAM_${year}_Q$questionNumber.png';
  bool get isOutOfSyllabus => topic == 'Out of Syllabus' || subTopic == 'Out of Syllabus';

  String get type {
    if (year >= 2015) {
      if (questionNumber <= 30) return 'MCQ';
      if (questionNumber <= 40) return 'MSQ';
      return 'NAT';
    }
    return 'MCQ';
  }

  int get marks {
    if (year >= 2015) {
      if (questionNumber <= 10) return 1;
      if (questionNumber <= 30) return 2;
      if (questionNumber <= 40) return 2;
      if (questionNumber <= 50) return 1;
      return 2;
    }
    return 6;
  }

  const PyqItem({
    required this.year,
    required this.questionNumber,
    required this.answer,
    required this.topic,
    required this.subTopic,
  });

  factory PyqItem.fromJson(Map<String, dynamic> json) {
    return PyqItem(
      year: json['year'] as int? ?? 0,
      questionNumber: json['question_number'] as int? ?? 0,
      answer: json['answer']?.toString() ?? '',
      topic: json['topic']?.toString() ?? 'General',
      subTopic: json['sub_topic']?.toString() ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
    'year': year,
    'question_number': questionNumber,
    'answer': answer,
    'topic': topic,
    'sub_topic': subTopic,
  };

  /// Infer default difficulty according to official pattern
  String get defaultDifficulty {
    if (year >= 2015 && questionNumber >= 1 && questionNumber <= 60) {
      if (questionNumber <= 5) return 'very_easy';
      if (questionNumber <= 10) return 'easy';
      if (questionNumber <= 20) return 'medium';
      if (questionNumber <= 30) return 'hard';
      if (questionNumber <= 35) return 'hard';
      if (questionNumber <= 40) return 'hardest'; // MSQ
      if (questionNumber <= 45) return 'easy';
      if (questionNumber <= 50) return 'medium';
      if (questionNumber <= 55) return 'hard';
      return 'hardest';
    }
    if (questionNumber % 3 == 0) return 'hard';
    if (questionNumber % 2 == 0) return 'medium';
    return 'easy';
  }
}

class QuestionProgress {
  final bool solved;
  final String difficulty; // 'very_easy', 'easy', 'medium', 'hard', 'hardest'
  final bool unnecessary;
  final String notes;
  final String? solvedDate; // YYYY-MM-DD

  const QuestionProgress({
    this.solved = false,
    this.difficulty = 'medium',
    this.unnecessary = false,
    this.notes = '',
    this.solvedDate,
  });

  factory QuestionProgress.fromJson(Map<String, dynamic> json) {
    return QuestionProgress(
      solved: json['solved'] as bool? ?? false,
      difficulty: json['difficulty']?.toString() ?? 'medium',
      unnecessary: json['unnecessary'] as bool? ?? false,
      notes: json['notes']?.toString() ?? '',
      solvedDate: json['solvedDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'solved': solved,
    'difficulty': difficulty,
    'unnecessary': unnecessary,
    'notes': notes,
    'solvedDate': solvedDate,
  };

  QuestionProgress copyWith({
    bool? solved,
    String? difficulty,
    bool? unnecessary,
    String? notes,
    String? solvedDate,
  }) {
    return QuestionProgress(
      solved: solved ?? this.solved,
      difficulty: difficulty ?? this.difficulty,
      unnecessary: unnecessary ?? this.unnecessary,
      notes: notes ?? this.notes,
      solvedDate: solvedDate ?? this.solvedDate,
    );
  }
}

