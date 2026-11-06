class Question {
  final String id;
  final String year;
  final int qNum;
  final String type; // 'MCQ', 'MSQ', 'NAT'
  final num marks;
  final num negativeMarks;
  final String image;
  final String answerKey;
  final String explanation;

  const Question({
    required this.id,
    required this.year,
    required this.qNum,
    required this.type,
    required this.marks,
    required this.negativeMarks,
    required this.image,
    required this.answerKey,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      year: json['year'] as String? ?? '',
      qNum: json['q_num'] is int ? json['q_num'] as int : int.tryParse(json['q_num']?.toString() ?? '0') ?? 0,
      type: (json['type'] as String? ?? 'MCQ').toUpperCase(),
      marks: json['marks'] is num ? json['marks'] as num : num.tryParse(json['marks']?.toString() ?? '1') ?? 1,
      negativeMarks: json['negative_marks'] is num
          ? json['negative_marks'] as num
          : num.tryParse(json['negative_marks']?.toString() ?? '0') ?? 0,
      image: json['image'] as String? ?? '',
      answerKey: json['answer_key']?.toString() ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'year': year,
    'q_num': qNum,
    'type': type,
    'marks': marks,
    'negative_marks': negativeMarks,
    'image': image,
    'answer_key': answerKey,
    'explanation': explanation,
  };

  /// Check if user response matches answer key
  bool isAnswerCorrect(dynamic userResponse) {
    if (userResponse == null) return false;

    final key = answerKey.trim();

    if (type == 'MCQ') {
      return userResponse.toString().trim().toUpperCase() == key.toUpperCase();
    }

    if (type == 'MSQ') {
      List<String> userList = [];
      if (userResponse is List) {
        userList = userResponse.map((e) => e.toString().trim().toUpperCase()).toList()..sort();
      } else if (userResponse is String) {
        userList = userResponse.split(RegExp(r'[,;]')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList()..sort();
      }

      final keyList = key.split(RegExp(r'[,;]')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList()..sort();

      if (userList.length != keyList.length) return false;
      for (int i = 0; i < userList.length; i++) {
        if (userList[i] != keyList[i]) return false;
      }
      return true;
    }

    if (type == 'NAT') {
      final userVal = double.tryParse(userResponse.toString().trim());
      if (userVal == null) return false;

      // Check range e.g. "1.9 to 2.1" or "2.0 to 2.2"
      if (key.toLowerCase().contains('to')) {
        final parts = key.toLowerCase().split('to');
        if (parts.length == 2) {
          final low = double.tryParse(parts[0].trim());
          final high = double.tryParse(parts[1].trim());
          if (low != null && high != null) {
            return userVal >= (low - 1e-4) && userVal <= (high + 1e-4);
          }
        }
      }

      final keyVal = double.tryParse(key);
      if (keyVal != null) {
        return (userVal - keyVal).abs() < 0.01;
      }

      return userResponse.toString().trim() == key;
    }

    return false;
  }
}

