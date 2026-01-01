import 'package:flutterquiz/core/offline/cache_manager.dart';
import 'package:flutterquiz/features/foundation/models/foundation_models.dart';

/// Local data source for Foundation School content with offline support
class FoundationLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  // ============================================
  // Foundation Classes
  // ============================================

  /// Cache foundation classes list
  Future<void> cacheClasses(List<FoundationClass> classes) async {
    await _cache.cacheList(
      CacheKeys.foundationClasses,
      classes,
      (cls) => {
        'id': cls.id,
        'name': cls.name,
        'title': cls.title,
        'content_text': cls.contentText,
        'row_order': cls.rowOrder.toString(),
        'questions_count': cls.questionsCount.toString(),
        'user_progress': cls.userProgress != null
            ? {
                'status': cls.userProgress!.status,
                'progress_percent': cls.userProgress!.progressPercent.toString(),
                'score': cls.userProgress!.score.toString(),
                'completed_at': cls.userProgress!.completedAt,
              }
            : null,
      },
    );
  }

  /// Get cached foundation classes
  Future<List<FoundationClass>?> getCachedClasses() async {
    return _cache.getList(
      CacheKeys.foundationClasses,
      (json) => FoundationClass.fromJson(json),
    );
  }

  /// Check if classes are cached
  Future<bool> hasClasses() => _cache.has(CacheKeys.foundationClasses);

  // ============================================
  // Class Details
  // ============================================

  /// Cache a class detail
  Future<void> cacheClassDetail(FoundationClass classDetail) async {
    await _cache.cache(
      CacheKeys.foundationClassDetail(classDetail.id),
      {
        'id': classDetail.id,
        'name': classDetail.name,
        'title': classDetail.title,
        'content_text': classDetail.contentText,
        'row_order': classDetail.rowOrder.toString(),
        'questions_count': classDetail.questionsCount.toString(),
        'user_progress': classDetail.userProgress != null
            ? {
                'status': classDetail.userProgress!.status,
                'progress_percent': classDetail.userProgress!.progressPercent.toString(),
                'score': classDetail.userProgress!.score.toString(),
                'completed_at': classDetail.userProgress!.completedAt,
              }
            : null,
      },
    );
  }

  /// Get cached class detail
  Future<FoundationClass?> getCachedClassDetail(String classId) async {
    return _cache.get(
      CacheKeys.foundationClassDetail(classId),
      (json) => FoundationClass.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Check if a class detail is cached
  Future<bool> hasClassDetail(String classId) =>
      _cache.has(CacheKeys.foundationClassDetail(classId));

  // ============================================
  // Utility
  // ============================================

  /// Clear all foundation cache
  Future<void> clearAll() async {
    final keys = await _cache.getAllKeys();
    for (final key in keys) {
      if (key.startsWith('foundation')) {
        await _cache.clear(key);
      }
    }
  }
}

