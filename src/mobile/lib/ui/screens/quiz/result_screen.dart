import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/ads/blocs/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/battle_room_cubit.dart';
import 'package:flutterquiz/features/battle_room/models/battle_room.dart';
import 'package:flutterquiz/features/exam/models/exam.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/models/user_profile.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/comprehension_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/set_coin_score_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/unlocked_level_cubit.dart';
import 'package:flutterquiz/features/quiz/models/comprehension.dart';
import 'package:flutterquiz/features/quiz/models/guess_the_word_question.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/models/user_battle_room_details.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody_remote_data_source.dart';
import 'package:flutterquiz/features/foundation/foundation_remote_data_source.dart';
import 'package:flutterquiz/ui/screens/quiz/category_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/guess_the_word_quiz_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/review_answers_screen.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/utils/answer_encryption.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

// Header color is now using primary color from theme - see _ResultScreenState._headerColor getter

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.isPlayed,
    required this.comprehension,
    required this.isPremiumCategory,
    super.key,
    this.exam,
    this.playWithBot,
    this.correctExamAnswers,
    this.incorrectExamAnswers,
    this.obtainedMarks,
    this.timeTakenToCompleteQuiz,
    this.battleRoom,
    this.questions,
    this.unlockedLevel,
    this.quizType,
    this.subcategoryMaxLevel,
    this.guessTheWordQuestions,
    this.entryFee,
    this.categoryId,
    this.subcategoryId,
    this.lifelines = const [],
    this.totalHintUsed,
    this.matchId,
    this.rhapsodyDay,
    this.rhapsodyMonth,
    this.rhapsodyYear,
    this.foundationClassId,
    this.foundationClassOrder,
  });

  final QuizTypes? quizType;
  final List<Question>? questions;
  final BattleRoom? battleRoom;
  final bool? playWithBot;
  final Comprehension comprehension;
  final List<GuessTheWordQuestion>? guessTheWordQuestions;
  final int? entryFee;
  final String? subcategoryMaxLevel;
  final int? unlockedLevel;
  final double? timeTakenToCompleteQuiz;
  final Exam? exam;
  final int? obtainedMarks;
  final int? correctExamAnswers;
  final int? incorrectExamAnswers;
  final String? categoryId;
  final String? subcategoryId;
  final bool isPlayed;
  final bool isPremiumCategory;
  final List<String> lifelines;
  final int? totalHintUsed;
  final String? matchId;
  
  // Rhapsody day info for "Next" navigation
  final int? rhapsodyDay;
  final int? rhapsodyMonth;
  final int? rhapsodyYear;
  
  // Foundation class info for "Next" navigation
  final String? foundationClassId;
  final int? foundationClassOrder;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SetCoinScoreCubit()),
          BlocProvider<UpdateCoinsCubit>(
            create: (_) => UpdateCoinsCubit(ProfileManagementRepository()),
          ),
          BlocProvider<UpdateUserDetailCubit>(
            create: (_) => UpdateUserDetailCubit(ProfileManagementRepository()),
          ),
        ],
        child: ResultScreen(
          battleRoom: args['battleRoom'] as BattleRoom?,
          categoryId: args['categoryId'] as String? ?? '',
          comprehension:
              args['comprehension'] as Comprehension? ?? Comprehension.empty,
          correctExamAnswers: args['correctExamAnswers'] as int?,
          entryFee: args['entryFee'] as int?,
          exam: args['exam'] as Exam?,
          guessTheWordQuestions:
              args['guessTheWordQuestions'] as List<GuessTheWordQuestion>?,
          incorrectExamAnswers: args['incorrectExamAnswers'] as int?,
          isPlayed: args['isPlayed'] as bool? ?? true,
          obtainedMarks: args['obtainedMarks'] as int?,
          playWithBot: args['play_with_bot'] as bool?,
          questions: args['questions'] as List<Question>?,
          quizType: args['quizType'] as QuizTypes?,
          subcategoryId: args['subcategoryId'] as String? ?? '',
          subcategoryMaxLevel: args['subcategoryMaxLevel'] as String?,
          timeTakenToCompleteQuiz: args['timeTakenToCompleteQuiz'] as double?,
          unlockedLevel: args['unlockedLevel'] as int?,
          isPremiumCategory: args['isPremiumCategory'] as bool? ?? false,
          lifelines: args['lifelines'] as List<String>? ?? const [],
          totalHintUsed: args['totalHintUsed'] as int?,
          matchId: args['matchId'] as String?,
          rhapsodyDay: args['rhapsodyDay'] as int?,
          rhapsodyMonth: args['rhapsodyMonth'] as int?,
          rhapsodyYear: args['rhapsodyYear'] as int?,
          foundationClassId: args['foundationClassId'] as String?,
          foundationClassOrder: args['foundationClassOrder'] as int?,
        ),
      ),
    );
  }

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isWinner = false;
  bool _isShareInProgress = false;
  bool _isReviewInProgress = false;
  int _selectedTabIndex = 0; // 0: Standings, 1: Summary, 2: Play again

  bool _displayedAlreadyLoggedInDialog = false;

  /// Header color using app's primary color
  Color get _headerColor => Theme.of(context).primaryColor;

  late final UserProfile userProfile = context
      .read<UserDetailsCubit>()
      .getUserProfile();
  late final String userProfileUrl = userProfile.profileUrl ?? '';
  late final String userName = userProfile.name ?? '';

  /// THIS is only for Self Challenge and Exam
  late final String _userFirebaseId = context
      .read<UserDetailsCubit>()
      .getUserFirebaseId();

  int get totalQuestions => widget.quizType == QuizTypes.exam
      ? widget.correctExamAnswers! + widget.incorrectExamAnswers!
      : widget.questions?.length ?? 0;

  int get correctAnswers {
    if (widget.quizType == QuizTypes.exam) return widget.correctExamAnswers!;

    if (widget.questions == null) return 0;

    return widget.questions!.where((question) {
      final ans = AnswerEncryption.decryptCorrectAnswer(
        rawKey: _userFirebaseId,
        correctAnswer: question.correctAnswer!,
      );

      return question.submittedAnswerId == ans;
    }).length;
  }

  int get wrongAnswers => widget.quizType == QuizTypes.exam
      ? widget.incorrectExamAnswers!
      : totalQuestions - correctAnswers;

  double get winPercentage => widget.quizType == QuizTypes.exam
      ? (widget.obtainedMarks! * 100) / (int.tryParse(widget.exam?.totalMarks ?? '') ?? 1)
      : (correctAnswers * 100) / totalQuestions;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!widget.isPremiumCategory) {
        context.read<InterstitialAdCubit>().showAd(context);
      }

      if (widget.quizType == QuizTypes.selfChallenge) {
        setState(() {
          _isWinner =
              winPercentage >
              context.read<SystemConfigCubit>().quizWinningPercentage;
        });
      }

      await _updateResult();

      await fetchUpdateUserDetails();
    });
  }

  Future<void> _updateResult() async {
    if (widget.quizType case QuizTypes.selfChallenge || QuizTypes.exam) return;

    final type = switch (widget.quizType) {
      QuizTypes.dailyQuiz => '1.1',
      QuizTypes.trueAndFalse => '1.2',
      QuizTypes.randomBattle => '1.3',
      QuizTypes.oneVsOneBattle => '1.4',
      QuizTypes.contest => 'contest',
      _ => widget.quizType!.typeValue!,
    };

    final playedQuestion = switch (widget.quizType) {
      QuizTypes.oneVsOneBattle || QuizTypes.randomBattle => {
        'user1_id': widget.battleRoom!.user1!.uid,
        'user2_id': widget.battleRoom!.user2!.uid,
        'user1_data': widget.battleRoom!.user1!.answers,
        'user2_data': widget.battleRoom!.user2!.answers,
      },
      QuizTypes.guessTheWord =>
        widget.guessTheWordQuestions!
            .map(
              (q) => <String, String>{
                'id': q.id,
                'answer': q.submittedAnswer.join(),
              },
            )
            .toList(),
      _ =>
        widget.questions!
            .map(
              (q) => <String, String>{
                'id': q.id!,
                'answer': q.submittedAnswerId,
              },
            )
            .toList(),
    };

    final categoryId = switch (widget.quizType) {
      QuizTypes.guessTheWord => widget.guessTheWordQuestions?.first.category,
      QuizTypes.dailyQuiz || QuizTypes.trueAndFalse => '',
      _ => widget.questions?.first.categoryId,
    };

    await context.read<SetCoinScoreCubit>().setCoinScore(
      categoryId: categoryId,
      quizType: type,
      playedQuestions: playedQuestion,
      lifelines: widget.lifelines,
      subcategoryId: widget.subcategoryId,
      playWithBot: widget.playWithBot,
      noOfHintUsed: widget.totalHintUsed,
      matchId: widget.matchId,
    );
  }

  Future<void> fetchUpdateUserDetails() async {
    await context.read<UserDetailsCubit>().fetchUserDetails();
  }

  /// Navigate to the next Rhapsody day's content
  Future<void> _navigateToNextRhapsodyDay() async {
    final currentDay = widget.rhapsodyDay!;
    final currentMonth = widget.rhapsodyMonth!;
    final currentYear = widget.rhapsodyYear!;
    
    // Calculate next day
    int nextDay = currentDay + 1;
    int nextMonth = currentMonth;
    int nextYear = currentYear;
    
    // Handle month overflow (simple check, max 31 days)
    if (nextDay > 31) {
      nextDay = 1;
      nextMonth++;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
    }
    
    // Check if next day exists by trying to fetch it
    try {
      final dataSource = RhapsodyRemoteDataSource();
      final nextDayDetail = await dataSource.getRhapsodyDayDetail(nextYear, nextMonth, nextDay);
      
      if (nextDayDetail != null) {
        // Next day exists, navigate to it
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            Routes.rhapsody,
            arguments: {
              'action': 'showDay',
              'year': nextYear,
              'month': nextMonth,
              'day': nextDay,
            },
          );
        }
      } else {
        // No next day available, show congratulations dialog
        _showNoMoreContentDialog();
      }
    } catch (e) {
      // Error fetching, show dialog
      _showNoMoreContentDialog();
    }
  }
  
  /// Navigate to the next Foundation class
  Future<void> _navigateToNextFoundationClass() async {
    final currentOrder = widget.foundationClassOrder!;
    
    try {
      final dataSource = FoundationRemoteDataSource();
      final classes = await dataSource.getFoundationClasses();
      
      if (classes == null || classes.isEmpty) {
        _showNoMoreFoundationContentDialog();
        return;
      }
      
      // Sort by rowOrder and find next class
      classes.sort((a, b) => a.rowOrder.compareTo(b.rowOrder));
      
      // Find the next class after current order
      final nextClass = classes.where((c) => c.rowOrder > currentOrder).firstOrNull;
      
      if (nextClass != null) {
        // Next class exists, navigate to it
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            Routes.foundationClass,
            arguments: {
              'classId': nextClass.id,
            },
          );
        }
      } else {
        // No next class available, show congratulations dialog
        _showNoMoreFoundationContentDialog();
      }
    } catch (e) {
      // Error fetching, show dialog
      _showNoMoreFoundationContentDialog();
    }
  }

  /// Show dialog when there's no more Foundation content
  void _showNoMoreFoundationContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🎓 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                context.trWithFallback('congratulationsLbl', 'Congratulations!'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          context.trWithFallback(
            'noMoreFoundationContentMsg', 
            "You've completed all Foundation School classes! Great job mastering the fundamentals.",
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to Foundation list
            },
            child: Text(
              context.trWithFallback('okLbl', 'OK'),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog when there's no more Rhapsody content
  void _showNoMoreContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                context.trWithFallback('congratulationsLbl', 'Congratulations!'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          context.trWithFallback(
            'noMoreRhapsodyContentMsg', 
            "You've completed all available Rhapsody content! Check back later for new devotionals.",
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to Rhapsody list
            },
            child: Text(
              context.trWithFallback('okLbl', 'OK'),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onPageBackCalls() {
    if (widget.quizType == QuizTypes.funAndLearn &&
        _isWinner &&
        !widget.comprehension.isPlayed) {
      context.read<ComprehensionCubit>().getComprehension(
        languageId: UiUtils.getCurrentQuizLanguageId(context),
        type: widget.questions!.first.subcategoryId! == '0'
            ? 'category'
            : 'subcategory',
        typeId: widget.questions!.first.subcategoryId! == '0'
            ? widget.questions!.first.categoryId!
            : widget.questions!.first.subcategoryId!,
      );
    } else if (widget.quizType == QuizTypes.audioQuestions &&
        _isWinner &&
        !widget.isPlayed) {
      if (widget.questions!.first.subcategoryId == '0') {
        context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
          languageId: UiUtils.getCurrentQuizLanguageId(context),
          type: UiUtils.getCategoryTypeNumberFromQuizType(
            QuizTypes.audioQuestions,
          ),
        );
      } else {
        context.read<SubCategoryCubit>().fetchSubCategory(
          widget.questions!.first.categoryId!,
        );
      }
    } else if (widget.quizType == QuizTypes.guessTheWord &&
        _isWinner &&
        !widget.isPlayed) {
      if (widget.guessTheWordQuestions!.first.subcategory == '0') {
        context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
          languageId: UiUtils.getCurrentQuizLanguageId(context),
          type: UiUtils.getCategoryTypeNumberFromQuizType(
            QuizTypes.guessTheWord,
          ),
        );
      } else {
        context.read<SubCategoryCubit>().fetchSubCategory(
          widget.guessTheWordQuestions!.first.category,
        );
      }
    } else if (widget.quizType == QuizTypes.mathMania &&
        _isWinner &&
        !widget.isPlayed) {
      if (widget.questions!.first.subcategoryId == '0') {
        context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
          languageId: UiUtils.getCurrentQuizLanguageId(context),
          type: UiUtils.getCategoryTypeNumberFromQuizType(QuizTypes.mathMania),
        );
      } else {
        context.read<SubCategoryCubit>().fetchSubCategory(
          widget.questions!.first.categoryId!,
        );
      }
    } else if (widget.quizType == QuizTypes.quizZone) {
      if (widget.subcategoryId == '') {
        context.read<UnlockedLevelCubit>().fetchUnlockLevel(
          widget.categoryId!,
          '0',
          quizType: QuizTypes.quizZone,
        );
      } else {
        context.read<SubCategoryCubit>().fetchSubCategory(widget.categoryId!);
      }
    } else if (widget.quizType == QuizTypes.contest) {
      context.read<ContestCubit>().getContest(
        languageId: UiUtils.getCurrentQuizLanguageId(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (context.read<UserDetailsCubit>().state
            is UserDetailsFetchInProgress) {
          return;
        }

        onPageBackCalls();
        context.shouldPop();
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<UpdateCoinsCubit, UpdateCoinsState>(
            listener: (context, state) {
              if (state is UpdateCoinsFailure) {
                if (state.errorMessage == errorCodeUnauthorizedAccess) {
                  if (!_displayedAlreadyLoggedInDialog) {
                    _displayedAlreadyLoggedInDialog = true;
                    showAlreadyLoggedInDialog(context);
                    return;
                  }
                }
              }
            },
          ),
          BlocListener<SetCoinScoreCubit, SetCoinScoreState>(
      listener: (context, state) {
        if (state is SetCoinScoreSuccess) {
                setState(() {
                  _isWinner = state.percentage >
                      context.read<SystemConfigCubit>().quizWinningPercentage;
                });
                
          if (widget.quizType
              case QuizTypes.oneVsOneBattle || QuizTypes.randomBattle) {
            final currUserId = context.read<UserDetailsCubit>().userId();
            if (state.userRanks.first.userId == currUserId) {
              context.read<BattleRoomCubit>().deleteBattleRoom();
            }
          }
        }
      },
          ),
        ],
        child: Scaffold(
          backgroundColor: _headerColor,
          body: Stack(
                      children: [
              // Purple background that covers top portion
              Container(
                height: context.height * 0.45,
                decoration: BoxDecoration(
                  color: _headerColor,
                ),
              ),
              
              // Content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Text(
              context.trWithFallback('quizSummaryLbl', 'Quiz Summary'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeights.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onPageBackCalls();
              globalCtx.pushNamedAndRemoveUntil(Routes.home, predicate: (_) => false);
              dashboardScreenKey.currentState?.changeTab(NavTabType.home);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_rounded,
                color: _headerColor,
              ),
                ),
              ),
            ],
      ),
          );
        }

  Widget _buildContent() {
    return BlocBuilder<SetCoinScoreCubit, SetCoinScoreState>(
      builder: (context, state) {
        if (state is SetCoinScoreFailure) {
          return Center(
            child: ErrorContainer(
              showBackButton: true,
              errorMessageColor: Colors.white,
              errorMessage: convertErrorCodeToLanguageKey(state.error),
              onTapRetry: _updateResult,
              showErrorImage: true,
            ),
          );
        }

        if (state is! SetCoinScoreSuccess && 
            widget.quizType != QuizTypes.selfChallenge && 
            widget.quizType != QuizTypes.exam) {
        return const Center(child: CircularProgressContainer());
        }

        final earnedScore = state is SetCoinScoreSuccess ? state.earnScore : 0;
        final totalQues = state is SetCoinScoreSuccess ? state.totalQuestions : totalQuestions;
        final correct = state is SetCoinScoreSuccess ? state.correctAnswer : correctAnswers;
        final wrong = totalQues - correct;

        return SingleChildScrollView(
          child: Column(
      children: [
              // Trophy and congratulations
              _buildTrophySection(earnedScore),
              
              // Stats row
              _buildStatsRow(totalQues, correct, wrong),
              
              const SizedBox(height: 16),
              
              // Tab bar and standings/summary
              _buildTabSection(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrophySection(int earnedScore) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
                children: [
          // Trophy
          Stack(
            alignment: Alignment.center,
            children: [
              // Stars decoration
              Positioned(
                top: 0,
                left: 20,
                child: Icon(
                  Icons.star,
                  color: Colors.amber.withValues(alpha: 0.5),
                  size: 16,
                ),
              ),
              Positioned(
                top: 10,
                right: 30,
                child: Icon(
                  Icons.star,
                  color: Colors.amber.withValues(alpha: 0.7),
                  size: 12,
                ),
              ),
              // Trophy icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isWinner 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'assets/images/cup.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Share button (top right of card)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: _shareScore,
              icon: Icon(
                Icons.share_rounded,
                color: context.primaryTextColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

          // Congratulations text
          Text(
            _isWinner 
                ? context.trWithFallback('congratulationsLbl', 'Congratulations!')
                : context.trWithFallback('betterLuckLbl', 'Better luck next time!'),
                        style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeights.bold,
                          color: context.primaryTextColor,
                        ),
                      ),
          
          const SizedBox(height: 8),
          
          // Success percentage
          RichText(
            text: TextSpan(
              text: context.trWithFallback('successRateLbl', "Success rate: "),
              style: TextStyle(
                fontSize: 16,
                color: context.primaryTextColor.withValues(alpha: 0.6),
              ),
              children: [
                TextSpan(
                  text: '${winPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeights.bold,
                    color: winPercentage >= 100 ? const Color(0xFF4CD964) : 
                           winPercentage >= 70 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Coin reward for 100% success
          if (winPercentage >= 100 && totalQuestions > 5) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 4),
                Text(
                  '+1 ${context.trWithFallback('coinLbl', 'coin')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeights.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, int correct, int wrong) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.quiz_rounded,
            iconColor: _headerColor,
            value: total.toString(),
            label: context.trWithFallback('totalQueLbl', 'Total Que'),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF4CD964),
            value: correct.toString().padLeft(2, '0'),
            label: context.trWithFallback('correctLbl', 'Correct'),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.cancel_rounded,
            iconColor: Colors.red,
            value: wrong.toString().padLeft(2, '0'),
            label: context.trWithFallback('wrongLbl', 'Wrong'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeights.bold,
                color: context.primaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.primaryTextColor.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildTabSection(SetCoinScoreState state) {
    final tabs = [
      context.trWithFallback('standingsLbl', 'Standings'),
      context.trWithFallback('summaryLbl', 'Summary'),
      context.trWithFallback('playAgainBtn', 'Play again'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Tab bar
                    Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = _selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                      child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? _headerColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        ),
                        child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                          style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeights.bold : FontWeights.regular,
                          color: isSelected 
                              ? context.primaryTextColor 
                              : context.primaryTextColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
          
          // Tab content
          IndexedStack(
            index: _selectedTabIndex,
                      children: [
              _buildStandingsTab(state),
              _buildSummaryTab(state),
              _buildPlayAgainTab(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(SetCoinScoreState state) {
    // Build standings from available data
    final standings = <Map<String, dynamic>>[];
    
    // Get percentage from state or calculate locally
    final percentage = state is SetCoinScoreSuccess 
        ? state.percentage 
        : winPercentage.toInt();
    final earnedCoins = state is SetCoinScoreSuccess ? state.earnCoin : 0;
    
    // Add user's own result
    standings.add({
      'rank': 1,
      'name': userName,
      'profile': userProfileUrl,
      'percentage': percentage,
      'coins': earnedCoins,
      'isMe': true,
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
                                children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    context.trWithFallback('rankLbl', 'Rank'),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.primaryTextColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${standings.length} ${context.trWithFallback('playersLbl', 'Players')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.primaryTextColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                              Text(
                  '${context.trWithFallback('correctLbl', 'Correct')}(%)',
                                style: TextStyle(
                    fontSize: 12,
                    color: context.primaryTextColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Standings list
          ...standings.take(5).map((player) => _buildStandingItem(player)),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStandingItem(Map<String, dynamic> player) {
    final rank = player['rank'] as int;
    final name = player['name'] as String;
    final profile = player['profile'] as String? ?? '';
    final percentage = player['percentage'] as int;
    final coins = player['coins'] as int;
    final isMe = player['isMe'] as bool? ?? false;
    
    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    final avatarColors = {
      1: const Color(0xFFF8B5D4),
      2: const Color(0xFFFFE4B5),
      3: const Color(0xFFB8E6D4),
      4: const Color(0xFFD4E4FF),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
        color: isMe 
            ? const Color(0xFFE8F5E9)
            : (rank == 1 ? const Color(0xFFFFF9E6) : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
                                child: Text(
              _getOrdinal(rank),
                                  style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeights.semiBold,
                color: context.primaryTextColor,
                                  ),
                                ),
                              ),
          
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: avatarColors[rank % 4 + 1],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: profile.isNotEmpty
                      ? QImage(imageUrl: profile, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.brown),
                ),
                if (rank == 1)
                  Positioned(
                    top: -8,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: rankColors[1],
                      size: 20,
                                  ),
                                ),
                              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Name and coins
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                              Text(
                  name,
                                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeights.semiBold,
                                  color: context.primaryTextColor,
                                ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rank == 1 && coins > 0)
                  Row(
                    children: [
                      Text(
                        context.trWithFallback('wonLbl', 'Won'),
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF4CD964),
                        ),
                      ),
                        const SizedBox(width: 4),
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFFC107),
                        size: 14,
                      ),
                      Text(
                        ' $coins',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                    ],
                                  ),
                                ],
                              ),
          ),
          
          // Percentage
                              Text(
            '$percentage%',
                                style: TextStyle(
                                  fontSize: 16,
              fontWeight: FontWeights.bold,
                                  color: context.primaryTextColor,
                                ),
                              ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(SetCoinScoreState state) {
    final earnedCoins = state is SetCoinScoreSuccess ? state.earnCoin : 0;
    final percentage = state is SetCoinScoreSuccess ? state.percentage : winPercentage.toInt();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Accuracy (success rate)
          _buildSummaryItem(
            context.trWithFallback('accuracyLbl', 'Accuracy'),
            '$percentage%',
            Icons.analytics_rounded,
            _headerColor,
          ),
          const SizedBox(height: 12),
          // Coins earned (only for 100% success with > 5 questions)
          _buildSummaryItem(
            context.trWithFallback('coinsEarnedLbl', 'Coins Earned'),
            '$earnedCoins',
            Icons.monetization_on,
            const Color(0xFFFFC107),
          ),
          const SizedBox(height: 20),
          
          // Review Answers Button
          _buildActionButton(
            context.trWithFallback('reviewAnsBtn', 'Review Answers'),
            _reviewAnswers,
            isPrimary: false,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.primaryTextColor,
                                  ),
                                ),
          const Spacer(),
                                Text(
            value,
                                  style: TextStyle(
              fontSize: 20,
                                    fontWeight: FontWeights.bold,
                                    color: context.primaryTextColor,
                                  ),
                                ),
                              ],
      ),
    );
  }

  Widget _buildPlayAgainTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.replay_rounded,
            size: 60,
            color: _headerColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
                              Text(
            context.trWithFallback('readyForMoreLbl', 'Ready for more?'),
                                style: TextStyle(
              fontSize: 18,
                                  fontWeight: FontWeights.bold,
                                  color: context.primaryTextColor,
                                ),
                              ),
          const SizedBox(height: 8),
          Text(
            context.trWithFallback('playAgainDescLbl', 'Challenge yourself again!'),
            style: TextStyle(
              fontSize: 14,
              color: context.primaryTextColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildPlayAgainButton(),
          const SizedBox(height: 16),
        ],
            ),
          );
        }

  Widget _buildPlayAgainButton() {
    if (widget.quizType == QuizTypes.audioQuestions) {
      return _buildActionButton(
        context.trWithFallback('playAgainBtn', 'Play Again'),
        () {
        fetchUpdateUserDetails();
        Navigator.of(context).pushReplacementNamed(
          Routes.quiz,
          arguments: {
            'isPlayed': widget.isPlayed,
            'quizType': QuizTypes.audioQuestions,
            'subcategoryId': widget.questions!.first.subcategoryId == '0'
                ? ''
                : widget.questions!.first.subcategoryId,
            'categoryId': widget.questions!.first.subcategoryId == '0'
                ? widget.questions!.first.categoryId
                : '',
          },
        );
        },
      );
    } else if (widget.quizType == QuizTypes.guessTheWord) {
      if (_isWinner) {
        return const SizedBox.shrink();
      }

      return _buildActionButton(
        context.trWithFallback('playAgainBtn', 'Play Again'),
        () async {
        await context.pushReplacementNamed(
          Routes.guessTheWord,
          arguments: GuessTheWordQuizScreenArgs(
            categoryId: widget.categoryId!,
            subcategoryId: widget.subcategoryId!.isNotEmpty
                ? widget.subcategoryId
                : null,
            isPlayed: widget.isPlayed,
            isPremiumCategory: widget.isPremiumCategory,
          ),
        );
        },
      );
    } else if (widget.quizType == QuizTypes.quizZone) {
      if (_isWinner) {
        // Check if this is a Rhapsody quiz (has rhapsody day info)
        final isRhapsodyQuiz = widget.rhapsodyDay != null && 
                               widget.rhapsodyMonth != null && 
                               widget.rhapsodyYear != null;
        
        if (isRhapsodyQuiz) {
          // Navigate to the next Rhapsody day
          return _buildActionButton(
            context.trWithFallback('nextBtn', 'Next'),
            () {
              fetchUpdateUserDetails();
              _navigateToNextRhapsodyDay();
            },
          );
        }
        
        // Check if this is a Foundation quiz (has foundation class info)
        final isFoundationQuiz = widget.foundationClassId != null && 
                                 widget.foundationClassOrder != null;
        
        if (isFoundationQuiz) {
          // Navigate to the next Foundation class
          return _buildActionButton(
            context.trWithFallback('nextBtn', 'Next'),
            () {
              fetchUpdateUserDetails();
              _navigateToNextFoundationClass();
            },
          );
        }
        
        // Non-Rhapsody/Foundation quizZone - just go back
        return _buildActionButton(
          context.trWithFallback('nextBtn', 'Next'),
          () {
            fetchUpdateUserDetails();
            Navigator.of(context).pop();
          },
        );
      }
      return _buildActionButton(
        context.trWithFallback('playAgainBtn', 'Play Again'),
        () {
        fetchUpdateUserDetails();
        // Restart quiz from the beginning (level 0)
        Navigator.of(context).pushReplacementNamed(
          Routes.quiz,
          arguments: {
            'quizType': widget.quizType,
            'categoryId': widget.categoryId,
            'subcategoryId': widget.subcategoryId,
            'level': '0', // Start from beginning
            'unlockedLevel': 0,
            'subcategoryMaxLevel': widget.subcategoryMaxLevel,
          },
        );
        },
      );
    } else if (widget.quizType == QuizTypes.funAndLearn) {
      // Rhapsody quiz - show "Next" button to go back to days list
      return _buildActionButton(
        context.trWithFallback('nextBtn', 'Next'),
        () {
          fetchUpdateUserDetails();
          // Go back to the Rhapsody days list
          Navigator.of(context).pop();
        },
      );
    }

    // Default fallback - show a "Done" button to go back
    return _buildActionButton(
      context.trWithFallback('doneBtn', 'Done'),
      () {
        fetchUpdateUserDetails();
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, {bool isPrimary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? _headerColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: _headerColor),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeights.semiBold,
            color: isPrimary ? Colors.white : _headerColor,
          ),
        ),
      ),
    );
  }

  Future<void> _shareScore() async {
          if (_isShareInProgress) return;

          setState(() => _isShareInProgress = true);

          try {
            final image = await screenshotController.capture();
            final directory = (await getApplicationDocumentsDirectory()).path;

            final fileName = DateTime.now().microsecondsSinceEpoch.toString();
            final file = await File('$directory/$fileName.png').create();
            await file.writeAsBytes(image!.buffer.asUint8List());

            final appLink = context.read<SystemConfigCubit>().appUrl;
            final referralCode =
          context.read<UserDetailsCubit>().getUserProfile().referCode ?? '';

            final scoreText =
                '$kAppName'
                "\n${context.tr('myScoreLbl')!}"
                "\n${context.tr("appLink")!}"
                '\n$appLink'
                "\n${context.tr("useMyReferral")} $referralCode ${context.tr("toGetCoins")}";

            await UiUtils.share(
              scoreText,
              files: [XFile(file.path)],
              context: context,
            ).onError((e, s) => ShareResult('$e', ShareResultStatus.dismissed));
          } on Exception catch (_) {
            if (!mounted) return;

            context.showSnack(
              context.tr(
                convertErrorCodeToLanguageKey(errorCodeDefaultMessage),
              )!,
            );
          } finally {
            if (mounted) {
              setState(() => _isShareInProgress = false);
            }
          }
  }

  bool _unlockedReviewAnswersOnce = false;

  Future<void> _reviewAnswers() async {
    if (_isReviewInProgress) return;

    if (_unlockedReviewAnswersOnce) {
      await context.pushNamed(
        Routes.reviewAnswers,
        arguments: ReviewAnswersScreenArgs(
          quizType: widget.quizType!,
          questions: widget.quizType == QuizTypes.guessTheWord
              ? []
              : widget.questions!,
          guessTheWordQuestions: widget.quizType == QuizTypes.guessTheWord
              ? widget.guessTheWordQuestions!
              : [],
        ),
      );
      return;
    }

    setState(() => _isReviewInProgress = true);

    try {
      await context.showDialog<void>(
        title: context.tr('reviewAnswers'),
        image: Assets.coinsDialogIcon,
        message:
            '${context.tr('spend')} ${context.read<SystemConfigCubit>().reviewAnswersDeductCoins} ${context.tr('reviewAnsMessage')}',
        onConfirm: () async {
      final reviewAnswersDeductCoins = context
          .read<SystemConfigCubit>()
          .reviewAnswersDeductCoins;
          
      if ((int.tryParse(context.read<UserDetailsCubit>().getCoins() ?? '') ?? 0) <
          reviewAnswersDeductCoins) {
        await showNotEnoughCoinsDialog(context);
        return;
      }

      await context
          .read<UpdateCoinsCubit>()
          .updateCoins(
            coins: reviewAnswersDeductCoins,
            addCoin: false,
            title: reviewAnswerLbl,
          )
          .then((_) async {
            final state = context.read<UpdateCoinsCubit>().state;
            if (state is UpdateCoinsFailure) {
              context
                ..shouldPop()
                ..showSnack(
                  context.tr(
                        convertErrorCodeToLanguageKey(state.errorMessage),
                      ) ??
                      context.tr(errorCodeDefaultMessage)!,
                );
              return;
            } else if (state is UpdateCoinsSuccess) {
              context.read<UserDetailsCubit>().updateCoins(
                addCoin: false,
                coins: reviewAnswersDeductCoins,
              );

              _unlockedReviewAnswersOnce = true;
              await context.pushNamed(
                Routes.reviewAnswers,
                arguments: ReviewAnswersScreenArgs(
                  quizType: widget.quizType!,
                  questions: widget.quizType == QuizTypes.guessTheWord
                      ? []
                      : widget.questions!,
                  guessTheWordQuestions:
                      widget.quizType == QuizTypes.guessTheWord
                      ? widget.guessTheWordQuestions!
                      : [],
                ),
              );
            }
          });
        },
          confirmButtonText: context.tr('reviewAndImprove'),
          cancelButtonText: context.tr('notNow'),
        );
      } finally {
        if (mounted) {
          setState(() => _isReviewInProgress = false);
        }
      }
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
}
