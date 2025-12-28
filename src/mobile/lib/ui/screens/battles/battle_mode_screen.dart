import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/topics/topics.dart';
import 'package:flutterquiz/features/battles/battles.dart';
import 'package:flutterquiz/ui/screens/battles/battle_1v1_screen.dart';

/// Battle Mode Selection Screen
class BattleModeScreen extends StatefulWidget {
  const BattleModeScreen({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const BattleModeScreen());
  }

  @override
  State<BattleModeScreen> createState() => _BattleModeScreenState();
}

class _BattleModeScreenState extends State<BattleModeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TopicsCubit>().loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Mode'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selection
            _buildModeSection(),

            const Divider(height: 32),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Battle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 1v1 Battle Card
          _BattleModeCard(
            icon: Icons.people,
            title: '1 vs 1 Battle',
            description: 'Challenge a friend to a duel',
            color: Colors.orange,
            onTap: () => _startBattleSetup('1v1'),
          ),
          const SizedBox(height: 12),

          // Group Battle Card
          _BattleModeCard(
            icon: Icons.groups,
            title: 'Group Battle',
            description: 'Battle with your group members',
            color: Colors.purple,
            onTap: () => _startBattleSetup('group'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Join Battle',
                  subtitle: 'Enter code',
                  onTap: _showJoinDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'Past battles',
                  onTap: _showHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startBattleSetup(String mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BattleSetupSheet(
        mode: mode,
        onStart: (topicId, categoryId) {
          Navigator.pop(context);
          if (mode == '1v1') {
            Navigator.push(
              context,
              Battle1v1Screen.route(
                topicId: topicId,
                categoryId: categoryId,
              ),
            );
          } else {
            // Navigate to group battle
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group battle coming soon!')),
            );
          }
        },
      ),
    );
  }

  void _showJoinDialog() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const JoinBattleDialog(),
    );
    
    if (code != null && code.isNotEmpty && mounted) {
      Navigator.push(
        context,
        Battle1v1Screen.route(matchCode: code),
      );
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => BlocBuilder<Battle1v1HistoryCubit, Battle1v1HistoryState>(
          builder: (context, state) {
            // Load history if not loaded
            if (state is Battle1v1HistoryInitial) {
              context.read<Battle1v1HistoryCubit>().loadHistory();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Battle History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: _buildHistoryContent(state, scrollController),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryContent(Battle1v1HistoryState state, ScrollController controller) {
    if (state is Battle1v1HistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is Battle1v1HistoryLoaded) {
      if (state.battles.isEmpty) {
        return const Center(
          child: Text('No battle history yet'),
        );
      }

      return ListView.builder(
        controller: controller,
        itemCount: state.battles.length,
        itemBuilder: (context, index) {
          final battle = state.battles[index];
          return _BattleHistoryCard(battle: battle);
        },
      );
    }

    if (state is Battle1v1HistoryError) {
      return Center(child: Text(state.message));
    }

    return const SizedBox();
  }
}

/// Battle Mode Card
class _BattleModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _BattleModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick Action Card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.purple),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Battle Setup Sheet
class _BattleSetupSheet extends StatefulWidget {
  final String mode;
  final void Function(String topicId, String categoryId) onStart;

  const _BattleSetupSheet({
    required this.mode,
    required this.onStart,
  });

  @override
  State<_BattleSetupSheet> createState() => _BattleSetupSheetState();
}

class _BattleSetupSheetState extends State<_BattleSetupSheet> {
  Topic? _selectedTopic;
  TopicCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.mode == '1v1' ? 'Start 1v1 Battle' : 'Start Group Battle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Topic Selection
          Text(
            'Select Topic',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          BlocBuilder<TopicsCubit, TopicsState>(
            builder: (context, state) {
              if (state is TopicsLoaded) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.topics.map((topic) {
                    final isSelected = _selectedTopic?.id == topic.id;
                    return ChoiceChip(
                      label: Text(topic.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTopic = selected ? topic : null;
                          _selectedCategory = null;
                        });
                        if (selected) {
                          context.read<TopicsCubit>().loadCategories(topic.id);
                        }
                      },
                    );
                  }).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 24),

          // Category Selection
          if (_selectedTopic != null) ...[
            Text(
              'Select Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            BlocBuilder<TopicsCubit, TopicsState>(
              builder: (context, state) {
                if (state is TopicsLoaded && state.categories != null) {
                  final categories = state.categories!
                      .where((c) => c.questionCount > 0)
                      .toList();
                  
                  if (categories.isEmpty) {
                    return const Text('No categories with questions');
                  }

                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategory?.id == category.id;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedCategory = category);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.purple.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.purple, width: 2)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${category.questionCount} Q',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
          const SizedBox(height: 24),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedTopic != null && _selectedCategory != null
                  ? () => widget.onStart(
                      _selectedTopic!.id,
                      _selectedCategory!.id,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Battle',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }
}

/// Battle History Card
class _BattleHistoryCard extends StatelessWidget {
  final Battle1v1 battle;

  const _BattleHistoryCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final isWinner = battle.winnerId != null; // TODO: Compare with current user
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isWinner ? Colors.green : Colors.red,
          child: Icon(
            isWinner ? Icons.emoji_events : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(
          'vs ${battle.opponent?.name ?? 'Unknown'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Score: ${battle.challengerScore} - ${battle.opponentScore}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              battle.isDraw ? 'Draw' : (isWinner ? 'Won' : 'Lost'),
              style: TextStyle(
                color: battle.isDraw
                    ? Colors.grey
                    : (isWinner ? Colors.green : Colors.red),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (battle.endedAt != null)
              Text(
                _formatDate(battle.endedAt!),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

