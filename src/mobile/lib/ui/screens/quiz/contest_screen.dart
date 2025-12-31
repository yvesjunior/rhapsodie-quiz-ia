import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/commons/screens/dashboard_screen.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/custom_back_button.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

/// Contest Type - Tab order: Ongoing, Upcoming, Finished
const int _live = 0;      // Ongoing
const int _upcoming = 1;  // Upcoming
const int _past = 2;      // Finished

class ContestScreen extends StatefulWidget {
  const ContestScreen({super.key});

  @override
  State<ContestScreen> createState() => _ContestScreen();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<ContestCubit>(
            create: (_) => ContestCubit(QuizRepository()),
          ),
          BlocProvider<UpdateCoinsCubit>(
            create: (_) => UpdateCoinsCubit(ProfileManagementRepository()),
          ),
        ],
        child: const ContestScreen(),
      ),
    );
  }
}

class _ContestScreen extends State<ContestScreen>
    with SingleTickerProviderStateMixin {
  // Key to force rebuild of daily contest cards when data changes
  final GlobalKey<_DailyRhapsodyCardState> _dailyCardKey = GlobalKey();
  final GlobalKey<_CompletedDailyContestsCardState> _completedCardKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    context.read<ContestCubit>().getContest(
      languageId: UiUtils.getCurrentQuizLanguageId(context),
    );
    // Force refresh of daily contest cards
    _dailyCardKey.currentState?._checkDailyContestStatus();
    _completedCardKey.currentState?._checkDailyContestStatus();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0, // Start on Ongoing tab
      child: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                context.tr('contestLbl')!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
              leading: CustomBackButton(
                onTap: () {
                  // Refresh home data before popping
                  dashboardScreenKey.currentState?.refreshHomeData();
                  Navigator.pop(context);
                },
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(
                      context,
                    ).colorScheme.onTertiary.withValues(alpha: 0.08),
                  ),
                  child: const TabBar(
                    tabAlignment: TabAlignment.fill,
                    tabs: [
                      Tab(text: 'Ongoing'),
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Finished'),
                    ],
                  ),
                ),
              ),
            ),
            body: BlocConsumer<ContestCubit, ContestState>(
              bloc: context.read<ContestCubit>(),
              listener: (context, state) {
                if (state is ContestFailure) {
                  if (state.errorMessage == errorCodeUnauthorizedAccess) {
                    showAlreadyLoggedInDialog(context);
                  }
                }
              },
              builder: (context, state) {
                if (state is ContestProgress || state is ContestInitial) {
                  return const Center(child: CircularProgressContainer());
                }
                if (state is ContestFailure) {
                  return ErrorContainer(
                    errorMessage: convertErrorCodeToLanguageKey(
                      state.errorMessage,
                    ),
                    onTapRetry: () {
                      context.read<ContestCubit>().getContest(
                        languageId: UiUtils.getCurrentQuizLanguageId(context),
                      );
                    },
                    showErrorImage: true,
                  );
                }
                final contestList = (state as ContestSuccess).contestList;
                return TabBarView(
                  children: [
                    live(contestList.live),       // Ongoing
                    future(contestList.upcoming), // Upcoming
                    past(contestList.past),       // Finished
                  ],
                );
              },
            ),
            bottomNavigationBar: _buildBottomNav(context),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: kBottomNavigationBarHeight + 26,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(blurRadius: 16, spreadRadius: 2, color: Colors.black12),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItemSvg(context, Assets.homeNavIcon, 'Home', NavTabType.home),
          _navItemSvg(context, Assets.leaderboardNavIcon, 'Leaderboard', NavTabType.leaderboard),
          _navItemIcon(context, Icons.school, 'Foundation', NavTabType.quizZone),
          _navItemSvg(context, Assets.playZoneNavIcon, 'Play Zone', NavTabType.playZone),
          _navItemSvg(context, Assets.profileNavIcon, 'Profile', NavTabType.profile),
        ],
      ),
    );
  }

  Widget _navItemSvg(BuildContext context, String iconAsset, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: QImage(imageUrl: iconAsset, color: color)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItemIcon(BuildContext context, IconData icon, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Icon(icon, color: color, size: 24)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget past(Contest data) {
    // Show completed daily contests + regular finished contests
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.contestDetails.length + 1, // +1 for completed Daily Rhapsody
        itemBuilder: (_, i) {
          // First item: Completed Daily Rhapsody contests
          if (i == 0) {
            return _CompletedDailyContestsCard(key: _completedCardKey);
          }
          // Regular finished contest cards
          return _ContestCard(
            contestDetails: data.contestDetails[i - 1],
            contestType: _past,
          );
        },
      ),
    );
  }

  Widget live(Contest data) {
    // Always show the Daily Rhapsody card, even if no regular contests exist
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.contestDetails.length + 1, // +1 for Daily Rhapsody card
        itemBuilder: (_, i) {
          // First item: Daily Rhapsody Contest card (always shown)
          if (i == 0) {
            return _DailyRhapsodyCard(
              key: _dailyCardKey,
              onContestCompleted: _refreshData,
            );
          }
          // Regular contest cards (if any)
          return _ContestCard(
            contestDetails: data.contestDetails[i - 1],
            contestType: _live,
          );
        },
      ),
    );
  }

  Widget future(Contest data) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: data.contestDetails.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text(
                      context.tr('noUpcomingContestsLbl') ?? 'No upcoming contests',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.contestDetails.length,
              itemBuilder: (_, i) => _ContestCard(
                contestDetails: data.contestDetails[i],
                contestType: _upcoming,
              ),
            ),
    );
  }

  ErrorContainer contestErrorContainer(Contest data) {
    return ErrorContainer(
      showBackButton: false,
      errorMessage: convertErrorCodeToLanguageKey(data.errorMessage),
      onTapRetry: () => context.read<ContestCubit>().getContest(
        languageId: UiUtils.getCurrentQuizLanguageId(context),
      ),
      showErrorImage: true,
    );
  }
}

class _ContestCard extends StatefulWidget {
  const _ContestCard({required this.contestDetails, required this.contestType});

  final ContestDetails contestDetails;
  final int contestType;

  @override
  State<_ContestCard> createState() => _ContestCardState();
}

class _ContestCardState extends State<_ContestCard> {
  void _handleOnTap() {
    if (widget.contestType == _past) {
      Navigator.of(context).pushNamed(
        Routes.contestLeaderboard,
        arguments: {'contestId': widget.contestDetails.id},
      );
    }
    if (widget.contestType == _live) {
      if (int.parse(context.read<UserDetailsCubit>().getCoins()!) >=
          int.parse(widget.contestDetails.entry!)) {
        context.read<UpdateCoinsCubit>().updateCoins(
          coins: int.parse(widget.contestDetails.entry!),
          addCoin: false,
          title: playedContestKey,
        );

        context.read<UserDetailsCubit>().updateCoins(
          addCoin: false,
          coins: int.parse(widget.contestDetails.entry!),
        );
        Navigator.of(context).pushReplacementNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.contest,
            'contestId': widget.contestDetails.id,
          },
        );
      } else {
        showNotEnoughCoinsDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boldTextStyle = TextStyle(
      fontSize: 14,
      color: context.primaryTextColor,
      fontWeight: FontWeight.bold,
    );
    final normalTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeights.regular,
      color: context.primaryTextColor.withValues(alpha: 0.6),
    );
    final width = context.width;

    final verticalDivider = SizedBox(
      width: 1,
      height: 30,
      child: ColoredBox(color: context.scaffoldBackgroundColor),
    );

    return Container(
      margin: const EdgeInsets.all(15),
      width: width * .9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(5, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: _handleOnTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: widget.contestDetails.image!,
                placeholder: (_, i) =>
                    const Center(child: CircularProgressContainer()),
                imageBuilder: (_, img) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: img, fit: BoxFit.cover),
                    ),
                    height: 171,
                    width: width,
                  );
                },
                errorWidget: (_, i, e) => Center(
                  child: Icon(Icons.error, color: context.primaryColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width * .78),
                    child: Text(
                      widget.contestDetails.name!,
                      style: boldTextStyle,
                    ),
                  ),
                  if (widget.contestDetails.description!.length > 50)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: context.scaffoldBackgroundColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      height: 30,
                      width: 30,
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            widget.contestDetails.showDescription =
                                !widget.contestDetails.showDescription!;
                          });
                        },
                        child: Icon(
                          widget.contestDetails.showDescription!
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: context.primaryTextColor,
                          size: 30,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                ],
              ),
              SizedBox(
                width: !widget.contestDetails.showDescription!
                    ? width * .75
                    : width,
                child: Text(
                  widget.contestDetails.description!,
                  style: TextStyle(
                    color: context.primaryTextColor.withValues(alpha: 0.3),
                  ),
                  maxLines: !widget.contestDetails.showDescription! ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: context.scaffoldBackgroundColor, height: 0),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.tr('entryFeesLbl')!, style: normalTextStyle),
                      Text(
                        '${widget.contestDetails.entry!} ${context.tr('coinsLbl')!}',
                        style: boldTextStyle,
                      ),
                    ],
                  ),

                  ///
                  verticalDivider,
                  if (widget.contestType == _upcoming)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('startsOnLbl')!,
                          style: normalTextStyle,
                        ),
                        Text(
                          widget.contestDetails.startDate!,
                          style: boldTextStyle,
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.tr('playersLbl')!, style: normalTextStyle),
                        Text(
                          widget.contestDetails.participants!,
                          style: boldTextStyle,
                        ),
                      ],
                    ),

                  ///
                  verticalDivider,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.tr('endsOnLbl')!, style: normalTextStyle),
                      Text(
                        widget.contestDetails.endDate!,
                        style: boldTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily Rhapsody Contest Card
/// Shows the daily contest based on today's Rhapsody
class _DailyRhapsodyCard extends StatefulWidget {
  const _DailyRhapsodyCard({super.key, this.onContestCompleted});

  final VoidCallback? onContestCompleted;

  @override
  State<_DailyRhapsodyCard> createState() => _DailyRhapsodyCardState();
}

class _DailyRhapsodyCardState extends State<_DailyRhapsodyCard> {
  bool _isLoading = true;
  bool _hasPendingContest = false;
  bool _hasCompleted = false;
  String? _contestName;
  int? _userScore;

  @override
  void initState() {
    super.initState();
    _checkDailyContestStatus();
  }

  Future<void> _checkDailyContestStatus() async {
    try {
      final result = await QuizRepository().getDailyContestStatus();
      if (mounted) {
        setState(() {
          _hasPendingContest = result['has_pending_contest'] ?? false;
          _hasCompleted = result['has_completed'] ?? false;
          _contestName = result['contest_name'];
          _userScore = result['user_score'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide this card in Ongoing tab if contest is completed
    // (It will show in Finished tab instead)
    if (_hasCompleted && !_isLoading) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final dateStr = '${today.day} ${_getMonthName(today.month)} ${today.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Daily Rhapsody',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_hasPendingContest && !_isLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (_hasCompleted && !_isLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_userScore ?? 0} pts',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber.shade300,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '10 points max',
                            style: TextStyle(
                              color: Colors.amber.shade200,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.quiz,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '5 questions',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Expiration time
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.orange.shade200,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${_getExpirationTime()}',
                            style: TextStyle(
                              color: Colors.orange.shade200,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.7),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (_hasCompleted) {
      // Already completed - go back to home
      Navigator.of(context).pop();
    } else if (_hasPendingContest) {
      // Start daily contest
      Navigator.of(context).pushNamed(Routes.dailyContest).then((_) {
        // Refresh status when returning
        _checkDailyContestStatus();
        // Notify parent to refresh all data
        widget.onContestCompleted?.call();
      });
    } else {
      // No contest available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No daily contest available. Try again later.'),
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getExpirationTime() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final remaining = midnight.difference(now);

    if (remaining.isNegative) {
      return 'Expired';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else {
      return '${minutes}m left';
    }
  }
}

/// Card showing completed Daily Rhapsody contests in the Finished tab
class _CompletedDailyContestsCard extends StatefulWidget {
  const _CompletedDailyContestsCard({super.key});

  @override
  State<_CompletedDailyContestsCard> createState() =>
      _CompletedDailyContestsCardState();
}

class _CompletedDailyContestsCardState
    extends State<_CompletedDailyContestsCard> {
  bool _isLoading = true;
  bool _hasCompleted = false;
  String? _contestName;
  int? _userScore;

  @override
  void initState() {
    super.initState();
    _checkDailyContestStatus();
  }

  Future<void> _checkDailyContestStatus() async {
    try {
      final result = await QuizRepository().getDailyContestStatus();
      if (mounted) {
        setState(() {
          _hasCompleted = result['has_completed'] ?? false;
          _contestName = result['contest_name'];
          _userScore = result['user_score'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if user has completed today's daily contest
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (!_hasCompleted) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final dateStr =
        '${today.day} ${_getMonthName(today.month)} ${today.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF9E9E9E), // Solid gray for completed
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E9E9E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Daily Rhapsody',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_userScore ?? 0} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
