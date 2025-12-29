/// Solo Mode Topic Model
class SoloTopic {
  final String id;
  final String slug;
  final String name;
  final String description;
  final String image;
  final String topicType;
  final int questionsCount;
  final bool hasEnoughQuestions;

  SoloTopic({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    this.image = '',
    this.topicType = 'general',
    this.questionsCount = 0,
    this.hasEnoughQuestions = false,
  });

  factory SoloTopic.fromJson(Map<String, dynamic> json) {
    return SoloTopic(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      topicType: json['topic_type']?.toString() ?? 'general',
      questionsCount: int.tryParse(json['questions_count']?.toString() ?? '0') ?? 0,
      hasEnoughQuestions: json['has_enough_questions'] == true || 
                          json['has_enough_questions'] == 1 ||
                          json['has_enough_questions'] == '1',
    );
  }
}

/// Solo Quiz Configuration
class SoloQuizConfig {
  final SoloTopic topic;
  final int questionCount;
  final int timePerQuestion; // in seconds

  SoloQuizConfig({
    required this.topic,
    this.questionCount = 10,
    this.timePerQuestion = 15,
  });

  SoloQuizConfig copyWith({
    SoloTopic? topic,
    int? questionCount,
    int? timePerQuestion,
  }) {
    return SoloQuizConfig(
      topic: topic ?? this.topic,
      questionCount: questionCount ?? this.questionCount,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
    );
  }
}

/// Solo Question Model
class SoloQuestion {
  final String id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final SoloCorrectAnswer correctAnswer;
  final String? note; // Explanation
  final String? image;

  SoloQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.note,
    this.image,
  });

  factory SoloQuestion.fromJson(Map<String, dynamic> json) {
    // Handle encrypted answer (Map with ciphertext/iv) or plain string
    SoloCorrectAnswer answer;
    final rawAnswer = json['answer'];
    if (rawAnswer is Map) {
      // Encrypted answer with ciphertext and iv
      answer = SoloCorrectAnswer.fromJson(Map<String, dynamic>.from(rawAnswer));
    } else {
      // Plain string answer (fallback)
      answer = SoloCorrectAnswer(cipherText: '', iv: '', plainAnswer: rawAnswer?.toString() ?? '');
    }
    
    return SoloQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      optionA: json['optiona']?.toString() ?? '',
      optionB: json['optionb']?.toString() ?? '',
      optionC: json['optionc']?.toString() ?? '',
      optionD: json['optiond']?.toString() ?? '',
      correctAnswer: answer,
      note: json['note']?.toString(),
      image: json['image']?.toString(),
    );
  }

  List<String> get options => [optionA, optionB, optionC, optionD];
}

/// Encrypted correct answer for Solo Mode
class SoloCorrectAnswer {
  final String cipherText;
  final String iv;
  final String? plainAnswer; // For fallback if not encrypted

  const SoloCorrectAnswer({
    required this.cipherText,
    required this.iv,
    this.plainAnswer,
  });

  factory SoloCorrectAnswer.fromJson(Map<String, dynamic> json) {
    return SoloCorrectAnswer(
      cipherText: json['ciphertext']?.toString() ?? '',
      iv: json['iv']?.toString() ?? '',
    );
  }
}

/// User's answer for a question
class SoloAnswer {
  final String questionId;
  final String selectedAnswer;
  final bool? isCorrect;

  SoloAnswer({
    required this.questionId,
    required this.selectedAnswer,
    this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_answer': selectedAnswer,
    };
  }
}

/// Solo Quiz Result Model
class SoloQuizResult {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int percentage;
  final int earnedCoin;
  final bool coinEligible;
  final int timeTaken;
  final SoloTopic topic;
  final List<SoloDetailedResult> detailedResults;
  final String message;

  SoloQuizResult({
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.earnedCoin,
    required this.coinEligible,
    required this.timeTaken,
    required this.topic,
    required this.detailedResults,
    required this.message,
  });

  factory SoloQuizResult.fromJson(Map<String, dynamic> json) {
    final topicJson = json['topic'] as Map<String, dynamic>? ?? {};
    final resultsJson = json['detailed_results'] as List<dynamic>? ?? [];

    return SoloQuizResult(
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      totalQuestions: int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      correctAnswers: int.tryParse(json['correct_answers']?.toString() ?? '0') ?? 0,
      wrongAnswers: int.tryParse(json['wrong_answers']?.toString() ?? '0') ?? 0,
      percentage: int.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
      earnedCoin: int.tryParse(json['earned_coin']?.toString() ?? '0') ?? 0,
      coinEligible: json['coin_eligible'] == true,
      timeTaken: int.tryParse(json['time_taken']?.toString() ?? '0') ?? 0,
      topic: SoloTopic(
        id: topicJson['id']?.toString() ?? '',
        slug: topicJson['slug'] as String? ?? '',
        name: topicJson['name'] as String? ?? '',
      ),
      detailedResults: resultsJson
          .map((r) => SoloDetailedResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }

  bool get isPerfect => percentage == 100;
}

/// Detailed result for each question
class SoloDetailedResult {
  final String questionId;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String question;
  final String? note;

  SoloDetailedResult({
    required this.questionId,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.question,
    this.note,
  });

  factory SoloDetailedResult.fromJson(Map<String, dynamic> json) {
    return SoloDetailedResult(
      questionId: json['question_id']?.toString() ?? '',
      selectedAnswer: json['selected_answer'] as String? ?? '',
      correctAnswer: json['correct_answer'] as String? ?? '',
      isCorrect: json['is_correct'] == true,
      question: json['question'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

