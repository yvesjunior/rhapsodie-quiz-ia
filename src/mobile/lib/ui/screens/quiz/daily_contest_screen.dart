import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/commons/screens/dashboard_screen.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/quiz/cubits/daily_contest_cubit.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';

/// Daily Contest Screen
/// Shows: Rhapsody text (5 points) + 5 questions (5 points) = 10 points max
class DailyContestScreen extends StatefulWidget {
  const DailyContestScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => DailyContestCubit(QuizRepository()),
        child: const DailyContestScreen(),
      ),
    );
  }

  @override
  State<DailyContestScreen> createState() => _DailyContestScreenState();
}

class _DailyContestScreenState extends State<DailyContestScreen> {
  // Contest data
  Map<String, dynamic>? _contestData;
  bool _isLoading = true;
  String? _errorMessage;

  // Reading state
  bool _hasReadText = false;
  bool _showQuiz = false;

  // Quiz state
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _userAnswers = {};
  bool _quizCompleted = false;

  // Lifeline tracking (each can only be used once)
  bool _fiftyFiftyUsed = false;
  bool _audiencePollUsed = false;
  bool _resetTimeUsed = false;
  bool _skipUsed = false;
  
  // For 50/50 - track which options to hide per question
  Map<int, List<String>> _hiddenOptions = {};
  
  // For audience poll - track poll results per question
  Map<int, Map<String, int>>? _pollResults;

  // Timer for each question (30 seconds per question)
  static const int _questionTimeSeconds = 30;
  Timer? _questionTimer;
  int _remainingSeconds = _questionTimeSeconds;

  // Results
  int _correctAnswers = 0;
  int _totalScore = 0;

  // Exit dialog
  bool _isExitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadDailyContest();
  }

  void _onTapBackButton() {
    // If quiz hasn't started yet (still on reading screen), allow exit without warning
    if (!_showQuiz) {
      Navigator.of(context).pop();
      return;
    }

    _isExitDialogOpen = true;
    
    // Calculate points earned so far
    final readingPoints = _hasReadText ? 5 : 0;
    int quizPoints = 0;
    for (int i = 0; i < _questions.length; i++) {
      final userAnswer = _userAnswers[i];
      if (userAnswer != null && userAnswer.isNotEmpty) {
        final question = _questions[i];
        final answerLetter = question['answer']?.toString().toLowerCase() ?? '';
        final correctAnswerText = _getOptionText(question, answerLetter);
        if (userAnswer.toLowerCase().trim() == correctAnswerText.toLowerCase().trim()) {
          quizPoints++;
        }
      }
    }
    final totalPoints = readingPoints + quizPoints;
    
    context.showDialog<void>(
      title: context.tr('quizExitTitle') ?? 'Leave Quiz?',
      message: 'You\'ve earned $totalPoints points so far.\nLeaving now will submit your current progress.\nYou won\'t be able to play again today.',
      image: Assets.quitQuizIcon,
      cancelButtonText: context.tr('leaveAnyways') ?? 'Leave & Collect',
      confirmButtonText: context.tr('keepPlaying') ?? 'Keep Playing',
      onCancel: () {
        context.shouldPop();
        _stopQuestionTimer();
        _submitAndLeave();
      },
      barrierDismissible: false,
    ).then((_) {
      _isExitDialogOpen = false;
    });
  }

  /// Get option text from option letter (a, b, c, d, e)
  String _getOptionText(Map<String, dynamic> question, String letter) {
    switch (letter.toLowerCase()) {
      case 'a':
        return question['optiona']?.toString() ?? '';
      case 'b':
        return question['optionb']?.toString() ?? '';
      case 'c':
        return question['optionc']?.toString() ?? '';
      case 'd':
        return question['optiond']?.toString() ?? '';
      case 'e':
        return question['optione']?.toString() ?? '';
      default:
        return '';
    }
  }

  Future<void> _submitAndLeave() async {
    if (_contestData == null) {
      Navigator.of(context).pop();
      return;
    }

    // Submit partial results to server (marks contest as completed)
    try {
      // Prepare answers
      final answers = <Map<String, dynamic>>[];
      for (var i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _userAnswers[i] ?? '';
        answers.add({
          'question_id': question['id'],
          'answer': userAnswer,
        });
      }

      await QuizRepository().submitDailyContest(
        contestId: _contestData!['contest_id'].toString(),
        answers: answers,
        readText: _hasReadText,
      );
      
      log('Contest submitted on early exit', name: 'DailyContest');
    } catch (e) {
      // Even if submission fails, exit the screen
      log('Error submitting partial results: $e', name: 'DailyContest');
    }
    
    if (mounted) {
      // Refresh home data before popping
      dashboardScreenKey.currentState?.refreshHomeData();
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadDailyContest() async {
    try {
      final result = await QuizRepository().getTodayDailyContest();
      setState(() {
        _contestData = result;
        _questions = List<Map<String, dynamic>>.from(result['questions'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading daily contest: $e', name: 'DailyContest');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onReadComplete() {
    setState(() {
      _hasReadText = true;
      _showQuiz = true;
    });
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    setState(() {
      _remainingSeconds = _questionTimeSeconds;
    });
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // Time's up - auto-submit with no answer (wrong)
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
  }

  void _onTimeUp() {
    // If no answer selected, mark as wrong and move to next
    if (_userAnswers[_currentQuestionIndex] == null) {
      _userAnswers[_currentQuestionIndex] = ''; // Empty = wrong answer
    }
    _onNextQuestion();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }

  void _onAnswerSelected(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
    
    // Auto-advance after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (_currentQuestionIndex < _questions.length - 1) {
          _onNextQuestion();
        } else {
          // Last question - auto submit
          _stopQuestionTimer();
          _submitContest();
        }
      }
    });
  }

  void _onNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionTimer(); // Restart timer for next question
    } else {
      _stopQuestionTimer();
      _submitContest();
    }
  }

  void _onPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _startQuestionTimer(); // Restart timer
    }
  }

  Widget _buildLifelineButton({
    required String icon,
    required String label,
    required bool isUsed,
    VoidCallback? onTap,
  }) {
    final onTertiary = Theme.of(context).colorScheme.onTertiary;
    
    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUsed
                ? onTertiary.withOpacity(0.3)
                : onTertiary.withOpacity(0.6),
          ),
          color: isUsed ? onTertiary.withOpacity(0.05) : null,
        ),
        width: 75,
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isUsed
                    ? onTertiary.withOpacity(0.4)
                    : onTertiary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUsed
                    ? onTertiary.withOpacity(0.4)
                    : onTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 50/50 - Remove two wrong options
  void _useFiftyFifty() {
    if (_fiftyFiftyUsed) return;
    
    final question = _questions[_currentQuestionIndex];
    final answerLetter = question['answer']?.toString().toLowerCase() ?? '';
    final correctAnswerText = _getOptionText(question, answerLetter);
    final optionKeys = ['optiona', 'optionb', 'optionc', 'optiond'];
    final options = optionKeys
        .where((key) => question[key] != null && question[key].toString().isNotEmpty)
        .toList();
    
    // Find wrong option keys (where text doesn't match correct answer)
    final wrongOptionKeys = options.where((key) => question[key] != correctAnswerText).toList();
    
    // Remove 2 wrong options
    wrongOptionKeys.shuffle();
    final toHide = wrongOptionKeys.take(2).map((key) => question[key] as String).toList();
    
    setState(() {
      _fiftyFiftyUsed = true;
      _hiddenOptions[_currentQuestionIndex] = toHide;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('50/50 used! Two wrong options removed.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Audience Poll - Show simulated poll results
  void _useAudiencePoll() {
    if (_audiencePollUsed) return;
    
    final question = _questions[_currentQuestionIndex];
    final answerLetter = question['answer']?.toString().toLowerCase() ?? '';
    final correctAnswerText = _getOptionText(question, answerLetter);
    final options = [
      question['optiona'],
      question['optionb'],
      question['optionc'],
      question['optiond'],
    ].where((o) => o != null && o.toString().isNotEmpty).cast<String>().toList();
    
    // Generate fake poll results (correct answer gets higher percentage)
    final results = <String, int>{};
    int remaining = 100;
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      if (option == correctAnswerText) {
        final percentage = 40 + (DateTime.now().millisecond % 30); // 40-70%
        results[option] = percentage;
        remaining -= percentage;
      } else if (i == options.length - 1) {
        results[option] = remaining.clamp(0, 100);
      } else {
        final percentage = (remaining ~/ (options.length - i)).clamp(5, 20);
        results[option] = percentage;
        remaining -= percentage;
      }
    }
    
    setState(() {
      _audiencePollUsed = true;
      _pollResults = {_currentQuestionIndex: results};
    });
    
    // Show poll dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Audience Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: results.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                Text('${e.value}%'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: e.value / 100,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Reset Time - Add extra time to current question
  void _useResetTime() {
    if (_resetTimeUsed) return;
    
    setState(() {
      _resetTimeUsed = true;
      _remainingSeconds = _questionTimeSeconds; // Reset to full time
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timer reset! You have 30 more seconds.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Skip - Skip question WITHOUT granting point (loses the point)
  /// Can be used unlimited times
  void _useSkip() {
    setState(() {
      // Mark as skipped (empty answer = wrong, no point)
      _userAnswers[_currentQuestionIndex] = '';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question skipped. No point awarded.'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Move to next question or submit if last
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (_currentQuestionIndex < _questions.length - 1) {
          _onNextQuestion();
        } else {
          // Last question - auto submit
          _stopQuestionTimer();
          _submitContest();
        }
      }
    });
  }

  Future<void> _submitContest() async {
    if (_contestData == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous error
    });

    try {
      // Prepare answers
      final answers = <Map<String, dynamic>>[];
      int localCorrectCount = 0;
      
      for (var i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _userAnswers[i] ?? '';
        
        // Get the correct answer text based on the answer letter
        final answerLetter = question['answer']?.toString().toLowerCase() ?? '';
        final correctAnswerText = _getOptionText(question, answerLetter);
        
        answers.add({
          'question_id': question['id'],
          'answer': userAnswer,
        });

        // Check if correct locally (fallback)
        if (userAnswer.isNotEmpty && 
            userAnswer.toLowerCase().trim() == correctAnswerText.toLowerCase().trim()) {
          localCorrectCount++;
        }
      }

      final result = await QuizRepository().submitDailyContest(
        contestId: _contestData!['contest_id'].toString(),
        answers: answers,
        readText: _hasReadText,
      );

      setState(() {
        _quizCompleted = true;
        _totalScore = result['total_score'] ?? (_hasReadText ? 5 : 0) + localCorrectCount;
        _correctAnswers = result['correct_answers'] ?? localCorrectCount;
        _isLoading = false;
      });
    } catch (e) {
      log('Error submitting contest: $e', name: 'DailyContest');
      
      // Check if it's "already completed" error - show result instead of error
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already') && errorMsg.contains('completed')) {
        setState(() {
          _quizCompleted = true;
          _isLoading = false;
        });
        return;
      }
      
      // For other errors, calculate score locally and show result anyway
      int localCorrectCount = 0;
      for (var i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _userAnswers[i] ?? '';
        final answerLetter = question['answer']?.toString().toLowerCase() ?? '';
        final correctAnswerText = _getOptionText(question, answerLetter);
        if (userAnswer.isNotEmpty && 
            userAnswer.toLowerCase().trim() == correctAnswerText.toLowerCase().trim()) {
          localCorrectCount++;
        }
      }
      
      setState(() {
        _quizCompleted = true;
        _totalScore = (_hasReadText ? 5 : 0) + localCorrectCount;
        _correctAnswers = localCorrectCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isExitDialogOpen) return;
        _onTapBackButton();
      },
      child: Scaffold(
        appBar: QAppBar(
          onTapBackButton: _onTapBackButton,
          title: Text(
            'Daily Rhapsody Contest',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_quizCompleted) {
      return _buildResultScreen();
    }

    if (!_showQuiz) {
      return _buildReadingScreen();
    }

    return _buildQuizScreen();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingScreen() {
    final rhapsodyText = _contestData?['rhapsody_text'] ?? '';
    final rhapsodyVerse = _contestData?['rhapsody_verse'] ?? '';
    final rhapsodyPrayer = _contestData?['rhapsody_prayer'] ?? '';
    final scriptureRef = _contestData?['scripture_ref'] ?? '';
    final contestName = _contestData?['name'] ?? 'Daily Rhapsody';

    return Column(
      children: [
        // Fixed Header (like regular Rhapsody)
        Container(
          color: const Color(0xFF1565C0),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    contestName,
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
                // Points Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reading: +5 points | Quiz: +5 points',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Scripture Box
                if (rhapsodyVerse.isNotEmpty || scriptureRef.isNotEmpty)
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
                        if (scriptureRef.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.menu_book,
                                  color: Color(0xFF1565C0), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                scriptureRef,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                        if (scriptureRef.isNotEmpty && rhapsodyVerse.isNotEmpty)
                          const SizedBox(height: 8),
                        if (rhapsodyVerse.isNotEmpty)
                          Text(
                            rhapsodyVerse,
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
                if (rhapsodyText.isNotEmpty)
                  Text(
                    rhapsodyText,
                    style: const TextStyle(fontSize: 16, height: 1.7),
                  )
                else
                  const Text(
                    'No content available for today.',
                    style: TextStyle(fontSize: 16, height: 1.7),
                  ),

                const SizedBox(height: 24),

                // Prayer Box
                if (rhapsodyPrayer.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.personPraying,
                              color: Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PRAYER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rhapsodyPrayer,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Further Study (like regular Rhapsody)
                if ((_contestData?['further_study'] ?? '').isNotEmpty)
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
                          _contestData?['further_study'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onReadComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'I\'ve Read It - Start Quiz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizScreen() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final question = _questions[_currentQuestionIndex];
    final hiddenOpts = _hiddenOptions[_currentQuestionIndex] ?? [];
    final options = [
      question['optiona'],
      question['optionb'],
      question['optionc'],
      question['optiond'],
    ].where((o) => o != null && o.toString().isNotEmpty && !hiddenOpts.contains(o)).toList();

    final selectedAnswer = _userAnswers[_currentQuestionIndex];

    return Column(
      children: [
        // Progress Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      // Timer Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _remainingSeconds <= 10
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: _remainingSeconds <= 10
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_remainingSeconds}s',
                              style: TextStyle(
                                color: _remainingSeconds <= 10
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Points Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+1 point',
                          style: TextStyle(
                            color: const Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),

        // Question
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    question['question'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Options
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value.toString();
                  final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
                  final isSelected = selectedAnswer == option;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _onAnswerSelected(option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1565C0).withOpacity(0.1)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1565C0),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Lifelines Row (like Rhapsody quiz)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 50/50 lifeline
              _buildLifelineButton(
                icon: Assets.fiftyFiftyLifeline,
                label: '50/50',
                isUsed: _fiftyFiftyUsed,
                onTap: _useFiftyFifty,
              ),
              // Poll lifeline
              _buildLifelineButton(
                icon: Assets.audiencePollLifeline,
                label: 'Poll',
                isUsed: _audiencePollUsed,
                onTap: _useAudiencePoll,
              ),
              // Timer lifeline
              _buildLifelineButton(
                icon: Assets.resetTimeLifeline,
                label: 'Timer',
                isUsed: _resetTimeUsed,
                onTap: _useResetTime,
              ),
              // Skip lifeline (skips question, NO point awarded) - unlimited use
              _buildLifelineButton(
                icon: Assets.skipQueLifeline,
                label: 'Skip',
                isUsed: false, // Never disabled - can use unlimited times
                onTap: _useSkip,
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildResultScreen() {
    final readingPoints = _hasReadText ? 5 : 0;
    final quizPoints = _correctAnswers;
    final maxScore = 10;
    final percentage = (_totalScore / maxScore * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Trophy Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: percentage >= 80
                    ? [Colors.amber.shade400, Colors.orange.shade600]
                    : percentage >= 50
                        ? [Colors.blue.shade400, Colors.blue.shade700]
                        : [Colors.grey.shade400, Colors.grey.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (percentage >= 80 ? Colors.amber : Colors.blue)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              percentage >= 80
                  ? Icons.emoji_events
                  : percentage >= 50
                      ? Icons.thumb_up
                      : Icons.sentiment_satisfied,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Congratulations Text
          Text(
            percentage >= 80
                ? 'Excellent!'
                : percentage >= 50
                    ? 'Good Job!'
                    : 'Keep Learning!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed today\'s Daily Rhapsody Contest',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Score Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Total Score
                Text(
                  '$_totalScore / $maxScore',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const Text(
                  'Total Points',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Breakdown
                _buildScoreRow(
                  icon: Icons.menu_book,
                  label: 'Reading Points',
                  value: '+$readingPoints',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _buildScoreRow(
                  icon: Icons.quiz,
                  label: 'Quiz Points',
                  value: '+$quizPoints',
                  subLabel: '$_correctAnswers / ${_questions.length} correct',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Leaderboard Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your score has been added to the daily leaderboard!',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Refresh home data before popping
                dashboardScreenKey.currentState?.refreshHomeData();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // View Leaderboard - navigates to home where leaderboard tab is available
          TextButton(
            onPressed: () {
              // Refresh home data and pop back
              dashboardScreenKey.currentState?.refreshHomeData();
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow({
    required IconData icon,
    required String label,
    required String value,
    String? subLabel,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

