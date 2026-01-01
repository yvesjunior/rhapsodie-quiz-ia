import 'package:flutterquiz/core/offline/cache_manager.dart';

/// Local data source for Statistics with offline support
class StatisticLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  // ============================================
  // User Statistics
  // ============================================

  /// Cache user statistics
  Future<void> cacheStatistics(Map<String, dynamic> statistics) async {
    await _cache.cache(CacheKeys.statistics, statistics);
  }

  /// Get cached statistics
  Future<Map<String, dynamic>?> getCachedStatistics() async {
    return _cache.get(
      CacheKeys.statistics,
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Check if statistics are cached
  Future<bool> hasStatistics() => _cache.has(CacheKeys.statistics);

  // ============================================
  // Battle Statistics
  // ============================================

  /// Cache battle statistics
  Future<void> cacheBattleStatistics(Map<String, dynamic> battleStats) async {
    await _cache.cache('battle_statistics', battleStats);
  }

  /// Get cached battle statistics
  Future<Map<String, dynamic>?> getCachedBattleStatistics() async {
    return _cache.get(
      'battle_statistics',
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Check if battle statistics are cached
  Future<bool> hasBattleStatistics() => _cache.has('battle_statistics');

  // ============================================
  // Utility
  // ============================================

  /// Clear all statistics cache
  Future<void> clearAll() async {
    await _cache.clear(CacheKeys.statistics);
    await _cache.clear('battle_statistics');
  }
}

