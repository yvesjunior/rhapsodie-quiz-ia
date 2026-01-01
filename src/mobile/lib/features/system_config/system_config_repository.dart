import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/system_config/model/supported_question_language.dart';
import 'package:flutterquiz/features/system_config/model/system_config_model.dart';
import 'package:flutterquiz/features/system_config/model/system_language.dart';
import 'package:flutterquiz/features/system_config/system_config_local_data_source.dart';
import 'package:flutterquiz/features/system_config/system_config_remote_data_source.dart';

final class SystemConfigRepository {
  factory SystemConfigRepository() {
    _systemConfigRepository._systemConfigRemoteDataSource =
        SystemConfigRemoteDataSource();
    _systemConfigRepository._localDataSource = SystemConfigLocalDataSource();
    return _systemConfigRepository;
  }

  SystemConfigRepository._internal();

  static final SystemConfigRepository _systemConfigRepository =
      SystemConfigRepository._internal();
  late SystemConfigRemoteDataSource _systemConfigRemoteDataSource;
  late SystemConfigLocalDataSource _localDataSource;

  /// Get system configuration (offline-first)
  /// 
  /// For first launch (no cache), always tries to fetch from server.
  /// Throws [ApiException] with proper error code if fails.
  Future<SystemConfigModel> getSystemConfig({bool forceRefresh = false}) async {
    // Try cache first (skip for first launch or force refresh)
    if (!forceRefresh) {
      final cached = await _localDataSource.getCachedSystemConfig();
      if (cached != null) {
        log('System config: returning cached');
        
        // Refresh in background if online (don't wait)
        _refreshConfigInBackground();
        
        return SystemConfigModel.fromJson(cached);
      }
    }

    // No cache available - must fetch from server
    // This is the first launch scenario
    log('System config: no cache, fetching from server...');
    
    try {
      final result = await _systemConfigRemoteDataSource.getSystemConfig();
      await _localDataSource.cacheSystemConfig(result);
      log('System config: fetched and cached from remote');
      return SystemConfigModel.fromJson(result);
    } on SocketException catch (e) {
      log('System config: network error - $e');
      // Check if there's a cache as fallback
      final cached = await _localDataSource.getCachedSystemConfig();
      if (cached != null) {
        log('System config: falling back to cache after network error');
        return SystemConfigModel.fromJson(cached);
      }
      // No cache, no network - throw proper error
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      // API returned an error
      final cached = await _localDataSource.getCachedSystemConfig();
      if (cached != null) return SystemConfigModel.fromJson(cached);
      rethrow;
    } on Exception catch (e) {
      log('System config: unexpected error - $e');
      final cached = await _localDataSource.getCachedSystemConfig();
      if (cached != null) return SystemConfigModel.fromJson(cached);
      // Generic error - could be server unreachable
      throw const ApiException(errorCodeNoInternet);
    }
  }

  Future<void> _refreshConfigInBackground() async {
    try {
      final result = await _systemConfigRemoteDataSource.getSystemConfig();
      await _localDataSource.cacheSystemConfig(result);
    } on Exception catch (e) {
      log('Background refresh config error: $e');
    }
  }

  Future<List<QuizLanguage>> getSupportedQuestionLanguages() async {
    final result = await _systemConfigRemoteDataSource
        .getSupportedQuestionLanguages();
    return result.map((e) => QuizLanguage.fromJson(Map.from(e))).toList();
  }

  Future<List<SystemLanguage>> getSupportedLanguageList() async {
    final result = await _systemConfigRemoteDataSource
        .getSupportedLanguageList();

    return result.map(SystemLanguage.fromJson).toList();
  }

  Future<String> getAppSettings(String type) async {
    return _systemConfigRemoteDataSource.getAppSettings(type);
  }

  Future<List<String>> getProfileImages() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = assetManifest.listAssets();

      const path = Assets.profileImagesPath;

      // Filter for images in the profile directory
      final profileImages =
          assets
              .where((asset) => asset.startsWith(path))
              .map((asset) => asset.split('/').last)
              .toList()
            ..sort((a, b) => a.compareTo(b));

      // Validate that we found some images
      if (profileImages.isEmpty) {
        throw const ApiException('No images found in $path');
      }

      return profileImages;
    } on FormatException catch (e) {
      throw ApiException('Failed to parse AssetManifest.json: ${e.message}');
    } on PlatformException catch (e) {
      throw ApiException('Failed to load AssetManifest.json: ${e.message}');
    } on Exception catch (e) {
      throw ApiException('Unexpected error loading images: $e');
    }
  }

  Future<List<String>> getEmojiImages() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = assetManifest.listAssets();

      const path = Assets.emojisPath;

      // Filter for PNG files in the profile directory
      final profileImages =
          assets
              .where((asset) => asset.startsWith(path))
              .map((asset) => asset.split('/').last)
              .toList()
            ..sort((a, b) => a.compareTo(b));

      // Validate that we found some images
      if (profileImages.isEmpty) {
        throw const ApiException('No images found in $path');
      }

      return profileImages;
    } on FormatException catch (e) {
      throw ApiException('Failed to parse AssetManifest.json: ${e.message}');
    } on PlatformException catch (e) {
      throw ApiException('Failed to load AssetManifest.json: ${e.message}');
    } on Exception catch (e) {
      throw ApiException('Unexpected error loading images: $e');
    }
  }
}
