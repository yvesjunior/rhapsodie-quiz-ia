import 'package:flutter/material.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/utils/extensions.dart';

class CategorySearchBar extends StatelessWidget {
  const CategorySearchBar({
    this.onTap,
    super.key,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.primaryTextColor.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('searchQuizCategoriesLbl') ?? 'Search Quiz Categories',
              style: TextStyle(
                fontSize: 14,
                color: context.primaryTextColor.withValues(alpha: 0.4),
                fontWeight: FontWeights.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

