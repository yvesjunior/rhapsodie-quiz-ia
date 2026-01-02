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

/// Blue header color - consistent across all screens
const _headerColor = Color(0xFF1565C0);

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
    
    // Get current user ID
    final userState = context.read<UserDetailsCubit>().state;
    final currentUserId = userState is UserDetailsFetchSuccess 
        ? userState.userProfile.userId 
        : null;
    
    // Extract podium users (1 per rank, prioritizing current user)
    final podiumResult = _extractPodiumUsers(leaderboardList, currentUserId);
    final podiumUsers = podiumResult.podiumUsers;
    final remainingUsers = podiumResult.remainingUsers;
    final tieCounts = podiumResult.tieCounts;

    return Column(
      children: [
        // Top 3 Podium (exactly 1 per place)
        _buildPodium(podiumUsers, tieCounts: tieCounts),
        
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
                
                // Other rankings (including tied users not on podium)
        Expanded(
          child: RefreshIndicator(
            key: refreshKey,
                    color: _headerColor,
            onRefresh: onRefresh,
                    child: ListView.builder(
              controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: remainingUsers.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (hasMore && index >= remainingUsers.length) {
                          return const Center(child: CircularProgressContainer());
                        }
                        
                        if (index >= remainingUsers.length) return null;
                        
                        return _buildLeaderboardItem(
                          remainingUsers[index],
                          allUsers: remainingUsers,
                        );
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
  
  /// Extract exactly 1 user per podium position (1st, 2nd, 3rd)
  /// If there are ties, prioritize the current user
  /// Also returns tie count per rank for displaying ex aequo indicator
  ({List<Map<String, dynamic>> podiumUsers, List<Map<String, dynamic>> remainingUsers, Map<int, int> tieCounts}) 
  _extractPodiumUsers(List<Map<String, dynamic>> allUsers, String? currentUserId) {
    if (allUsers.isEmpty) {
      return (podiumUsers: <Map<String, dynamic>>[], remainingUsers: <Map<String, dynamic>>[], tieCounts: <int, int>{});
    }
    
    final podiumUsers = <Map<String, dynamic>>[];
    final remainingUsers = <Map<String, dynamic>>[];
    final tieCounts = <int, int>{}; // rank -> number of users tied
    final usedRanks = <int>{};
    
    // First pass: find best user for each rank (prioritize current user)
    for (final rank in [1, 2, 3]) {
      // Get all users with this rank
      final usersAtRank = allUsers.where((u) {
        final userRank = int.tryParse(u['user_rank']?.toString() ?? '0') ?? 0;
        return userRank == rank;
      }).toList();
      
      if (usersAtRank.isEmpty) continue;
      
      // Store tie count
      tieCounts[rank] = usersAtRank.length;
      
      // Check if current user is at this rank
      final currentUserAtRank = usersAtRank.firstWhere(
        (u) => u['id']?.toString() == currentUserId || u['user_id']?.toString() == currentUserId,
        orElse: () => <String, dynamic>{},
      );
      
      // Pick current user if present, otherwise first user
      final selectedUser = currentUserAtRank.isNotEmpty ? currentUserAtRank : usersAtRank.first;
      podiumUsers.add(selectedUser);
      usedRanks.add(rank);
    }
    
    // Second pass: add everyone else to remaining list
    for (final user in allUsers) {
      final userRank = int.tryParse(user['user_rank']?.toString() ?? '0') ?? 0;
      final userId = user['id']?.toString() ?? user['user_id']?.toString() ?? '';
      
      // Check if this user is already on podium
      final isOnPodium = podiumUsers.any((p) => 
        (p['id']?.toString() ?? p['user_id']?.toString() ?? '') == userId
      );
      
      if (!isOnPodium) {
        remainingUsers.add(user);
      }
    }
    
    return (podiumUsers: podiumUsers, remainingUsers: remainingUsers, tieCounts: tieCounts);
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3, {Map<int, int>? tieCounts}) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 40; // Account for padding
        final stepWidth = availableWidth / 3;
        
        // Podium height scales with width to maintain aspect ratio
        // Original image aspect ratio is approximately 2.5:1 (width:height)
        final podiumHeight = availableWidth / 2.5;
        final totalHeight = podiumHeight + 140; // Extra space for avatars
        
        // Score positions as percentages of podium height
        // These percentages match where the white boxes are in the image
        final score1stBottom = podiumHeight * 0.68; // 1st place (highest)
        final score2ndBottom = podiumHeight * 0.46; // 2nd place (medium)
        final score3rdBottom = podiumHeight * 0.39; // 3rd place (lowest)
        
        // Avatar overlap positions
        final avatarBottom = podiumHeight * 0.68;
        final avatar1stExtra = podiumHeight * 0.25; // Extra height for 1st place
        final avatar3rdOffset = podiumHeight * 0.14; // Push down 3rd place

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Podium image at the bottom with blue tint
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/poduim.png',
                    width: double.infinity,
                    height: podiumHeight,
                    fit: BoxFit.fill,
                    color: const Color(0xFF1565C0),
                    colorBlendMode: BlendMode.hue,
                  ),
                ),
                // 2nd place score - on left white box
                if (top3.length > 1)
                  Positioned(
                    bottom: score2ndBottom,
                    left: 0,
                    width: stepWidth,
                    child: Center(
                      child: Text(
                        '${top3[1]['score'] ?? '0'} pt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeights.bold,
                          color: _headerColor,
                        ),
                      ),
                    ),
                  ),
                // 1st place score - on center white box (highest)
                if (top3.isNotEmpty)
                  Positioned(
                    bottom: score1stBottom,
                    left: stepWidth,
                    width: stepWidth,
                    child: Center(
                      child: Text(
                        '${top3[0]['score'] ?? '0'} pt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeights.bold,
                          color: _headerColor,
                        ),
                      ),
                    ),
                  ),
                // 3rd place score - on right white box (lowest)
                if (top3.length > 2)
                  Positioned(
                    bottom: score3rdBottom,
                    right: 0,
                    width: stepWidth,
                    child: Center(
                      child: Text(
                        '${top3[2]['score'] ?? '0'} pt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeights.bold,
                          color: _headerColor,
                        ),
                      ),
                    ),
                  ),
                // Avatars positioned to overlap the podium
                Positioned(
                  bottom: avatarBottom,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd place (medium height step)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: podiumHeight * 0.08),
                          child: top3.length > 1
                              ? _buildPodiumAvatar(top3[1], 2, tieCount: tieCounts?[2] ?? 1)
                              : const SizedBox.shrink(),
                        ),
                      ),
                      // 1st place (tallest step)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: avatar1stExtra),
                          child: top3.isNotEmpty
                              ? _buildPodiumAvatar(top3[0], 1, tieCount: tieCounts?[1] ?? 1)
                              : const SizedBox.shrink(),
                        ),
                      ),
                      // 3rd place (shortest step)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: avatar3rdOffset),
                          child: top3.length > 2
                              ? _buildPodiumAvatar(top3[2], 3, tieCount: tieCounts?[3] ?? 1)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodiumAvatar(Map<String, dynamic> user, int position, {int tieCount = 1}) {
    final name = user['name'] as String? ?? '...';
    final profileUrl = user['profile'] as String? ?? '';
    final isExAequo = tieCount > 1;
    
    // Avatar border colors matching the design
    final avatarBorderColors = {
      1: const Color(0xFFFFD700), // Gold for 1st
      2: const Color(0xFF90EE90), // Light green for 2nd
      3: const Color(0xFF87CEEB), // Light blue for 3rd
    };
    
    // Avatar background colors
    final avatarBgColors = {
      1: const Color(0xFFFFE4B5),
      2: const Color(0xFFB8E6D4),
      3: const Color(0xFFB8D4E6),
    };

    final avatarSize = position == 1 ? 68.0 : 54.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (position == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              '👑',
              style: TextStyle(fontSize: 22),
            ),
          ),
        
        // Avatar with border
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: avatarBgColors[position],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExAequo ? Colors.amber.shade400 : avatarBorderColors[position]!,
                  width: isExAequo ? 4 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  if (isExAequo)
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: profileUrl.isNotEmpty
                    ? QImage(imageUrl: profileUrl, fit: BoxFit.cover)
                    : Icon(
                        Icons.person,
                        color: Colors.brown.shade300,
                        size: position == 1 ? 34 : 28,
                      ),
              ),
            ),
            // Ex aequo badge
            if (isExAequo)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade500,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '=$tieCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeights.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Name with ex aequo indicator
        SizedBox(
          width: 80,
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeights.semiBold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isExAequo)
                Text(
                  'ex æquo',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.amber.shade300,
                    fontWeight: FontWeights.medium,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyRankCard(String rank, String profile, String score) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8E6B8), width: 1),
      ),
      child: Row(
        children: [
          // Rank with superscript
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeights.bold,
                color: context.primaryTextColor,
              ),
              children: [
                TextSpan(text: rank),
                WidgetSpan(
                  child: Transform.translate(
                    offset: const Offset(0, -6),
                    child: Text(
                      _getOrdinalSuffix(int.tryParse(rank) ?? 0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeights.bold,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFD4B8E6),
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
              color: context.primaryTextColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Widget _buildLeaderboardItem(
    Map<String, dynamic> item, {
    List<Map<String, dynamic>>? allUsers,
  }) {
    final rank = item['user_rank'] as String? ?? '0';
    final name = item['name'] as String? ?? '...';
    final profileUrl = item['profile'] as String? ?? '';
    final score = item['score'] as String? ?? '0';
    final rankInt = int.tryParse(rank) ?? 0;
    
    // Check if this user is ex aequo (tied with others)
    bool isExAequo = false;
    if (allUsers != null) {
      final usersWithSameRank = allUsers.where((u) => 
        (u['user_rank'] as String? ?? '0') == rank
      ).length;
      isExAequo = usersWithSameRank > 1;
    }

    // Colors for different rank ranges
    Color getItemColor() {
      if (rankInt <= 10) return const Color(0xFFE8D4F4); // Purple tint
      if (rankInt <= 20) return const Color(0xFFD4E8F4); // Blue tint
      if (rankInt <= 50) return const Color(0xFFD4F4E8); // Green tint
      return const Color(0xFFF4E8D4); // Orange tint
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isExAequo 
            ? Border.all(color: Colors.amber.shade400, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank with superscript and ex aequo indicator
          SizedBox(
            width: 52,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExAequo)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.drag_handle,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeights.bold,
                      color: isExAequo ? Colors.amber.shade700 : context.primaryTextColor,
                    ),
                    children: [
                      TextSpan(text: rank),
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -5),
                          child: Text(
                            _getOrdinalSuffix(rankInt),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeights.bold,
                              color: isExAequo ? Colors.amber.shade700 : context.primaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Avatar with colored background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: getItemColor(),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: profileUrl.isNotEmpty
                  ? QImage(imageUrl: profileUrl, fit: BoxFit.cover)
                  : Icon(Icons.person, color: Colors.brown.shade300),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name with ex aequo badge
          Expanded(
            child: Row(
              children: [
                Flexible(
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
                if (isExAequo)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ex æquo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeights.semiBold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
              ],
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
