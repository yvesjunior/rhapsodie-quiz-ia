import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutterquiz/commons/screens/dashboard_screen.dart';
import 'package:flutterquiz/commons/bottom_nav/bottom_nav.dart';
import 'package:flutterquiz/commons/widgets/show_login_required_dialog.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/core/routes/routes.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';
import 'package:flutterquiz/ui/screens/home/widgets/rhapsody_section.dart' show CategoryColors;
import 'package:flutterquiz/utils/extensions.dart';

class RhapsodyScreen extends StatefulWidget {
  const RhapsodyScreen({super.key});

  static Route route({Map<String, dynamic>? arguments}) {
    // Check if we need to navigate to a specific day
    if (arguments != null && arguments['action'] == 'showDay') {
      final year = arguments['year'] as int;
      final month = arguments['month'] as int;
      final day = arguments['day'] as int;
      return dayRoute(year: year, month: month, day: day);
    }
    
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => RhapsodyCubit(RhapsodyRepository())..loadYearsAndMonths(),
        child: const RhapsodyScreen(),
      ),
    );
  }

  /// Route directly to a specific day
  static Route dayRoute({
    required int year,
    required int month,
    required int day,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => RhapsodyCubit(RhapsodyRepository())
          ..loadDayDetail(year, month, day),
        child: _RhapsodyDayScreen(
          day: RhapsodyDay(
            id: '',
            name: 'Day $day',
            title: '',
            day: day,
            month: month,
            year: year,
          ),
        ),
      ),
    );
  }

  /// Route directly to a specific month
  static Route monthRoute({
    required int year,
    required int month,
    required String monthName,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => RhapsodyCubit(RhapsodyRepository())
          ..loadDays(year, month, monthName),
        child: RhapsodyMonthScreen(
          year: year,
          month: month,
          monthName: monthName,
        ),
      ),
    );
  }

  @override
  State<RhapsodyScreen> createState() => _RhapsodyScreenState();
}

class _RhapsodyScreenState extends State<RhapsodyScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedYearIndex = 0;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabController(int length) {
    if (_tabController?.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController!.indexIsChanging) return;
    
    final state = context.read<RhapsodyCubit>().state;
    if (state is RhapsodyYearsLoaded) {
      final selectedYear = state.years[_tabController!.index].year;
      context.read<RhapsodyCubit>().loadMonths(selectedYear);
      setState(() {
        _selectedYearIndex = _tabController!.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Primary blue
      body: BlocBuilder<RhapsodyCubit, RhapsodyState>(
        builder: (context, state) {
          if (state is RhapsodyLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state is RhapsodyError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isOffline ? Icons.wifi_off : Icons.error_outline,
                      color: Colors.white70,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(state.message) ?? 'No internet connection found. check your connection or try again.',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<RhapsodyCubit>().loadYearsAndMonths(),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.tr('tryAgain') ?? 'Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is RhapsodyYearsLoaded) {
            if (state.years.isEmpty) {
              return const Center(
                child: Text(
                  'No Rhapsody content available',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            _initTabController(state.years.length);

            return SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context),
                  
                  // Year Tabs
                  _buildYearTabs(state.years),
                  
                  // Months Grid
                  Expanded(
                    child: _buildMonthsGrid(state.months ?? []),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
          _navItemSvg(context, Assets.homeNavIcon, 'Home', NavTabType.home),
          _navItemSvg(context, Assets.leaderboardNavIcon, 'Leaderboard', NavTabType.leaderboard),
          _navItemIcon(context, Icons.school, 'Foundation', NavTabType.quizZone),
          _navItemSvg(context, Assets.playZoneNavIcon, 'Play Zone', NavTabType.playZone),
          _navItemSvg(context, Assets.profileNavIcon, 'Profile', NavTabType.profile),
        ],
      ),
    );
  }

  Widget _navItemSvg(BuildContext context, String iconAsset, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: QImage(imageUrl: iconAsset, color: color)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItemIcon(BuildContext context, IconData icon, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Icon(icon, color: color, size: 24)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rhapsody of Realities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Daily Devotional',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_stories, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildYearTabs(List<RhapsodyYear> years) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, // White outer bar
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: years.length > 3,
        indicator: BoxDecoration(
          color: const Color(0xFF1565C0), // Primary blue for selected
          borderRadius: BorderRadius.circular(8), // Less rounded, matching outer bar
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF1565C0),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        tabs: years.map((year) => Tab(text: year.name)).toList(),
      ),
    );
  }

  Widget _buildMonthsGrid(List<RhapsodyMonth> months) {
    if (months.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Select a Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                return _MonthCard(
                  month: month,
                  color: _getMonthColor(index),
                  onTap: () => _onMonthTap(month),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getMonthColor(int index) {
    final colors = [
      CategoryColors.space,
      CategoryColors.sports,
      CategoryColors.history,
      CategoryColors.maths,
      CategoryColors.science,
      CategoryColors.geography,
      CategoryColors.music,
      CategoryColors.movies,
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
    ];
    return colors[index % colors.length];
  }

  void _onMonthTap(RhapsodyMonth month) {
    // Create a new cubit for the month screen to avoid state conflicts
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => RhapsodyCubit(RhapsodyRepository())
            ..loadDays(month.year, month.month, month.name),
          child: RhapsodyMonthScreen(
            year: month.year,
            month: month.month,
            monthName: month.name,
            daysCount: month.daysCount,
          ),
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final RhapsodyMonth month;
  final Color color;
  final VoidCallback onTap;

  const _MonthCard({
    required this.month,
    required this.color,
    required this.onTap,
  });

  // Get seasonal icon based on month
  IconData get _seasonIcon {
    final monthNum = _getMonthNumber(month.name);
    if (monthNum >= 12 || monthNum <= 2) return Icons.ac_unit; // Winter
    if (monthNum >= 3 && monthNum <= 5) return Icons.local_florist; // Spring
    if (monthNum >= 6 && monthNum <= 8) return Icons.wb_sunny; // Summer
    return Icons.eco; // Fall
  }

  int _getMonthNumber(String name) {
    const months = ['january', 'february', 'march', 'april', 'may', 'june',
                    'july', 'august', 'september', 'october', 'november', 'december'];
    return months.indexOf(name.toLowerCase()) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                _seasonIcon,
                size: 60,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Season icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _seasonIcon,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Month name
                  Text(
                    month.name.substring(0, 3).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Frosted stats bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${month.daysCount}d',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (month.questionsCount > 0) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            '${month.questionsCount}Q',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Rhapsody Month Screen (Days List)
class RhapsodyMonthScreen extends StatelessWidget {
  final int year;
  final int month;
  final String monthName;
  final int? daysCount;

  const RhapsodyMonthScreen({
    super.key,
    required this.year,
    required this.month,
    required this.monthName,
    this.daysCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Primary blue
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Days Grid
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: BlocBuilder<RhapsodyCubit, RhapsodyState>(
                  builder: (context, state) {
                    if (state is RhapsodyLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is RhapsodyDaysLoaded) {
                      return _buildDaysGrid(context, state.days);
                    }

                    if (state is RhapsodyError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                state.isOffline ? Icons.wifi_off : Icons.error_outline,
                                color: Colors.grey,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr(state.message) ?? 'Unable to load',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
          _navItemSvg(context, Assets.homeNavIcon, 'Home', NavTabType.home),
          _navItemSvg(context, Assets.leaderboardNavIcon, 'Leaderboard', NavTabType.leaderboard),
          _navItemIcon(context, Icons.school, 'Foundation', NavTabType.quizZone),
          _navItemSvg(context, Assets.playZoneNavIcon, 'Play Zone', NavTabType.playZone),
          _navItemSvg(context, Assets.profileNavIcon, 'Profile', NavTabType.profile),
        ],
      ),
    );
  }

  Widget _navItemSvg(BuildContext context, String iconAsset, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: QImage(imageUrl: iconAsset, color: color)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItemIcon(BuildContext context, IconData icon, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Icon(icon, color: color, size: 24)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  daysCount != null ? '$daysCount devotionals' : 'Devotionals',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(BuildContext context, List<RhapsodyDay> days) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _DayCard(
          day: day,
          colorIndex: index,
          onTap: () => _onDayTap(context, day),
        );
      },
    );
  }

  void _onDayTap(BuildContext context, RhapsodyDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => RhapsodyCubit(RhapsodyRepository())
            ..loadDayDetail(day.year, day.month, day.day),
          child: _RhapsodyDayScreen(day: day),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final RhapsodyDay day;
  final int colorIndex;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.colorIndex,
    required this.onTap,
  });

  // Accent colors for glass cards
  static const _accentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
    Color(0xFFA855F7), // Purple
  ];

  Color get _accentColor => _accentColors[colorIndex % _accentColors.length];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Glass effect: semi-transparent white
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          // Elegant border with gradient feel
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 1.5,
          ),
          boxShadow: [
            // Soft outer shadow
            BoxShadow(
              color: _accentColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Inner glow effect
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              spreadRadius: -1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accentColor.withOpacity(0.05),
                        _accentColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  // Day number - floating pill
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Day ${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      day.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bottom accent line
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Rhapsody Day Screen (Full Content)
class _RhapsodyDayScreen extends StatelessWidget {
  final RhapsodyDay day;

  const _RhapsodyDayScreen({required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<RhapsodyCubit, RhapsodyState>(
        builder: (context, state) {
          if (state is RhapsodyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RhapsodyDayDetailLoaded) {
            return _buildContent(context, state.detail);
          }

          if (state is RhapsodyError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isOffline ? Icons.wifi_off : Icons.error_outline,
                      color: Colors.grey,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(state.message) ?? 'Unable to load',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<RhapsodyCubit>().loadDayDetail(
                            day.year,
                            day.month,
                            day.day,
                          ),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.tr('tryAgain') ?? 'Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
          _navItemSvg(context, Assets.homeNavIcon, 'Home', NavTabType.home),
          _navItemSvg(context, Assets.leaderboardNavIcon, 'Leaderboard', NavTabType.leaderboard),
          _navItemIcon(context, Icons.school, 'Foundation', NavTabType.quizZone),
          _navItemSvg(context, Assets.playZoneNavIcon, 'Play Zone', NavTabType.playZone),
          _navItemSvg(context, Assets.profileNavIcon, 'Profile', NavTabType.profile),
        ],
      ),
    );
  }

  Widget _navItemSvg(BuildContext context, String iconAsset, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: QImage(imageUrl: iconAsset, color: color)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItemIcon(BuildContext context, IconData icon, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Icon(icon, color: color, size: 24)),
              const Flexible(child: SizedBox(height: 4)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, height: 1.15, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RhapsodyDayDetail detail) {
    return Column(
      children: [
        // Fixed Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_getMonthName(detail.month)} ${detail.day}, ${detail.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scripture
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1565C0).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book, 
                            color: Color(0xFF1565C0), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            detail.scriptureRef,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.dailyText,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Content Text
                Text(
                  detail.contentText,
                  style: const TextStyle(fontSize: 16, height: 1.7),
                ),

                const SizedBox(height: 24),

                // Prayer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.personPraying,
                            color: Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'PRAYER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detail.prayerText,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Further Study
                if (detail.furtherStudy.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FURTHER STUDY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.furtherStudy,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Test Your Knowledge Section (like Foundation School)
                if (detail.questionsCount > 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.quiz_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Test Your Knowledge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${detail.questionsCount} questions available',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _startQuiz(context, detail),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1565C0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Start Quiz',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _startQuiz(BuildContext context, RhapsodyDayDetail detail) {
    // Check if the user is a guest, Show login required dialog for guest users
    if (context.read<AuthCubit>().isGuest) {
      showLoginRequiredDialog(context);
      return;
    }

    Navigator.of(context).pushNamed(
      Routes.quiz,
      arguments: {
        'numberOfPlayer': 1,
        'quizType': QuizTypes.quizZone,
        'categoryId': detail.id,
        'subcategoryId': '',
        'level': '0',
        'isPlayed': false,
        'isPremiumCategory': false,
        'showCoins': true,
        // Rhapsody day info for "Next" navigation
        'rhapsodyDay': detail.day,
        'rhapsodyMonth': detail.month,
        'rhapsodyYear': detail.year,
      },
    );
  }
}

