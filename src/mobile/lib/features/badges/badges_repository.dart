import 'dart:developer';

import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/features/badges/badges_local_data_source.dart';
import 'package:flutterquiz/features/badges/badges_remote_data_source.dart';
import 'package:flutterquiz/features/badges/models/badge.dart';

final class BadgesRepository {
  factory BadgesRepository({ConnectivityCubit? connectivityCubit}) {
    _badgesRepository._badgesRemoteDataSource = BadgesRemoteDataSource();
    _badgesRepository._localDataSource = BadgesLocalDataSource();
    _badgesRepository._connectivityCubit = connectivityCubit;
    return _badgesRepository;
  }

  BadgesRepository._internal();

  static final _badgesRepository = BadgesRepository._internal();
  late BadgesRemoteDataSource _badgesRemoteDataSource;
  late BadgesLocalDataSource _localDataSource;
  ConnectivityCubit? _connectivityCubit;

  /// Check if we're currently online
  bool get _isOnline => _connectivityCubit?.isOnline ?? true;

  /// Get user badges (offline-first)
  Future<List<Badges>> getBadges({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = await _localDataSource.getCachedBadges();
      if (cached != null && cached.isNotEmpty) {
        log('Badges: returning ${cached.length} cached');
        
        if (_isOnline) {
          _refreshBadgesInBackground();
        }
        
        return cached;
      }
    }

    // Fetch from remote
    if (_isOnline) {
      try {
        final result = await _badgesRemoteDataSource.getBadges();
        final badges = result.map(Badges.fromJson).toList();
        await _localDataSource.cacheBadges(badges);
        log('Badges: fetched ${badges.length} from remote');
        return badges;
      } catch (e) {
        log('Error fetching badges: $e');
        final cached = await _localDataSource.getCachedBadges();
        if (cached != null) return cached;
        rethrow;
      }
    }

    // Offline
    final cached = await _localDataSource.getCachedBadges();
    if (cached != null) return cached;
    throw Exception('No cached badges available offline');
  }

  Future<void> _refreshBadgesInBackground() async {
    try {
      final result = await _badgesRemoteDataSource.getBadges();
      final badges = result.map(Badges.fromJson).toList();
      await _localDataSource.cacheBadges(badges);
    } catch (e) {
      log('Background refresh badges error: $e');
    }
  }

  /// Clear cached badges
  Future<void> clearCache() => _localDataSource.clearAll();
}
