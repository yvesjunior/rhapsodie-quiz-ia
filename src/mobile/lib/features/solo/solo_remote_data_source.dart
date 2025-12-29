import 'dart:convert';

import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/features/solo/models/solo_models.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

class SoloRemoteDataSource {
  /// Get available topics for Solo Mode
  Future<List<SoloTopic>> getSoloTopics() async {
    try {
      final response = await http.post(
        Uri.parse(getSoloTopicsUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] == true) {
        throw Exception(responseJson['message'] ?? 'Failed to load topics');
      }

      final rawData = responseJson['data'];
      
      // Handle different response formats
      List<dynamic> data;
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        // PHP sometimes returns associative array instead of indexed array
        data = rawData.values.toList();
      } else {
        data = [];
      }
      
      return data
          .map((t) => SoloTopic.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching solo topics: $e');
    }
  }

  /// Get random questions for a topic
  Future<List<SoloQuestion>> getRandomQuestions({
    required String topicSlug,
    required int count,
    int languageId = 0,
  }) async {
    try {
      final body = <String, String>{
        'topic': topicSlug,
        'count': count.toString(),
        if (languageId > 0) 'language_id': languageId.toString(),
      };

      final response = await http.post(
        Uri.parse(getSoloQuestionsUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] == true) {
        throw Exception(responseJson['message'] ?? 'Failed to load questions');
      }

      final rawData = responseJson['data'];
      
      // Handle different response formats
      List<dynamic> data;
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        // PHP sometimes returns associative array instead of indexed array
        data = rawData.values.toList();
      } else {
        data = [];
      }
      
      return data
          .map((q) => SoloQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching solo questions: $e');
    }
  }

  /// Submit solo quiz answers
  Future<SoloQuizResult> submitSoloQuiz({
    required String topicSlug,
    required int questionCount,
    required List<SoloAnswer> answers,
    int timeTaken = 0,
  }) async {
    try {
      final answersJson = answers.map((a) => a.toJson()).toList();

      final body = <String, String>{
        'topic': topicSlug,
        'question_count': questionCount.toString(),
        'answers': jsonEncode(answersJson),
        'time_taken': timeTaken.toString(),
      };

      final response = await http.post(
        Uri.parse(submitSoloQuizUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] == true) {
        throw Exception(responseJson['message'] ?? 'Failed to submit quiz');
      }

      return SoloQuizResult.fromJson(responseJson);
    } catch (e) {
      throw Exception('Error submitting solo quiz: $e');
    }
  }
}

