import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/config/colors.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';
import 'package:flutterquiz/features/settings/settings_cubit.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

/// Generic question model for shared quiz widget
class QuizQuestionData {
  final String id;
  final String question;
  final List<QuizOptionData> options;
  final String correctOptionId; // 'a', 'b', 'c', or 'd'
  final String? imageUrl;
  final String? note; // Explanation

  const QuizQuestionData({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionId,
    this.imageUrl,
    this.note,
  });
}

/// Generic option model
class QuizOptionData {
  final String id; // 'a', 'b', 'c', or 'd'
  final String text;

  const QuizOptionData({
    required this.id,
    required this.text,
  });
}

/// Answer feedback mode
enum QuizAnswerMode {
  /// Don't show if answer was correct/wrong
  noFeedback,
  /// Show if answer was correct/wrong
  showCorrectness,
  /// Show if answer was correct/wrong AND highlight correct answer
  showCorrectnessAndCorrect,
}

/// Shared Quiz Question Widget with answer feedback
/// 
/// Features:
/// - Question text display
/// - Answer options with tap handling
/// - Correct/wrong answer feedback (color + sound)
/// - Poll percentage display (optional)
/// - 50/50 hidden options support
class SharedQuizQuestion extends StatefulWidget {
  final QuizQuestionData question;
  final String? selectedAnswerId;
  final bool hasSubmitted;
  final Function(String optionId) onOptionSelected;
  final QuizAnswerMode answerMode;
  
  // Lifeline effects
  final List<String> hiddenOptions;
  final Map<String, int>? pollPercentages; // optionId -> percentage
  
  // Styling
  final Color? headerColor;
  final bool showQuestionNumber;
  final int? currentQuestionNumber;
  final int? totalQuestions;

  const SharedQuizQuestion({
    required this.question,
    required this.onOptionSelected,
    this.selectedAnswerId,
    this.hasSubmitted = false,
    this.answerMode = QuizAnswerMode.showCorrectnessAndCorrect,
    this.hiddenOptions = const [],
    this.pollPercentages,
    this.headerColor,
    this.showQuestionNumber = false,
    this.currentQuestionNumber,
    this.totalQuestions,
    super.key,
  });

  @override
  State<SharedQuizQuestion> createState() => _SharedQuizQuestionState();
}

class _SharedQuizQuestionState extends State<SharedQuizQuestion> {
  late final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String trackName) async {
    if (context.read<SettingsCubit>().getSettings().sound) {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setAsset(trackName);
      await _audioPlayer.play();
    }
  }

  Future<void> _playVibrate() async {
    if (context.read<SettingsCubit>().getSettings().vibration) {
      UiUtils.vibrate();
    }
  }

  void _onTapOption(String optionId) {
    if (widget.hasSubmitted) return;

    widget.onOptionSelected(optionId);

    // Play appropriate sound
    if (widget.answerMode == QuizAnswerMode.noFeedback) {
      _playSound(Assets.sfxClickEvent);
    } else {
      if (optionId == widget.question.correctOptionId) {
        _playSound(Assets.sfxCorrectAnswer);
      } else {
        _playSound(Assets.sfxWrongAnswer);
      }
    }
    _playVibrate();
  }

  Color _getOptionBackgroundColor(String optionId) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!widget.hasSubmitted) {
      return colorScheme.surface;
    }

    switch (widget.answerMode) {
      case QuizAnswerMode.noFeedback:
        return widget.selectedAnswerId == optionId
            ? Theme.of(context).primaryColor
            : colorScheme.surface;

      case QuizAnswerMode.showCorrectness:
        if (widget.selectedAnswerId == optionId) {
          return optionId == widget.question.correctOptionId
              ? kCorrectAnswerColor
              : kWrongAnswerColor;
        }
        return colorScheme.surface;

      case QuizAnswerMode.showCorrectnessAndCorrect:
        if (optionId == widget.question.correctOptionId) {
          return kCorrectAnswerColor;
        }
        if (widget.selectedAnswerId == optionId) {
          return kWrongAnswerColor;
        }
        return colorScheme.surface;
    }
  }

  Color _getOptionTextColor(String optionId) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = _getOptionBackgroundColor(optionId);

    if (bgColor == kCorrectAnswerColor || bgColor == kWrongAnswerColor) {
      return Colors.white;
    }
    if (bgColor == Theme.of(context).primaryColor) {
      return Colors.white;
    }
    return colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Filter out hidden options (50/50)
    final visibleOptions = widget.question.options
        .where((o) => !widget.hiddenOptions.contains(o.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question number (optional)
        if (widget.showQuestionNumber && 
            widget.currentQuestionNumber != null && 
            widget.totalQuestions != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Question ${widget.currentQuestionNumber} of ${widget.totalQuestions}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Question text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.question.question,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: TextStyle(
                height: 1.3,
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Question image (optional)
        if (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.question.imageUrl!,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

        // Answer options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: visibleOptions.map((option) {
              final pollPct = widget.pollPercentages?[option.id];
              
              return _QuizOptionTile(
                option: option,
                backgroundColor: _getOptionBackgroundColor(option.id),
                textColor: _getOptionTextColor(option.id),
                pollPercentage: pollPct,
                isSelected: widget.selectedAnswerId == option.id,
                isCorrect: option.id == widget.question.correctOptionId,
                hasSubmitted: widget.hasSubmitted,
                showCorrectIcon: widget.hasSubmitted && 
                    widget.answerMode != QuizAnswerMode.noFeedback &&
                    option.id == widget.question.correctOptionId,
                showWrongIcon: widget.hasSubmitted && 
                    widget.answerMode != QuizAnswerMode.noFeedback &&
                    widget.selectedAnswerId == option.id &&
                    option.id != widget.question.correctOptionId,
                onTap: () => _onTapOption(option.id),
              );
            }).toList(),
          ),
        ),

        // Explanation note (shown after answer)
        if (widget.hasSubmitted && 
            widget.question.note != null && 
            widget.question.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.note!,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Individual option tile
class _QuizOptionTile extends StatefulWidget {
  final QuizOptionData option;
  final Color backgroundColor;
  final Color textColor;
  final int? pollPercentage;
  final bool isSelected;
  final bool isCorrect;
  final bool hasSubmitted;
  final bool showCorrectIcon;
  final bool showWrongIcon;
  final VoidCallback onTap;

  const _QuizOptionTile({
    required this.option,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.pollPercentage,
    this.isSelected = false,
    this.isCorrect = false,
    this.hasSubmitted = false,
    this.showCorrectIcon = false,
    this.showWrongIcon = false,
  });

  @override
  State<_QuizOptionTile> createState() => _QuizOptionTileState();
}

class _QuizOptionTileState extends State<_QuizOptionTile>
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
    final hasPoll = widget.pollPercentage != null;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.hasSubmitted ? null : (_) => _animationController.forward(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.hasSubmitted 
            ? null 
            : () async {
                await _animationController.reverse();
                widget.onTap();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected && !widget.hasSubmitted
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Poll percentage badge
              if (hasPoll) ...[
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.pollPercentage}%',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Option text
              Expanded(
                child: Text(
                  widget.option.text,
                  textAlign: hasPoll ? TextAlign.left : TextAlign.center,
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      color: widget.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ),

              // Correct/Wrong icon
              if (widget.showCorrectIcon)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: kCorrectAnswerColor,
                    size: 20,
                  ),
                )
              else if (widget.showWrongIcon)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: kWrongAnswerColor,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

