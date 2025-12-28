/// 1v1 Battle Model
class Battle1v1 {
  final String id;
  final String matchCode;
  final String topicId;
  final String categoryId;
  final String challengerId;
  final String? opponentId;
  final int questionCount;
  final int timePerQuestion;
  final int entryCoins;
  final int prizeCoins;
  final List<BattleQuestion>? questions;
  final String status;
  final String? winnerId;
  final bool isDraw;
  final DateTime? expiresAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  // Challenger stats
  final int challengerScore;
  final int challengerCorrect;
  final int challengerTimeMs;
  final bool challengerReady;

  // Opponent stats
  final int opponentScore;
  final int opponentCorrect;
  final int opponentTimeMs;
  final bool opponentReady;

  // Player info
  final BattlePlayer? challenger;
  final BattlePlayer? opponent;

  Battle1v1({
    required this.id,
    required this.matchCode,
    required this.topicId,
    required this.categoryId,
    required this.challengerId,
    this.opponentId,
    this.questionCount = 10,
    this.timePerQuestion = 15,
    this.entryCoins = 0,
    this.prizeCoins = 0,
    this.questions,
    this.status = 'waiting',
    this.winnerId,
    this.isDraw = false,
    this.expiresAt,
    this.startedAt,
    this.endedAt,
    this.challengerScore = 0,
    this.challengerCorrect = 0,
    this.challengerTimeMs = 0,
    this.challengerReady = false,
    this.opponentScore = 0,
    this.opponentCorrect = 0,
    this.opponentTimeMs = 0,
    this.opponentReady = false,
    this.challenger,
    this.opponent,
  });

  factory Battle1v1.fromJson(Map<String, dynamic> json) {
    List<BattleQuestion>? questions;
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List<dynamic>)
          .map((q) => BattleQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    return Battle1v1(
      id: json['id']?.toString() ?? '',
      matchCode: (json['match_code'] as String?) ?? '',
      topicId: json['topic_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      challengerId: json['challenger_id']?.toString() ?? '',
      opponentId: json['opponent_id']?.toString(),
      questionCount: int.tryParse(json['question_count']?.toString() ?? '10') ?? 10,
      timePerQuestion: int.tryParse(json['time_per_question']?.toString() ?? '15') ?? 15,
      entryCoins: int.tryParse(json['entry_coins']?.toString() ?? '0') ?? 0,
      prizeCoins: int.tryParse(json['prize_coins']?.toString() ?? '0') ?? 0,
      questions: questions,
      status: (json['status'] as String?) ?? 'waiting',
      winnerId: json['winner_id']?.toString(),
      isDraw: json['is_draw'] == '1' || json['is_draw'] == true,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'] as String) : null,
      challengerScore: int.tryParse(json['challenger_score']?.toString() ?? '0') ?? 0,
      challengerCorrect: int.tryParse(json['challenger_correct']?.toString() ?? '0') ?? 0,
      challengerTimeMs: int.tryParse(json['challenger_time_ms']?.toString() ?? '0') ?? 0,
      challengerReady: json['challenger_ready'] == '1' || json['challenger_ready'] == true,
      opponentScore: int.tryParse(json['opponent_score']?.toString() ?? '0') ?? 0,
      opponentCorrect: int.tryParse(json['opponent_correct']?.toString() ?? '0') ?? 0,
      opponentTimeMs: int.tryParse(json['opponent_time_ms']?.toString() ?? '0') ?? 0,
      opponentReady: json['opponent_ready'] == '1' || json['opponent_ready'] == true,
      challenger: json['challenger'] != null ? BattlePlayer.fromJson(json['challenger'] as Map<String, dynamic>) : null,
      opponent: json['opponent'] != null ? BattlePlayer.fromJson(json['opponent'] as Map<String, dynamic>) : null,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isReady => status == 'ready';
  bool get isPlaying => status == 'playing';
  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired';

  bool isChallenger(String oderId) => challengerId == oderId;
  bool isOpponent(String oderId) => opponentId == oderId;
  bool isWinner(String oderId) => winnerId == oderId;
}

/// Battle Player Info
class BattlePlayer {
  final String id;
  final String? name;
  final String? profile;

  BattlePlayer({
    required this.id,
    this.name,
    this.profile,
  });

  factory BattlePlayer.fromJson(Map<String, dynamic> json) {
    return BattlePlayer(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      profile: json['profile'] as String?,
    );
  }
}

/// Battle Question
class BattleQuestion {
  final String id;
  final String question;
  final String optionA;
  final String optionB;
  final String? optionC;
  final String? optionD;
  final String answer;
  final String? note;

  BattleQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    this.optionC,
    this.optionD,
    required this.answer,
    this.note,
  });

  factory BattleQuestion.fromJson(Map<String, dynamic> json) {
    return BattleQuestion(
      id: json['id']?.toString() ?? '',
      question: (json['question'] as String?) ?? '',
      optionA: (json['optiona'] as String?) ?? '',
      optionB: (json['optionb'] as String?) ?? '',
      optionC: json['optionc'] as String?,
      optionD: json['optiond'] as String?,
      answer: (json['answer'] as String?) ?? '',
      note: json['note'] as String?,
    );
  }

  List<String> get options {
    final opts = [optionA, optionB];
    if (optionC != null && optionC!.isNotEmpty) opts.add(optionC!);
    if (optionD != null && optionD!.isNotEmpty) opts.add(optionD!);
    return opts;
  }
}

/// Group Battle Model
class GroupBattle {
  final String id;
  final String groupId;
  final String topicId;
  final String categoryId;
  final String createdBy;
  final String? title;
  final int questionCount;
  final int timePerQuestion;
  final int entryCoins;
  final int prizeCoins;
  final int minPlayers;
  final int maxPlayers;
  final int playerCount;
  final String status;
  final List<BattleQuestion>? questions;
  final List<GroupBattleEntry>? entries;
  final DateTime? scheduledStart;
  final DateTime? startedAt;
  final DateTime? endedAt;

  GroupBattle({
    required this.id,
    required this.groupId,
    required this.topicId,
    required this.categoryId,
    required this.createdBy,
    this.title,
    this.questionCount = 10,
    this.timePerQuestion = 15,
    this.entryCoins = 0,
    this.prizeCoins = 0,
    this.minPlayers = 2,
    this.maxPlayers = 10,
    this.playerCount = 0,
    this.status = 'pending',
    this.questions,
    this.entries,
    this.scheduledStart,
    this.startedAt,
    this.endedAt,
  });

  factory GroupBattle.fromJson(Map<String, dynamic> json) {
    List<BattleQuestion>? questions;
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List<dynamic>)
          .map((q) => BattleQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    List<GroupBattleEntry>? entries;
    if (json['entries'] != null && json['entries'] is List) {
      entries = (json['entries'] as List<dynamic>)
          .map((e) => GroupBattleEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return GroupBattle(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      topicId: json['topic_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      title: json['title'] as String?,
      questionCount: int.tryParse(json['question_count']?.toString() ?? '10') ?? 10,
      timePerQuestion: int.tryParse(json['time_per_question']?.toString() ?? '15') ?? 15,
      entryCoins: int.tryParse(json['entry_coins']?.toString() ?? '0') ?? 0,
      prizeCoins: int.tryParse(json['prize_coins']?.toString() ?? '0') ?? 0,
      minPlayers: int.tryParse(json['min_players']?.toString() ?? '2') ?? 2,
      maxPlayers: int.tryParse(json['max_players']?.toString() ?? '10') ?? 10,
      playerCount: int.tryParse(json['player_count']?.toString() ?? '0') ?? 0,
      status: (json['status'] as String?) ?? 'pending',
      questions: questions,
      entries: entries,
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.tryParse(json['scheduled_start'] as String)
          : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'] as String) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get canStart => playerCount >= minPlayers;
}

/// Group Battle Entry
class GroupBattleEntry {
  final String id;
  final String battleId;
  final String oderId;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalTimeMs;
  final int? rank;
  final int coinsEarned;
  final String status;
  final String? name;
  final String? profile;

  GroupBattleEntry({
    required this.id,
    required this.battleId,
    required this.oderId,
    this.score = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.totalTimeMs = 0,
    this.rank,
    this.coinsEarned = 0,
    this.status = 'joined',
    this.name,
    this.profile,
  });

  factory GroupBattleEntry.fromJson(Map<String, dynamic> json) {
    return GroupBattleEntry(
      id: json['id']?.toString() ?? '',
      battleId: json['battle_id']?.toString() ?? '',
      oderId: json['user_id']?.toString() ?? '',
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      correctAnswers: int.tryParse(json['correct_answers']?.toString() ?? '0') ?? 0,
      wrongAnswers: int.tryParse(json['wrong_answers']?.toString() ?? '0') ?? 0,
      totalTimeMs: int.tryParse(json['total_time_ms']?.toString() ?? '0') ?? 0,
      rank: int.tryParse(json['rank']?.toString() ?? ''),
      coinsEarned: int.tryParse(json['coins_earned']?.toString() ?? '0') ?? 0,
      status: (json['status'] as String?) ?? 'joined',
      name: json['name'] as String?,
      profile: json['profile'] as String?,
    );
  }

  bool get isWinner => rank == 1;
}

