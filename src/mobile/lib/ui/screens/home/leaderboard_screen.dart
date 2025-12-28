import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/leaderboard/cubit/leaderboard_all_time_cubit.dart';
import 'package:flutterquiz/features/leaderboard/cubit/leaderboard_daily_cubit.dart';
import 'package:flutterquiz/features/leaderboard/cubit/leaderboard_monthly_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

/// Purple header color - consistent across all screens
const _headerColor = Color(0xFF7B68EE);

class LeaderBoardScreen extends StatefulWidget {
  const LeaderBoardScreen({super.key});

  @override
  State<LeaderBoardScreen> createState() => LeaderBoardScreenState();
}

class LeaderBoardScreenState extends State<LeaderBoardScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  final _allTimeRefreshKey = GlobalKey<RefreshIndicatorState>();
  final _monthlyRefreshKey = GlobalKey<RefreshIndicatorState>();
  final _dailyRefreshKey = GlobalKey<RefreshIndicatorState>();

  final controllerM = ScrollController();
  final controllerA = ScrollController();
  final controllerD = ScrollController();

  @override
  void initState() {
    controllerM.addListener(scrollListenerM);
    controllerA.addListener(scrollListenerA);
    controllerD.addListener(scrollListenerD);

    Future.delayed(Duration.zero, () {
      context.read<LeaderBoardDailyCubit>().fetchLeaderBoard('20');
      context.read<LeaderBoardMonthlyCubit>().fetchLeaderBoard('20');
      context.read<LeaderBoardAllTimeCubit>().fetchLeaderBoard('20');
    });
    super.initState();
  }

  @override
  void dispose() {
    controllerM.removeListener(scrollListenerM);
    controllerA.removeListener(scrollListenerA);
    controllerD.removeListener(scrollListenerD);
    controllerM.dispose();
    controllerA.dispose();
    controllerD.dispose();
    super.dispose();
  }

  void scrollListenerM() {
    if (controllerM.position.maxScrollExtent == controllerM.offset) {
      if (context.read<LeaderBoardMonthlyCubit>().hasMoreData()) {
        context.read<LeaderBoardMonthlyCubit>().fetchMoreLeaderBoardData('20');
      }
    }
  }

  void scrollListenerA() {
    if (controllerA.position.maxScrollExtent == controllerA.offset) {
      if (context.read<LeaderBoardAllTimeCubit>().hasMoreData()) {
        context.read<LeaderBoardAllTimeCubit>().fetchMoreLeaderBoardData('20');
      }
    }
  }

  void scrollListenerD() {
    if (controllerD.position.maxScrollExtent == controllerD.offset) {
      if (context.read<LeaderBoardDailyCubit>().hasMoreData()) {
        context.read<LeaderBoardDailyCubit>().fetchMoreLeaderBoardData('20');
      }
    }
  }

  void onTapTab() {
    if (_selectedTabIndex == 0) {
      if (controllerA.hasClients && controllerA.offset != 0) {
        controllerA.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else {
        _allTimeRefreshKey.currentState?.show();
      }
    } else if (_selectedTabIndex == 1) {
      if (controllerM.hasClients && controllerM.offset != 0) {
        controllerM.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else {
        _monthlyRefreshKey.currentState?.show();
      }
    } else if (_selectedTabIndex == 2) {
      if (controllerD.hasClients && controllerD.offset != 0) {
        controllerD.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else {
        _dailyRefreshKey.currentState?.show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: _headerColor,
      body: Stack(
        children: [
          // Purple background
          Container(
            height: context.height * 0.55,
            color: _headerColor,
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildTabBar(),
                const SizedBox(height: 24),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
        children: [
          allTimeLeaderBoard(),
          monthlyLeaderBoard(),
          dailyLeaderBoard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // User avatar
          BlocBuilder<UserDetailsCubit, UserDetailsState>(
            builder: (context, state) {
              var profileUrl = '';
              if (state is UserDetailsFetchSuccess) {
                profileUrl = state.userProfile.profileUrl ?? '';
              }
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFFFE4B5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: profileUrl.isNotEmpty
                      ? QImage(imageUrl: profileUrl, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.brown),
                ),
              );
            },
          ),
          
          // Title
          Expanded(
            child: Text(
              context.trWithFallback('leaderboardLbl', 'Leaderboard'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeights.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Notification bell with badge
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      context.trWithFallback('allTimeLbl', 'All Time'),
      context.trWithFallback('thisMonthLbl', 'This Month'),
      context.trWithFallback('thisWeekLbl', 'This Week'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeights.bold : FontWeights.regular,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void fetchMonthlyLeaderBoard() =>
      context.read<LeaderBoardMonthlyCubit>().fetchLeaderBoard('20');

  void fetchDailyLeaderBoard() =>
      context.read<LeaderBoardDailyCubit>().fetchLeaderBoard('20');

  void fetchAllTimeLeaderBoard() =>
      context.read<LeaderBoardAllTimeCubit>().fetchLeaderBoard('20');

  Widget noLeaderboard(VoidCallback onTapRetry) => Center(
    child: ErrorContainer(
      topMargin: 0,
      errorMessage: 'noLeaderboardLbl',
      onTapRetry: onTapRetry,
      showErrorImage: false,
    ),
  );

  Widget dailyLeaderBoard() {
    return BlocConsumer<LeaderBoardDailyCubit, LeaderBoardDailyState>(
      bloc: context.read<LeaderBoardDailyCubit>(),
      listener: (context, state) {
        if (state is LeaderBoardDailyFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
            return;
          }
        }
      },
      builder: (context, state) {
        if (state is LeaderBoardDailyFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: fetchDailyLeaderBoard,
            showErrorImage: true,
            errorMessageColor: Colors.white,
          );
        }

        if (state is LeaderBoardDailySuccess) {
          final dailyList = state.leaderBoardDetails;
          final hasMore = state.hasMore;

          if (dailyList.isEmpty) {
            return noLeaderboard(fetchDailyLeaderBoard);
          }

          return _buildLeaderboardContent(
            leaderboardList: dailyList,
            controller: controllerD,
            hasMore: hasMore,
            rank: LeaderBoardDailyCubit.rankD,
            profile: LeaderBoardDailyCubit.profileD,
            score: LeaderBoardDailyCubit.scoreD,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
                context.read<LeaderBoardDailyCubit>().fetchLeaderBoard('20');
            },
            refreshKey: _dailyRefreshKey,
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget monthlyLeaderBoard() {
    return BlocConsumer<LeaderBoardMonthlyCubit, LeaderBoardMonthlyState>(
      bloc: context.read<LeaderBoardMonthlyCubit>(),
      listener: (context, state) {
        if (state is LeaderBoardMonthlyFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
            return;
          }
        }
      },
      builder: (context, state) {
        if (state is LeaderBoardMonthlyFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: fetchMonthlyLeaderBoard,
            showErrorImage: true,
            errorMessageColor: Colors.white,
          );
        }

        if (state is LeaderBoardMonthlySuccess) {
          final monthlyList = state.leaderBoardDetails;
          final hasMore = state.hasMore;

          if (monthlyList.isEmpty) {
            return noLeaderboard(fetchMonthlyLeaderBoard);
          }

          return _buildLeaderboardContent(
            leaderboardList: monthlyList,
            controller: controllerM,
            hasMore: hasMore,
            rank: LeaderBoardMonthlyCubit.rankM,
            profile: LeaderBoardMonthlyCubit.profileM,
            score: LeaderBoardMonthlyCubit.scoreM,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
                context.read<LeaderBoardMonthlyCubit>().fetchLeaderBoard('20');
            },
            refreshKey: _monthlyRefreshKey,
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget allTimeLeaderBoard() {
    return BlocConsumer<LeaderBoardAllTimeCubit, LeaderBoardAllTimeState>(
      bloc: context.read<LeaderBoardAllTimeCubit>(),
      listener: (context, state) {
        if (state is LeaderBoardAllTimeFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is LeaderBoardAllTimeFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: fetchAllTimeLeaderBoard,
            showErrorImage: true,
            errorMessageColor: Colors.white,
          );
        }

        if (state is LeaderBoardAllTimeSuccess) {
          final allTimeList = state.leaderBoardDetails;
          final hasMore = state.hasMore;

          if (allTimeList.isEmpty) {
            return noLeaderboard(fetchAllTimeLeaderBoard);
          }

          return _buildLeaderboardContent(
            leaderboardList: allTimeList,
            controller: controllerA,
            hasMore: hasMore,
            rank: LeaderBoardAllTimeCubit.rankA,
            profile: LeaderBoardAllTimeCubit.profileA,
            score: LeaderBoardAllTimeCubit.scoreA,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
                context.read<LeaderBoardAllTimeCubit>().fetchLeaderBoard('20');
            },
            refreshKey: _allTimeRefreshKey,
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget _buildLeaderboardContent({
    required List<Map<String, dynamic>> leaderboardList,
    required ScrollController controller,
    required bool hasMore,
    required String rank,
    required String profile,
    required String score,
    required Future<void> Function() onRefresh,
    required GlobalKey<RefreshIndicatorState> refreshKey,
  }) {
    final showMyRank = score != '0' && int.parse(rank) > 3;

    return Column(
      children: [
        // Top 3 Podium
        _buildPodium(leaderboardList.take(3).toList()),
        
        const SizedBox(height: 16),
        
        // Rankings List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // My rank highlight (if applicable)
                if (showMyRank)
                  _buildMyRankCard(rank, profile, score),
                
                // Other rankings
        Expanded(
          child: RefreshIndicator(
            key: refreshKey,
                    color: _headerColor,
            onRefresh: onRefresh,
                    child: ListView.builder(
              controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: leaderboardList.length > 3 
                          ? leaderboardList.length - 3 + (hasMore ? 1 : 0)
                          : 0,
                      itemBuilder: (context, index) {
                          final actualIndex = index + 3;

                        if (hasMore && actualIndex >= leaderboardList.length) {
                          return const Center(child: CircularProgressContainer());
                        }
                        
                        if (actualIndex >= leaderboardList.length) return null;
                        
                        return _buildLeaderboardItem(leaderboardList[actualIndex]);
                      },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
      children: [
            // 2nd place
        Expanded(
              child: top3.length > 1
                  ? _buildPodiumItem(top3[1], 2, 120)
                  : const SizedBox.shrink(),
        ),
            const SizedBox(width: 8),
            
            // 1st place (taller)
        Expanded(
              child: top3.isNotEmpty
                  ? _buildPodiumItem(top3[0], 1, 160)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            
            // 3rd place
            Expanded(
              child: top3.length > 2
                  ? _buildPodiumItem(top3[2], 3, 100)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int position, double podiumHeight) {
    final name = user['name'] as String? ?? '...';
    final profileUrl = user['profile'] as String? ?? '';
    final score = user['score'] as String? ?? '0';
    
    // Avatar background colors
    final avatarColors = {
      1: const Color(0xFFFFE4B5),
      2: const Color(0xFFB8E6D4),
      3: const Color(0xFFFFD4CC),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
          children: [
        // Crown for 1st place
        if (position == 1)
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFFFD700),
            size: 28,
          ),
        
        const SizedBox(height: 4),
        
        // Avatar
        Container(
          width: position == 1 ? 70 : 56,
          height: position == 1 ? 70 : 56,
                      decoration: BoxDecoration(
            color: avatarColors[position],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: profileUrl.isNotEmpty
                ? QImage(imageUrl: profileUrl, fit: BoxFit.cover)
                : const Icon(Icons.person, color: Colors.brown),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Name
        Text(
          name.length > 10 ? '${name.substring(0, 10)}...' : name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeights.semiBold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Podium block
        Container(
          height: podiumHeight,
          decoration: BoxDecoration(
            color: _headerColor.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Points
            Text(
                  '$score pt',
              style: TextStyle(
                fontSize: 12,
                    fontWeight: FontWeights.semiBold,
                    color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
                const SizedBox(height: 8),
                // Position number
            Text(
                  '$position',
                  style: const TextStyle(
                    fontSize: 40,
                fontWeight: FontWeights.bold,
                    color: Colors.white,
              ),
            ),
          ],
        ),
          ),
        ),
      ],
      );
    }

  Widget _buildMyRankCard(String rank, String profile, String score) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
            children: [
          // Rank
          Text(
            _getOrdinal(int.tryParse(rank) ?? 0),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeights.bold,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          Container(
            width: 48,
            height: 48,
      decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFB8E6D4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: profile.isNotEmpty
                  ? QImage(imageUrl: profile, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.brown),
            ),
          ),
          const SizedBox(width: 12),
          
          // "YOU" label
                            Expanded(
                              child: Text(
              'YOU',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeights.bold,
                color: context.primaryTextColor,
              ),
            ),
          ),
          
          // Score
          Text(
            '$score pt',
            style: TextStyle(
              fontSize: 14,
              color: context.primaryTextColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> item) {
    final rank = item['user_rank'] as String? ?? '0';
    final name = item['name'] as String? ?? '...';
    final profileUrl = item['profile'] as String? ?? '';
    final score = item['score'] as String? ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              _getOrdinal(int.tryParse(rank) ?? 0),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeights.semiBold,
                color: context.primaryTextColor,
              ),
            ),
          ),
          
          // Avatar
              Container(
            width: 48,
            height: 48,
                decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _getAvatarColor(int.tryParse(rank) ?? 0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: profileUrl.isNotEmpty
                  ? QImage(imageUrl: profileUrl, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.brown),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name
          Expanded(
            child: Text(
              name,
                  style: TextStyle(
                fontSize: 16,
                    fontWeight: FontWeights.semiBold,
                color: context.primaryTextColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
                ),
          ),
          
          // Score
                Text(
            '$score pt',
                  style: TextStyle(
              fontSize: 14,
              color: context.primaryTextColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int rank) {
    final colors = [
      const Color(0xFFFFE4B5),
      const Color(0xFFB8E6D4),
      const Color(0xFFFFD4CC),
      const Color(0xFFD4E4FF),
      const Color(0xFFE4D4FF),
    ];
    return colors[(rank - 1) % colors.length];
  }

  String _getOrdinal(int number) {
    if (number <= 0) return '0';
    
    final lastDigit = number % 10;
    final lastTwoDigits = number % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
      return '${number}th';
    }
    
    switch (lastDigit) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  @override
  bool get wantKeepAlive => true;
}
