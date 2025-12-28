import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/battles/battles.dart';
import 'package:flutterquiz/features/battles/cubits/group_battle_cubit.dart';

/// Group Battle Screen
class GroupBattleScreen extends StatefulWidget {
  final String battleId;
  final String? groupId;
  final String? topicId;
  final String? categoryId;
  final bool isCreator;

  const GroupBattleScreen({
    super.key,
    required this.battleId,
    this.groupId,
    this.topicId,
    this.categoryId,
    this.isCreator = false,
  });

  static Route route({
    required String battleId,
    String? groupId,
    String? topicId,
    String? categoryId,
    bool isCreator = false,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => GroupBattleCubit(BattlesRemoteDataSource()),
        child: GroupBattleScreen(
          battleId: battleId,
          groupId: groupId,
          topicId: topicId,
          categoryId: categoryId,
          isCreator: isCreator,
        ),
      ),
    );
  }

  @override
  State<GroupBattleScreen> createState() => _GroupBattleScreenState();
}

class _GroupBattleScreenState extends State<GroupBattleScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isCreator && widget.groupId != null && widget.topicId != null && widget.categoryId != null) {
      context.read<GroupBattleCubit>().createBattle(
        groupId: widget.groupId!,
        topicId: widget.topicId!,
        categoryId: widget.categoryId!,
      );
    } else {
      context.read<GroupBattleCubit>().loadBattle(widget.battleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<GroupBattleCubit, GroupBattleState>(
        listener: (context, state) {
          if (state is GroupBattleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is GroupBattleLoading) {
            return _buildLoadingState();
          }

          if (state is GroupBattleCreated || state is GroupBattleWaiting) {
            final battle = state is GroupBattleCreated
                ? (state).battle
                : (state as GroupBattleWaiting).battle;
            return _buildWaitingState(battle);
          }

          if (state is GroupBattleReady) {
            return _buildReadyState(state.battle);
          }

          if (state is GroupBattlePlaying) {
            return _buildPlayingState(state);
          }

          if (state is GroupBattleSubmitted) {
            return _buildSubmittedState(state.battle);
          }

          if (state is GroupBattleCompleted) {
            return _buildCompletedState(state.battle);
          }

          if (state is GroupBattleError) {
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
          colors: [Colors.teal.shade700, Colors.teal.shade900],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Loading Battle...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState(GroupBattle battle) {
    final cubit = context.read<GroupBattleCubit>();
    final isOwner = widget.isCreator;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade700, Colors.teal.shade900],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.groups,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 24),
              const Text(
                'Waiting for players...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Players count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${battle.playerCount}/${battle.maxPlayers} Players',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Players list
              if (battle.entries != null && battle.entries!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: battle.entries!.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: entry.profile != null && entry.profile!.isNotEmpty
                                  ? NetworkImage(entry.profile!)
                                  : null,
                              child: entry.profile == null || entry.profile!.isEmpty
                                  ? Text(entry.name?.isNotEmpty == true 
                                      ? entry.name![0].toUpperCase() 
                                      : '?')
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.name ?? 'Player',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 32),

              // Start button (owner only)
              if (isOwner && battle.canStart)
                ElevatedButton(
                  onPressed: () => cubit.startBattle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  ),
                  child: const Text(
                    'START BATTLE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              else if (isOwner && !battle.canStart)
                Text(
                  'Need at least ${battle.minPlayers} players to start',
                  style: const TextStyle(color: Colors.white70),
                ),

              const SizedBox(height: 24),

              // Cancel button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyState(GroupBattle battle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade700, Colors.teal.shade900],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Battle is Ready!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${battle.playerCount} Players',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 48),

              // Battle info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem(Icons.help_outline, '${battle.questionCount}', 'Questions'),
                    _buildInfoItem(Icons.timer, '${battle.timePerQuestion}s', 'Per Question'),
                    if (battle.prizeCoins > 0)
                      _buildInfoItem(Icons.monetization_on, '${battle.prizeCoins}', 'Prize'),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Start button
              ElevatedButton(
                onPressed: () => context.read<GroupBattleCubit>().startGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('START'),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildPlayingState(GroupBattlePlaying state) {
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
          colors: [Colors.teal.shade700, Colors.teal.shade900],
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${state.currentQuestionIndex + 1}/${questions.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                          color: state.timeRemaining <= 5 ? Colors.red.shade300 : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                          final optionLabel = String.fromCharCode(65 + index);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.read<GroupBattleCubit>().answerQuestion(optionLabel.toLowerCase());
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
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildSubmittedState(GroupBattle battle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade700, Colors.teal.shade900],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Waiting for other players...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState(GroupBattle battle) {
    final cubit = context.read<GroupBattleCubit>();
    final entries = battle.entries ?? [];
    entries.sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.amber.shade600, Colors.orange.shade800],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.emoji_events, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Battle Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Score: ${cubit.score}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 24),

            // Leaderboard
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: index < entries.length - 1
                                  ? Border(bottom: BorderSide(color: Colors.white24))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Rank
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == 0
                                        ? Colors.amber
                                        : index == 1
                                            ? Colors.grey.shade300
                                            : index == 2
                                                ? Colors.brown.shade300
                                                : Colors.white24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.rank ?? index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: index < 3 ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Avatar
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: entry.profile != null && entry.profile!.isNotEmpty
                                      ? NetworkImage(entry.profile!)
                                      : null,
                                  child: entry.profile == null || entry.profile!.isEmpty
                                      ? Text(entry.name?.isNotEmpty == true 
                                          ? entry.name![0].toUpperCase() 
                                          : '?')
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Name
                                Expanded(
                                  child: Text(
                                    entry.name ?? 'Player',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Score
                                Text(
                                  '${entry.score}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Back to Group'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade700, Colors.teal.shade900],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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

