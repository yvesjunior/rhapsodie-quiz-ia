import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/correct_answer.dart';
import 'package:flutterquiz/features/solo/models/solo_models.dart';
import 'package:flutterquiz/features/solo/solo_remote_data_source.dart';
import 'package:flutterquiz/utils/answer_encryption.dart';

// ============================================
// States
// ============================================

sealed class SoloModeState {
  const SoloModeState();
}

final class SoloModeInitial extends SoloModeState {
  const SoloModeInitial();
}

final class SoloModeLoading extends SoloModeState {
  const SoloModeLoading();
}

final class SoloModeTopicsLoaded extends SoloModeState {
  final List<SoloTopic> topics;
  
  const SoloModeTopicsLoaded(this.topics);
}

final class SoloModeConfiguring extends SoloModeState {
  final SoloTopic selectedTopic;
  final int questionCount;
  final int timePerQuestion;
  
  const SoloModeConfiguring({
    required this.selectedTopic,
    this.questionCount = 10,
    this.timePerQuestion = 15,
  });

  SoloModeConfiguring copyWith({
    SoloTopic? selectedTopic,
    int? questionCount,
    int? timePerQuestion,
  }) {
    return SoloModeConfiguring(
      selectedTopic: selectedTopic ?? this.selectedTopic,
      questionCount: questionCount ?? this.questionCount,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
    );
  }
}

final class SoloModeQuestionsLoading extends SoloModeState {
  const SoloModeQuestionsLoading();
}

final class SoloModeReady extends SoloModeState {
  final SoloTopic topic;
  final List<SoloQuestion> questions;
  final int timePerQuestion;
  
  const SoloModeReady({
    required this.topic,
    required this.questions,
    required this.timePerQuestion,
  });
}

/// Lifeline status for tracking usage
enum LifelineStatus { unused, using, used }

final class SoloModePlaying extends SoloModeState {
  final SoloTopic topic;
  final List<SoloQuestion> questions;
  final int currentQuestionIndex;
  final int timeRemaining;
  final int timePerQuestion;
  final List<SoloAnswer> answers;
  final int startTimeMs;
  
  // Answer feedback
  final String? selectedAnswerId; // Currently selected answer (for showing feedback)
  final bool showingFeedback; // True when showing correct/wrong feedback
  
  // Lifelines
  final LifelineStatus fiftyFiftyStatus;
  final LifelineStatus audiencePollStatus;
  final LifelineStatus resetTimeStatus;
  final List<String> hiddenOptions; // Options hidden by 50/50
  final List<int> audiencePollPercentages; // Poll percentages for each option
  
  const SoloModePlaying({
    required this.topic,
    required this.questions,
    required this.currentQuestionIndex,
    required this.timeRemaining,
    required this.timePerQuestion,
    required this.answers,
    required this.startTimeMs,
    this.selectedAnswerId,
    this.showingFeedback = false,
    this.fiftyFiftyStatus = LifelineStatus.unused,
    this.audiencePollStatus = LifelineStatus.unused,
    this.resetTimeStatus = LifelineStatus.unused,
    this.hiddenOptions = const [],
    this.audiencePollPercentages = const [],
  });

  SoloQuestion get currentQuestion => questions[currentQuestionIndex];
  int get totalQuestions => questions.length;
  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;
  
  SoloModePlaying copyWith({
    int? currentQuestionIndex,
    int? timeRemaining,
    List<SoloAnswer>? answers,
    String? selectedAnswerId,
    bool? showingFeedback,
    LifelineStatus? fiftyFiftyStatus,
    LifelineStatus? audiencePollStatus,
    LifelineStatus? resetTimeStatus,
    List<String>? hiddenOptions,
    List<int>? audiencePollPercentages,
  }) {
    return SoloModePlaying(
      topic: topic,
      questions: questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      timePerQuestion: timePerQuestion,
      answers: answers ?? this.answers,
      startTimeMs: startTimeMs,
      selectedAnswerId: selectedAnswerId,
      showingFeedback: showingFeedback ?? this.showingFeedback,
      fiftyFiftyStatus: fiftyFiftyStatus ?? this.fiftyFiftyStatus,
      audiencePollStatus: audiencePollStatus ?? this.audiencePollStatus,
      resetTimeStatus: resetTimeStatus ?? this.resetTimeStatus,
      hiddenOptions: hiddenOptions ?? this.hiddenOptions,
      audiencePollPercentages: audiencePollPercentages ?? this.audiencePollPercentages,
    );
  }
}

final class SoloModeSubmitting extends SoloModeState {
  const SoloModeSubmitting();
}

final class SoloModeCompleted extends SoloModeState {
  final SoloQuizResult result;
  
  const SoloModeCompleted(this.result);
}

final class SoloModeError extends SoloModeState {
  final String message;
  
  const SoloModeError(this.message);
}

// ============================================
// Cubit
// ============================================

class SoloModeCubit extends Cubit<SoloModeState> {
  final SoloRemoteDataSource _dataSource;
  final String firebaseUserId;
  Timer? _timer;
  
  SoloModeCubit({
    required this.firebaseUserId,
    SoloRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? SoloRemoteDataSource(),
       super(const SoloModeInitial());
  
  /// Decrypt the correct answer for a question
  String getDecryptedAnswer(SoloQuestion question) {
    if (question.isEncrypted) {
      return AnswerEncryption.decryptCorrectAnswer(
        rawKey: firebaseUserId,
        correctAnswer: CorrectAnswer(
          cipherText: question.cipherText,
          iv: question.iv,
        ),
      ).toLowerCase();
    } else {
      return (question.plainAnswer ?? '').toLowerCase();
    }
  }

  /// Load available topics for Solo Mode
  Future<void> loadTopics() async {
    emit(const SoloModeLoading());
    try {
      final topics = await _dataSource.getSoloTopics();
      emit(SoloModeTopicsLoaded(topics));
    } catch (e) {
      emit(SoloModeError(e.toString()));
    }
  }

  /// Select a topic and move to configuration
  void selectTopic(SoloTopic topic) {
    emit(SoloModeConfiguring(selectedTopic: topic));
  }

  /// Update question count
  void setQuestionCount(int count) {
    final currentState = state;
    if (currentState is SoloModeConfiguring) {
      emit(currentState.copyWith(questionCount: count));
    }
  }

  /// Update time per question
  void setTimePerQuestion(int seconds) {
    final currentState = state;
    if (currentState is SoloModeConfiguring) {
      emit(currentState.copyWith(timePerQuestion: seconds));
    }
  }

  /// Fetch random questions and start the quiz immediately
  Future<void> startQuiz() async {
    final currentState = state;
    if (currentState is! SoloModeConfiguring) return;

    emit(const SoloModeQuestionsLoading());
    
    try {
      final questions = await _dataSource.getRandomQuestions(
        topicSlug: currentState.selectedTopic.slug,
        count: currentState.questionCount,
      );

      if (questions.isEmpty) {
        emit(const SoloModeError('No questions available for this topic'));
        return;
      }

      // Skip "Ready" screen - go directly to playing
      emit(SoloModePlaying(
        topic: currentState.selectedTopic,
        questions: questions,
        currentQuestionIndex: 0,
        timeRemaining: currentState.timePerQuestion,
        timePerQuestion: currentState.timePerQuestion,
        answers: [],
        startTimeMs: DateTime.now().millisecondsSinceEpoch,
      ));

      _startTimer();
    } catch (e) {
      emit(SoloModeError(e.toString()));
    }
  }

  /// Start the countdown timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentState = state;
      if (currentState is SoloModePlaying) {
        if (currentState.timeRemaining > 0) {
          emit(currentState.copyWith(
            timeRemaining: currentState.timeRemaining - 1,
          ));
        } else {
          // Time's up - auto-skip
          _handleTimeUp();
        }
      }
    });
  }

  /// Handle time up - skip question
  void _handleTimeUp() {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;

    // Add empty answer for skipped question (timeout)
    final newAnswers = List<SoloAnswer>.from(currentState.answers)
      ..add(SoloAnswer(
        questionId: currentState.currentQuestion.id,
        selectedAnswer: '', // No answer
        selectedOptionText: '', // No option selected
      ));

    if (currentState.isLastQuestion) {
      _submitQuiz(newAnswers);
    } else {
      emit(currentState.copyWith(
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
        timeRemaining: currentState.timePerQuestion,
        answers: newAnswers,
      ));
    }
  }

  /// Answer the current question with feedback
  Future<void> answerQuestion(String answer) async {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;
    if (currentState.showingFeedback) return; // Already showing feedback

    _timer?.cancel();

    // Show feedback first
    emit(currentState.copyWith(
      selectedAnswerId: answer,
      showingFeedback: true,
    ));

    // Wait for feedback display (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if still in the same state (not cancelled)
    final afterDelay = state;
    if (afterDelay is! SoloModePlaying || !afterDelay.showingFeedback) return;

    // Get the selected option text for accurate server validation
    final question = afterDelay.currentQuestion;
    final optionTextMap = {
      'a': question.optionA,
      'b': question.optionB,
      'c': question.optionC,
      'd': question.optionD,
    };
    final selectedOptionText = optionTextMap[answer.toLowerCase()] ?? '';

    // Add answer
    final newAnswers = List<SoloAnswer>.from(afterDelay.answers)
      ..add(SoloAnswer(
        questionId: question.id,
        selectedAnswer: answer,
        selectedOptionText: selectedOptionText,
      ));

    if (afterDelay.isLastQuestion) {
      _submitQuiz(newAnswers);
    } else {
      // Move to next question - reset lifeline effects but keep used status
      emit(SoloModePlaying(
        topic: afterDelay.topic,
        questions: afterDelay.questions,
        currentQuestionIndex: afterDelay.currentQuestionIndex + 1,
        timeRemaining: afterDelay.timePerQuestion,
        timePerQuestion: afterDelay.timePerQuestion,
        answers: newAnswers,
        startTimeMs: afterDelay.startTimeMs,
        selectedAnswerId: null, // Reset for new question
        showingFeedback: false,
        fiftyFiftyStatus: afterDelay.fiftyFiftyStatus,
        audiencePollStatus: afterDelay.audiencePollStatus,
        resetTimeStatus: afterDelay.resetTimeStatus,
        hiddenOptions: const [], // Reset for new question
        audiencePollPercentages: const [], // Reset for new question
      ));
      _startTimer();
    }
  }

  /// Submit the quiz to the server
  Future<void> _submitQuiz(List<SoloAnswer> answers) async {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;

    _timer?.cancel();

    final timeTaken = DateTime.now().millisecondsSinceEpoch - currentState.startTimeMs;

    emit(const SoloModeSubmitting());

    try {
      final result = await _dataSource.submitSoloQuiz(
        topicSlug: currentState.topic.slug,
        questionCount: currentState.questions.length,
        answers: answers,
        timeTaken: timeTaken,
      );

      emit(SoloModeCompleted(result));
    } catch (e) {
      emit(SoloModeError(e.toString()));
    }
  }

  // ============================================
  // Lifeline Methods
  // ============================================

  /// Use 50/50 lifeline - removes 2 wrong answers
  void useFiftyFifty() {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;
    if (currentState.fiftyFiftyStatus != LifelineStatus.unused) return;
    
    // Can't use 50/50 if audience poll is active
    if (currentState.audiencePollStatus == LifelineStatus.using) return;

    final question = currentState.currentQuestion;
    // Decrypt the correct answer
    final correctAnswer = getDecryptedAnswer(question);
    
    // Get all wrong options
    final options = ['a', 'b', 'c', 'd'];
    final optionTexts = {
      'a': question.optionA,
      'b': question.optionB,
      'c': question.optionC,
      'd': question.optionD,
    };
    
    final wrongOptions = options
        .where((o) => o != correctAnswer && optionTexts[o]!.isNotEmpty)
        .toList();
    
    // Randomly pick 2 wrong options to hide
    wrongOptions.shuffle();
    final toHide = wrongOptions.take(2).toList();
    
    emit(currentState.copyWith(
      fiftyFiftyStatus: LifelineStatus.used,
      hiddenOptions: toHide,
    ));
  }

  /// Use Audience Poll lifeline - shows fake poll percentages
  void useAudiencePoll() {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;
    if (currentState.audiencePollStatus != LifelineStatus.unused) return;
    
    // Can't use poll if 50/50 is active
    if (currentState.fiftyFiftyStatus == LifelineStatus.using) return;

    final question = currentState.currentQuestion;
    // Decrypt the correct answer
    final correctAnswer = getDecryptedAnswer(question);
    
    // Generate fake poll percentages (correct answer gets higher %)
    final percentages = <int>[];
    final options = ['a', 'b', 'c', 'd'];
    var remaining = 100;
    
    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final isCorrect = opt == correctAnswer;
      final isLast = i == options.length - 1;
      
      if (isLast) {
        percentages.add(remaining);
      } else if (isCorrect) {
        // Correct answer gets 40-70%
        final pct = 40 + (DateTime.now().millisecond % 31);
        percentages.add(pct);
        remaining -= pct;
      } else {
        // Wrong answers get smaller percentages
        final maxPct = (remaining / (options.length - i - 1)).floor();
        final pct = maxPct > 0 ? (DateTime.now().microsecond % maxPct).clamp(5, maxPct) : 0;
        percentages.add(pct);
        remaining -= pct;
      }
    }
    
    emit(currentState.copyWith(
      audiencePollStatus: LifelineStatus.used,
      audiencePollPercentages: percentages,
    ));
  }

  /// Use Reset Time lifeline - resets timer to full
  void useResetTime() {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;
    if (currentState.resetTimeStatus != LifelineStatus.unused) return;

    emit(currentState.copyWith(
      resetTimeStatus: LifelineStatus.used,
      timeRemaining: currentState.timePerQuestion,
    ));
  }

  /// Skip question - move to next without answering
  void skipQuestion() {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;

    // Add empty answer for skipped question
    final newAnswers = List<SoloAnswer>.from(currentState.answers)
      ..add(SoloAnswer(
        questionId: currentState.currentQuestion.id,
        selectedAnswer: '', // Skipped
        selectedOptionText: '', // No option selected
      ));

    if (currentState.isLastQuestion) {
      _submitQuiz(newAnswers);
    } else {
      emit(SoloModePlaying(
        topic: currentState.topic,
        questions: currentState.questions,
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
        timeRemaining: currentState.timePerQuestion,
        timePerQuestion: currentState.timePerQuestion,
        answers: newAnswers,
        startTimeMs: currentState.startTimeMs,
        // Reset lifeline effects for new question, but keep used status
        fiftyFiftyStatus: currentState.fiftyFiftyStatus == LifelineStatus.used 
            ? LifelineStatus.used : LifelineStatus.unused,
        audiencePollStatus: currentState.audiencePollStatus == LifelineStatus.used 
            ? LifelineStatus.used : LifelineStatus.unused,
        resetTimeStatus: currentState.resetTimeStatus == LifelineStatus.used 
            ? LifelineStatus.used : LifelineStatus.unused,
        hiddenOptions: const [],
        audiencePollPercentages: const [],
      ));
      _startTimer();
    }
  }

  /// Reset to topic selection
  void reset() {
    _timer?.cancel();
    emit(const SoloModeInitial());
    loadTopics();
  }

  /// Go back to topic selection (from config)
  void backToTopics() {
    loadTopics();
  }

  /// Play again with same settings
  Future<void> playAgain() async {
    final currentState = state;
    if (currentState is! SoloModeCompleted) return;

    // Re-fetch and start with the same topic
    emit(SoloModeConfiguring(
      selectedTopic: currentState.result.topic as SoloTopic,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

