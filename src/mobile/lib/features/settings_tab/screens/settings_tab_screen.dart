import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/settings/settings_cubit.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/delete_account_dialog.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/language_selector_sheet.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/logout_dialog.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/quiz_language_selector_sheet.dart';
import 'package:flutterquiz/ui/screens/menu/widgets/theme_selector_sheet.dart';
import 'package:flutterquiz/ui/widgets/all.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/gdpr_helper.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

/// Menu item with localization key and asset path
typedef MenuItem = ({String name, String image});

/// Blue header color - consistent across all screens
const _headerColor = Color(0xFF1565C0);

final class SettingsTabScreen extends StatefulWidget {
  const SettingsTabScreen({super.key});

  @override
  State<SettingsTabScreen> createState() => SettingsTabScreenState();
}

final class SettingsTabScreenState extends State<SettingsTabScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  bool get _isGuest => context.read<AuthCubit>().isGuest;

  /// Cached to avoid repeated async calls across rebuilds
  Future<bool>? _gdprFuture;

  /// Settings menu items
  static const List<MenuItem> _settingsMenuItems = [
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

    return _settingsMenuItems.where((item) {
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
          // Blue header background
          Container(
            height: context.height * 0.16,
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
                const SizedBox(height: 60),
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
      child: Center(
        child: Text(
          context.trWithFallback('settingsLbl', 'Settings'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeights.bold,
            color: Colors.white,
          ),
        ),
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

  @override
  bool get wantKeepAlive => true;
}

/// Extracts only sound value from settings state
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

/// Extracts only vibration value from settings state
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

