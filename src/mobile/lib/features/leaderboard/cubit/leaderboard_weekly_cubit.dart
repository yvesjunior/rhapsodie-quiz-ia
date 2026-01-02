import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart' show errorCodeNoInternet;
import 'package:flutterquiz/features/leaderboard/leaderboard_local_data_source.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

sealed class LeaderBoardWeeklyState {
  const LeaderBoardWeeklyState();
}

final class LeaderBoardWeeklyInitial extends LeaderBoardWeeklyState {
  const LeaderBoardWeeklyInitial();
}

final class LeaderBoardWeeklyProgress extends LeaderBoardWeeklyState {
  const LeaderBoardWeeklyProgress();
}

final class LeaderBoardWeeklySuccess extends LeaderBoardWeeklyState {
  const LeaderBoardWeeklySuccess(
    this.leaderBoardDetails,
    this.totalData, {
    required this.hasMore,
    this.isOffline = false,
    this.weekStart,
    this.weekEnd,
  });

  final List<Map<String, dynamic>> leaderBoardDetails;
  final int totalData;
  final bool hasMore;
  final bool isOffline;
  final String? weekStart;
  final String? weekEnd;
}

final class LeaderBoardWeeklyFailure extends LeaderBoardWeeklyState {
  const LeaderBoardWeeklyFailure(this.errorMessage);

  final String errorMessage;
}

final class LeaderBoardWeeklyCubit extends Cubit<LeaderBoardWeeklyState> {
  LeaderBoardWeeklyCubit() : super(const LeaderBoardWeeklyInitial());

  final LeaderboardLocalDataSource _localDataSource = LeaderboardLocalDataSource();

  static late String profileW;
  static late String nameW;
  static late String scoreW;
  static late String rankW;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks, String? weekStart, String? weekEnd})> _fetchData({
    required String limit,
    String? offset,
  }) async {
    try {
      final body = <String, String>{limitKey: limit, offsetKey: offset ?? ''};

      if (offset == null) body.remove(offset);

      final response = await http.post(
        Uri.parse(getWeeklyLeaderboardUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      final total = int.parse(responseJson['total'] as String? ?? '0');
      final weekStart = responseJson['week_start'] as String?;
      final weekEnd = responseJson['week_end'] as String?;
      final otherUsersRanks = (responseJson['other_users_rank'] as List).cast<Map<String, dynamic>>();
      final myRank = responseJson['my_rank'] as Map<String, dynamic>;

      if (total != 0) {
        nameW = myRank['name'].toString();
        rankW = myRank['user_rank'].toString();
        profileW = myRank[profileKey].toString();
        scoreW = myRank['score'].toString();

        // Cache the data
        await _localDataSource.cacheWeeklyLeaderboard(otherUsersRanks, myRank, total);
      } else {
        nameW = '';
        rankW = '';
        profileW = '';
        scoreW = '0';
      }

      return (total: total, otherUsersRanks: otherUsersRanks, weekStart: weekStart, weekEnd: weekEnd);
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  void fetchLeaderBoard(String limit) {
    emit(const LeaderBoardWeeklyProgress());
    _fetchData(limit: limit)
        .then((v) {
          emit(
            LeaderBoardWeeklySuccess(
              v.otherUsersRanks,
              v.total,
              hasMore: v.total > v.otherUsersRanks.length,
              weekStart: v.weekStart,
              weekEnd: v.weekEnd,
            ),
          );
        })
        .catchError((dynamic e) {
          // Try to load from cache on error
          _loadFromCache().then((cached) {
            if (cached != null) {
              emit(
                LeaderBoardWeeklySuccess(
                  cached.otherUsersRanks,
                  cached.total,
                  hasMore: cached.total > cached.otherUsersRanks.length,
                  isOffline: true,
                ),
              );
            } else {
              emit(const LeaderBoardWeeklyFailure(errorCodeNoInternet));
            }
          });
        });
  }

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})?> _loadFromCache() async {
    try {
      final cached = await _localDataSource.getCachedWeeklyLeaderboard();
      final myRankCached = await _localDataSource.getCachedWeeklyMyRank();

      if (cached != null && cached['data'] != null) {
        final data = (cached['data'] as List).cast<Map<String, dynamic>>();
        final total = cached['total'] as int? ?? 0;

        if (myRankCached != null) {
          nameW = myRankCached['name']?.toString() ?? '';
          rankW = myRankCached['user_rank']?.toString() ?? '';
          profileW = myRankCached['profile']?.toString() ?? '';
          scoreW = myRankCached['score']?.toString() ?? '0';
        }

        log('Loaded weekly leaderboard from cache: ${data.length} entries');
        return (total: total, otherUsersRanks: data);
      }
    } catch (e) {
      log('Error loading weekly leaderboard from cache: $e');
    }
    return null;
  }

  void fetchMoreLeaderBoardData(String limit) {
    _fetchData(
          limit: limit,
          offset: (state as LeaderBoardWeeklySuccess).leaderBoardDetails.length
              .toString(),
        )
        .then((v) {
          final oldState = state as LeaderBoardWeeklySuccess;
          final updatedUserDetails = oldState.leaderBoardDetails
            ..addAll(v.otherUsersRanks);

          emit(
            LeaderBoardWeeklySuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
              weekStart: v.weekStart,
              weekEnd: v.weekEnd,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(const LeaderBoardWeeklyFailure(errorCodeNoInternet));
        });
  }

  bool hasMoreData() =>
      state is LeaderBoardWeeklySuccess &&
      (state as LeaderBoardWeeklySuccess).hasMore;
}

