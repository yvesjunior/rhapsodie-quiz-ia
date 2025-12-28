import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'models/battle_model.dart';

/// Remote Data Source for Battles
class BattlesRemoteDataSource {
  // ============================================
  // 1v1 BATTLES
  // ============================================

  /// Create a 1v1 battle
  Future<Battle1v1> create1v1Battle({
    required String topicId,
    required String categoryId,
    int questionCount = 10,
    int timePerQuestion = 15,
    int entryCoins = 0,
    int prizeCoins = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(create1v1BattleUrl),
        body: {
          'topic_id': topicId,
          'category_id': categoryId,
          'question_count': questionCount.toString(),
          'time_per_question': timePerQuestion.toString(),
          'entry_coins': entryCoins.toString(),
          'prize_coins': prizeCoins.toString(),
        },
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to create battle');
      }

      // Get full battle details
      return await get1v1Battle(battleId: data['data']['battle_id'].toString());
    } catch (e) {
      throw Exception('Failed to create battle: $e');
    }
  }

  /// Join a 1v1 battle
  Future<Battle1v1> join1v1Battle(String matchCode) async {
    try {
      final response = await http.post(
        Uri.parse(join1v1BattleUrl),
        body: {'match_code': matchCode},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to join battle');
      }

      return Battle1v1.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to join battle: $e');
    }
  }

  /// Get 1v1 battle details
  Future<Battle1v1> get1v1Battle({String? battleId, String? matchCode}) async {
    try {
      final body = <String, String>{};
      if (battleId != null) body['battle_id'] = battleId;
      if (matchCode != null) body['match_code'] = matchCode;

      final response = await http.post(
        Uri.parse(get1v1BattleUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Battle not found');
      }

      return Battle1v1.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get battle: $e');
    }
  }

  /// Submit 1v1 battle answers
  Future<Battle1v1> submit1v1Answers({
    required String battleId,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int correct,
    required int timeMs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(submit1v1AnswersUrl),
        body: {
          'battle_id': battleId,
          'answers': jsonEncode(answers),
          'score': score.toString(),
          'correct': correct.toString(),
          'time_ms': timeMs.toString(),
        },
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to submit answers');
      }

      return Battle1v1.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to submit answers: $e');
    }
  }

  /// Get 1v1 battle history
  Future<List<Battle1v1>> get1v1History() async {
    try {
      final response = await http.post(
        Uri.parse(get1v1HistoryUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> battlesJson = (data['data'] as List<dynamic>?) ?? [];
      return battlesJson.map((json) => Battle1v1.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get battle history: $e');
    }
  }

  // ============================================
  // GROUP BATTLES
  // ============================================

  /// Create a group battle
  Future<GroupBattle> createGroupBattle({
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
    String? scheduledStart,
  }) async {
    try {
      final body = <String, String>{
        'group_id': groupId,
        'topic_id': topicId,
        'category_id': categoryId,
        'question_count': questionCount.toString(),
        'time_per_question': timePerQuestion.toString(),
        'entry_coins': entryCoins.toString(),
        'prize_coins': prizeCoins.toString(),
        'min_players': minPlayers.toString(),
        'max_players': maxPlayers.toString(),
      };
      if (title != null) body['title'] = title;
      if (scheduledStart != null) body['scheduled_start'] = scheduledStart;

      final response = await http.post(
        Uri.parse(createGroupBattleUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to create group battle');
      }

      return GroupBattle.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create group battle: $e');
    }
  }

  /// Join a group battle
  Future<GroupBattle> joinGroupBattle(String battleId) async {
    try {
      final response = await http.post(
        Uri.parse(joinGroupBattleUrl),
        body: {'battle_id': battleId},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to join battle');
      }

      return GroupBattle.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to join group battle: $e');
    }
  }

  /// Start a group battle
  Future<GroupBattle> startGroupBattle(String battleId) async {
    try {
      final response = await http.post(
        Uri.parse(startGroupBattleUrl),
        body: {'battle_id': battleId},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to start battle');
      }

      return GroupBattle.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to start group battle: $e');
    }
  }

  /// Submit group battle answers
  Future<GroupBattle> submitGroupBattleAnswers({
    required String battleId,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int correct,
    required int wrong,
    required int timeMs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(submitGroupBattleAnswersUrl),
        body: {
          'battle_id': battleId,
          'answers': jsonEncode(answers),
          'score': score.toString(),
          'correct': correct.toString(),
          'wrong': wrong.toString(),
          'time_ms': timeMs.toString(),
        },
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to submit answers');
      }

      return GroupBattle.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to submit answers: $e');
    }
  }

  /// Get group battle details
  Future<GroupBattle> getGroupBattle(String battleId) async {
    try {
      final response = await http.post(
        Uri.parse(getGroupBattleUrl),
        body: {'battle_id': battleId},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Battle not found');
      }

      return GroupBattle.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get group battle: $e');
    }
  }

  /// Get group's battles
  Future<List<GroupBattle>> getGroupBattles(String groupId, {String? status}) async {
    try {
      final body = <String, String>{'group_id': groupId};
      if (status != null) body['status'] = status;

      final response = await http.post(
        Uri.parse(getGroupBattlesUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> battlesJson = (data['data'] as List<dynamic>?) ?? [];
      return battlesJson.map((json) => GroupBattle.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get group battles: $e');
    }
  }
}

