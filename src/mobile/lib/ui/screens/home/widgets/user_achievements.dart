import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:intl/intl.dart';

class UserAchievements extends StatelessWidget {
  const UserAchievements({
    super.key,
    this.userRank = '0',
    this.userCoins = '0',
    this.userScore = '0',
  });

  final String userRank;
  final String userCoins;
  final String userScore;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.width * UiUtils.hzMarginPct,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Rank Section
          Expanded(
            child: _AchievementItem(
              icon: _buildRankIcon(context),
              topLabel: '${_getOrdinal(int.tryParse(userRank) ?? 0)} ${context.tr('rankLbl') ?? 'Rank'}',
              value: '${numberFormat.format(double.parse(userScore))} pt',
            ),
          ),
          
          // Divider
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          
          // Reward Points Section
          Expanded(
            child: _AchievementItem(
              icon: _buildCoinIcon(context),
              topLabel: context.tr('rewardPointLbl') ?? 'Reward Point',
              value: numberFormat.format(double.parse(userCoins)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.emoji_events_rounded,
        color: context.primaryColor,
        size: 22,
      ),
    );
  }

  Widget _buildCoinIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.monetization_on_rounded,
        color: Color(0xFFFFC107),
        size: 24,
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
}

class _AchievementItem extends StatelessWidget {
  const _AchievementItem({
    required this.icon,
    required this.topLabel,
    required this.value,
  });

  final Widget icon;
  final String topLabel;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeights.regular,
                color: context.primaryTextColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, animatedValue, child) {
                final displayValue = value.contains('pt')
                    ? '${NumberFormat.decimalPattern().format(animatedValue.round())} pt'
                    : NumberFormat.decimalPattern().format(animatedValue.round());
                return Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeights.bold,
                    color: context.primaryTextColor,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
