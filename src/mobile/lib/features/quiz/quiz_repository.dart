import 'dart:developer';
import 'dart:io';

import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart' show errorCodeNoInternet;
import 'package:flutterquiz/features/quiz/models/category.dart';
import 'package:flutterquiz/features/quiz/models/comprehension.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';
import 'package:flutterquiz/features/quiz/models/contest_leaderboard.dart';
import 'package:flutterquiz/features/quiz/models/guess_the_word_question.dart';
import 'package:flutterquiz/features/quiz/models/leaderboard_monthly.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/models/subcategory.dart';
import 'package:flutterquiz/features/quiz/daily_contest_local_data_source.dart';
import 'package:flutterquiz/features/quiz/quiz_local_data_source.dart';
import 'package:flutterquiz/features/quiz/quiz_remote_data_source.dart';
import 'package:flutterquiz/utils/datetime_utils.dart';

final class QuizRepository {
  factory QuizRepository({ConnectivityCubit? connectivityCubit}) {
    _quizRepository._quizRemoteDataSource = QuizRemoteDataSource();
    _quizRepository._quizLocalDataSource = QuizLocalDataSource();
    _quizRepository._dailyContestLocalDataSource = DailyContestLocalDataSource();
    _quizRepository._connectivityCubit = connectivityCubit;
    return _quizRepository;
  }

  QuizRepository._internal();

  static final QuizRepository _quizRepository = QuizRepository._internal();
  late QuizRemoteDataSource _quizRemoteDataSource;
  late QuizLocalDataSource _quizLocalDataSource;
  late DailyContestLocalDataSource _dailyContestLocalDataSource;
  ConnectivityCubit? _connectivityCubit;
  static List<LeaderBoardMonthly> leaderBoardMonthlyList = [];

  /// Check if we're currently online
  bool get _isOnline => _connectivityCubit?.isOnline ?? true;

  /// Get categories (offline-first)
  Future<List<Category>> getCategory({
    required String languageId,
    required String type,
    String? subType,
    bool forceRefresh = false,
  }) async {
    // Try cache first (ALWAYS check cache)
    final cached = await _quizLocalDataSource.getCachedCategories();
    
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      log('Quiz categories: returning ${cached.length} cached items');
      
      // Refresh in background if online
      if (_isOnline) {
        _refreshCategoriesInBackground(languageId, type, subType);
      }
      
      return cached;
    }

    // Try to fetch from remote
    try {
      final result = await _quizRemoteDataSource.getCategoryWithUser(
        languageId: languageId,
        type: type,
        subType: subType,
      );
      final categories = result.map(Category.fromJson).toList();
      await _quizLocalDataSource.cacheCategories(categories);
      log('Quiz categories: fetched ${categories.length} from remote');
      return categories;
    } on SocketException catch (e) {
      log('Network error fetching categories: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    } on ApiException {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching categories: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    }
  }

  Future<void> _refreshCategoriesInBackground(
    String languageId, 
    String type, 
    String? subType,
  ) async {
    try {
      final result = await _quizRemoteDataSource.getCategoryWithUser(
        languageId: languageId,
        type: type,
        subType: subType,
      );
      final categories = result.map(Category.fromJson).toList();
      await _quizLocalDataSource.cacheCategories(categories);
    } catch (e) {
      log('Background refresh categories error: $e');
    }
  }

  Future<List<Category>> getCategoryWithoutUser({
    required String languageId,
    required String type,
    String? subType,
  }) async {
    final result = await _quizRemoteDataSource.getCategory(
      languageId: languageId,
      type: type,
      subType: subType,
    );

    return result.map(Category.fromJson).toList();
  }

  /// Get subcategories (offline-first)
  Future<List<Subcategory>> getSubCategory(
    String category, 
    {bool forceRefresh = false}
  ) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = await _quizLocalDataSource.getCachedSubCategories(category);
      if (cached != null && cached.isNotEmpty) {
        log('Quiz subcategories ($category): returning ${cached.length} cached');
        
        if (_isOnline) {
          _refreshSubCategoriesInBackground(category);
        }
        
        return cached;
      }
    }

    // Fetch from remote
    if (_isOnline) {
      try {
        final result = await _quizRemoteDataSource.getSubCategory(category);
        final subcategories = result.map(Subcategory.fromJson).toList();
        await _quizLocalDataSource.cacheSubCategories(category, subcategories);
        log('Quiz subcategories ($category): fetched ${subcategories.length}');
        return subcategories;
      } catch (e) {
        log('Error fetching subcategories: $e');
        final cached = await _quizLocalDataSource.getCachedSubCategories(category);
        if (cached != null) return cached;
        rethrow;
      }
    }

    // Offline
    final cached = await _quizLocalDataSource.getCachedSubCategories(category);
    if (cached != null) return cached;
    throw Exception('No cached subcategories available offline');
  }

  Future<void> _refreshSubCategoriesInBackground(String category) async {
    try {
      final result = await _quizRemoteDataSource.getSubCategory(category);
      final subcategories = result.map(Subcategory.fromJson).toList();
      await _quizLocalDataSource.cacheSubCategories(category, subcategories);
    } catch (e) {
      log('Background refresh subcategories error: $e');
    }
  }

  Future<int> getUnlockedLevel(
    String category,
    String subCategory, {
    required QuizTypes quizType,
  }) async {
    return _quizRemoteDataSource.getUnlockedLevel(
      category,
      subCategory,
      quizType: quizType,
    );
  }

  Future<List<Question>> getQuestions(
    QuizTypes? quizType, {
    String? languageId,
    String? categoryId,
    String? subcategoryId,
    String? numberOfQuestions,
    String? level,
    String? contestId,
    String? funAndLearnId,
  }) async {
    final List<Map<String, dynamic>> result;

    if (quizType == QuizTypes.dailyQuiz) {
      final (:gmt, :localTimezone) = await DateTimeUtils.getTimeZone();
      result = await _quizRemoteDataSource.getQuestionsForDailyQuiz(
        languageId: languageId,
        timezone: localTimezone,
        gmt: gmt,
      );
    } else if (quizType == QuizTypes.selfChallenge) {
      result = await _quizRemoteDataSource.getQuestionsForSelfChallenge(
        languageId: languageId!,
        categoryId: categoryId!,
        numberOfQuestions: numberOfQuestions!,
        subcategoryId: subcategoryId!,
      );
    } else if (quizType == QuizTypes.quizZone) {
      //if level is 0 means need to fetch questions by get_question api endpoint
      if (level! == '0') {
        final type = categoryId!.isNotEmpty ? 'category' : 'subcategory';
        final id = type == 'category' ? categoryId : subcategoryId!;
        result = await _quizRemoteDataSource.getQuestionByCategoryOrSubcategory(
          type: type,
          id: id,
        );
      } else {
        result = await _quizRemoteDataSource.getQuestionsForQuizZone(
          languageId: languageId!,
          categoryId: categoryId!,
          subcategoryId: subcategoryId!,
          level: level,
        );
      }
    } else if (quizType == QuizTypes.trueAndFalse) {
      result = await _quizRemoteDataSource.getQuestionByType(languageId!);
    } else if (quizType == QuizTypes.contest) {
      result = await _quizRemoteDataSource.getQuestionContest(contestId!);
    } else if (quizType == QuizTypes.funAndLearn) {
      result = await _quizRemoteDataSource.getComprehensionQuestion(
        funAndLearnId,
      );
    } else if (quizType == QuizTypes.audioQuestions) {
      final type = categoryId!.isNotEmpty ? 'category' : 'subcategory';
      final id = type == 'category' ? categoryId : subcategoryId!;
      result = await _quizRemoteDataSource.getAudioQuestions(
        type: type,
        id: id,
      );
    } else if (quizType == QuizTypes.mathMania) {
      final type = subcategoryId != null && subcategoryId.isNotEmpty
          ? 'subcategory'
          : 'category';
      final id = type == 'category' ? categoryId! : subcategoryId!;
      result = await _quizRemoteDataSource.getLatexQuestions(
        type: type,
        id: id,
      );
    } else {
      result = [];
    }

    return result.map(Question.fromJson).toList(growable: false);
  }

  Future<List<GuessTheWordQuestion>> getGuessTheWordQuestions({
    required String languageId,
    required String type, //category or subcategory
    required String typeId, //id of the category or subcategory
  }) async {
    final result = await _quizRemoteDataSource.getGuessTheWordQuestions(
      languageId: languageId,
      type: type,
      typeId: typeId,
    );

    return result.map(GuessTheWordQuestion.fromJson).toList();
  }

  Future<Contests> getContest({
    required String languageId,
    required String timezone,
    required String gmt,
  }) async {
    // Try cache first
    final cached = await _quizLocalDataSource.getCachedContests();
    
    // Try to fetch from remote
    try {
      final result = await _quizRemoteDataSource.getContest(
        languageId: languageId,
        timezone: timezone,
        gmt: gmt,
      );
      final contests = Contests.fromJson(result);
      
      // Cache the result
      await _quizLocalDataSource.cacheContests(contests);
      
      return contests;
    } on SocketException {
      // Network error - return cache if available
      if (cached != null) {
        log('Contests: returning cached due to network error');
        return cached;
      }
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      if (cached != null) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching contests: $e');
      if (cached != null) return cached;
      throw const ApiException(errorCodeNoInternet);
    }
  }

  Future<({int total, List<ContestLeaderboard> otherUsersRanks})>
  getContestLeaderboard(
    String contestId, {
    required int limit,
    int? offset,
  }) async {
    final (:total, :otherUsersRanks) = await _quizRemoteDataSource
        .getContestLeaderboard(
          contestId: contestId,
          limit: limit,
          offset: offset,
        );

    return (
      total: total,
      otherUsersRanks: otherUsersRanks
          .map(ContestLeaderboard.fromJson)
          .toList(),
    );
  }

  Future<List<Comprehension>> getComprehension({
    required String languageId,
    required String type,
    required String typeId,
  }) async {
    final result = await _quizRemoteDataSource.getComprehension(
      languageId: languageId,
      type: type,
      typeId: typeId,
    );

    return result.map(Comprehension.fromJson).toList();
  }

  Future<void> unlockPremiumCategory({required String categoryId}) async {
    await _quizRemoteDataSource.unlockPremiumCategory(categoryId: categoryId);
  }

  Future<Map<String, dynamic>> setQuizCoinScore({
    required String quizType,
    required dynamic playedQuestions,
    String? categoryId,
    String? subcategoryId,
    List<String>? lifelines,
    String? roomId,
    bool? playWithBot,
    int? noOfHintUsed,
    String? matchId,
    int? joinedUsersCount,
  }) async {
    return _quizRemoteDataSource.setQuizCoinScore(
      categoryId: categoryId,
      quizType: quizType,
      playedQuestions: playedQuestions,
      subcategoryId: subcategoryId,
      lifelines: lifelines,
      roomId: roomId,
      playWithBot: playWithBot,
      noOfHintUsed: noOfHintUsed,
      matchId: matchId,
      joinedUsersCount: joinedUsersCount,
    );
  }

  // ============================================
  // DAILY CONTEST METHODS (Offline-First)
  // ============================================

  /// Check if user has a pending daily contest (offline-first)
  Future<Map<String, dynamic>> getDailyContestStatus({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = await _dailyContestLocalDataSource.getCachedContestStatus();
      if (cached != null) {
        log('Daily contest status: returning cached');
        
        if (_isOnline) {
          _refreshContestStatusInBackground();
        }
        
        return cached;
      }
    }

    // Fetch from remote
    if (_isOnline) {
      try {
        final status = await _quizRemoteDataSource.getDailyContestStatus();
        await _dailyContestLocalDataSource.cacheContestStatus(status);
        return status;
      } catch (e) {
        log('Error fetching contest status: $e');
        final cached = await _dailyContestLocalDataSource.getCachedContestStatus();
        if (cached != null) return cached;
        rethrow;
      }
    }

    // Offline
    final cached = await _dailyContestLocalDataSource.getCachedContestStatus();
    if (cached != null) return cached;
    throw Exception('No cached contest status available offline');
  }

  Future<void> _refreshContestStatusInBackground() async {
    try {
      final status = await _quizRemoteDataSource.getDailyContestStatus();
      await _dailyContestLocalDataSource.cacheContestStatus(status);
    } catch (e) {
      log('Background refresh contest status error: $e');
    }
  }

  /// Get today's daily contest details (offline-first)
  Future<Map<String, dynamic>> getTodayDailyContest({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = await _dailyContestLocalDataSource.getCachedTodayContest();
      if (cached != null) {
        log('Today\'s contest: returning cached');
        
        if (_isOnline) {
          _refreshTodayContestInBackground();
        }
        
        return cached;
      }
    }

    // Fetch from remote
    if (_isOnline) {
      try {
        final contest = await _quizRemoteDataSource.getTodayDailyContest();
        await _dailyContestLocalDataSource.cacheTodayContest(contest);
        return contest;
      } catch (e) {
        log('Error fetching today\'s contest: $e');
        final cached = await _dailyContestLocalDataSource.getCachedTodayContest();
        if (cached != null) return cached;
        rethrow;
      }
    }

    // Offline
    final cached = await _dailyContestLocalDataSource.getCachedTodayContest();
    if (cached != null) return cached;
    throw Exception('No cached daily contest available offline');
  }

  Future<void> _refreshTodayContestInBackground() async {
    try {
      final contest = await _quizRemoteDataSource.getTodayDailyContest();
      await _dailyContestLocalDataSource.cacheTodayContest(contest);
    } catch (e) {
      log('Background refresh today\'s contest error: $e');
    }
  }

  /// Submit daily contest answers (with offline queue support)
  Future<Map<String, dynamic>> submitDailyContest({
    required String contestId,
    required List<Map<String, dynamic>> answers,
    required bool readText,
  }) async {
    if (_isOnline) {
      // Submit immediately if online
      final result = await _quizRemoteDataSource.submitDailyContest(
        contestId: contestId,
        answers: answers,
        readText: readText,
      );
      
      // Clear any saved progress
      await _dailyContestLocalDataSource.clearProgress(contestId);
      
      return result;
    } else {
      // Queue for later if offline
      await _dailyContestLocalDataSource.queueSubmission(
        contestId: contestId,
        answers: answers,
        readText: readText,
      );
      
      // Return a pending response
      return {
        'error': false,
        'message': 'Submission queued for when online',
        'pending': true,
      };
    }
  }

  /// Create daily contest (for testing/admin)
  Future<Map<String, dynamic>> createDailyContest() async {
    return _quizRemoteDataSource.createDailyContest();
  }

  /// Save contest progress (for resume if app closes)
  Future<void> saveDailyContestProgress({
    required String contestId,
    required int currentQuestionIndex,
    required List<Map<String, dynamic>> answeredQuestions,
    required int remainingTime,
  }) async {
    await _dailyContestLocalDataSource.saveProgress(
      contestId: contestId,
      currentQuestionIndex: currentQuestionIndex,
      answeredQuestions: answeredQuestions,
      remainingTime: remainingTime,
    );
  }

  /// Get saved contest progress
  Future<Map<String, dynamic>?> getDailyContestProgress(String contestId) async {
    return _dailyContestLocalDataSource.getSavedProgress(contestId);
  }

  /// Check if there are pending contest submissions
  Future<bool> hasPendingContestSubmissions() async {
    return _dailyContestLocalDataSource.hasPendingSubmissions();
  }

  // ============================================
  // OFFLINE SUPPORT METHODS
  // ============================================

  /// Clear all cached quiz data
  Future<void> clearCache() => _quizLocalDataSource.clearAll();

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() => _quizLocalDataSource.getStats();

  /// Check if categories are cached
  Future<bool> hasCachedCategories() => _quizLocalDataSource.hasCategories();

  /// Check if questions for a category are cached
  Future<bool> hasCachedQuestions(String categoryId) => 
      _quizLocalDataSource.hasQuestions(categoryId);
}
