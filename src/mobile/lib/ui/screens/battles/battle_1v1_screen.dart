import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/battles/battles.dart';

/// 1v1 Battle Screen
class Battle1v1Screen extends StatefulWidget {
  final String? topicId;
  final String? categoryId;
  final String? matchCode; // If joining an existing battle

  const Battle1v1Screen({
    super.key,
    this.topicId,
    this.categoryId,
    this.matchCode,
  });

  static Route route({
    String? topicId,
    String? categoryId,
    String? matchCode,
  }) {
    return MaterialPageRoute(
      builder: (_) => Battle1v1Screen(
        topicId: topicId,
        categoryId: categoryId,
        matchCode: matchCode,
      ),
    );
  }

  @override
  State<Battle1v1Screen> createState() => _Battle1v1ScreenState();
}

class _Battle1v1ScreenState extends State<Battle1v1Screen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<Battle1v1Cubit>();
    
    if (widget.matchCode != null) {
      // Join existing battle
      cubit.joinBattle(widget.matchCode!);
    } else if (widget.topicId != null && widget.categoryId != null) {
      // Create new battle
      cubit.createBattle(
        topicId: widget.topicId!,
        categoryId: widget.categoryId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<Battle1v1Cubit, Battle1v1State>(
        listener: (context, state) {
          if (state is Battle1v1Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is Battle1v1Loading) {
            return _buildLoadingState();
          }

          if (state is Battle1v1Created || state is Battle1v1WaitingOpponent) {
            final battle = state is Battle1v1Created
                ? (state).battle
                : (state as Battle1v1WaitingOpponent).battle;
            return _buildWaitingState(battle);
          }

          if (state is Battle1v1Ready) {
            return _buildReadyState(state.battle);
          }

          if (state is Battle1v1Playing) {
            return _buildPlayingState(state);
          }

          if (state is Battle1v1Completed) {
            return _buildCompletedState(state.battle);
          }

          if (state is Battle1v1Error) {
            return _buildErrorState(state.message);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade700, Colors.purple.shade900],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Preparing Battle...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState(Battle1v1 battle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade700, Colors.purple.shade900],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 24),
              const Text(
                'Waiting for opponent...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Match Code Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Share this code with your opponent',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            battle.matchCode,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: battle.matchCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copied!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Cancel Button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyState(Battle1v1 battle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade700, Colors.purple.shade900],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Opponent Found!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              
              // VS Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerCard(
                    name: battle.challenger?.name ?? 'You',
                    profile: battle.challenger?.profile,
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildPlayerCard(
                    name: battle.opponent?.name ?? 'Opponent',
                    profile: battle.opponent?.profile,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Battle Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem(
                      Icons.help_outline,
                      '${battle.questionCount}',
                      'Questions',
                    ),
                    _buildInfoItem(
                      Icons.timer,
                      '${battle.timePerQuestion}s',
                      'Per Question',
                    ),
                    if (battle.prizeCoins > 0)
                      _buildInfoItem(
                        Icons.monetization_on,
                        '${battle.prizeCoins}',
                        'Prize',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Start Button
              ElevatedButton(
                onPressed: () {
                  context.read<Battle1v1Cubit>().startGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('START BATTLE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard({required String name, String? profile}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: profile != null && profile.isNotEmpty
              ? NetworkImage(profile)
              : null,
          child: profile == null || profile.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 32),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPlayingState(Battle1v1Playing state) {
    final battle = state.battle;
    final questions = battle.questions;
    if (questions == null || questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final question = questions[state.currentQuestionIndex];
    final progress = (state.currentQuestionIndex + 1) / questions.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade700, Colors.purple.shade900],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${state.currentQuestionIndex + 1}/${questions.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Timer
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.timeRemaining <= 5
                          ? Colors.red.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        '${state.timeRemaining}',
                        style: TextStyle(
                          color: state.timeRemaining <= 5
                              ? Colors.red.shade300
                              : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, index) {
                          final option = question.options[index];
                          final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.read<Battle1v1Cubit>().answerQuestion(optionLabel.toLowerCase());
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          optionLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

  Widget _buildCompletedState(Battle1v1 battle) {
    final cubit = context.read<Battle1v1Cubit>();
    final isWinner = battle.winnerId != null; // TODO: Compare with current user ID
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWinner
              ? [Colors.amber.shade600, Colors.orange.shade800]
              : [Colors.grey.shade600, Colors.grey.shade800],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                battle.isDraw
                    ? "It's a Draw!"
                    : (isWinner ? 'You Won!' : 'You Lost'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // Score Comparison
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreColumn(
                      'You',
                      cubit.score,
                      cubit.correct,
                      battle.questionCount,
                    ),
                    Container(
                      width: 1,
                      height: 80,
                      color: Colors.white30,
                    ),
                    _buildScoreColumn(
                      'Opponent',
                      battle.opponentScore,
                      battle.opponentCorrect,
                      battle.questionCount,
                    ),
                  ],
                ),
              ),
              
              if (battle.prizeCoins > 0 && isWinner) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        '+${battle.prizeCoins} Coins',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 48),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Home'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Rematch - create new battle
                      cubit.createBattle(
                        topicId: battle.topicId,
                        categoryId: battle.categoryId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Play Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreColumn(String label, int score, int correct, int total) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$correct/$total correct',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade700, Colors.purple.shade900],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Join Battle Dialog
class JoinBattleDialog extends StatefulWidget {
  const JoinBattleDialog({super.key});

  @override
  State<JoinBattleDialog> createState() => _JoinBattleDialogState();
}

class _JoinBattleDialogState extends State<JoinBattleDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join 1v1 Battle'),
      content: TextField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: 'Match Code',
          hintText: 'Enter the battle code',
        ),
        textCapitalization: TextCapitalization.characters,
        maxLength: 10,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final code = _codeController.text.trim().toUpperCase();
            if (code.isNotEmpty) {
              Navigator.pop(context, code);
            }
          },
          child: const Text('Join'),
        ),
      ],
    );
  }
}

