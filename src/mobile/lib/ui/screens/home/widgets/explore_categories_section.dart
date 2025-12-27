import 'package:flutter/material.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/ui/screens/home/widgets/game_mode_card.dart';
import 'package:flutterquiz/utils/extensions.dart';

class ExploreCategoriesSection extends StatelessWidget {
  const ExploreCategoriesSection({
    required this.categories,
    this.onViewAll,
    this.onCategoryTap,
    this.onRandomQuizTap,
    super.key,
  });

  final List<CategoryItem> categories;
  final VoidCallback? onViewAll;
  final void Function(CategoryItem category)? onCategoryTap;
  final VoidCallback? onRandomQuizTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('exploreCategoriesLbl') ?? 'Explore Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeights.bold,
                  color: context.primaryTextColor,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  context.tr('viewAllKey') ?? 'VIEW ALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeights.semiBold,
                    color: context.primaryTextColor.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Categories Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Random Quiz Card (larger)
              Expanded(
                flex: 2,
                child: _RandomQuizCard(onTap: onRandomQuizTap),
              ),
              const SizedBox(width: 12),
              
              // Category Grid (2x2)
              Expanded(
                flex: 3,
                child: _CategoryGrid(
                  categories: categories.take(4).toList(),
                  onCategoryTap: onCategoryTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RandomQuizCard extends StatelessWidget {
  const _RandomQuizCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: GameModeColors.randomQuiz,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 8,
              color: GameModeColors.randomQuiz.withValues(alpha: 0.4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeights.semiBold,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('randomQuizLbl') ?? 'RANDOM QUIZ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeights.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              left: 10,
              child: Icon(
                Icons.help_outline_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    this.onCategoryTap,
  });

  final List<CategoryItem> categories;
  final void Function(CategoryItem category)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                category: categories.isNotEmpty
                    ? categories[0]
                    : CategoryItem(
                        id: '',
                        name: 'Space',
                        color: const Color(0xFFFFB74D),
                        icon: Icons.rocket_launch_rounded,
                      ),
                onTap: () {
                  if (categories.isNotEmpty) {
                    onCategoryTap?.call(categories[0]);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CategoryCard(
                category: categories.length > 1
                    ? categories[1]
                    : CategoryItem(
                        id: '',
                        name: 'Sports',
                        color: const Color(0xFFE91E63),
                        icon: Icons.sports_soccer_rounded,
                      ),
                onTap: () {
                  if (categories.length > 1) {
                    onCategoryTap?.call(categories[1]);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                category: categories.length > 2
                    ? categories[2]
                    : CategoryItem(
                        id: '',
                        name: 'History',
                        color: const Color(0xFF4CAF50),
                        icon: Icons.shield_rounded,
                      ),
                onTap: () {
                  if (categories.length > 2) {
                    onCategoryTap?.call(categories[2]);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CategoryCard(
                category: categories.length > 3
                    ? categories[3]
                    : CategoryItem(
                        id: '',
                        name: 'Maths',
                        color: const Color(0xFF9C27B0),
                        icon: Icons.calculate_rounded,
                      ),
                onTap: () {
                  if (categories.length > 3) {
                    onCategoryTap?.call(categories[3]);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    this.onTap,
  });

  final CategoryItem category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeights.bold,
                color: category.color,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Icon(
              category.icon,
              size: 36,
              color: category.color,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.imageUrl,
  });

  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final String? imageUrl;
}

/// Predefined category colors
class CategoryColors {
  static const space = Color(0xFFFFB74D);
  static const sports = Color(0xFFE91E63);
  static const history = Color(0xFF4CAF50);
  static const maths = Color(0xFF9C27B0);
  static const science = Color(0xFF2196F3);
  static const geography = Color(0xFF00BCD4);
  static const music = Color(0xFFFF5722);
  static const movies = Color(0xFF795548);
}

