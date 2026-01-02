import 'dart:convert';

import 'package:flutterquiz/core/offline/cache_manager.dart';

/// Local data source for caching leaderboard data
class LeaderboardLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  static const _keyAllTime = 'leaderboard_all_time';
  static const _keyMonthly = 'leaderboard_monthly';
  static const _keyWeekly = 'leaderboard_weekly';
  static const _keyDaily = 'leaderboard_daily';
  static const _keyMyRankAllTime = 'leaderboard_my_rank_all_time';
  static const _keyMyRankMonthly = 'leaderboard_my_rank_monthly';
  static const _keyMyRankWeekly = 'leaderboard_my_rank_weekly';
  static const _keyMyRankDaily = 'leaderboard_my_rank_daily';

  /// Decode a JSON string to Map
  Map<String, dynamic>? _decode(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // All Time Leaderboard
  // ============================================

  Future<void> cacheAllTimeLeaderboard(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> myRank,
    int total,
  ) async {
    await _cache.cache(_keyAllTime, {
      'data': data,
      'total': total,
    });
    await _cache.cache(_keyMyRankAllTime, myRank);
  }

  Future<Map<String, dynamic>?> getCachedAllTimeLeaderboard() async {
    final raw = await _cache.getRaw(_keyAllTime);
    return _decode(raw);
  }

  Future<Map<String, dynamic>?> getCachedAllTimeMyRank() async {
    final raw = await _cache.getRaw(_keyMyRankAllTime);
    return _decode(raw);
  }

  // ============================================
  // Monthly Leaderboard
  // ============================================

  Future<void> cacheMonthlyLeaderboard(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> myRank,
    int total,
  ) async {
    await _cache.cache(_keyMonthly, {
      'data': data,
      'total': total,
    });
    await _cache.cache(_keyMyRankMonthly, myRank);
  }

  Future<Map<String, dynamic>?> getCachedMonthlyLeaderboard() async {
    final raw = await _cache.getRaw(_keyMonthly);
    return _decode(raw);
  }

  Future<Map<String, dynamic>?> getCachedMonthlyMyRank() async {
    final raw = await _cache.getRaw(_keyMyRankMonthly);
    return _decode(raw);
  }

  // ============================================
  // Weekly Leaderboard
  // ============================================

  Future<void> cacheWeeklyLeaderboard(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> myRank,
    int total,
  ) async {
    await _cache.cache(_keyWeekly, {
      'data': data,
      'total': total,
    });
    await _cache.cache(_keyMyRankWeekly, myRank);
  }

  Future<Map<String, dynamic>?> getCachedWeeklyLeaderboard() async {
    final raw = await _cache.getRaw(_keyWeekly);
    return _decode(raw);
  }

  Future<Map<String, dynamic>?> getCachedWeeklyMyRank() async {
    final raw = await _cache.getRaw(_keyMyRankWeekly);
    return _decode(raw);
  }

  // ============================================
  // Daily Leaderboard
  // ============================================

  Future<void> cacheDailyLeaderboard(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> myRank,
    int total,
  ) async {
    await _cache.cache(_keyDaily, {
      'data': data,
      'total': total,
    });
    await _cache.cache(_keyMyRankDaily, myRank);
  }

  Future<Map<String, dynamic>?> getCachedDailyLeaderboard() async {
    final raw = await _cache.getRaw(_keyDaily);
    return _decode(raw);
  }

  Future<Map<String, dynamic>?> getCachedDailyMyRank() async {
    final raw = await _cache.getRaw(_keyMyRankDaily);
    return _decode(raw);
  }

  // ============================================
  // Clear
  // ============================================

  Future<void> clearAll() async {
    await _cache.clear(_keyAllTime);
    await _cache.clear(_keyMonthly);
    await _cache.clear(_keyWeekly);
    await _cache.clear(_keyDaily);
    await _cache.clear(_keyMyRankAllTime);
    await _cache.clear(_keyMyRankMonthly);
    await _cache.clear(_keyMyRankWeekly);
    await _cache.clear(_keyMyRankDaily);
  }
}

