import 'dart:developer';
import 'dart:io';

import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/features/rhapsody/models/rhapsody_models.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody_local_data_source.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody_remote_data_source.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';

/// Repository for Rhapsody content with offline-first support
/// 
/// Strategy:
/// 1. Return cached data immediately if available
/// 2. If online, fetch fresh data and update cache
/// 3. If offline, return cached data only
class RhapsodyRepository {
  RhapsodyRepository({
    RhapsodyRemoteDataSource? remoteDataSource,
    RhapsodyLocalDataSource? localDataSource,
    this.connectivityCubit,
  })  : _remote = remoteDataSource ?? RhapsodyRemoteDataSource(),
        _local = localDataSource ?? RhapsodyLocalDataSource();

  final RhapsodyRemoteDataSource _remote;
  final RhapsodyLocalDataSource _local;
  final ConnectivityCubit? connectivityCubit;

  /// Check if we're currently online
  bool get _isOnline => connectivityCubit?.isOnline ?? true;

  // ============================================
  // Years
  // ============================================

  /// Get all Rhapsody years (offline-first)
  Future<List<RhapsodyYear>> getYears({bool forceRefresh = false}) async {
    // 1. Try to get cached data first (ALWAYS check cache)
    final cached = await _local.getCachedYears();
    
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      log('Rhapsody years: returning ${cached.length} cached items');
      
      // Refresh in background if online
      if (_isOnline) {
        _refreshYearsInBackground();
      }
      
      return cached;
    }

    // 2. If no cache or force refresh, try to fetch from remote
    try {
      final years = await _remote.getRhapsodyYears();
      await _local.cacheYears(years);
      log('Rhapsody years: fetched ${years.length} from remote');
      return years;
    } on SocketException catch (e) {
      log('Network error fetching years: $e');
      // Return cache on network error
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000'); // noInternet
    } on ApiException {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching years: $e');
      // Fall back to cache on any error
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000'); // noInternet
    }
  }

  Future<void> _refreshYearsInBackground() async {
    try {
      final years = await _remote.getRhapsodyYears();
      await _local.cacheYears(years);
      log('Rhapsody years: background refresh complete');
    } catch (e) {
      log('Background refresh years error: $e');
    }
  }

  // ============================================
  // Months
  // ============================================

  /// Get Rhapsody months for a year (offline-first)
  Future<List<RhapsodyMonth>> getMonths(int year, {bool forceRefresh = false}) async {
    // 1. Try cache first (ALWAYS check cache)
    final cached = await _local.getCachedMonths(year);
    
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      log('Rhapsody months ($year): returning ${cached.length} cached items');
      
      if (_isOnline) {
        _refreshMonthsInBackground(year);
      }
      
      return cached;
    }

    // 2. Try to fetch from remote
    try {
      final months = await _remote.getRhapsodyMonths(year);
      await _local.cacheMonths(year, months);
      log('Rhapsody months ($year): fetched ${months.length} from remote');
      return months;
    } on SocketException catch (e) {
      log('Network error fetching months: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    } on ApiException {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching months: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    }
  }

  Future<void> _refreshMonthsInBackground(int year) async {
    try {
      final months = await _remote.getRhapsodyMonths(year);
      await _local.cacheMonths(year, months);
    } catch (e) {
      log('Background refresh months error: $e');
    }
  }

  // ============================================
  // Days
  // ============================================

  /// Get Rhapsody days for a month (offline-first)
  Future<List<RhapsodyDay>> getDays(int year, int month, {bool forceRefresh = false}) async {
    // 1. Try cache first (ALWAYS check cache)
    final cached = await _local.getCachedDays(year, month);
    
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      log('Rhapsody days ($year/$month): returning ${cached.length} cached items');
      
      if (_isOnline) {
        _refreshDaysInBackground(year, month);
      }
      
      return cached;
    }

    // 2. Try to fetch from remote
    try {
      final days = await _remote.getRhapsodyDays(year, month);
      await _local.cacheDays(year, month, days);
      log('Rhapsody days ($year/$month): fetched ${days.length} from remote');
      return days;
    } on SocketException catch (e) {
      log('Network error fetching days: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    } on ApiException {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching days: $e');
      if (cached != null && cached.isNotEmpty) return cached;
      throw const ApiException('000');
    }
  }

  Future<void> _refreshDaysInBackground(int year, int month) async {
    try {
      final days = await _remote.getRhapsodyDays(year, month);
      await _local.cacheDays(year, month, days);
    } catch (e) {
      log('Background refresh days error: $e');
    }
  }

  // ============================================
  // Day Detail
  // ============================================

  /// Get full Rhapsody day detail (offline-first)
  Future<RhapsodyDayDetail?> getDayDetail(
    int year, 
    int month, 
    int day, 
    {bool forceRefresh = false}
  ) async {
    // 1. Try cache first (ALWAYS check cache)
    final cached = await _local.getCachedDayDetail(year, month, day);
    
    if (!forceRefresh && cached != null) {
      log('Rhapsody detail ($year/$month/$day): returning cached');
      
      if (_isOnline) {
        _refreshDayDetailInBackground(year, month, day);
      }
      
      return cached;
    }

    // 2. Try to fetch from remote
    try {
      final detail = await _remote.getRhapsodyDayDetail(year, month, day);
      if (detail != null) {
        await _local.cacheDayDetail(detail);
        log('Rhapsody detail ($year/$month/$day): fetched from remote');
      }
      return detail;
    } on SocketException catch (e) {
      log('Network error fetching day detail: $e');
      if (cached != null) return cached;
      return null; // No cache, no network
    } on ApiException {
      if (cached != null) return cached;
      rethrow;
    } catch (e) {
      log('Error fetching day detail: $e');
      if (cached != null) return cached;
      return null;
    }
  }

  Future<void> _refreshDayDetailInBackground(int year, int month, int day) async {
    try {
      final detail = await _remote.getRhapsodyDayDetail(year, month, day);
      if (detail != null) {
        await _local.cacheDayDetail(detail);
      }
    } catch (e) {
      log('Background refresh day detail error: $e');
    }
  }

  // ============================================
  // Utility
  // ============================================

  /// Prefetch and cache Rhapsody content for offline use
  /// 
  /// Downloads years, current month's days, and today's detail
  Future<void> prefetchForOffline() async {
    if (!_isOnline) return;

    log('Prefetching Rhapsody content for offline...');
    
    try {
      // Fetch years
      final years = await _remote.getRhapsodyYears();
      await _local.cacheYears(years);

      // Fetch current month
      final now = DateTime.now();
      final months = await _remote.getRhapsodyMonths(now.year);
      await _local.cacheMonths(now.year, months);

      // Fetch current month's days
      final days = await _remote.getRhapsodyDays(now.year, now.month);
      await _local.cacheDays(now.year, now.month, days);

      // Fetch today's detail
      final detail = await _remote.getRhapsodyDayDetail(now.year, now.month, now.day);
      if (detail != null) {
        await _local.cacheDayDetail(detail);
      }

      log('Prefetch complete');
    } catch (e) {
      log('Prefetch error: $e');
    }
  }

  /// Check if content is available offline
  Future<bool> isAvailableOffline(int year, int month, int day) async {
    return _local.hasDayDetail(year, month, day);
  }

  /// Clear all cached Rhapsody content
  Future<void> clearCache() => _local.clearAll();

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() => _local.getStats();
}

