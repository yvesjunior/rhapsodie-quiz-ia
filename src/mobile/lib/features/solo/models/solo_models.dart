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
  final String cipherText; // Encrypted correct answer
  final String iv; // Initialization vector for decryption
  final String? plainAnswer; // Plain text answer (for non-encrypted fallback)
  final String? note; // Explanation
  final String? image;

  SoloQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.cipherText,
    required this.iv,
    this.plainAnswer,
    this.note,
    this.image,
  });

  factory SoloQuestion.fromJson(Map<String, dynamic> json) {
    // Handle encrypted answer (Map with ciphertext/iv) or plain string
    String cipherText = '';
    String iv = '';
    String? plainAnswer;
    
    final rawAnswer = json['answer'];
    if (rawAnswer is Map) {
      // Encrypted answer with ciphertext and iv
      cipherText = rawAnswer['ciphertext']?.toString() ?? '';
      iv = rawAnswer['iv']?.toString() ?? '';
    } else {
      // Plain string answer (fallback - for older API or testing)
      plainAnswer = rawAnswer?.toString();
    }
    
    return SoloQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      optionA: json['optiona']?.toString() ?? '',
      optionB: json['optionb']?.toString() ?? '',
      optionC: json['optionc']?.toString() ?? '',
      optionD: json['optiond']?.toString() ?? '',
      cipherText: cipherText,
      iv: iv,
      plainAnswer: plainAnswer,
      note: json['note']?.toString(),
      image: json['image']?.toString(),
    );
  }

  List<String> get options => [optionA, optionB, optionC, optionD];
  
  /// Check if answer is encrypted
  bool get isEncrypted => cipherText.isNotEmpty && iv.isNotEmpty;
}

/// User's answer for a question
class SoloAnswer {
  final String questionId;
  final String selectedAnswer; // Letter: 'a', 'b', 'c', 'd'
  final String selectedOptionText; // The actual option text
  final bool? isCorrect;

  SoloAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.selectedOptionText,
    this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'selected_option_text': selectedOptionText, // Send text for accurate comparison
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
    // Handle nested 'data' field if present (some APIs wrap response in data)
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    
    final topicJson = data['topic'] as Map<String, dynamic>? ?? {};
    
    // Handle detailed_results as both List and Map (PHP associative array)
    final resultsRaw = data['detailed_results'];
    List<dynamic> resultsJson;
    if (resultsRaw is List) {
      resultsJson = resultsRaw;
    } else if (resultsRaw is Map) {
      resultsJson = resultsRaw.values.toList();
    } else {
      resultsJson = [];
    }
    
    // Handle coin_eligible as boolean, int, or string
    final coinEligibleRaw = data['coin_eligible'];
    final coinEligible = coinEligibleRaw == true || 
                         coinEligibleRaw == 1 || 
                         coinEligibleRaw == '1';

    return SoloQuizResult(
      score: int.tryParse(data['score']?.toString() ?? '0') ?? 0,
      totalQuestions: int.tryParse(data['total_questions']?.toString() ?? '0') ?? 0,
      correctAnswers: int.tryParse(data['correct_answers']?.toString() ?? '0') ?? 0,
      wrongAnswers: int.tryParse(data['wrong_answers']?.toString() ?? '0') ?? 0,
      percentage: int.tryParse(data['percentage']?.toString() ?? '0') ?? 0,
      earnedCoin: int.tryParse(data['earned_coin']?.toString() ?? '0') ?? 0,
      coinEligible: coinEligible,
      timeTaken: int.tryParse(data['time_taken']?.toString() ?? '0') ?? 0,
      topic: SoloTopic(
        id: topicJson['id']?.toString() ?? '',
        slug: topicJson['slug']?.toString() ?? '',
        name: topicJson['name']?.toString() ?? '',
      ),
      detailedResults: resultsJson
          .map((r) => SoloDetailedResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      message: data['message']?.toString() ?? '',
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
    // Handle both boolean true and PHP's 1/0 or "1"/"0" for is_correct
    final isCorrectRaw = json['is_correct'];
    final isCorrect = isCorrectRaw == true || 
                      isCorrectRaw == 1 || 
                      isCorrectRaw == '1' ||
                      isCorrectRaw == 'true';
    
    return SoloDetailedResult(
      questionId: json['question_id']?.toString() ?? '',
      selectedAnswer: json['selected_answer']?.toString() ?? '',
      correctAnswer: json['correct_answer']?.toString() ?? '',
      isCorrect: isCorrect,
      question: json['question']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }
}

