import 'package:flutterquiz/core/offline/cache_manager.dart';
import 'package:flutterquiz/features/badges/models/badge.dart';

/// Local data source for Badges with offline support
class BadgesLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  // ============================================
  // Badges
  // ============================================

  /// Cache user badges
  Future<void> cacheBadges(List<Badges> badges) async {
    await _cache.cacheList(
      CacheKeys.badges,
      badges,
      (badge) => {
        'id': badge.id,
        'type': badge.type,
        'badge_reward': badge.badgeReward,
        'badge_icon': badge.badgeIcon,
        'badge_counter': badge.badgeCounter,
        'status': badge.status.value,
      },
    );
  }

  /// Get cached badges
  Future<List<Badges>?> getCachedBadges() async {
    return _cache.getList(
      CacheKeys.badges,
      (json) => Badges.fromJson(json),
    );
  }

  /// Check if badges are cached
  Future<bool> hasBadges() => _cache.has(CacheKeys.badges);

  // ============================================
  // Utility
  // ============================================

  /// Clear all badges cache
  Future<void> clearAll() async {
    await _cache.clear(CacheKeys.badges);
  }
}

