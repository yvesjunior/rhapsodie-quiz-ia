import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/screens/dashboard_screen.dart';
import 'package:flutterquiz/commons/bottom_nav/bottom_nav.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/core/routes/routes.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/rhapsody/rhapsody.dart';
import 'package:flutterquiz/ui/screens/home/widgets/explore_categories_section.dart';
import 'package:flutterquiz/utils/extensions.dart';

class RhapsodyScreen extends StatefulWidget {
  const RhapsodyScreen({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => RhapsodyCubit(RhapsodyRemoteDataSource())..loadYearsAndMonths(),
        child: const RhapsodyScreen(),
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
        create: (_) => RhapsodyCubit(RhapsodyRemoteDataSource())
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<RhapsodyCubit>().loadYearsAndMonths(),
                    child: const Text('Retry'),
                  ),
                ],
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
          _navItem(context, Icons.home_rounded, 'Home', NavTabType.home),
          _navItem(context, Icons.school, 'Foundation', NavTabType.quizZone),
          _navItem(context, Icons.sports_esports_rounded, 'Play Zone', NavTabType.playZone),
          _navItem(context, Icons.person_rounded, 'Profile', NavTabType.profile),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.6);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Pop back to dashboard and switch to the selected tab
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
          create: (_) => RhapsodyCubit(RhapsodyRemoteDataSource())
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month.name.substring(0, 3).toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${month.daysCount} days',
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
            if (month.questionsCount > 0)
              Text(
                '${month.questionsCount} Q',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.6),
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
                      return Center(child: Text(state.message));
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
          _navItem(context, Icons.home_rounded, 'Home', NavTabType.home),
          _navItem(context, Icons.school, 'Foundation', NavTabType.quizZone),
          _navItem(context, Icons.sports_esports_rounded, 'Play Zone', NavTabType.playZone),
          _navItem(context, Icons.person_rounded, 'Profile', NavTabType.profile),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, NavTabType tabType) {
    final color = context.primaryTextColor.withValues(alpha: 0.6);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          dashboardScreenKey.currentState?.changeTab(tabType);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
          create: (_) => RhapsodyCubit(RhapsodyRemoteDataSource())
            ..loadDayDetail(day.year, day.month, day.day),
          child: _RhapsodyDayScreen(day: day),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final RhapsodyDay day;
  final VoidCallback onTap;

  const _DayCard({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number - top left, sharing corner border
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(13),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            // Title - centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  day.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
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
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
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
                          Icon(Icons.favorite, color: Colors.amber, size: 20),
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
      },
    );
  }
}

