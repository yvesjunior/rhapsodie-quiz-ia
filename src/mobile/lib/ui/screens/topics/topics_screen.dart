import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/routes/routes.dart';
import 'package:flutterquiz/features/topics/topics.dart';

/// Topics Screen - Select between Rhapsody and Foundation School
class TopicsScreen extends StatefulWidget {
  final String? quizType; // 'solo', '1v1', 'group'

  const TopicsScreen({super.key, this.quizType = 'solo'});

  static Route<dynamic> route(RouteSettings rs) {
    final args = rs.arguments as Map<String, dynamic>?;
    final String? quizType = args?['quizType'] as String?;
    return MaterialPageRoute(
      builder: (_) => TopicsScreen(
        quizType: quizType ?? 'solo',
      ),
    );
  }

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TopicsCubit>().loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Topic'),
        elevation: 0,
      ),
      body: BlocBuilder<TopicsCubit, TopicsState>(
        builder: (context, state) {
          if (state is TopicsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TopicsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TopicsCubit>().loadTopics(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TopicsLoaded) {
            return _buildTopicsList(state.topics);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildTopicsList(List<Topic> topics) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _TopicCard(
          topic: topic,
          onTap: () => _selectTopic(topic),
        );
      },
    );
  }

  void _selectTopic(Topic topic) {
    // Navigate to category selection with the topic
    Navigator.pushNamed(
      context,
      Routes.category,
      arguments: {
        'topicId': topic.id,
        'topicName': topic.name,
        'topicSlug': topic.slug,
        'quizType': widget.quizType,
      },
    );
  }
}

/// Topic Card Widget
class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.onTap});

  Color get _color {
    switch (topic.slug) {
      case 'rhapsody':
        return Colors.purple;
      case 'foundation_school':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData get _icon {
    switch (topic.slug) {
      case 'rhapsody':
        return Icons.auto_stories;
      case 'foundation_school':
        return Icons.school;
      default:
        return Icons.quiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _color.withOpacity(0.8),
                _color,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -30,
                bottom: -30,
                child: Icon(
                  _icon,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      topic.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.description ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Type badge
              Positioned(
                left: 20,
                bottom: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    topic.topicType == 'daily' ? 'Daily Quiz' : 'Training',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
