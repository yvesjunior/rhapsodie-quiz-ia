import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/auth/models/auth_providers_enum.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/settings/settings_cubit.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/app_settings_screen.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/delete_account_dialog.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/language_selector_sheet.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/logout_dialog.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/quiz_language_selector_sheet.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/theme_selector_sheet.dart';
import 'package:flutterquiz/ui/screens/profile/create_or_edit_profile_screen.dart';
import 'package:flutterquiz/ui/widgets/all.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/gdpr_helper.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Menu item with localization key and asset path
typedef MenuItem = ({String name, String image});

/// Blue header color - consistent across all screens
const _headerColor = Color(0xFF1565C0);

final class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => ProfileTabScreenState();
}

final class ProfileTabScreenState extends State<ProfileTabScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  bool get _isGuest => context.read<AuthCubit>().isGuest;

  /// Cached to avoid repeated async calls across rebuilds
  Future<bool>? _gdprFuture;

  /// All menu items in fixed order - visibility determined at build time
  static const List<MenuItem> _allMenuItems = [
    (name: 'wallet', image: Assets.walletMenuIcon),
    (name: 'coinHistory', image: Assets.coinHistoryMenuIcon),
    (name: 'inviteFriendsLbl', image: Assets.inviteFriendsMenuIcon),
    (name: 'badges', image: Assets.badgesMenuIcon),
    (name: 'rewardsLbl', image: Assets.rewardMenuIcon),
    (name: 'statisticsLabel', image: Assets.statisticsMenuIcon),
    (name: 'theme', image: Assets.themeMenuIcon),
    (name: 'quizLanguage', image: Assets.quizLanguageIcon),
    (name: 'language', image: Assets.languageMenuIcon),
    (name: 'soundLbl', image: Assets.volumeIcon),
    (name: 'vibrationLbl', image: Assets.vibrationIcon),
    (name: 'adsPreference', image: Assets.adsPreferenceIcon),
    (name: 'aboutQuizApp', image: Assets.aboutUsMenuIcon),
    (name: 'shareAppLbl', image: Assets.shareMenuIcon),
    (name: 'logoutLbl', image: Assets.logoutMenuIcon),
    (name: 'deleteAccountLbl', image: Assets.deleteAccountMenuIcon),
  ];

  @override
  void initState() {
    super.initState();
    _gdprFuture = GdprHelper.isUnderGdpr();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void onTapTab() {
    if (_scrollController.hasClients && _scrollController.offset != 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Filters menu items based on feature flags, auth state, and GDPR compliance
  List<MenuItem> _getVisibleMenuItems({
    required bool isAuthenticated,
    required bool isUnderGdpr,
  }) {
    final config = context.read<SystemConfigCubit>();
    final systemLanguages = context
        .read<AppLocalizationCubit>()
        .state
        .systemLanguages;

    return _allMenuItems.where((item) {
      if (item.name == 'wallet' && !config.isPaymentRequestEnabled) {
        return false;
      }
      if (item.name == 'quizLanguage' && !config.isLanguageModeEnabled) {
        return false;
      }
      if (item.name == 'language' && systemLanguages.length == 1) {
        return false;
      }
      if (item.name == 'adsPreference' && !isUnderGdpr) {
        return false;
      }
      if ((item.name == 'logoutLbl' || item.name == 'deleteAccountLbl') &&
          !isAuthenticated) {
        return false;
      }

      return true;
    }).toList();
  }

  void _onTapMenuItem(String name) {
    /// Menus that guest can use without being logged in.
    switch (name) {
      case 'theme':
        showThemeSelectorSheet(globalCtx);
        return;
      case 'quizLanguage':
        showQuizLanguageSelectorSheet(globalCtx);
        return;
      case 'language':
        showLanguageSelectorSheet(globalCtx, onChange: () => setState(() {}));
        return;
      case 'aboutQuizApp':
        globalCtx.pushNamed(Routes.aboutApp);
        return;
      case 'shareAppLbl':
        {
          try {
            UiUtils.share(
              '${context.read<SystemConfigCubit>().appUrl}\n${context.read<SystemConfigCubit>().shareAppText}',
              context: globalCtx,
            );
          } on Exception catch (e) {
            context.showSnack(e.toString());
          }
        }
        return;
      case 'adsPreference':
        GdprHelper.changePrivacyPreferences();
        return;
    }

    /// Menus that users can't use without signing in, (ex. in guest mode).
    if (_isGuest) {
      showLoginRequiredDialog(context);
      return;
    }

    switch (name) {
      case 'coinHistory':
        globalCtx.pushNamed(Routes.coinHistory);
        return;
      case 'wallet':
        globalCtx.pushNamed(Routes.wallet);
        return;
      case 'inviteFriendsLbl':
        globalCtx.pushNamed(Routes.referAndEarn);
        return;
      case 'badges':
        globalCtx.pushNamed(Routes.badges);
        return;
      case 'rewardsLbl':
        globalCtx.pushNamed(Routes.rewards);
        return;
      case 'statisticsLabel':
        globalCtx.pushNamed(Routes.statistics);
        return;
      case 'logoutLbl':
        showLogoutDialog(globalCtx);
        return;
      case 'deleteAccountLbl':
        showDeleteAccountDialog(globalCtx);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Purple header background
          Container(
            height: context.height * 0.35,
            decoration: const BoxDecoration(
              color: _headerColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildUserProfile(),
                const SizedBox(height: 20),
                _buildCoinBalanceCard(),
                const SizedBox(height: 20),
                _buildRankingSection(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildMenuSection(),
                const SizedBox(height: 100),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 44), // Placeholder for symmetry
          Text(
            context.trWithFallback('accountLbl', 'Account'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeights.bold,
              color: Colors.white,
            ),
          ),
          // Menu button
          GestureDetector(
            onTap: () {
              // Show menu options
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    void onTapEditProfile() {
      if (_isGuest) {
        showLoginRequiredDialog(context);
        return;
      }

      globalCtx.pushNamed(
        Routes.selectProfile,
        arguments: const CreateOrEditProfileScreenArgs(isNewUser: false),
      );
    }

    return BlocBuilder<UserDetailsCubit, UserDetailsState>(
      builder: (context, state) {
        var profileUrl = '';
        var username = context.tr('guest') ?? 'Guest';
        var userId = '';
        var followers = '0';
        var following = '0';

        if (state is UserDetailsFetchSuccess) {
          profileUrl = state.userProfile.profileUrl ?? '';
          username = state.userProfile.name ?? 'User';
          userId = 'QRZ${state.userProfile.userId ?? ''}';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFFFE4B5),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: profileUrl.isNotEmpty
                          ? QImage(imageUrl: profileUrl, fit: BoxFit.cover)
                          : const Icon(Icons.person, size: 40, color: Colors.brown),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Name and ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeights.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (userId.isNotEmpty)
                          Text(
                            userId,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Followers, Following, Edit Profile
              Row(
                children: [
                  // Followers
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        followers,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeights.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        context.trWithFallback('followersLbl', 'Followers'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  
                  // Following
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        following,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeights.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        context.trWithFallback('followingLbl', 'Following'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Edit Profile Button
                  GestureDetector(
                    onTap: onTapEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CD964),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        context.trWithFallback('editProfileLbl', 'Edit Profile'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeights.semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinBalanceCard() {
    return BlocBuilder<UserDetailsCubit, UserDetailsState>(
      builder: (context, state) {
        var coins = '0';
        if (state is UserDetailsFetchSuccess) {
          coins = NumberFormat.decimalPattern().format(
            int.tryParse(state.userProfile.coins ?? '0') ?? 0,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => globalCtx.pushNamed(Routes.wallet),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFB8E6F7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.trWithFallback('coinBalanceLbl', 'Coin Balance'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Color(0xFFFFC107),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              coins,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeights.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Money bag icon placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD964).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      size: 48,
                      color: Color(0xFF4CD964),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD964),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingSection() {
    return BlocBuilder<UserDetailsCubit, UserDetailsState>(
      builder: (context, state) {
        var rank = '0';
        var rankChange = '+0';
        
        if (state is UserDetailsFetchSuccess) {
          rank = state.userProfile.allTimeRank ?? '0';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    // Rank with change
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getOrdinal(int.tryParse(rank) ?? 0),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeights.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '↑ 27',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeights.semiBold,
                            color: const Color(0xFF4CD964),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // This week dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            context.trWithFallback('thisWeekLbl', 'This week'),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.primaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: context.primaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Labels
                Row(
                  children: [
                    Text(
                      context.trWithFallback('rankingLbl', 'Ranking'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.primaryTextColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      context.trWithFallback('pointsLbl', 'Points'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.primaryTextColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Chart placeholder
                SizedBox(
                  height: 100,
                  child: CustomPaint(
                    size: const Size(double.infinity, 100),
                    painter: _ChartPainter(),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Days of week
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((day) => Text(
                            day,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.primaryTextColor.withValues(alpha: 0.5),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: context.trWithFallback('correctoMeterLbl', 'Correcto Meter'),
              value: '68%',
              dropdownValue: 'All',
              color: const Color(0xFF4CD964),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: context.trWithFallback('winningMeterLbl', 'Winning Meter'),
              value: '59%',
              dropdownValue: 'All',
              color: const Color(0xFF4CD964),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String dropdownValue,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeights.bold,
                  color: context.primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      dropdownValue,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.primaryTextColor,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: context.primaryTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: context.primaryTextColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar placeholder
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: double.tryParse(value.replaceAll('%', ''))! / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) =>
          (previous is Authenticated) != (current is Authenticated),
      builder: (context, authState) {
        final isAuthenticated = authState is Authenticated;

        return FutureBuilder<bool>(
          future: _gdprFuture,
          builder: (context, gdprSnapshot) {
            final isUnderGdpr =
                gdprSnapshot.hasData && (gdprSnapshot.data ?? false);

            final visibleItems = _getVisibleMenuItems(
              isAuthenticated: isAuthenticated,
              isUnderGdpr: isUnderGdpr,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: visibleItems.map((item) => _buildMenuItem(item)).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    Widget? trailing;
    final isDeleteAccount = item.name == 'deleteAccountLbl';

    if (item.name == 'soundLbl') {
      trailing = const _SoundSwitchWidget();
    } else if (item.name == 'vibrationLbl') {
      trailing = const _VibrationSwitchWidget();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
      onTap: () => _onTapMenuItem(item.name),
        borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDeleteAccount 
              ? Colors.red.shade50 
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: isDeleteAccount 
              ? Border.all(color: Colors.red.shade300, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            QImage(
              imageUrl: item.image,
              color: isDeleteAccount ? Colors.red : context.primaryColor,
              fit: BoxFit.fitHeight,
              height: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr(item.name)!,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontWeight: isDeleteAccount ? FontWeights.bold : FontWeights.regular,
                  fontSize: 16,
                  color: isDeleteAccount ? Colors.red : context.primaryTextColor,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
          ],
          ),
        ),
      ),
    );
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

/// Simple chart painter for ranking visualization
class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CD964)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = const Color(0xFF4CD964).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    // Sample data points
    final points = [0.3, 0.4, 0.35, 0.5, 0.7, 0.8, 0.75];
    final width = size.width;
    final height = size.height;
    final stepX = width / (points.length - 1);

    // Start fill path
    fillPath.moveTo(0, height);
    
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = height - (points[i] * height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    // Complete fill path
    fillPath.lineTo(width, height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw dots
    final dotPaint = Paint()
      ..color = const Color(0xFF4CD964)
      ..style = PaintingStyle.fill;
    
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = height - (points[i] * height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Extracts only sound value from settings state to prevent rebuilds
/// when other settings (vibration, notifications, etc.) change
class _SoundSwitchWidget extends StatelessWidget {
  const _SoundSwitchWidget();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, SettingsState, bool>(
      selector: (state) => state.settingsModel!.sound,
      builder: (context, isSoundEnabled) {
        return CustomSwitch(
          value: isSoundEnabled,
          onChanged: (v) => context.read<SettingsCubit>().sound = v,
        );
      },
    );
  }
}

/// Extracts only vibration value from settings state to prevent rebuilds
/// when other settings (sound, notifications, etc.) change
class _VibrationSwitchWidget extends StatelessWidget {
  const _VibrationSwitchWidget();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, SettingsState, bool>(
      selector: (state) => state.settingsModel!.vibration,
      builder: (context, isVibrationEnabled) {
        return CustomSwitch(
          value: isVibrationEnabled,
          onChanged: (v) => context.read<SettingsCubit>().vibration = v,
        );
      },
    );
  }
}
