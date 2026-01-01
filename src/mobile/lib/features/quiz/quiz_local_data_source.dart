import 'dart:convert';

import 'package:flutterquiz/core/offline/cache_manager.dart';
import 'package:flutterquiz/features/quiz/models/category.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';
import 'package:flutterquiz/features/quiz/models/subcategory.dart';

/// Local data source for Quiz content using Hive cache
class QuizLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  // ============================================
  // Categories
  // ============================================

  /// Cache list of quiz categories
  Future<void> cacheCategories(List<Category> categories) async {
    await _cache.cacheList(
      CacheKeys.quizCategories,
      categories,
      (cat) => {
        'id': cat.id,
        'language_id': cat.languageId,
        'category_name': cat.categoryName,
        'image': cat.image,
        'no_of': cat.subcategoriesCount.toString(),
        'no_of_que': cat.questionsCount.toString(),
        'maxlevel': cat.maxLevel,
        'is_play': cat.isPlayed ? '1' : '0',
        'is_premium': cat.isPremium ? '1' : '0',
        'has_unlocked': cat.hasUnlocked ? '1' : '0',
        'coins': cat.requiredCoins.toString(),
      },
    );
  }

  /// Get cached quiz categories
  Future<List<Category>?> getCachedCategories() async {
    return _cache.getList(
      CacheKeys.quizCategories,
      (json) => Category.fromJson(json),
    );
  }

  /// Check if categories are cached
  Future<bool> hasCategories() => _cache.has(CacheKeys.quizCategories);

  // ============================================
  // Subcategories
  // ============================================

  /// Cache subcategories for a category
  Future<void> cacheSubCategories(String categoryId, List<Subcategory> subs) async {
    await _cache.cacheList(
      CacheKeys.quizSubCategories(categoryId),
      subs,
      (sub) => {
        'id': sub.id,
        'image': sub.image,
        'language_id': sub.languageId,
        'maincat_id': sub.mainCatId,
        'maxlevel': sub.maxLevel,
        'no_of_que': sub.noOfQue,
        'row_order': sub.rowOrder,
        'status': sub.status,
        'subcategory_name': sub.subcategoryName,
        'is_play': sub.isPlayed ? '1' : '0',
        'coins': sub.requiredCoins.toString(),
      },
    );
  }

  /// Get cached subcategories for a category
  Future<List<Subcategory>?> getCachedSubCategories(String categoryId) async {
    return _cache.getList(
      CacheKeys.quizSubCategories(categoryId),
      (json) => Subcategory.fromJson(json),
    );
  }

  /// Check if subcategories are cached
  Future<bool> hasSubCategories(String categoryId) => 
      _cache.has(CacheKeys.quizSubCategories(categoryId));

  // ============================================
  // Questions
  // ============================================

  /// Cache questions for a category/subcategory
  Future<void> cacheQuestions(String key, List<Question> questions) async {
    await _cache.cacheList(
      key,
      questions,
      (q) => _questionToJson(q),
    );
  }

  /// Convert Question to JSON for caching
  Map<String, dynamic> _questionToJson(Question q) {
    final options = <String, String>{};
    final optionIds = ['a', 'b', 'c', 'd', 'e'];
    
    if (q.answerOptions != null) {
      for (var i = 0; i < q.answerOptions!.length && i < optionIds.length; i++) {
        options['option${optionIds[i]}'] = q.answerOptions![i].title ?? '';
      }
    }

    return {
      'id': q.id,
      'question': q.question,
      'category': q.categoryId,
      'subcategory': q.subcategoryId,
      'image': q.imageUrl,
      'language_id': q.languageId,
      'level': q.level,
      'note': q.note,
      'question_type': q.questionType,
      'audio': q.audio,
      'audio_type': q.audioType,
      'marks': q.marks,
      'answer': {
        'ciphertext': q.correctAnswer?.cipherText ?? '',
        'iv': q.correctAnswer?.iv ?? '',
      },
      ...options,
    };
  }

  /// Get cached questions
  Future<List<Question>?> getCachedQuestions(String key) async {
    return _cache.getList(
      key,
      (json) => Question.fromJson(json),
    );
  }

  /// Cache questions by category
  Future<void> cacheQuestionsByCategory(String categoryId, List<Question> questions) async {
    await cacheQuestions(CacheKeys.quizQuestions(categoryId), questions);
  }

  /// Get cached questions by category
  Future<List<Question>?> getCachedQuestionsByCategory(String categoryId) async {
    return getCachedQuestions(CacheKeys.quizQuestions(categoryId));
  }

  /// Check if questions are cached
  Future<bool> hasQuestions(String categoryId) => 
      _cache.has(CacheKeys.quizQuestions(categoryId));

  // ============================================
  // Daily Quiz
  // ============================================

  /// Cache daily quiz questions
  Future<void> cacheDailyQuizQuestions(String date, List<Question> questions) async {
    await cacheQuestions('daily_quiz_$date', questions);
  }

  /// Get cached daily quiz questions
  Future<List<Question>?> getCachedDailyQuizQuestions(String date) async {
    return getCachedQuestions('daily_quiz_$date');
  }

  // ============================================
  // Contests
  // ============================================

  static const _contestsKey = 'contests';

  /// Cache contests
  Future<void> cacheContests(Contests contests) async {
    final json = {
      'live_contest': _contestToJson(contests.live),
      'past_contest': _contestToJson(contests.past),
      'upcoming_contest': _contestToJson(contests.upcoming),
    };
    await _cache.cache(_contestsKey, json);
  }

  Map<String, dynamic> _contestToJson(Contest c) => {
    'error': c.errorMessage.isNotEmpty,
    'message': c.errorMessage,
    'data': c.contestDetails.map((d) => _contestDetailsToJson(d)).toList(),
  };

  Map<String, dynamic> _contestDetailsToJson(ContestDetails d) => {
    'id': d.id,
    'name': d.name,
    'description': d.description,
    'image': d.image,
    'start_date': d.startDate,
    'end_date': d.endDate,
    'entry': d.entry,
    'prize_status': d.prizeStatus,
    'date_created': d.dateCreated,
    'status': d.status,
    'top_users': d.topUsers,
    'points': d.points,
    'participants': d.participants,
  };

  /// Get cached contests
  Future<Contests?> getCachedContests() async {
    final raw = await _cache.getRaw(_contestsKey);
    if (raw == null) return null;
    
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Contests.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Check if contests are cached
  Future<bool> hasContests() => _cache.has(_contestsKey);

  // ============================================
  // Utility
  // ============================================

  /// Clear all quiz cache
  Future<void> clearAll() async {
    final keys = await _cache.getAllKeys();
    for (final key in keys) {
      if (key.startsWith('quiz') || key.startsWith('daily_quiz')) {
        await _cache.clear(key);
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final keys = await _cache.getAllKeys();
    final quizKeys = keys.where((k) => 
        k.startsWith('quiz') || k.startsWith('daily_quiz')).toList();
    
    return {
      'totalEntries': quizKeys.length,
      'categories': quizKeys.where((k) => k == CacheKeys.quizCategories).length,
      'subcategories': quizKeys.where((k) => k.startsWith('quiz_subcategories')).length,
      'questions': quizKeys.where((k) => k.startsWith('quiz_questions')).length,
      'dailyQuiz': quizKeys.where((k) => k.startsWith('daily_quiz')).length,
    };
  }
}

