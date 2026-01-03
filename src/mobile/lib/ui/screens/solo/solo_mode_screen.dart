import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/core/localization/localization_extensions.dart';
import 'package:flutterquiz/core/theme/theme_extension.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/solo/solo.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/shared/shared.dart';
import 'package:flutterquiz/ui/widgets/text_circular_timer.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';
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
    final firebaseUserId = context.read<UserDetailsCubit>().getUserFirebaseId();
    
    return BlocProvider(
      create: (_) => SoloModeCubit(firebaseUserId: firebaseUserId)..loadTopics(),
      child: const _SoloModeView(),
    );
  }
}

class _SoloModeView extends StatelessWidget {
  const _SoloModeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SoloModeCubit, SoloModeState>(
      listener: (context, state) {
        // Refresh user data when coins are earned
        if (state is SoloModeCompleted && state.result.earnedCoin > 0) {
          context.read<UserDetailsCubit>().fetchUserDetails();
        }
      },
      child: BlocBuilder<SoloModeCubit, SoloModeState>(
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
          bottomNavigationBar: const SharedBottomNav(),
        );
        },
      ),
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
      bottomNavigationBar: const SharedBottomNav(),
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
                                state.questionCount >= 5
                                    ? '+1 coin for 100% correct!'
                                    : 'No coin for less than 5 questions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: state.questionCount >= 5 ? Colors.green : Colors.grey,
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
      bottomNavigationBar: const SharedBottomNav(),
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
// Playing View - Matching Rhapsody Quiz Layout
// ============================================

class _PlayingView extends StatefulWidget {
  final SoloModePlaying state;
  
  const _PlayingView({required this.state});

  @override
  State<_PlayingView> createState() => _PlayingViewState();
}

class _PlayingViewState extends State<_PlayingView> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.state.timePerQuestion),
    );
    _updateTimer();
  }

  @override
  void didUpdateWidget(_PlayingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTimer();
  }

  void _updateTimer() {
    // Calculate timer progress based on remaining time
    final progress = widget.state.timeRemaining / widget.state.timePerQuestion;
    _timerController.value = progress;
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _onTapBack() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SoloModeCubit>().reset();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SoloModeCubit>();
    final question = widget.state.currentQuestion;
    
    // Get decrypted correct answer from cubit
    final correctAnswer = cubit.getDecryptedAnswer(question);
    
    // Hide explanation for Foundation School topic
    final isFoundation = widget.state.topic.slug == 'foundation_school' || 
                         widget.state.topic.slug == 'foundation';
    
    // Build question data for shared widget
    final questionData = QuizQuestionData(
      id: question.id,
      question: question.question,
      options: [
        if (question.optionA.isNotEmpty)
          QuizOptionData(id: 'a', text: question.optionA),
        if (question.optionB.isNotEmpty)
          QuizOptionData(id: 'b', text: question.optionB),
        if (question.optionC.isNotEmpty)
          QuizOptionData(id: 'c', text: question.optionC),
        if (question.optionD.isNotEmpty)
          QuizOptionData(id: 'd', text: question.optionD),
      ],
      correctOptionId: correctAnswer,
      imageUrl: question.image,
      note: isFoundation ? null : question.note, // Hide explanation for Foundation
    );
    
    // Build poll percentages map
    final pollPercentages = widget.state.audiencePollPercentages.isNotEmpty
        ? {
            'a': widget.state.audiencePollPercentages.isNotEmpty ? widget.state.audiencePollPercentages[0] : 0,
            'b': widget.state.audiencePollPercentages.length > 1 ? widget.state.audiencePollPercentages[1] : 0,
            'c': widget.state.audiencePollPercentages.length > 2 ? widget.state.audiencePollPercentages[2] : 0,
            'd': widget.state.audiencePollPercentages.length > 3 ? widget.state.audiencePollPercentages[3] : 0,
          }
        : null;

    return Scaffold(
      appBar: QAppBar(
        onTapBackButton: _onTapBack,
        roundedAppBar: false,
        title: TextCircularTimer(
          animationController: _timerController,
          arcColor: Theme.of(context).primaryColor,
          color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.2),
        ),
      ),
      body: Column(
        children: [
          // Question count header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${widget.state.currentQuestionIndex + 1} / ${widget.state.totalQuestions}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Question and Options using SharedQuizQuestion
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SharedQuizQuestion(
                question: questionData,
                selectedAnswerId: widget.state.selectedAnswerId,
                hasSubmitted: widget.state.showingFeedback,
                hiddenOptions: widget.state.hiddenOptions,
                pollPercentages: pollPercentages,
                answerMode: QuizAnswerMode.showCorrectnessAndCorrect,
                onOptionSelected: (optionId) {
                  if (!widget.state.showingFeedback) {
                    cubit.answerQuestion(optionId);
                  }
                },
              ),
            ),
          ),
          
          // Lifelines Row (only show if not showing feedback)
          if (!widget.state.showingFeedback)
            _LifelinesRow(state: widget.state),
        ],
      ),
    );
  }
}

// ============================================
// Lifelines Row
// ============================================

class _LifelinesRow extends StatelessWidget {
  final SoloModePlaying state;
  
  const _LifelinesRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 50/50 lifeline
          _LifelineButton(
            icon: Assets.fiftyFiftyLifeline,
            label: '50/50',
            isUsed: state.fiftyFiftyStatus == LifelineStatus.used,
            onTap: state.fiftyFiftyStatus == LifelineStatus.unused
                ? () => context.read<SoloModeCubit>().useFiftyFifty()
                : null,
          ),
          // Poll lifeline
          _LifelineButton(
            icon: Assets.audiencePollLifeline,
            label: 'Poll',
            isUsed: state.audiencePollStatus == LifelineStatus.used,
            onTap: state.audiencePollStatus == LifelineStatus.unused
                ? () => context.read<SoloModeCubit>().useAudiencePoll()
                : null,
          ),
          // Timer lifeline
          _LifelineButton(
            icon: Assets.resetTimeLifeline,
            label: 'Timer',
            isUsed: state.resetTimeStatus == LifelineStatus.used,
            onTap: state.resetTimeStatus == LifelineStatus.unused
                ? () => context.read<SoloModeCubit>().useResetTime()
                : null,
          ),
          // Skip lifeline (always available)
          _LifelineButton(
            icon: Assets.skipQueLifeline,
            label: 'Skip',
            isUsed: false,
            onTap: () => context.read<SoloModeCubit>().skipQuestion(),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Lifeline Button
// ============================================

class _LifelineButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isUsed;
  final VoidCallback? onTap;

  const _LifelineButton({
    required this.icon,
    required this.label,
    required this.isUsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isUsed ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUsed 
                    ? Colors.grey.shade200 
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUsed 
                      ? Colors.grey.shade300 
                      : colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    isUsed ? Colors.grey : colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUsed 
                    ? Colors.grey 
                    : colorScheme.onSurface,
              ),
            ),
            if (isUsed)
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: const Icon(
                  Icons.check_circle,
                  size: 12,
                  color: Colors.green,
                ),
              ),
          ],
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
  
  void _showReviewAnswers(BuildContext context, SoloQuizResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.rate_review_outlined),
                  const SizedBox(width: 12),
                  Text(
                    'Review Answers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List of results
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: result.detailedResults.length,
                itemBuilder: (context, index) {
                  final detail = result.detailedResults[index];
                  return _buildQuestionReviewCard(context, detail, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionReviewCard(BuildContext context, SoloDetailedResult detail, int index) {
    final isCorrect = detail.isCorrect;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and source
            Row(
              children: [
                // Question number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Correct/Wrong indicator
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
                const Spacer(),
                // Source label
                if (detail.hasSource)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: detail.sourceType == 'rhapsody'
                          ? Colors.deepPurple.withOpacity(0.1)
                          : Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          detail.sourceType == 'rhapsody'
                              ? Icons.calendar_today_rounded
                              : Icons.school_rounded,
                          size: 12,
                          color: detail.sourceType == 'rhapsody'
                              ? Colors.deepPurple
                              : Colors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detail.sourceLabel!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: detail.sourceType == 'rhapsody'
                                ? Colors.deepPurple
                                : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Question text
            Text(
              detail.question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Your answer
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your answer: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    detail.selectedAnswer.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Correct answer: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      detail.correctAnswer.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Note/explanation if available
            if (detail.note != null && detail.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
                          
                          const SizedBox(height: 20),
                          
                          // Review Answers button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showReviewAnswers(context, result),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text(
                                'Review Answers',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
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
    bottomNavigationBar: const SharedBottomNav(),
  );
  }
}


