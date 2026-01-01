import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/ads/ads.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/badges/blocs/badges_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/battle_room_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/multi_user_battle_room_cubit.dart';
import 'package:flutterquiz/features/exam/cubits/exam_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_local_data_source.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/daily_contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/battle/create_or_join_screen.dart';
import 'package:flutterquiz/ui/screens/home/widgets/all.dart';
import 'package:flutterquiz/ui/screens/profile/create_or_edit_profile_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/category_screen.dart';
import 'package:flutterquiz/ui/widgets/all.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

typedef ZoneType = ({String title, String img, String desc});

class HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  bool get _isGuest => context.read<AuthCubit>().isGuest;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int _notificationId = 0;

  final battleZones = <ZoneType>[
    (title: 'groupPlay', img: Assets.groupBattleIcon, desc: 'desGroupPlay'),
    (title: 'battleQuiz', img: Assets.oneVsOneIcon, desc: 'desBattleQuiz'),
  ];

  final examZones = <ZoneType>[
    (title: 'exam', img: Assets.examQuizIcon, desc: 'desExam'),
    (
      title: 'selfChallenge',
      img: Assets.selfChallengeIcon,
      desc: 'challengeYourselfLbl',
    ),
  ];

  /// Blue header color (matching Foundation School)
  static const _headerColor = Color(0xFF1565C0);

  // Screen dimensions
  double get scrWidth => context.width;

  double get scrHeight => context.height;

  // HomeScreen horizontal margin, change from here
  double get hzMargin => scrWidth * UiUtils.hzMarginPct;

  double get _statusBarPadding => MediaQuery.of(context).padding.top;

  // TextStyles
  // check build() method
  late var _boldTextStyle = TextStyle(
    fontWeight: FontWeights.bold,
    fontSize: 18,
    color: Theme.of(context).colorScheme.onTertiary,
  );

  ///
  late String _currLangId;
  late final SystemConfigCubit _sysConfigCubit;
  
  /// Daily Contest status
  bool _hasPendingDailyContest = false;
  late final DailyContestCubit _dailyContestCubit;

  @override
  void initState() {
    super.initState();

    showAppUnderMaintenanceDialog();

    _sysConfigCubit = context.read<SystemConfigCubit>();
    
    // Initialize daily contest cubit
    _dailyContestCubit = DailyContestCubit(QuizRepository());
    _checkDailyContestStatus();

    setQuizMenu();
    _initLocalNotification();
    setupInteractedMessage();

    /// Create Ads
    Future.delayed(Duration.zero, () async {
      await context.read<RewardedAdCubit>().createDailyRewardAd(context);
      context.read<InterstitialAdCubit>().createInterstitialAd(context);
    });

    WidgetsBinding.instance.addObserver(this);

    ///
    _currLangId = UiUtils.getCurrentQuizLanguageId(context);

    if (!_isGuest) {
      fetchUserDetails();

      context.read<ContestCubit>().getContest(languageId: _currLangId);
    }

    // Pre-fetch all data for offline use (runs in background)
    _prefetchDataForOffline();
  }

  /// Pre-fetch all essential data for offline use
  void _prefetchDataForOffline() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      DataPrefetcher.instance.prefetchAll(
        connectivityCubit: context.read<ConnectivityCubit>(),
        languageId: _currLangId,
      );
    });
  }

  void onTapTab() {
    if (_scrollController.hasClients && _scrollController.offset != 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      refreshKey.currentState?.show();
    }
  }

  void showAppUnderMaintenanceDialog() {
    Future.delayed(Duration.zero, () {
      if (_sysConfigCubit.isAppUnderMaintenance) {
        showDialog<void>(
          context: context,
          builder: (_) => const AppUnderMaintenanceDialog(),
        );
      }
    });
  }

  Future<void> _initLocalNotification() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onTapLocalNotification,
    );

    /// Request Permissions for IOS
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions();
    }
  }

  void setQuizMenu() {
    Future.delayed(Duration.zero, () {
      if (!_sysConfigCubit.isExamQuizEnabled) {
        examZones.removeWhere((e) => e.title == 'exam');
      }

      if (!_sysConfigCubit.isSelfChallengeQuizEnabled) {
        examZones.removeWhere((e) => e.title == 'selfChallenge');
      }

      if (!_sysConfigCubit.isGroupBattleEnabled) {
        battleZones.removeWhere((e) => e.title == 'groupPlay');
      }

      if (!_sysConfigCubit.isOneVsOneBattleEnabled &&
          !_sysConfigCubit.isRandomBattleEnabled) {
        battleZones.removeWhere((e) => e.title == 'battleQuiz');
      }

      setState(() {});
    });
  }

  static StreamSubscription<RemoteMessage>? notificationStream;

  Future<void> setupInteractedMessage() async {
    if (Platform.isIOS) {
      // Request full notification permissions on iOS
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
        provisional: false, // Request full permission, not provisional
      );
      log('iOS notification permission: ${settings.authorizationStatus}');
      
      // Get APNs token to verify iOS push is working
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        log('APNs token obtained: ${apnsToken != null ? "YES (${apnsToken.substring(0, 20)}...)" : "NO"}');
      } catch (e) {
        log('Failed to get APNs token: $e');
      }
    } else {
      final isGranted = (await Permission.notification.status).isGranted;
      if (!isGranted) await Permission.notification.request();
    }

    await notificationStream?.cancel();

    // Get FCM token for debugging
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      log('FCM token: ${fcmToken != null ? "${fcmToken.substring(0, 30)}..." : "NULL"}');
    } catch (e) {
      log('Failed to get FCM token: $e');
    }

    // Subscribe to daily_quiz topic for notifications
    try {
      await FirebaseMessaging.instance.subscribeToTopic('daily_quiz');
      log('✓ Subscribed to daily_quiz topic');
    } catch (e) {
      log('✗ Failed to subscribe to topic: $e');
    }

    await FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // handle background notification
    FirebaseMessaging.onBackgroundMessage(UiUtils.onBackgroundMessage);
    //handle foreground notification
    notificationStream = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      if (message.data.isNotEmpty) {
        log('Notification arrives : ${message.toMap()}');
        final data = message.data;
        final title = data['title'].toString();
        final body = data['body'].toString();
        final type = data['type'].toString();
        final image = data['image'].toString();

        //payload is some data you want to pass in local notification
        if (image != 'null' && image.isNotEmpty) {
          log('image ${image.runtimeType}');
          await generateImageNotification(title, body, image, type, type);
        } else {
          await generateSimpleNotification(title, body, type);
        }

        //if notification type is badges then update badges in cubit list
        if (type == 'badges') {
          Future.delayed(Duration.zero, () {
            if (context.mounted) {
              context.read<BadgesCubit>().unlockBadge(
                data['badge_type'] as String,
              );
            }
          });
        } else if (type == 'payment_request') {
          Future.delayed(Duration.zero, () {
            context.read<UserDetailsCubit>().updateCoins(
              addCoin: true,
              coins: int.parse(data['coins'] as String),
            );
          });
        }
      }
    });
  }

  //quiz_type according to the notification category
  QuizTypes _getQuizTypeFromCategory(String category) {
    return switch (category) {
      'audio-question-category' => QuizTypes.audioQuestions,
      'guess-the-word-category' => QuizTypes.guessTheWord,
      'fun-n-learn-category' => QuizTypes.funAndLearn,
      _ => QuizTypes.quizZone,
    };
  }

  // notification type is category then move to category screen
  Future<void> _handleMessage(RemoteMessage message) async {
    try {
      if (message.data['type'].toString().contains('category')) {
        await Navigator.of(context).pushNamed(
          Routes.category,
          arguments: CategoryScreenArgs(
            quizType: _getQuizTypeFromCategory(message.data['type'] as String),
          ),
        );
      } else if (message.data['type'] == 'badges') {
        //if user open app by tapping
        UiUtils.updateBadgesLocally(context);
        await Navigator.of(context).pushNamed(Routes.badges);
      } else if (message.data['type'] == 'payment_request') {
        await Navigator.of(context).pushNamed(Routes.wallet);
      }
    } on Exception catch (e) {
      log(e.toString(), error: e);
    }
  }

  Future<void> _onTapLocalNotification(NotificationResponse? payload) async {
    final type = payload!.payload ?? '';
    if (type == 'badges') {
      await Navigator.of(context).pushNamed(Routes.badges);
    } else if (type.contains('category')) {
      await Navigator.of(context).pushNamed(
        Routes.category,
        arguments: CategoryScreenArgs(quizType: _getQuizTypeFromCategory(type)),
      );
    } else if (type == 'payment_request') {
      await Navigator.of(context).pushNamed(Routes.wallet);
    }
  }

  Future<void> generateImageNotification(
    String title,
    String msg,
    String image,
    String payloads,
    String type,
  ) async {
    final largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true,
    );
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      kPackageName,
      kAppName,
      icon: '@drawable/ic_notification',
      channelDescription: kAppName,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation,
    );
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      _notificationId++,
      title,
      msg,
      platformChannelSpecifics,
      payload: payloads,
    );
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  // notification on foreground
  Future<void> generateSimpleNotification(
    String title,
    String body,
    String payloads,
  ) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      kPackageName, //channel id
      kAppName, //channel name
      channelDescription: kAppName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@drawable/ic_notification',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      _notificationId++,
      title,
      body,
      platformChannelSpecifics,
      payload: payloads,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dailyContestCubit.close();
    ProfileManagementLocalDataSource().updateReversedCoins(0);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Check if user has a pending daily contest
  /// Also manages local reminder notifications
  Future<void> _checkDailyContestStatus() async {
    if (_isGuest) return;
    
    try {
      await _dailyContestCubit.checkDailyContestStatus();
      if (mounted) {
        final hasPending = _dailyContestCubit.hasPendingContest;
        setState(() {
          _hasPendingDailyContest = hasPending;
        });
        
        // Manage local reminders based on contest status
        if (hasPending) {
          // User hasn't completed today's contest - schedule reminders
          log('Scheduling local reminders for pending contest', name: 'HomeScreen');
          await LocalReminderService.instance.scheduleContestReminders();
        } else {
          // User completed today's contest - cancel reminders
          log('Cancelling local reminders - contest completed', name: 'HomeScreen');
          await LocalReminderService.instance.cancelContestReminders();
        }
      }
    } catch (e) {
      log('Error checking daily contest status: $e', name: 'HomeScreen');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    //show you left the game
    if (state == AppLifecycleState.resumed) {
      UiUtils.needToUpdateCoinsLocally(context);
    } else {
      ProfileManagementLocalDataSource().updateReversedCoins(0);
    }
  }

  void _onPressedSelfExam(String index) {
    if (_isGuest) {
      showLoginRequiredDialog(context);
      return;
    }

    if (index == 'exam') {
      context.read<ExamCubit>().reset();
      globalCtx.pushNamed(Routes.exams);
    } else if (index == 'selfChallenge') {
      context.read<QuizCategoryCubit>().reset();
      context.read<SubCategoryCubit>().reset();
      globalCtx.pushNamed(Routes.selfChallenge);
    }
  }

  void _onPressedSoloMode() {
    if (_isGuest) {
      showLoginRequiredDialog(context);
      return;
    }
    globalCtx.pushNamed(Routes.soloMode);
  }

  void _onPressedBattle(String index) {
    if (_isGuest) {
      showLoginRequiredDialog(context);
      return;
    }

    context.read<QuizCategoryCubit>().reset();
    if (index == 'groupPlay') {
      context.read<MultiUserBattleRoomCubit>().reset(cancelSubscription: false);

      globalCtx.push(
        CupertinoPageRoute<void>(
          builder: (_) => BlocProvider<UpdateCoinsCubit>(
            create: (context) =>
                UpdateCoinsCubit(ProfileManagementRepository()),
            child: CreateOrJoinRoomScreen(
              quizType: QuizTypes.groupPlay,
              title: context.tr('groupPlay')!,
            ),
          ),
        ),
      );
    } else if (index == 'battleQuiz') {
      context.read<BattleRoomCubit>().updateState(
        const BattleRoomInitial(),
        cancelSubscription: true,
      );

      if (_sysConfigCubit.isRandomBattleEnabled) {
        globalCtx.pushNamed(Routes.randomBattle);
      } else {
        globalCtx.push(
          CupertinoPageRoute<CreateOrJoinRoomScreen>(
            builder: (_) => BlocProvider<UpdateCoinsCubit>(
              create: (_) => UpdateCoinsCubit(ProfileManagementRepository()),
              child: CreateOrJoinRoomScreen(
                quizType: QuizTypes.oneVsOneBattle,
                title: context.tr('playWithFrdLbl')!,
              ),
            ),
          ),
        );
      }
    }
  }

  late String _userName = context.tr('guest')!;
  String _userProfileImg = '';

  Widget _buildGameModes() {
    return Padding(
      padding: EdgeInsets.only(
        left: hzMargin,
        right: hzMargin,
        top: 16,
      ),
      child: Row(
        children: [
          // Solo Mode (Self Challenge)
          if (_sysConfigCubit.isSelfChallengeQuizEnabled)
            Expanded(
              child: GameModeCard(
                title: context.trWithFallback('soloModeLbl', 'Solo'),
                backgroundColor: GameModeColors.soloMode,
                imagePath: 'assets/images/solo_mode.png',
                onTap: () => _onPressedSoloMode(),
              ),
            ),
          if (_sysConfigCubit.isSelfChallengeQuizEnabled)
            const SizedBox(width: 12),
          
          // Multiplayer Mode (Group Battle)
          if (_sysConfigCubit.isGroupBattleEnabled)
            Expanded(
              child: GameModeCard(
                title: context.trWithFallback('multiplayerModeLbl', 'Multiplayer'),
                backgroundColor: GameModeColors.multiplayerMode,
                imagePath: 'assets/images/multiplayer_mode.png',
                onTap: () => _onPressedBattle('groupPlay'),
              ),
            ),
          if (_sysConfigCubit.isGroupBattleEnabled)
            const SizedBox(width: 12),
          
          // 1 Vs 1 Mode (Battle Quiz)
          if (_sysConfigCubit.isOneVsOneBattleEnabled || _sysConfigCubit.isRandomBattleEnabled)
            Expanded(
              child: GameModeCard(
                title: context.trWithFallback('oneVsOneModeLbl', '1 Vs 1'),
                backgroundColor: GameModeColors.oneVsOneMode,
                imagePath: 'assets/images/one_vs_one_mode.png',
                onTap: () => _onPressedBattle('battleQuiz'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBattle() {
    return battleZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(battleOfTheDayKey)!,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeights.semiBold,
                    color: context.primaryTextColor,
                  ),
                ),

                /// Categories
                GridView.count(
                  // Create a grid with 2 columns. If you change the scrollDirection to
                  // horizontal, this produces 2 rows.
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(
                    battleZones.length,
                    (i) => QuizGridCard(
                      onTap: () => _onPressedBattle(battleZones[i].title),
                      title: context.tr(battleZones[i].title)!,
                      desc: context.tr(battleZones[i].desc)!,
                      img: battleZones[i].img,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _buildExamSelf() {
    return examZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(selfExamZoneKey)!,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeights.semiBold,
                    color: context.primaryTextColor,
                  ),
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(
                    examZones.length,
                    (i) => QuizGridCard(
                      onTap: () => _onPressedSelfExam(examZones[i].title),
                      title: context.tr(examZones[i].title)!,
                      desc: context.tr(examZones[i].desc)!,
                      img: examZones[i].img,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _buildDailyAds() {
    var clicked = false;
    return BlocBuilder<RewardedAdCubit, RewardedAdState>(
      builder: (context, state) {
        if (state is RewardedAdLoaded &&
            context.read<UserDetailsCubit>().isDailyAdAvailable) {
          return GestureDetector(
            onTap: () async {
              if (!clicked) {
                await context.read<RewardedAdCubit>().showDailyAd(
                  context: context,
                );
                clicked = true;
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                left: hzMargin,
                right: hzMargin,
                top: scrHeight * 0.02,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              width: scrWidth,
              height: scrWidth * 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      Assets.dailyCoins,
                      width: scrWidth * .23,
                      height: scrWidth * .23,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          context.tr('dailyAdsTitle')!,
                          maxLines: 2,
                          style: TextStyle(
                            fontWeight: FontWeights.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${context.tr("get")!} "
                        '${_sysConfigCubit.coinsPerDailyAdView} '
                        "${context.tr("dailyAdsDesc")!}",
                        style: TextStyle(
                          fontWeight: FontWeights.regular,
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiary.withValues(alpha: .6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContestPromoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hzMargin),
      child: GestureDetector(
        onTap: () {
          if (_isGuest) {
            showLoginRequiredDialog(context);
            return;
          }
          if (_sysConfigCubit.isContestEnabled) {
            Navigator.of(context).pushNamed(Routes.contest).then((_) {
              // Refresh daily contest status when returning from contest screen
              _checkDailyContestStatus();
            });
          } else {
            context.showSnack(context.tr(currentlyNotAvailableKey)!);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  // Trophy Image
                  Image.asset(
                    'assets/images/cup-contest.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(contest) ?? 'Contest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compete and win prizes!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr('playnowLbl') ?? 'Play Now',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Notification Badge - shows when daily contest is pending (with jiggle animation)
            if (_hasPendingDailyContest)
              Positioned(
                top: -8,
                right: -8,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    // Continuous jiggle using a repeating animation
                    return _JigglingBadge(child: child!);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveContestSection() {
    void onTapViewAll() {
      if (_sysConfigCubit.isContestEnabled) {
        Navigator.of(context).pushNamed(Routes.contest);
      } else {
        context.showSnack(context.tr(currentlyNotAvailableKey)!);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hzMargin, vertical: 10),
      child: Column(
        children: [
          /// Contest Section Title
          Row(
            children: [
              Text(
                context.tr(contest) ?? contest,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeights.semiBold,
                  color: context.primaryTextColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onTapViewAll,
                child: Text(
                  context.tr(viewAllKey) ?? viewAllKey,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeights.semiBold,
                    color: context.primaryTextColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// Contest Card
          BlocConsumer<ContestCubit, ContestState>(
            bloc: context.read<ContestCubit>(),
            listener: (context, state) {
              if (state is ContestFailure) {
                if (state.errorMessage == errorCodeUnauthorizedAccess) {
                  showAlreadyLoggedInDialog(context);
                }
              }
            },
            builder: (context, state) {
              if (state is ContestFailure) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    context.tr(
                      convertErrorCodeToLanguageKey(state.errorMessage),
                    )!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeights.regular,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 2,
                  ),
                );
              }

              if (state is ContestSuccess) {
                final colorScheme = Theme.of(context).colorScheme;
                final textStyle = GoogleFonts.nunito(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeights.regular,
                    color: colorScheme.onTertiary.withValues(alpha: 0.6),
                  ),
                );

                ///
                final live = state.contestList.live;

                /// No Contest
                if (live.errorMessage.isNotEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      context.tr(
                        convertErrorCodeToLanguageKey(live.errorMessage),
                      )!,
                      style: _boldTextStyle.copyWith(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }

                final contest = live.contestDetails.first;
                final entryFee = int.parse(contest.entry!);

                void onTapPlayNow() {
                  final userDetailsCubit = context.read<UserDetailsCubit>();

                  if (int.parse(userDetailsCubit.getCoins()!) >= entryFee) {
                    context.read<UpdateCoinsCubit>().updateCoins(
                      coins: entryFee,
                      addCoin: false,
                      title: playedContestKey,
                    );
                    userDetailsCubit.updateCoins(
                      addCoin: false,
                      coins: entryFee,
                    );

                    Navigator.of(globalCtx).pushNamed(
                      Routes.quiz,
                      arguments: {
                        'quizType': QuizTypes.contest,
                        'contestId': contest.id,
                      },
                    );
                  } else {
                    showNotEnoughCoinsDialog(context);
                  }
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 5),
                        blurRadius: 5,
                        color: Colors.black12,
                      ),
                    ],
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(99999),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(12.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Contest Image
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: QImage(
                                  imageUrl: contest.image!,
                                  height: 45,
                                  width: 45,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            /// Contest Name & Description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contest.name.toString(),
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: _boldTextStyle.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    contest.description.toString(),
                                    softWrap: true,
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: textStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        ///
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Entry Fees
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: context.tr('entryFeesLbl'),
                                      ),
                                      const TextSpan(text: ' : '),
                                      TextSpan(
                                        text:
                                            "$entryFee ${context.tr("coinsLbl")!}",
                                        style: textStyle.copyWith(
                                          color: colorScheme.onTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: textStyle,
                                ),
                                const SizedBox(height: 5),

                                /// Ends on
                                Text.rich(
                                  style: textStyle,
                                  TextSpan(
                                    children: [
                                      TextSpan(text: context.tr('endsOnLbl')),
                                      const TextSpan(text: ' : '),
                                      TextSpan(
                                        text: '${contest.endDate}  |  ',
                                        style: textStyle.copyWith(
                                          color: colorScheme.onTertiary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: contest.participants.toString(),
                                        style: textStyle.copyWith(
                                          color: colorScheme.onTertiary,
                                        ),
                                      ),
                                      const TextSpan(text: ' : '),
                                      TextSpan(text: context.tr('playersLbl')),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            /// Play Now
                            GestureDetector(
                              onTap: onTapPlayNow,
                              child: Container(
                                width: double.maxFinite,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                ),
                                child: Text(
                                  context.tr('playnowLbl')!,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const Center(child: CircularProgressContainer());
            },
          ),
        ],
      ),
    );
  }

  String _userRank = '0';
  String _userCoins = '0';
  String _userScore = '0';

  Widget _buildHome() {
    return BlocConsumer<AppLocalizationCubit, AppLocalizationState>(
      listener: (context, state) async {
        _userName = context.tr('guest')!;
        if (_isGuest) return;

        final currentLanguage = state.language.name;
        final userProfile = context.read<UserDetailsCubit>().getUserProfile();

        if (currentLanguage != userProfile.appLanguage) {
          await context.read<UserDetailsCubit>().updateLanguage(
            currentLanguage,
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
                      key: refreshKey,
          color: Colors.white,
          backgroundColor: _headerColor,
                      onRefresh: () async {
                        _currLangId = UiUtils.getCurrentQuizLanguageId(context);

                        if (!_isGuest) {
                          fetchUserDetails();

                          await context.read<ContestCubit>().getContest(
                            languageId: _currLangId,
                          );
              
              // Refresh daily contest status for notification badge
              await _checkDailyContestStatus();
                        }
                        setState(() {});
                      },
                      child: ListView(
                        controller: _scrollController,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
                        children: [
              // Blue header section
              Container(
                decoration: const BoxDecoration(
                  color: _headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Header with avatar, app name, notification
                      _buildPurpleHeader(),
                      
                      const SizedBox(height: 16),
                      
                      // Stats bar (Rank & Reward Points)
                          UserAchievements(
                            userRank: _userRank,
                            userCoins: _userCoins,
                            userScore: _userScore,
                          ),
                      
                      // Extra space for game modes to overlap into
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              // Game Mode Cards - pulled up with negative margin to overlap header
              Transform.translate(
                offset: const Offset(0, -80),
                child: _buildGameModes(),
              ),
              
              // Contest Promotion Section - moved up
              Transform.translate(
                offset: const Offset(0, -50),
                child: _buildContestPromoSection(),
              ),
              
              // Rhapsody Section
              RhapsodySection(
                months: _buildRhapsodyMonths(),
                onViewAll: () {
                  // Navigate to Rhapsody screen with year tabs
                  Navigator.pushNamed(context, Routes.rhapsody);
                },
                onMonthTap: (month) {
                  // Navigate directly to the month screen
                  Navigator.pushNamed(
                    context,
                    Routes.rhapsodyMonth,
                    arguments: {
                      'year': month.year,
                      'month': month.month,
                      'monthName': month.name,
                    },
                  );
                },
                onCurrentMonthTap: () {
                  if (_isGuest) {
                    showLoginRequiredDialog(context);
                    return;
                  }
                  // Navigate to current month's devotional
                  final now = DateTime.now();
                  final monthNames = [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ];
                  Navigator.pushNamed(
                    context,
                    Routes.rhapsodyMonth,
                    arguments: {
                      'year': now.year,
                      'month': now.month,
                      'monthName': monthNames[now.month - 1],
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting current month quiz...')),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Daily Ads
                          if (!_isGuest &&
                              _sysConfigCubit.isAdsEnable &&
                              _sysConfigCubit.isDailyAdsEnabled) ...[
                            _buildDailyAds(),
                          ],
              
              
              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        );
      },
    );
  }

  List<RhapsodyMonth> _buildRhapsodyMonths() {
    // Generate the 4 most recent months for Rhapsody
    // These would typically come from the API, but for now we show placeholders
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final colors = [
      CategoryColors.space,    // Orange
      CategoryColors.sports,   // Pink
      CategoryColors.history,  // Green
      CategoryColors.maths,    // Purple
    ];

    return List.generate(4, (index) {
      // Start from previous month (current month is shown separately)
      final targetMonth = now.month - index - 1;
      final targetYear = now.year;
      
      // Adjust for year boundaries
      DateTime date;
      if (targetMonth <= 0) {
        date = DateTime(targetYear - 1, 12 + targetMonth);
      } else {
        date = DateTime(targetYear, targetMonth);
      }

      return RhapsodyMonth(
        id: '${date.year}-${date.month}',
        name: monthNames[date.month - 1],
        year: date.year,
        month: date.month,
        color: colors[index % colors.length],
        questionCount: 0, // Would come from API
        categoryId: null, // Would come from API
      );
    });
  }

  Widget _buildPurpleHeader() {
    void onTapNotification() {
      if (_isGuest) {
        globalCtx.pushNamed(Routes.login);
      } else {
        globalCtx.pushNamed(Routes.notification);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hzMargin, vertical: 8),
      child: Row(
        children: [
          // User Avatar - Circle (clickable -> Edit Profile)
          GestureDetector(
            onTap: () {
              if (_isGuest) {
                showLoginRequiredDialog(context);
              } else {
                globalCtx.pushNamed(
                  Routes.selectProfile,
                  arguments: const CreateOrEditProfileScreenArgs(isNewUser: false),
                );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _userProfileImg.isNotEmpty
                    ? QImage(imageUrl: _userProfileImg)
                    : Container(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),
          
          // App Name (centered)
          Expanded(
            child: Text(
              kAppName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeights.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // TODO: Enable Groups Button in next release
          // Groups Button - Hidden for now
          // GestureDetector(
          //   onTap: () {
          //     if (_isGuest) {
          //       showLoginRequiredDialog(context);
          //     } else {
          //       globalCtx.pushNamed(Routes.groups);
          //     }
          //   },
          //   child: Container(
          //     width: 44,
          //     height: 44,
          //     decoration: BoxDecoration(
          //       color: Colors.white.withValues(alpha: 0.2),
          //       shape: BoxShape.circle,
          //     ),
          //     child: const Icon(
          //       Icons.groups_rounded,
          //       color: Colors.white,
          //       size: 22,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 8),
          // Notification Bell with badge for pending daily contest
          GestureDetector(
            onTap: onTapNotification,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isGuest ? Icons.login_rounded : Icons.notifications_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                // Red badge when daily contest is pending
                if (!_isGuest && _hasPendingDailyContest)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    void onTapNotification() {
      if (_isGuest) {
        globalCtx.pushNamed(Routes.login);
      } else {
        globalCtx.pushNamed(Routes.notification);
      }
    }

    void onTapCoinStore() {
      globalCtx.pushNamed(Routes.coinStore);
    }

    const minHeaderHeight = 100.0;
    const minContentHeight = 48.0;
    const iconSize = 36.0;
    const avatarSize = 44.0;

    final headerHeight = (context.height * .16).clamp(minHeaderHeight, 160.0);

    return Stack(
      clipBehavior: .none,
      alignment: .bottomCenter,
      children: [
        Container(
          height: context.height * .01,
          width: context.width * .8,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.elliptical(context.height * .04, context.height * .04),
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryTextColor.withValues(alpha: .3),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        Container(
          height: headerHeight,
          width: context.width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(10),
            ),
          ),
          alignment: .bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minContentHeight),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: .circle,
                    border: Border.all(
                      color: context.primaryTextColor.withValues(alpha: .3),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  width: avatarSize,
                  height: avatarSize,
                  child: QImage.circular(imageUrl: _userProfileImg),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisAlignment: .center,
                    mainAxisSize: .min,
                    children: [
                      Text(
                        _userName,
                        textAlign: .start,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 18,
                          fontWeight: .bold,
                        ),
                      ),
                      Text(
                        context.tr(letsPlay)!,
                        textAlign: .start,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          color: context.primaryTextColor.withValues(alpha: .3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onTapNotification,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: .center,
                    child: _isGuest
                        ? Icon(
                            Icons.login_rounded,
                            color: context.surfaceColor,
                            size: 20,
                          )
                        : QImage(
                            imageUrl: Assets.notificationMenuIcon,
                            color: context.surfaceColor,
                            height: 20,
                            width: 20,
                            fit: .contain,
                          ),
                  ),
                ),
                if (_sysConfigCubit.isCoinStoreEnabled) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onTapCoinStore,
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: .center,
                      child: QImage(
                        imageUrl: Assets.coinMenuIcon,
                        color: context.surfaceColor,
                        height: 20,
                        width: 20,
                        fit: .contain,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void fetchUserDetails() {
    context.read<UserDetailsCubit>().fetchUserDetails();
  }

  /// Public method to refresh all home screen data
  /// Called when returning from other screens (Contest, Daily Contest, etc.)
  void refreshHomeData() {
    fetchUserDetails();
    // Refresh daily contest status to update notification badge
    _checkDailyContestStatus();
  }

  bool profileComplete = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    /// need to add this here, cause textStyle doesn't update automatically when changing theme.
    _boldTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: context.primaryTextColor,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: _isGuest
          ? _buildHome()
          /// Build home with User
          : BlocConsumer<UserDetailsCubit, UserDetailsState>(
              bloc: context.read<UserDetailsCubit>(),
              listener: (context, state) {
                if (state is UserDetailsFetchSuccess) {
                  final currLang = context
                      .read<AppLocalizationCubit>()
                      .state
                      .language
                      .name;

                  if (state.userProfile.appLanguage != currLang) {
                    context.read<UserDetailsCubit>().updateLanguage(currLang);
                  }

                  UiUtils.fetchBookmarkAndBadges(
                    context: context,
                    userId: state.userProfile.userId!,
                  );
                  if (state.userProfile.profileUrl!.isEmpty ||
                      state.userProfile.name!.isEmpty) {
                    if (!profileComplete) {
                      profileComplete = true;

                      globalCtx.pushNamed(
                        Routes.selectProfile,
                        arguments: const CreateOrEditProfileScreenArgs(
                          isNewUser: false,
                        ),
                      );
                    }
                    return;
                  }
                } else if (state is UserDetailsFetchFailure) {
                  if (state.errorMessage == errorCodeUnauthorizedAccess) {
                    showAlreadyLoggedInDialog(context);
                  }
                }
              },
              builder: (context, state) {
                if (state is UserDetailsFetchInProgress ||
                    state is UserDetailsInitial) {
                  return const Center(child: CircularProgressContainer());
                }
                if (state is UserDetailsFetchFailure) {
                  return Center(
                    child: ErrorContainer(
                      showBackButton: true,
                      errorMessage: convertErrorCodeToLanguageKey(
                        state.errorMessage,
                      ),
                      onTapRetry: fetchUserDetails,
                      showErrorImage: true,
                    ),
                  );
                }

                final user = (state as UserDetailsFetchSuccess).userProfile;

                _userName = user.name!;
                _userProfileImg = user.profileUrl!;
                _userRank = user.allTimeRank!;
                _userCoins = user.coins!;
                _userScore = user.allTimeScore!;

                return _buildHome();
              },
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Bell badge widget with gentle swing animation
class _JigglingBadge extends StatefulWidget {
  const _JigglingBadge({required this.child});
  
  final Widget child;

  @override
  State<_JigglingBadge> createState() => _JigglingBadgeState();
}

class _JigglingBadgeState extends State<_JigglingBadge> {
  double _angle = 0;
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _startJiggle();
  }

  void _startJiggle() {
    // Gentle swing animation (80ms intervals)
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Gentle bell swing pattern
        final cycleStep = _step % 30;
        
        if (cycleStep < 10) {
          // Gentle swing phase - smooth oscillation
          switch (cycleStep) {
            case 0:
              _angle = 0.12;
              break;
            case 1:
              _angle = 0.18;
              break;
            case 2:
              _angle = 0.12;
              break;
            case 3:
              _angle = 0;
              break;
            case 4:
              _angle = -0.12;
              break;
            case 5:
              _angle = -0.18;
              break;
            case 6:
              _angle = -0.12;
              break;
            case 7:
              _angle = 0;
              break;
            case 8:
              _angle = 0.08;
              break;
            case 9:
              _angle = -0.08;
              break;
          }
        } else {
          // Pause phase - rest before next swing
          _angle = 0;
        }
        
        _step++;
        if (_step >= 60) _step = 0; // Reset after ~4.8 seconds
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _angle,
      child: widget.child,
    );
  }
}
