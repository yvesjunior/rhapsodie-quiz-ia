import 'package:flutter/material.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/ui/screens/home/widgets/explore_categories_section.dart';
import 'package:flutterquiz/utils/extensions.dart';

/// Rhapsody Section for Home Screen
/// Similar layout to ExploreCategoriesSection but for Rhapsody months
class RhapsodySection extends StatelessWidget {
  const RhapsodySection({
    required this.months,
    this.onViewAll,
    this.onMonthTap,
    this.onCurrentMonthTap,
    super.key,
  });

  final List<RhapsodyMonth> months;
  final VoidCallback? onViewAll;
  final void Function(RhapsodyMonth month)? onMonthTap;
  final VoidCallback? onCurrentMonthTap;

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
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: RhapsodyColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rhapsody of Realities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeights.bold,
                      color: context.primaryTextColor,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  context.trWithFallback('viewAllKey', 'VIEW ALL'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeights.semiBold,
                    color: RhapsodyColors.primary.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Content Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Month Card (larger)
              Expanded(
                flex: 2,
                child: _CurrentMonthCard(onTap: onCurrentMonthTap),
              ),
              const SizedBox(width: 12),
              
              // Recent Months Grid (2x2)
              Expanded(
                flex: 3,
                child: _MonthsGrid(
                  months: months.take(4).toList(),
                  onMonthTap: onMonthTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentMonthCard extends StatelessWidget {
  const _CurrentMonthCard({this.onTap});

  final VoidCallback? onTap;

  String get _currentMonthName {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[DateTime.now().month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              RhapsodyColors.primary,
              RhapsodyColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 12,
              color: RhapsodyColors.primary.withValues(alpha: 0.4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              bottom: -20,
              right: -20,
              child: Icon(
                Icons.auto_stories,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeights.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentMonthName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeights.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeights.medium,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Play button
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: RhapsodyColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'START',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeights.bold,
                        color: RhapsodyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthsGrid extends StatelessWidget {
  const _MonthsGrid({
    required this.months,
    this.onMonthTap,
  });

  final List<RhapsodyMonth> months;
  final void Function(RhapsodyMonth month)? onMonthTap;

  // Get recent 4 months if no data from API
  List<RhapsodyMonth> get _displayMonths {
    if (months.isNotEmpty) return months;
    
    // Generate placeholder months (4 previous months)
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final colors = [
      CategoryColors.space,    // Orange
      CategoryColors.sports,   // Pink
      CategoryColors.history,  // Green
      CategoryColors.maths,    // Purple
    ];
    
    return List.generate(4, (index) {
      final date = DateTime(now.year, now.month - index - 1);
      final monthIndex = date.month - 1;
      return RhapsodyMonth(
        id: '',
        name: monthNames[monthIndex < 0 ? monthIndex + 12 : monthIndex],
        year: date.year,
        month: date.month,
        color: colors[index % colors.length],
        questionCount: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayMonths = _displayMonths;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MonthCard(
                month: displayMonths[0],
                onTap: () => onMonthTap?.call(displayMonths[0]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MonthCard(
                month: displayMonths.length > 1 ? displayMonths[1] : displayMonths[0],
                onTap: () {
                  if (displayMonths.length > 1) {
                    onMonthTap?.call(displayMonths[1]);
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
              child: _MonthCard(
                month: displayMonths.length > 2 ? displayMonths[2] : displayMonths[0],
                onTap: () {
                  if (displayMonths.length > 2) {
                    onMonthTap?.call(displayMonths[2]);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MonthCard(
                month: displayMonths.length > 3 ? displayMonths[3] : displayMonths[0],
                onTap: () {
                  if (displayMonths.length > 3) {
                    onMonthTap?.call(displayMonths[3]);
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

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.month,
    this.onTap,
  });

  final RhapsodyMonth month;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: month.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: month.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month.name.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeights.bold,
                color: month.color,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${month.year}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeights.medium,
                color: month.color.withValues(alpha: 0.8),
              ),
            ),
            if (month.questionCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${month.questionCount} Q',
                style: TextStyle(
                  fontSize: 10,
                  color: month.color.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rhapsody Month Data Model
class RhapsodyMonth {
  const RhapsodyMonth({
    required this.id,
    required this.name,
    required this.year,
    required this.month,
    required this.color,
    this.questionCount = 0,
    this.categoryId,
  });

  final String id;
  final String name;
  final int year;
  final int month;
  final Color color;
  final int questionCount;
  final String? categoryId;
}

/// Rhapsody Colors
class RhapsodyColors {
  static const primary = Color(0xFF7B1FA2); // Deep Purple
  static const primaryDark = Color(0xFF4A148C);
  static const primaryLight = Color(0xFFCE93D8);
  
  // Month card colors (rotating)
  static const month1 = Color(0xFF9C27B0); // Purple
  static const month2 = Color(0xFF673AB7); // Deep Purple
  static const month3 = Color(0xFF3F51B5); // Indigo
  static const month4 = Color(0xFF5C6BC0); // Indigo lighter
}

