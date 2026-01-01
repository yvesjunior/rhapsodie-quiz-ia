import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

/// Hive box name for cached data
const String _cacheBoxName = 'offline_cache';

/// Metadata suffix for storing cache timestamps
const String _metaSuffix = '_meta';

/// Generic cache manager using Hive for local storage
/// 
/// Provides methods to cache, retrieve, and clear data with optional
/// timestamp tracking for cache invalidation.
class CacheManager {
  static CacheManager? _instance;
  Box<String>? _cacheBox;

  CacheManager._();

  /// Singleton instance
  static CacheManager get instance {
    _instance ??= CacheManager._();
    return _instance!;
  }

  /// Initialize the cache box (call in main.dart)
  Future<void> init() async {
    if (_cacheBox != null && _cacheBox!.isOpen) return;
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    log('CacheManager initialized');
  }

  /// Get the cache box, initializing if needed
  Future<Box<String>> get _box async {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      await init();
    }
    return _cacheBox!;
  }

  /// Cache data with a key
  /// 
  /// [key] - Unique identifier for the cached data
  /// [data] - Data to cache (will be JSON encoded)
  Future<void> cache<T>(String key, T data) async {
    try {
      final box = await _box;
      final jsonString = jsonEncode(data);
      await box.put(key, jsonString);
      
      // Store metadata with timestamp
      final meta = {
        'cachedAt': DateTime.now().toIso8601String(),
        'type': T.toString(),
      };
      await box.put('$key$_metaSuffix', jsonEncode(meta));
      
      log('Cached: $key (${jsonString.length} bytes)');
    } catch (e) {
      log('Cache error for $key: $e');
    }
  }

  /// Cache a list of items
  Future<void> cacheList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final jsonList = items.map(toJson).toList();
    await cache(key, jsonList);
  }

  /// Get cached data
  /// 
  /// Returns null if not found or on error
  Future<T?> get<T>(String key, T Function(dynamic json) fromJson) async {
    try {
      final box = await _box;
      final jsonString = box.get(key);
      
      if (jsonString == null) {
        log('Cache miss: $key');
        return null;
      }
      
      final decoded = jsonDecode(jsonString);
      log('Cache hit: $key');
      return fromJson(decoded);
    } catch (e) {
      log('Cache get error for $key: $e');
      return null;
    }
  }

  /// Get cached list of items
  Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final box = await _box;
      final jsonString = box.get(key);
      
      if (jsonString == null) {
        log('Cache miss: $key');
        return null;
      }
      
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final items = decoded
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      
      log('Cache hit: $key (${items.length} items)');
      return items;
    } catch (e) {
      log('Cache getList error for $key: $e');
      return null;
    }
  }

  /// Get raw JSON string from cache
  Future<String?> getRaw(String key) async {
    final box = await _box;
    return box.get(key);
  }

  /// Check if a key exists in cache
  Future<bool> has(String key) async {
    final box = await _box;
    return box.containsKey(key);
  }

  /// Get the timestamp when data was cached
  Future<DateTime?> getCachedAt(String key) async {
    try {
      final box = await _box;
      final metaString = box.get('$key$_metaSuffix');
      
      if (metaString == null) return null;
      
      final meta = jsonDecode(metaString) as Map<String, dynamic>;
      return DateTime.parse(meta['cachedAt'] as String);
    } catch (e) {
      return null;
    }
  }

  /// Check if cached data is older than [duration]
  Future<bool> isStale(String key, Duration duration) async {
    final cachedAt = await getCachedAt(key);
    if (cachedAt == null) return true;
    
    return DateTime.now().difference(cachedAt) > duration;
  }

  /// Clear specific cached data
  Future<void> clear(String key) async {
    final box = await _box;
    await box.delete(key);
    await box.delete('$key$_metaSuffix');
    log('Cleared cache: $key');
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
    log('Cleared all cache');
  }

  /// Get all cache keys (excluding metadata)
  Future<List<String>> getAllKeys() async {
    final box = await _box;
    return box.keys
        .cast<String>()
        .where((k) => !k.endsWith(_metaSuffix))
        .toList();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final box = await _box;
    final keys = await getAllKeys();
    var totalSize = 0;
    
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        totalSize += value.length;
      }
    }
    
    return {
      'entries': keys.length,
      'totalSizeBytes': totalSize,
      'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
    };
  }
}

/// Cache keys for different data types
class CacheKeys {
  CacheKeys._();

  // System
  static const String systemConfig = 'system_config';
  static const String languages = 'languages';
  
  // User
  static const String userProfile = 'user_profile';
  static const String statistics = 'user_statistics';
  
  // Badges
  static const String badges = 'user_badges';
  
  // Rhapsody
  static const String rhapsodyYears = 'rhapsody_years';
  static String rhapsodyMonths(int year) => 'rhapsody_months_$year';
  static String rhapsodyDays(int year, int month) => 'rhapsody_days_${year}_$month';
  static String rhapsodyDetail(int year, int month, int day) => 
      'rhapsody_detail_${year}_${month}_$day';
  
  // Quiz
  static const String quizCategories = 'quiz_categories';
  static String quizSubCategories(String categoryId) => 
      'quiz_subcategories_$categoryId';
  static String quizQuestions(String categoryId) => 
      'quiz_questions_$categoryId';
  
  // Topics
  static const String topics = 'topics';
  static String topicCategories(String topicId) => 
      'topic_categories_$topicId';
  
  // Foundation School
  static const String foundationClasses = 'foundation_classes';
  static String foundationClassDetail(String classId) => 
      'foundation_class_detail_$classId';
  
  // Daily Contest
  static const String dailyContest = 'daily_contest';
  static String dailyContestDate(String date) => 'daily_contest_$date';
}

