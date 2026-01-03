import 'package:flutterquiz/core/offline/cache_manager.dart';
import 'package:flutterquiz/core/offline/pending_operations.dart';

/// Local data source for Daily Contest with offline support
class DailyContestLocalDataSource {
  final CacheManager _cache = CacheManager.instance;
  final PendingOperationsQueue _pendingOps = PendingOperationsQueue.instance;

  // ============================================
  // Today's Contest
  // ============================================

  /// Cache today's daily contest data
  Future<void> cacheTodayContest(Map<String, dynamic> contestData) async {
    final today = _getTodayKey();
    await _cache.cache(CacheKeys.dailyContestDate(today), contestData);
  }

  /// Get cached today's contest
  Future<Map<String, dynamic>?> getCachedTodayContest() async {
    final today = _getTodayKey();
    return _cache.get(
      CacheKeys.dailyContestDate(today),
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Check if today's contest is cached
  Future<bool> hasTodayContest() async {
    final today = _getTodayKey();
    return _cache.has(CacheKeys.dailyContestDate(today));
  }

  // ============================================
  // Contest Status
  // ============================================

  /// Cache contest status
  Future<void> cacheContestStatus(Map<String, dynamic> status) async {
    await _cache.cache('daily_contest_status', status);
  }

  /// Get cached contest status
  Future<Map<String, dynamic>?> getCachedContestStatus() async {
    return _cache.get(
      'daily_contest_status',
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Clear contest status cache (call after submission)
  Future<void> clearContestStatusCache() async {
    await _cache.clear('daily_contest_status');
  }

  // ============================================
  // Pending Submissions
  // ============================================

  /// Queue a daily contest submission for when online
  Future<String> queueSubmission({
    required String contestId,
    required List<Map<String, dynamic>> answers,
    required bool readText,
  }) async {
    return _pendingOps.queue(
      OperationType.submitDailyContest,
      {
        'contestId': contestId,
        'answers': answers,
        'readText': readText,
        'queuedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get all pending contest submissions
  Future<List<PendingOperation>> getPendingSubmissions() async {
    return _pendingOps.getByType(OperationType.submitDailyContest);
  }

  /// Check if there are pending submissions
  Future<bool> hasPendingSubmissions() async {
    final pending = await getPendingSubmissions();
    return pending.isNotEmpty;
  }

  /// Mark a submission as completed
  Future<void> completeSubmission(String operationId) async {
    await _pendingOps.complete(operationId);
  }

  // ============================================
  // User's Contest Progress (for resume)
  // ============================================

  /// Save user's progress in a contest (for resume if app closes)
  Future<void> saveProgress({
    required String contestId,
    required int currentQuestionIndex,
    required List<Map<String, dynamic>> answeredQuestions,
    required int remainingTime,
  }) async {
    await _cache.cache('daily_contest_progress_$contestId', {
      'contestId': contestId,
      'currentQuestionIndex': currentQuestionIndex,
      'answeredQuestions': answeredQuestions,
      'remainingTime': remainingTime,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get saved progress
  Future<Map<String, dynamic>?> getSavedProgress(String contestId) async {
    return _cache.get(
      'daily_contest_progress_$contestId',
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Clear saved progress
  Future<void> clearProgress(String contestId) async {
    await _cache.clear('daily_contest_progress_$contestId');
  }

  // ============================================
  // Utility
  // ============================================

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Clear old contest cache (older than 7 days)
  Future<void> clearOldCache() async {
    final keys = await _cache.getAllKeys();
    final now = DateTime.now();
    
    for (final key in keys) {
      if (key.startsWith('daily_contest_')) {
        final cachedAt = await _cache.getCachedAt(key);
        if (cachedAt != null && now.difference(cachedAt).inDays > 7) {
          await _cache.clear(key);
        }
      }
    }
  }

  /// Clear all daily contest cache
  Future<void> clearAll() async {
    final keys = await _cache.getAllKeys();
    for (final key in keys) {
      if (key.startsWith('daily_contest')) {
        await _cache.clear(key);
      }
    }
  }
}

