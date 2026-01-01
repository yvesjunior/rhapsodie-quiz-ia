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

sealed class LeaderBoardDailyState {
  const LeaderBoardDailyState();
}

final class LeaderBoardDailyInitial extends LeaderBoardDailyState {
  const LeaderBoardDailyInitial();
}

final class LeaderBoardDailyProgress extends LeaderBoardDailyState {
  const LeaderBoardDailyProgress();
}

final class LeaderBoardDailySuccess extends LeaderBoardDailyState {
  const LeaderBoardDailySuccess(
    this.leaderBoardDetails,
    this.totalData, {
    required this.hasMore,
    this.isOffline = false,
  });

  final List<Map<String, dynamic>> leaderBoardDetails;
  final int totalData;
  final bool hasMore;
  final bool isOffline;
}

final class LeaderBoardDailyFailure extends LeaderBoardDailyState {
  const LeaderBoardDailyFailure(this.errorMessage);

  final String errorMessage;
}

final class LeaderBoardDailyCubit extends Cubit<LeaderBoardDailyState> {
  LeaderBoardDailyCubit() : super(const LeaderBoardDailyInitial());

  final LeaderboardLocalDataSource _localDataSource = LeaderboardLocalDataSource();

  static late String profileD;
  static late String nameD;
  static late String scoreD;
  static late String rankD;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})> _fetchData({
    required String limit,
    String? offset,
  }) async {
    try {
      final body = <String, String>{limitKey: limit, offsetKey: offset ?? ''};

      if (offset == null) body.remove(offset);

      final response = await http.post(
        Uri.parse(getDailyLeaderboardUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      final total = int.parse(responseJson['total'] as String? ?? '0');
      final data = responseJson['data'] as Map<String, dynamic>;
      final otherUsersRanks = (data['other_users_rank'] as List).cast<Map<String, dynamic>>();

      if (total != 0) {
        final myRank = data['my_rank'] as Map<String, dynamic>;

        nameD = myRank['name'].toString();
        rankD = myRank['user_rank'].toString();
        profileD = myRank[profileKey].toString();
        scoreD = myRank['score'].toString();

        // Cache the data
        await _localDataSource.cacheDailyLeaderboard(otherUsersRanks, myRank, total);
      } else {
        nameD = '';
        rankD = '';
        profileD = '';
        scoreD = '0';
      }

      return (total: total, otherUsersRanks: otherUsersRanks);
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  void fetchLeaderBoard(String limit) {
    emit(const LeaderBoardDailyProgress());
    _fetchData(limit: limit)
        .then((v) {
          emit(
            LeaderBoardDailySuccess(
              v.otherUsersRanks,
              v.total,
              hasMore: v.total > v.otherUsersRanks.length,
            ),
          );
        })
        .catchError((dynamic e) {
          // Try to load from cache on error
          _loadFromCache().then((cached) {
            if (cached != null) {
              emit(
                LeaderBoardDailySuccess(
                  cached.otherUsersRanks,
                  cached.total,
                  hasMore: cached.total > cached.otherUsersRanks.length,
                  isOffline: true,
                ),
              );
            } else {
              emit(const LeaderBoardDailyFailure(errorCodeNoInternet));
            }
          });
        });
  }

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})?> _loadFromCache() async {
    try {
      final cached = await _localDataSource.getCachedDailyLeaderboard();
      final myRankCached = await _localDataSource.getCachedDailyMyRank();

      if (cached != null && cached['data'] != null) {
        final data = (cached['data'] as List).cast<Map<String, dynamic>>();
        final total = cached['total'] as int? ?? 0;

        if (myRankCached != null) {
          nameD = myRankCached['name']?.toString() ?? '';
          rankD = myRankCached['user_rank']?.toString() ?? '';
          profileD = myRankCached['profile']?.toString() ?? '';
          scoreD = myRankCached['score']?.toString() ?? '0';
        }

        log('Loaded daily leaderboard from cache: ${data.length} entries');
        return (total: total, otherUsersRanks: data);
      }
    } catch (e) {
      log('Error loading daily leaderboard from cache: $e');
    }
    return null;
  }

  void fetchMoreLeaderBoardData(String limit) {
    _fetchData(
          limit: limit,
          offset: (state as LeaderBoardDailySuccess).leaderBoardDetails.length
              .toString(),
        )
        .then((v) {
          final oldState = state as LeaderBoardDailySuccess;
          final updatedUserDetails = oldState.leaderBoardDetails
            ..addAll(v.otherUsersRanks);

          emit(
            LeaderBoardDailySuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(const LeaderBoardDailyFailure(errorCodeNoInternet));
        });
  }

  bool hasMoreData() =>
      state is LeaderBoardDailySuccess &&
      (state as LeaderBoardDailySuccess).hasMore;
}
