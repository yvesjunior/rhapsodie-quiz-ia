import 'dart:developer';

import 'package:flutterquiz/core/offline/connectivity_cubit.dart';
import 'package:flutterquiz/features/statistic/models/statistic_model.dart';
import 'package:flutterquiz/features/statistic/statistic_local_data_source.dart';
import 'package:flutterquiz/features/statistic/statistic_remote_data_source.dart';

final class StatisticRepository {
  factory StatisticRepository({ConnectivityCubit? connectivityCubit}) {
    _statisticRepository._statisticRemoteDataSource =
        StatisticRemoteDataSource();
    _statisticRepository._localDataSource = StatisticLocalDataSource();
    _statisticRepository._connectivityCubit = connectivityCubit;

    return _statisticRepository;
  }

  StatisticRepository._internal();

  static final StatisticRepository _statisticRepository =
      StatisticRepository._internal();
  late StatisticRemoteDataSource _statisticRemoteDataSource;
  late StatisticLocalDataSource _localDataSource;
  ConnectivityCubit? _connectivityCubit;

  /// Check if we're currently online
  bool get _isOnline => _connectivityCubit?.isOnline ?? true;

  /// Get user statistics (offline-first)
  Future<StatisticModel> getStatistic({
    required bool getBattleStatistics,
    bool forceRefresh = false,
  }) async {
    // Try cache first
    if (!forceRefresh) {
      final cachedStats = await _localDataSource.getCachedStatistics();
      final cachedBattle = getBattleStatistics
          ? await _localDataSource.getCachedBattleStatistics()
          : null;

      if (cachedStats != null) {
        log('Statistics: returning cached');
        
        if (_isOnline) {
          _refreshStatisticsInBackground(getBattleStatistics);
        }
        
        return StatisticModel.fromJson(cachedStats, cachedBattle ?? {});
      }
    }

    // Fetch from remote
    if (_isOnline) {
      try {
        final result = await _statisticRemoteDataSource.getStatistic();
        await _localDataSource.cacheStatistics(result);

        if (getBattleStatistics) {
          final battleResult = await _statisticRemoteDataSource
              .getBattleStatistic();
          final battleStatistics = <String, dynamic>{};
          final myReports = (battleResult['myreport'] as List)
              .cast<Map<String, dynamic>>()
              .first;

          for (final element in myReports.keys) {
            battleStatistics.addAll({element: myReports[element]});
          }

          battleStatistics['playedBattles'] = (battleResult['data'] as List? ?? [])
              .cast<Map<String, dynamic>>();

          await _localDataSource.cacheBattleStatistics(battleStatistics);
          return StatisticModel.fromJson(result, battleStatistics);
        }
        return StatisticModel.fromJson(result, {});
      } catch (e) {
        log('Error fetching statistics: $e');
        final cachedStats = await _localDataSource.getCachedStatistics();
        final cachedBattle = await _localDataSource.getCachedBattleStatistics();
        if (cachedStats != null) {
          return StatisticModel.fromJson(cachedStats, cachedBattle ?? {});
        }
        rethrow;
      }
    }

    // Offline
    final cachedStats = await _localDataSource.getCachedStatistics();
    final cachedBattle = await _localDataSource.getCachedBattleStatistics();
    if (cachedStats != null) {
      return StatisticModel.fromJson(cachedStats, cachedBattle ?? {});
    }
    throw Exception('No cached statistics available offline');
  }

  Future<void> _refreshStatisticsInBackground(bool getBattleStatistics) async {
    try {
      final result = await _statisticRemoteDataSource.getStatistic();
      await _localDataSource.cacheStatistics(result);

      if (getBattleStatistics) {
        final battleResult = await _statisticRemoteDataSource
            .getBattleStatistic();
        final battleStatistics = <String, dynamic>{};
        final myReports = (battleResult['myreport'] as List)
            .cast<Map<String, dynamic>>()
            .first;

        for (final element in myReports.keys) {
          battleStatistics.addAll({element: myReports[element]});
        }

        battleStatistics['playedBattles'] = (battleResult['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();

        await _localDataSource.cacheBattleStatistics(battleStatistics);
      }
    } catch (e) {
      log('Background refresh statistics error: $e');
    }
  }

  /// Clear cached statistics
  Future<void> clearCache() => _localDataSource.clearAll();
}
