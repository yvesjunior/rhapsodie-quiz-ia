import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'models/topic_model.dart';
import 'models/topic_category_model.dart';

/// Remote Data Source for Topics
class TopicsRemoteDataSource {
  /// Get all topics
  Future<List<Topic>> getTopics() async {
    try {
      final response = await http.post(
        Uri.parse(getTopicsUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Failed to load topics');
      }

      final List<dynamic> topicsJson = (data['data'] as List<dynamic>?) ?? [];
      return topicsJson.map((json) => Topic.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load topics: $e');
    }
  }

  /// Get topic by ID or slug
  Future<Topic> getTopic({String? id, String? slug}) async {
    try {
      final body = <String, String>{};
      if (id != null) body['id'] = id;
      if (slug != null) body['slug'] = slug;

      final response = await http.post(
        Uri.parse(getTopicUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'Topic not found');
      }

      return Topic.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load topic: $e');
    }
  }

  /// Get categories for a topic
  Future<List<TopicCategory>> getTopicCategories({
    String? topicId,
    String? topicSlug,
    String? parentId,
    String ageGroup = 'all',
  }) async {
    try {
      final body = <String, String>{};
      if (topicId != null) body['topic_id'] = topicId;
      if (topicSlug != null) body['topic_slug'] = topicSlug;
      if (parentId != null) body['parent_id'] = parentId;
      body['age_group'] = ageGroup;

      final response = await http.post(
        Uri.parse(getTopicCategoriesUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return []; // Return empty list if no categories
      }

      final List<dynamic> categoriesJson = (data['data'] as List<dynamic>?) ?? [];
      return categoriesJson.map((json) => TopicCategory.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get Rhapsody daily content by date
  Future<List<TopicCategory>> getRhapsodyDaily({
    required int year,
    int? month,
    int? day,
    String ageGroup = 'all',
  }) async {
    try {
      final body = <String, String>{
        'year': year.toString(),
        'age_group': ageGroup,
      };
      if (month != null) body['month'] = month.toString();
      if (day != null) body['day'] = day.toString();

      final response = await http.post(
        Uri.parse(getRhapsodyDailyUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> categoriesJson = (data['data'] as List<dynamic>?) ?? [];
      return categoriesJson.map((json) => TopicCategory.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load Rhapsody daily: $e');
    }
  }

  /// Get Foundation School modules
  Future<List<TopicCategory>> getFoundationSchoolModules() async {
    try {
      final response = await http.post(
        Uri.parse(getFoundationSchoolModulesUrl),
        body: {},
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> modulesJson = (data['data'] as List<dynamic>?) ?? [];
      return modulesJson.map((json) => TopicCategory.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load Foundation School modules: $e');
    }
  }

  /// Get user progress
  Future<List<UserProgress>> getUserProgress({
    String? topicId,
    String? categoryId,
  }) async {
    try {
      final body = <String, String>{};
      if (topicId != null) body['topic_id'] = topicId;
      if (categoryId != null) body['category_id'] = categoryId;

      final response = await http.post(
        Uri.parse(getUserProgressUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data['error'] == true) {
        return [];
      }

      final List<dynamic> progressJson = (data['data'] as List<dynamic>?) ?? [];
      return progressJson.map((json) => UserProgress.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load user progress: $e');
    }
  }

  /// Update user progress
  Future<bool> updateUserProgress({
    required String topicId,
    required String categoryId,
    String? quizDate,
    String status = 'in_progress',
    double progressPercent = 0,
    int questionsTotal = 0,
    int questionsAnswered = 0,
    int questionsCorrect = 0,
    int score = 0,
  }) async {
    try {
      final body = <String, String>{
        'topic_id': topicId,
        'category_id': categoryId,
        'status': status,
        'progress_percent': progressPercent.toString(),
        'questions_total': questionsTotal.toString(),
        'questions_answered': questionsAnswered.toString(),
        'questions_correct': questionsCorrect.toString(),
        'score': score.toString(),
      };
      if (quizDate != null) body['quiz_date'] = quizDate;

      final response = await http.post(
        Uri.parse(updateUserProgressUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final data = jsonDecode(response.body);
      return data['error'] != true;
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }
}

