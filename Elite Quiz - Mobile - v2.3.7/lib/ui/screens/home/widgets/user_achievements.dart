import 'package:flutter/material.dart';
import 'package:flutterquiz/commons/commons.dart';
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
    final rank = context.tr('rankLbl')!;
    final coins = context.tr('coinsLbl')!;
    final score = context.tr('scoreLbl')!;

    final numberFormat = NumberFormat.decimalPattern();

    final verticalDivider = Container(
      height: 48,
      width: 2,
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.width * UiUtils.hzMarginPct,
      ),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 5),
            blurRadius: 5,
            color: context.primaryColor.withValues(alpha: .3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(99999),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Achievement(
              title: rank,
              value: numberFormat.format(double.parse(userRank)),
              showOrdinalSuffix: true,
            ),
            verticalDivider,
            _Achievement(
              title: coins,
              value: numberFormat.format(double.parse(userCoins)),
              showCoinIcon: true,
            ),
            verticalDivider,
            _Achievement(
              title: score,
              value: numberFormat.format(double.parse(userScore)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({
    required this.title,
    required this.value,
    this.showCoinIcon = false,
    this.showOrdinalSuffix = false,
  });

  final String title;
  final String value;
  final bool showCoinIcon;
  final bool showOrdinalSuffix;

  /// Helper function to get ordinal suffix with superscript (ˢᵗ, ⁿᵈ, ʳᵈ, ᵗʰ)
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'ᵗʰ'; // Superscript th
    }
    switch (number % 10) {
      case 1:
        return 'ˢᵗ'; // Superscript st
      case 2:
        return 'ⁿᵈ'; // Superscript nd
      case 3:
        return 'ʳᵈ'; // Superscript rd
      default:
        return 'ᵗʰ'; // Superscript th
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse the numeric value for animation
    final numericValue = double.tryParse(value.replaceAll(',', '')) ?? 0;
    final numberFormat = NumberFormat.decimalPattern();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeights.regular,
            color: context.surfaceColor.withValues(alpha: 0.7),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: numericValue),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, animatedValue, child) {
            final roundedValue = animatedValue.round();
            final formattedValue = numberFormat.format(roundedValue);
            
            if (showCoinIcon) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const QImage(
                    imageUrl: Assets.coin,
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedValue,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeights.bold,
                      height: 1.136,
                      color: context.surfaceColor,
                    ),
                  ),
                ],
              );
            }
            
            if (showOrdinalSuffix) {
              final suffix = _getOrdinalSuffix(roundedValue);
              return RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: formattedValue,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeights.bold,
                        height: 1.136,
                        color: context.surfaceColor,
                      ),
                    ),
                    TextSpan(
                      text: suffix,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeights.bold,
                        height: 1.136,
                        color: context.surfaceColor,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Text(
              formattedValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeights.bold,
                height: 1.136,
                color: context.surfaceColor,
              ),
            );
          },
        ),
      ],
    );
  }
}
