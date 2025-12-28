import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../battles_remote_data_source.dart';
import '../models/battle_model.dart';

/// 1v1 Battle State
abstract class Battle1v1State {}

class Battle1v1Initial extends Battle1v1State {}

class Battle1v1Loading extends Battle1v1State {}

class Battle1v1Created extends Battle1v1State {
  final Battle1v1 battle;
  Battle1v1Created(this.battle);
}

class Battle1v1WaitingOpponent extends Battle1v1State {
  final Battle1v1 battle;
  Battle1v1WaitingOpponent(this.battle);
}

class Battle1v1Ready extends Battle1v1State {
  final Battle1v1 battle;
  Battle1v1Ready(this.battle);
}

class Battle1v1Playing extends Battle1v1State {
  final Battle1v1 battle;
  final int currentQuestionIndex;
  final int timeRemaining;
  Battle1v1Playing(this.battle, {this.currentQuestionIndex = 0, this.timeRemaining = 15});
}

class Battle1v1Completed extends Battle1v1State {
  final Battle1v1 battle;
  Battle1v1Completed(this.battle);
}

class Battle1v1Error extends Battle1v1State {
  final String message;
  Battle1v1Error(this.message);
}

/// 1v1 Battle Cubit
class Battle1v1Cubit extends Cubit<Battle1v1State> {
  final BattlesRemoteDataSource _dataSource;
  Timer? _pollTimer;
  Timer? _questionTimer;
  
  Battle1v1? _currentBattle;
  int _currentQuestionIndex = 0;
  int _timeRemaining = 15;
  List<Map<String, dynamic>> _answers = [];
  int _score = 0;
  int _correct = 0;
  int _totalTimeMs = 0;
  DateTime? _questionStartTime;

  Battle1v1Cubit(this._dataSource) : super(Battle1v1Initial());

  /// Create a new battle
  Future<void> createBattle({
    required String topicId,
    required String categoryId,
    int questionCount = 10,
    int timePerQuestion = 15,
    int entryCoins = 0,
    int prizeCoins = 0,
  }) async {
    emit(Battle1v1Loading());
    try {
      final battle = await _dataSource.create1v1Battle(
        topicId: topicId,
        categoryId: categoryId,
        questionCount: questionCount,
        timePerQuestion: timePerQuestion,
        entryCoins: entryCoins,
        prizeCoins: prizeCoins,
      );
      _currentBattle = battle;
      emit(Battle1v1Created(battle));
      
      // Start polling for opponent
      _startPolling();
    } catch (e) {
      emit(Battle1v1Error(e.toString()));
    }
  }

  /// Join a battle
  Future<void> joinBattle(String matchCode) async {
    emit(Battle1v1Loading());
    try {
      final battle = await _dataSource.join1v1Battle(matchCode);
      _currentBattle = battle;
      
      if (battle.isReady) {
        emit(Battle1v1Ready(battle));
      } else {
        emit(Battle1v1WaitingOpponent(battle));
        _startPolling();
      }
    } catch (e) {
      emit(Battle1v1Error(e.toString()));
    }
  }

  /// Start the game
  void startGame() {
    if (_currentBattle == null || _currentBattle!.questions == null) return;
    
    _stopPolling();
    _currentQuestionIndex = 0;
    _answers = [];
    _score = 0;
    _correct = 0;
    _totalTimeMs = 0;
    
    _startQuestion();
  }

  void _startQuestion() {
    if (_currentBattle == null) return;
    
    _timeRemaining = _currentBattle!.timePerQuestion;
    _questionStartTime = DateTime.now();
    
    emit(Battle1v1Playing(
      _currentBattle!,
      currentQuestionIndex: _currentQuestionIndex,
      timeRemaining: _timeRemaining,
    ));
    
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;
      
      if (_timeRemaining <= 0) {
        timer.cancel();
        answerQuestion(''); // Time's up, submit empty answer
      } else {
        emit(Battle1v1Playing(
          _currentBattle!,
          currentQuestionIndex: _currentQuestionIndex,
          timeRemaining: _timeRemaining,
        ));
      }
    });
  }

  /// Answer current question
  void answerQuestion(String answer) {
    if (_currentBattle == null || _currentBattle!.questions == null) return;
    
    _questionTimer?.cancel();
    
    final question = _currentBattle!.questions![_currentQuestionIndex];
    final isCorrect = answer.toLowerCase() == question.answer.toLowerCase();
    final timeMs = DateTime.now().difference(_questionStartTime!).inMilliseconds;
    
    _answers.add({
      'question_id': question.id,
      'answer': answer,
      'is_correct': isCorrect,
      'time_ms': timeMs,
    });
    
    if (isCorrect) {
      _correct++;
      // Score based on time - faster = more points
      final maxTime = _currentBattle!.timePerQuestion * 1000;
      final timeBonus = ((maxTime - timeMs) / maxTime * 5).round();
      _score += 10 + timeBonus;
    }
    _totalTimeMs += timeMs;
    
    _currentQuestionIndex++;
    
    if (_currentQuestionIndex < _currentBattle!.questions!.length) {
      _startQuestion();
    } else {
      _submitAnswers();
    }
  }

  Future<void> _submitAnswers() async {
    if (_currentBattle == null) return;
    
    try {
      final battle = await _dataSource.submit1v1Answers(
        battleId: _currentBattle!.id,
        answers: _answers,
        score: _score,
        correct: _correct,
        timeMs: _totalTimeMs,
      );
      _currentBattle = battle;
      
      if (battle.isCompleted) {
        emit(Battle1v1Completed(battle));
      } else {
        // Wait for opponent to finish
        _startPolling();
      }
    } catch (e) {
      emit(Battle1v1Error(e.toString()));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentBattle == null) return;
      
      try {
        final battle = await _dataSource.get1v1Battle(battleId: _currentBattle!.id);
        _currentBattle = battle;
        
        if (battle.isReady && state is Battle1v1WaitingOpponent) {
          timer.cancel();
          emit(Battle1v1Ready(battle));
        } else if (battle.isCompleted) {
          timer.cancel();
          emit(Battle1v1Completed(battle));
        }
      } catch (e) {
        // Ignore polling errors
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Get current battle
  Battle1v1? get currentBattle => _currentBattle;

  /// Get score
  int get score => _score;

  /// Get correct answers count
  int get correct => _correct;

  @override
  Future<void> close() {
    _stopPolling();
    _questionTimer?.cancel();
    return super.close();
  }
}

/// 1v1 History State
abstract class Battle1v1HistoryState {}

class Battle1v1HistoryInitial extends Battle1v1HistoryState {}

class Battle1v1HistoryLoading extends Battle1v1HistoryState {}

class Battle1v1HistoryLoaded extends Battle1v1HistoryState {
  final List<Battle1v1> battles;
  Battle1v1HistoryLoaded(this.battles);
}

class Battle1v1HistoryError extends Battle1v1HistoryState {
  final String message;
  Battle1v1HistoryError(this.message);
}

/// 1v1 History Cubit
class Battle1v1HistoryCubit extends Cubit<Battle1v1HistoryState> {
  final BattlesRemoteDataSource _dataSource;

  Battle1v1HistoryCubit(this._dataSource) : super(Battle1v1HistoryInitial());

  Future<void> loadHistory() async {
    emit(Battle1v1HistoryLoading());
    try {
      final battles = await _dataSource.get1v1History();
      emit(Battle1v1HistoryLoaded(battles));
    } catch (e) {
      emit(Battle1v1HistoryError(e.toString()));
    }
  }
}

