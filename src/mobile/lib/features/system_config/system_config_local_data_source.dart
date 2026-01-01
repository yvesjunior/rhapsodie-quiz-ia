import 'package:flutterquiz/core/offline/cache_manager.dart';

/// Local data source for System Configuration with offline support
/// 
/// This is critical for app startup - the app needs config to function
class SystemConfigLocalDataSource {
  final CacheManager _cache = CacheManager.instance;

  // ============================================
  // System Configuration
  // ============================================

  /// Cache system configuration
  Future<void> cacheSystemConfig(Map<String, dynamic> config) async {
    await _cache.cache(CacheKeys.systemConfig, config);
  }

  /// Get cached system configuration
  Future<Map<String, dynamic>?> getCachedSystemConfig() async {
    return _cache.get(
      CacheKeys.systemConfig,
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Check if system config is cached
  Future<bool> hasSystemConfig() => _cache.has(CacheKeys.systemConfig);

  // ============================================
  // Languages
  // ============================================

  /// Cache supported languages
  Future<void> cacheLanguages(List<Map<String, dynamic>> languages) async {
    await _cache.cache(CacheKeys.languages, languages);
  }

  /// Get cached languages
  Future<List<Map<String, dynamic>>?> getCachedLanguages() async {
    return _cache.get(
      CacheKeys.languages,
      (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Check if languages are cached
  Future<bool> hasLanguages() => _cache.has(CacheKeys.languages);

  // ============================================
  // App Settings
  // ============================================

  /// Cache app settings
  Future<void> cacheAppSettings(Map<String, dynamic> settings) async {
    await _cache.cache('app_settings', settings);
  }

  /// Get cached app settings
  Future<Map<String, dynamic>?> getCachedAppSettings() async {
    return _cache.get(
      'app_settings',
      (json) => json as Map<String, dynamic>,
    );
  }

  // ============================================
  // Utility
  // ============================================

  /// Clear all system config cache
  Future<void> clearAll() async {
    await _cache.clear(CacheKeys.systemConfig);
    await _cache.clear(CacheKeys.languages);
    await _cache.clear('app_settings');
  }
}

