import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/bottom_nav/models/nav_tab_type_enum.dart';
import 'package:flutterquiz/commons/screens/dashboard_screen.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/core/localization/localization_extensions.dart';
import 'package:flutterquiz/core/theme/theme_extension.dart';
import 'package:flutterquiz/features/solo/solo.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:google_fonts/google_fonts.dart';

class SoloModeScreen extends StatelessWidget {
  const SoloModeScreen({super.key});

  static const routeName = '/solo-mode';

  static Route<dynamic> route(RouteSettings rs) {
    return CupertinoPageRoute(
      builder: (_) => const SoloModeScreen(),
      settings: rs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SoloModeCubit()..loadTopics(),
      child: const _SoloModeView(),
    );
  }
}

class _SoloModeView extends StatelessWidget {
  const _SoloModeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SoloModeCubit, SoloModeState>(
      builder: (context, state) {
        // States with their own full-screen layout (blue header)
        if (state is SoloModePlaying) {
          return _PlayingView(state: state);
        }
        if (state is SoloModeConfiguring) {
          return _ConfigurationView(state: state);
        }
        if (state is SoloModeCompleted) {
          return _ResultsView(result: state.result);
        }
        if (state is SoloModeTopicsLoaded) {
          return _TopicSelectionView(topics: state.topics);
        }
        
        // Other states use the standard appbar layout
        return Scaffold(
          appBar: QAppBar(
            title: Text(
              context.trWithFallback('soloModeLbl', 'Solo Mode'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            roundedAppBar: false,
          ),
          body: switch (state) {
            SoloModeInitial() => const _LoadingView(),
            SoloModeLoading() => const _LoadingView(),
            SoloModeQuestionsLoading() => const _LoadingView(message: 'Loading questions...'),
            SoloModeReady() => const _LoadingView(message: 'Starting...'),
            SoloModeSubmitting() => const _LoadingView(message: 'Submitting...'),
            SoloModeError(:final message) => _ErrorView(message: message),
            _ => const SizedBox(), // Handled above
          },
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }
}

// ============================================
// Loading View
// ============================================

class _LoadingView extends StatelessWidget {
  final String message;
  
  const _LoadingView({this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

// ============================================
// Error View
// ============================================

class _ErrorView extends StatelessWidget {
  final String message;
  
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<SoloModeCubit>().loadTopics(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Topic Selection View
// ============================================

class _TopicSelectionView extends StatelessWidget {
  final List<SoloTopic> topics;
  
  const _TopicSelectionView({required this.topics});

  // Same blue gradient as Foundation screen
  static const _headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Blue gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Solo Mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance for centered title
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: topics.isEmpty
                ? const Center(child: Text('No topics available'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a Topic',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a topic to practice with random questions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: topics.length,
                            itemBuilder: (context, index) {
                              final topic = topics[index];
                              return _TopicCard(topic: topic);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final SoloTopic topic;
  
  const _TopicCard({required this.topic});

  IconData get _topicIcon {
    switch (topic.slug) {
      case 'rhapsody':
        return Icons.menu_book;
      case 'foundation_school':
        return Icons.school;
      default:
        return Icons.quiz;
    }
  }

  Color get _topicColor {
    switch (topic.slug) {
      case 'rhapsody':
        return Colors.deepPurple;
      case 'foundation_school':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = topic.hasEnoughQuestions;
    
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isEnabled
            ? () => context.read<SoloModeCubit>().selectTopic(topic)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled
                  ? [_topicColor, _topicColor.withOpacity(0.7)]
                  : [Colors.grey[400]!, Colors.grey[300]!],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _topicIcon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                topic.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${topic.questionsCount} questions',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              if (!isEnabled)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Not enough questions',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Configuration View
// ============================================

class _ConfigurationView extends StatelessWidget {
  final SoloModeConfiguring state;
  
  const _ConfigurationView({required this.state});

  // Same blue gradient as Foundation screen
  static const _headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SoloModeCubit>();
    
    return Scaffold(
      body: Column(
        children: [
          // Blue gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => cubit.backToTopics(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Solo Mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance for centered title
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected topic header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.selectedTopic.slug == 'rhapsody' 
                              ? Icons.menu_book 
                              : Icons.school,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.selectedTopic.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${state.selectedTopic.questionsCount} questions available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Question count selection
                  Text(
                    'Number of Questions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SelectionChips<int>(
                    options: const [5, 10, 15, 20],
                    selected: state.questionCount,
                    onSelected: cubit.setQuestionCount,
                    labelBuilder: (count) => '$count',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Time per question selection
                  Text(
                    'Time per Question',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SelectionChips<int>(
                    options: const [10, 15, 30, 60],
                    selected: state.timePerQuestion,
                    onSelected: cubit.setTimePerQuestion,
                    labelBuilder: (time) => '${time}s',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Coin reward info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Coin Reward',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                state.questionCount > 5
                                    ? '+1 coin for 100% correct!'
                                    : 'No coin for 5 questions (choose 10+ for rewards)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: state.questionCount > 5 ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: cubit.startQuiz,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Quiz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
}

class _SelectionChips<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  
  const _SelectionChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labelBuilder(option),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================
// Playing View - Matching existing Quiz Screen design
// ============================================

class _PlayingView extends StatelessWidget {
  final SoloModePlaying state;
  
  const _PlayingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final options = ['a', 'b', 'c', 'd'];
    final optionTexts = [question.optionA, question.optionB, question.optionC, question.optionD];
    final colorScheme = Theme.of(context).colorScheme;
    final onTertiary = colorScheme.onTertiary;

    return Scaffold(
      body: Column(
        children: [
          // Blue Header (same as Foundation)
          Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Timer
                _CircularTimer(
                  timeRemaining: state.timeRemaining,
                  totalTime: state.timePerQuestion,
                ),
                const SizedBox(height: 12),
                // Question index
                Text(
                  'Question ${state.currentQuestionIndex + 1} of ${state.totalQuestions}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Question and Options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Question text
                Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      height: 1.125,
                      color: onTertiary,
                      fontSize: 20,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Options
                ...List.generate(4, (index) {
                  final optionText = optionTexts[index];
                  if (optionText.isEmpty) return const SizedBox.shrink();
                  
                  return _SoloOptionContainer(
                    optionId: options[index],
                    optionText: optionText,
                    onTap: () => context.read<SoloModeCubit>().answerQuestion(options[index]),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: _buildBottomNav(context),
  );
  }
}

/// Circular timer for blue header (white theme)
class _CircularTimer extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;

  const _CircularTimer({
    required this.timeRemaining,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = timeRemaining / totalTime;
    final isLowTime = timeRemaining <= 5;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.3),
            ),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              isLowTime ? Colors.red[300]! : Colors.white,
            ),
          ),
          // Time text
          Text(
            '$timeRemaining',
            style: TextStyle(
              color: isLowTime ? Colors.red[300] : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Option container matching the existing quiz design
class _SoloOptionContainer extends StatefulWidget {
  final String optionId;
  final String optionText;
  final VoidCallback onTap;

  const _SoloOptionContainer({
    required this.optionId,
    required this.optionText,
    required this.onTap,
  });

  @override
  State<_SoloOptionContainer> createState() => _SoloOptionContainerState();
}

class _SoloOptionContainerState extends State<_SoloOptionContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInQuad),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surface;
    final onTertiary = colorScheme.onTertiary;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapCancel: () => _animationController.reverse(),
        onTap: () async {
          await _animationController.reverse();
          widget.onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              widget.optionText,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  color: onTertiary,
                  height: 1,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// Results View - Quiz Summary Design
// ============================================

class _ResultsView extends StatelessWidget {
  final SoloQuizResult result;
  
  const _ResultsView({required this.result});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header with title only
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Text(
                  'Quiz Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Main content - White card with trophy
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // White card
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        children: [
                          // Congratulations text
                          Text(
                            'Congratulations !',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Success rate
                          Builder(
                            builder: (context) {
                              final successRate = result.totalQuestions > 0
                                  ? (result.correctAnswers / result.totalQuestions * 100).round()
                                  : 0;
                              final rateColor = successRate == 100
                                  ? const Color(0xFF4CD964) // Green for 100%
                                  : (successRate >= 70
                                      ? Colors.orange // Orange for 70-99%
                                      : Colors.red); // Red for <70%
                              return RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 16),
                                  children: [
                                    TextSpan(
                                      text: 'Success rate: ',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    TextSpan(
                                      text: '$successRate%',
                                      style: TextStyle(
                                        color: rateColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Stats row
                          Row(
                            children: [
                              // Total Questions
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                          child: const Text(
                                            'Q',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${result.totalQuestions}',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: context.primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Total Que',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Divider
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              
                              // Correct
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          result.correctAnswers.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: context.primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Correct',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Divider
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              
                              // Wrong
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.cancel, color: Colors.red, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          result.wrongAnswers.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: context.primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Wrong',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Coin reward
                          if (result.earnedCoin > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+${result.earnedCoin} Coin Earned!',
                                      style: TextStyle(
                                        color: Colors.amber[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 40),
                          
                          // Play Again button (full width)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.read<SoloModeCubit>().reset(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Play Again',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Trophy image floating at top
                  Positioned(
                    top: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stars around trophy
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Icon(Icons.star, color: Colors.white.withValues(alpha: 0.8), size: 14),
                        ),
                        Positioned(
                          top: 5,
                          right: 20,
                          child: Icon(Icons.star, color: Colors.white.withValues(alpha: 0.6), size: 10),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 5,
                          child: Icon(Icons.star, color: Colors.white.withValues(alpha: 0.5), size: 8),
                        ),
                        // Trophy
                        Image.asset(
                          'assets/images/cup.png',
                          width: 100,
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                  
                  // Share button
                  Positioned(
                    top: 70,
                    right: 30,
                    child: IconButton(
                      onPressed: () {
                        // Share functionality to be implemented
                      },
                      icon: Icon(
                        Icons.share,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: _buildBottomNav(context),
  );
  }
}

// ============================================
// Bottom Navigation Bar for Solo Mode (matching Dashboard)
// ============================================

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

