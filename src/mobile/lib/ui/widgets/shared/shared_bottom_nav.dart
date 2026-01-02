import 'package:flutter/material.dart';
import 'package:flutterquiz/commons/bottom_nav/models/nav_tab_type_enum.dart';
import 'package:flutterquiz/commons/screens/dashboard_screen.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';
import 'package:flutterquiz/core/localization/localization_extensions.dart';
import 'package:flutterquiz/core/theme/theme_extension.dart';
import 'package:flutterquiz/utils/extensions.dart';

/// Shared bottom navigation bar for sub-screens
/// This provides navigation back to dashboard tabs while maintaining consistent styling
/// 
/// Matches the Dashboard's BottomNavBar styling with:
/// - Same container height and decoration
/// - Same icon/label layout
/// - AnimatedScale on tap
class SharedBottomNav extends StatelessWidget {
  const SharedBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
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
          _NavItem(
            icon: Assets.homeNavIcon,
            activeIcon: Assets.homeActiveNavIcon,
            label: 'navHome',
            fallbackLabel: 'Home',
            tabType: NavTabType.home,
          ),
          _NavItem(
            icon: Assets.leaderboardNavIcon,
            activeIcon: Assets.leaderboardActiveNavIcon,
            label: 'navLeaderBoard',
            fallbackLabel: 'Leaderboard',
            tabType: NavTabType.leaderboard,
          ),
          _NavItem(
            iconData: Icons.school_outlined,
            activeIconData: Icons.school,
            label: 'Foundation',
            fallbackLabel: 'Foundation',
            tabType: NavTabType.quizZone,
          ),
          _NavItem(
            icon: Assets.profileNavIcon,
            activeIcon: Assets.profileActiveNavIcon,
            label: 'navProfile',
            fallbackLabel: 'Profile',
            tabType: NavTabType.profile,
          ),
          _NavItem(
            iconData: Icons.settings_outlined,
            activeIconData: Icons.settings,
            label: 'Settings',
            fallbackLabel: 'Settings',
            tabType: NavTabType.settings,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String? icon;
  final String? activeIcon;
  final IconData? iconData;
  final IconData? activeIconData;
  final String label;
  final String fallbackLabel;
  final NavTabType tabType;

  const _NavItem({
    this.icon,
    this.activeIcon,
    this.iconData,
    this.activeIconData,
    required this.label,
    required this.fallbackLabel,
    required this.tabType,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    dashboardScreenKey.currentState?.changeTab(widget.tabType);
  }

  @override
  Widget build(BuildContext context) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          _onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
                child: widget.iconData != null
                    ? Transform.translate(
                        offset: const Offset(0, -2),
                        child: Icon(widget.iconData, color: color, size: 24),
                      )
                    : QImage(imageUrl: widget.icon!, color: color),
              ),
              SizedBox(height: widget.iconData != null ? 0 : 4),
              Text(
                context.trWithFallback(widget.label, widget.fallbackLabel),
                style: TextStyle(fontSize: 12, height: 1.15, color: color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
