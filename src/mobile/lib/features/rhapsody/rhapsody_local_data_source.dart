import 'package:flutterquiz/core/offline/cache_manager.dart';
import 'package:flutterquiz/features/rhapsody/models/rhapsody_models.dart';

/// Local data source for Rhapsody content using Hive cache
class RhapsodyLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  // ============================================
  // Years
  // ============================================

  /// Cache list of Rhapsody years
  Future<void> cacheYears(List<RhapsodyYear> years) async {
    await _cache.cacheList(
      CacheKeys.rhapsodyYears,
      years,
      (year) => {
        'id': year.id,
        'name': year.name,
        'year': year.year,
      },
    );
  }

  /// Get cached Rhapsody years
  Future<List<RhapsodyYear>?> getCachedYears() async {
    return _cache.getList(
      CacheKeys.rhapsodyYears,
      (json) => RhapsodyYear.fromJson(json),
    );
  }

  /// Check if years are cached
  Future<bool> hasYears() => _cache.has(CacheKeys.rhapsodyYears);

  // ============================================
  // Months
  // ============================================

  /// Cache list of Rhapsody months for a year
  Future<void> cacheMonths(int year, List<RhapsodyMonth> months) async {
    await _cache.cacheList(
      CacheKeys.rhapsodyMonths(year),
      months,
      (month) => {
        'id': month.id,
        'name': month.name,
        'month': month.month,
        'year': month.year,
        'image': month.image,
        'days_count': month.daysCount,
        'questions_count': month.questionsCount,
      },
    );
  }

  /// Get cached Rhapsody months for a year
  Future<List<RhapsodyMonth>?> getCachedMonths(int year) async {
    return _cache.getList(
      CacheKeys.rhapsodyMonths(year),
      (json) => RhapsodyMonth.fromJson(json),
    );
  }

  /// Check if months for a year are cached
  Future<bool> hasMonths(int year) => _cache.has(CacheKeys.rhapsodyMonths(year));

  // ============================================
  // Days
  // ============================================

  /// Cache list of Rhapsody days for a month
  Future<void> cacheDays(int year, int month, List<RhapsodyDay> days) async {
    await _cache.cacheList(
      CacheKeys.rhapsodyDays(year, month),
      days,
      (day) => {
        'id': day.id,
        'name': day.name,
        'title': day.title,
        'day': day.day,
        'month': day.month,
        'year': day.year,
        'questions_count': day.questionsCount,
      },
    );
  }

  /// Get cached Rhapsody days for a month
  Future<List<RhapsodyDay>?> getCachedDays(int year, int month) async {
    return _cache.getList(
      CacheKeys.rhapsodyDays(year, month),
      (json) => RhapsodyDay.fromJson(json),
    );
  }

  /// Check if days for a month are cached
  Future<bool> hasDays(int year, int month) => 
      _cache.has(CacheKeys.rhapsodyDays(year, month));

  // ============================================
  // Day Detail
  // ============================================

  /// Cache full Rhapsody day detail
  Future<void> cacheDayDetail(RhapsodyDayDetail detail) async {
    await _cache.cache(
      CacheKeys.rhapsodyDetail(detail.year, detail.month, detail.day),
      {
        'id': detail.id,
        'name': detail.name,
        'title': detail.title,
        'daily_text': detail.dailyText,
        'scripture_ref': detail.scriptureRef,
        'content_text': detail.contentText,
        'prayer_text': detail.prayerText,
        'further_study': detail.furtherStudy,
        'day': detail.day,
        'month': detail.month,
        'year': detail.year,
        'questions_count': detail.questionsCount,
      },
    );
  }

  /// Get cached Rhapsody day detail
  Future<RhapsodyDayDetail?> getCachedDayDetail(int year, int month, int day) async {
    return _cache.get(
      CacheKeys.rhapsodyDetail(year, month, day),
      (json) => RhapsodyDayDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Check if day detail is cached
  Future<bool> hasDayDetail(int year, int month, int day) => 
      _cache.has(CacheKeys.rhapsodyDetail(year, month, day));

  // ============================================
  // Utility
  // ============================================

  /// Clear all Rhapsody cache
  Future<void> clearAll() async {
    final keys = await _cache.getAllKeys();
    for (final key in keys) {
      if (key.startsWith('rhapsody')) {
        await _cache.clear(key);
      }
    }
  }

  /// Get cache statistics for Rhapsody content
  Future<Map<String, dynamic>> getStats() async {
    final keys = await _cache.getAllKeys();
    final rhapsodyKeys = keys.where((k) => k.startsWith('rhapsody')).toList();
    
    return {
      'totalEntries': rhapsodyKeys.length,
      'years': rhapsodyKeys.where((k) => k == CacheKeys.rhapsodyYears).length,
      'months': rhapsodyKeys.where((k) => k.startsWith('rhapsody_months')).length,
      'days': rhapsodyKeys.where((k) => k.startsWith('rhapsody_days')).length,
      'details': rhapsodyKeys.where((k) => k.startsWith('rhapsody_detail')).length,
    };
  }
}

