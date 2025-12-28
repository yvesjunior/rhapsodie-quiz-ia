import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../battles_remote_data_source.dart';
import '../models/battle_model.dart';

/// Group Battle State
abstract class GroupBattleState {}

class GroupBattleInitial extends GroupBattleState {}

class GroupBattleLoading extends GroupBattleState {}

class GroupBattleCreated extends GroupBattleState {
  final GroupBattle battle;
  GroupBattleCreated(this.battle);
}

class GroupBattleWaiting extends GroupBattleState {
  final GroupBattle battle;
  GroupBattleWaiting(this.battle);
}

class GroupBattleReady extends GroupBattleState {
  final GroupBattle battle;
  GroupBattleReady(this.battle);
}

class GroupBattlePlaying extends GroupBattleState {
  final GroupBattle battle;
  final int currentQuestionIndex;
  final int timeRemaining;
  GroupBattlePlaying(this.battle, {this.currentQuestionIndex = 0, this.timeRemaining = 15});
}

class GroupBattleSubmitted extends GroupBattleState {
  final GroupBattle battle;
  GroupBattleSubmitted(this.battle);
}

class GroupBattleCompleted extends GroupBattleState {
  final GroupBattle battle;
  GroupBattleCompleted(this.battle);
}

class GroupBattleError extends GroupBattleState {
  final String message;
  GroupBattleError(this.message);
}

/// Group Battle Cubit
class GroupBattleCubit extends Cubit<GroupBattleState> {
  final BattlesRemoteDataSource _dataSource;
  Timer? _pollTimer;
  Timer? _questionTimer;

  GroupBattle? _currentBattle;
  int _currentQuestionIndex = 0;
  int _timeRemaining = 15;
  List<Map<String, dynamic>> _answers = [];
  int _score = 0;
  int _correct = 0;
  int _wrong = 0;
  int _totalTimeMs = 0;
  DateTime? _questionStartTime;

  GroupBattleCubit(this._dataSource) : super(GroupBattleInitial());

  /// Create a new group battle
  Future<void> createBattle({
    required String groupId,
    required String topicId,
    required String categoryId,
    String? title,
    int questionCount = 10,
    int timePerQuestion = 15,
    int entryCoins = 0,
    int prizeCoins = 0,
    int minPlayers = 2,
    int maxPlayers = 10,
  }) async {
    emit(GroupBattleLoading());
    try {
      final battle = await _dataSource.createGroupBattle(
        groupId: groupId,
        topicId: topicId,
        categoryId: categoryId,
        title: title,
        questionCount: questionCount,
        timePerQuestion: timePerQuestion,
        entryCoins: entryCoins,
        prizeCoins: prizeCoins,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
      );
      _currentBattle = battle;
      emit(GroupBattleCreated(battle));
      _startPolling();
    } catch (e) {
      emit(GroupBattleError(e.toString()));
    }
  }

  /// Join an existing battle
  Future<void> joinBattle(String battleId) async {
    emit(GroupBattleLoading());
    try {
      final battle = await _dataSource.joinGroupBattle(battleId);
      _currentBattle = battle;

      if (battle.isActive) {
        emit(GroupBattleReady(battle));
      } else {
        emit(GroupBattleWaiting(battle));
        _startPolling();
      }
    } catch (e) {
      emit(GroupBattleError(e.toString()));
    }
  }

  /// Load battle details
  Future<void> loadBattle(String battleId) async {
    emit(GroupBattleLoading());
    try {
      final battle = await _dataSource.getGroupBattle(battleId);
      _currentBattle = battle;

      if (battle.isCompleted) {
        emit(GroupBattleCompleted(battle));
      } else if (battle.isActive) {
        emit(GroupBattleReady(battle));
      } else {
        emit(GroupBattleWaiting(battle));
        _startPolling();
      }
    } catch (e) {
      emit(GroupBattleError(e.toString()));
    }
  }

  /// Start the battle (owner only)
  Future<void> startBattle() async {
    if (_currentBattle == null) return;

    try {
      final battle = await _dataSource.startGroupBattle(_currentBattle!.id);
      _currentBattle = battle;
      emit(GroupBattleReady(battle));
      _stopPolling();
    } catch (e) {
      emit(GroupBattleError(e.toString()));
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
    _wrong = 0;
    _totalTimeMs = 0;

    _startQuestion();
  }

  void _startQuestion() {
    if (_currentBattle == null) return;

    _timeRemaining = _currentBattle!.timePerQuestion;
    _questionStartTime = DateTime.now();

    emit(GroupBattlePlaying(
      _currentBattle!,
      currentQuestionIndex: _currentQuestionIndex,
      timeRemaining: _timeRemaining,
    ));

    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;

      if (_timeRemaining <= 0) {
        timer.cancel();
        answerQuestion(''); // Time's up
      } else {
        emit(GroupBattlePlaying(
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
      final maxTime = _currentBattle!.timePerQuestion * 1000;
      final timeBonus = ((maxTime - timeMs) / maxTime * 5).round();
      _score += 10 + timeBonus;
    } else {
      _wrong++;
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
      emit(GroupBattleSubmitted(_currentBattle!));
      
      final battle = await _dataSource.submitGroupBattleAnswers(
        battleId: _currentBattle!.id,
        answers: _answers,
        score: _score,
        correct: _correct,
        wrong: _wrong,
        timeMs: _totalTimeMs,
      );
      _currentBattle = battle;

      if (battle.isCompleted) {
        emit(GroupBattleCompleted(battle));
      } else {
        // Wait for other players
        _startPolling();
      }
    } catch (e) {
      emit(GroupBattleError(e.toString()));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_currentBattle == null) return;

      try {
        final battle = await _dataSource.getGroupBattle(_currentBattle!.id);
        _currentBattle = battle;

        if (battle.isActive && state is GroupBattleWaiting) {
          timer.cancel();
          emit(GroupBattleReady(battle));
        } else if (battle.isCompleted) {
          timer.cancel();
          emit(GroupBattleCompleted(battle));
        } else if (state is GroupBattleWaiting) {
          emit(GroupBattleWaiting(battle));
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
  GroupBattle? get currentBattle => _currentBattle;

  /// Get score
  int get score => _score;

  /// Get correct answers
  int get correct => _correct;

  /// Get wrong answers
  int get wrong => _wrong;

  @override
  Future<void> close() {
    _stopPolling();
    _questionTimer?.cancel();
    return super.close();
  }
}

