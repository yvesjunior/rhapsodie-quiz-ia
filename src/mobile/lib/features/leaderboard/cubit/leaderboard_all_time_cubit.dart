import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart';
import 'package:flutterquiz/features/leaderboard/leaderboard_local_data_source.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

sealed class LeaderBoardAllTimeState {
  const LeaderBoardAllTimeState();
}

final class LeaderBoardAllTimeInitial extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeInitial();
}

final class LeaderBoardAllTimeProgress extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeProgress();
}

final class LeaderBoardAllTimeSuccess extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeSuccess(
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

final class LeaderBoardAllTimeFailure extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeFailure(this.errorMessage);

  final String errorMessage;
}

final class LeaderBoardAllTimeCubit extends Cubit<LeaderBoardAllTimeState> {
  LeaderBoardAllTimeCubit() : super(const LeaderBoardAllTimeInitial());

  final LeaderboardLocalDataSource _localDataSource = LeaderboardLocalDataSource();

  static late String profileA;
  static late String nameA;
  static late String scoreA;
  static late String rankA;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})> _fetchData({
    required String limit,
    String? offset,
  }) async {
    try {
      final body = <String, String>{limitKey: limit, offsetKey: offset ?? ''};
      if (offset == null) {
        body.remove(offset);
      }
      final response = await http.post(
        Uri.parse(getAllTimeLeaderboardUrl),
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

        nameA = myRank['name'].toString();
        rankA = myRank['user_rank'].toString();
        profileA = myRank['profile'].toString();
        scoreA = myRank['score'].toString();

        // Cache the data
        await _localDataSource.cacheAllTimeLeaderboard(otherUsersRanks, myRank, total);
      } else {
        nameA = '';
        rankA = '';
        profileA = '';
        scoreA = '0';
      }

      return (total: total, otherUsersRanks: otherUsersRanks);
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  void fetchLeaderBoard(String limit) {
    emit(const LeaderBoardAllTimeProgress());
    _fetchData(limit: limit)
        .then((v) {
          emit(
            LeaderBoardAllTimeSuccess(
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
                LeaderBoardAllTimeSuccess(
                  cached.otherUsersRanks,
                  cached.total,
                  hasMore: cached.total > cached.otherUsersRanks.length,
                  isOffline: true,
                ),
              );
            } else {
              emit(const LeaderBoardAllTimeFailure(errorCodeNoInternet));
            }
          });
        });
  }

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})?> _loadFromCache() async {
    try {
      final cached = await _localDataSource.getCachedAllTimeLeaderboard();
      final myRankCached = await _localDataSource.getCachedAllTimeMyRank();

      if (cached != null && cached['data'] != null) {
        final data = (cached['data'] as List).cast<Map<String, dynamic>>();
        final total = cached['total'] as int? ?? 0;

        if (myRankCached != null) {
          nameA = myRankCached['name']?.toString() ?? '';
          rankA = myRankCached['user_rank']?.toString() ?? '';
          profileA = myRankCached['profile']?.toString() ?? '';
          scoreA = myRankCached['score']?.toString() ?? '0';
        }

        log('Loaded all-time leaderboard from cache: ${data.length} entries');
        return (total: total, otherUsersRanks: data);
      }
    } catch (e) {
      log('Error loading all-time leaderboard from cache: $e');
    }
    return null;
  }

  void fetchMoreLeaderBoardData(String limit) {
    _fetchData(
          limit: limit,
          offset: (state as LeaderBoardAllTimeSuccess).leaderBoardDetails.length
              .toString(),
        )
        .then((v) {
          final oldState = state as LeaderBoardAllTimeSuccess;

          final updatedUserDetails = oldState.leaderBoardDetails
            ..addAll(v.otherUsersRanks);

          emit(
            LeaderBoardAllTimeSuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
            ),
          );
        })
        .catchError((e) {
          emit(const LeaderBoardAllTimeFailure(errorCodeDefaultMessage));
        });
  }

  bool hasMoreData() =>
      state is LeaderBoardAllTimeSuccess &&
      (state as LeaderBoardAllTimeSuccess).hasMore;
}
