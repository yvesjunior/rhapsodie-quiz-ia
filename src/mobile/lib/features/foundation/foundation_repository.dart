import 'dart:developer';
import 'dart:io';

import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/features/foundation/foundation_local_data_source.dart';
import 'package:flutterquiz/features/foundation/foundation_remote_data_source.dart';
import 'package:flutterquiz/features/foundation/models/foundation_models.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';

/// Repository for Foundation School with offline-first support
class FoundationRepository {
  final FoundationRemoteDataSource _remoteDataSource;
  final FoundationLocalDataSource _localDataSource;
  final ConnectivityCubit? _connectivityCubit;

  FoundationRepository({
    FoundationRemoteDataSource? remoteDataSource,
    FoundationLocalDataSource? localDataSource,
    ConnectivityCubit? connectivityCubit,
  })  : _remoteDataSource = remoteDataSource ?? FoundationRemoteDataSource(),
        _localDataSource = localDataSource ?? FoundationLocalDataSource(),
        _connectivityCubit = connectivityCubit;

  /// Check if we're currently online
  bool get _isOnline => _connectivityCubit?.isOnline ?? true;

  /// Get Foundation classes (offline-first)
  Future<List<FoundationClass>> getClasses({bool forceRefresh = false}) async {
    // Try cache first (ALWAYS check cache)
    final cached = await _localDataSource.getCachedClasses();
    
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      log('Foundation classes: returning ${cached.length} cached');
      
      if (_isOnline) {
        _refreshClassesInBackground();
      }
      
      return cached;
    }

    // Try to fetch from remote
    try {
      final classes = await _remoteDataSource.getFoundationClasses();
      await _localDataSource.cacheClasses(classes);
      log('Foundation classes: fetched ${classes.length} from remote');
      return classes;
    } on SocketException catch (e) {
      log('Network error fetching foundation classes: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    } on ApiException {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching foundation classes: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    }
  }

  Future<void> _refreshClassesInBackground() async {
    try {
      final classes = await _remoteDataSource.getFoundationClasses();
      await _localDataSource.cacheClasses(classes);
    } catch (e) {
      log('Background refresh foundation classes error: $e');
    }
  }

  /// Get class detail (offline-first)
  Future<FoundationClass> getClassDetail(
    String classId, {
    bool forceRefresh = false,
  }) async {
    // Try cache first (ALWAYS check cache)
    final cached = await _localDataSource.getCachedClassDetail(classId);
    
    if (!forceRefresh && cached != null) {
      log('Foundation class detail ($classId): returning cached');
      
      if (_isOnline) {
        _refreshClassDetailInBackground(classId);
      }
      
      return cached;
    }

    // Try to fetch from remote
    try {
      final classDetail = await _remoteDataSource.getFoundationClassDetail(classId);
      await _localDataSource.cacheClassDetail(classDetail);
      log('Foundation class detail ($classId): fetched from remote');
      return classDetail;
    } on SocketException catch (e) {
      log('Network error fetching foundation class detail: $e');
      if (cached != null) return cached;
      throw const ApiException('000');
    } on ApiException {
      if (cached != null) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching foundation class detail: $e');
      if (cached != null) return cached;
      throw const ApiException('000');
    }
  }

  Future<void> _refreshClassDetailInBackground(String classId) async {
    try {
      final classDetail = await _remoteDataSource.getFoundationClassDetail(classId);
      await _localDataSource.cacheClassDetail(classDetail);
    } catch (e) {
      log('Background refresh foundation class detail error: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() => _localDataSource.clearAll();
}

