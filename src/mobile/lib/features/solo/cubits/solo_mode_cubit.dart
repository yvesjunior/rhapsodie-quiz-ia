import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/solo/models/solo_models.dart';
import 'package:flutterquiz/features/solo/solo_remote_data_source.dart';

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

final class SoloModePlaying extends SoloModeState {
  final SoloTopic topic;
  final List<SoloQuestion> questions;
  final int currentQuestionIndex;
  final int timeRemaining;
  final int timePerQuestion;
  final List<SoloAnswer> answers;
  final int startTimeMs;
  
  const SoloModePlaying({
    required this.topic,
    required this.questions,
    required this.currentQuestionIndex,
    required this.timeRemaining,
    required this.timePerQuestion,
    required this.answers,
    required this.startTimeMs,
  });

  SoloQuestion get currentQuestion => questions[currentQuestionIndex];
  int get totalQuestions => questions.length;
  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;
  
  SoloModePlaying copyWith({
    int? currentQuestionIndex,
    int? timeRemaining,
    List<SoloAnswer>? answers,
  }) {
    return SoloModePlaying(
      topic: topic,
      questions: questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      timePerQuestion: timePerQuestion,
      answers: answers ?? this.answers,
      startTimeMs: startTimeMs,
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
  Timer? _timer;
  
  SoloModeCubit([SoloRemoteDataSource? dataSource]) 
      : _dataSource = dataSource ?? SoloRemoteDataSource(),
        super(const SoloModeInitial());

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

    // Add empty answer for skipped question
    final newAnswers = List<SoloAnswer>.from(currentState.answers)
      ..add(SoloAnswer(
        questionId: currentState.currentQuestion.id,
        selectedAnswer: '', // No answer
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

  /// Answer the current question
  void answerQuestion(String answer) {
    final currentState = state;
    if (currentState is! SoloModePlaying) return;

    _timer?.cancel();

    // Add answer
    final newAnswers = List<SoloAnswer>.from(currentState.answers)
      ..add(SoloAnswer(
        questionId: currentState.currentQuestion.id,
        selectedAnswer: answer,
      ));

    if (currentState.isLastQuestion) {
      _submitQuiz(newAnswers);
    } else {
      emit(currentState.copyWith(
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
        timeRemaining: currentState.timePerQuestion,
        answers: newAnswers,
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

