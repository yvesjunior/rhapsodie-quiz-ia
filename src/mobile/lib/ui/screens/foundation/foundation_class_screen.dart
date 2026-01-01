import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/widgets/show_login_required_dialog.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/core/routes/routes.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/foundation/foundation.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';

/// Screen showing Foundation School class content
class FoundationClassScreen extends StatelessWidget {
  final String classId;

  const FoundationClassScreen({required this.classId, super.key});

  static Route route({required String classId}) {
    return MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (_) => FoundationCubit(
          FoundationRepository(connectivityCubit: context.read<ConnectivityCubit>()),
        )..loadClassDetail(classId),
        child: FoundationClassScreen(classId: classId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FoundationCubit, FoundationState>(
        builder: (context, state) {
          if (state is FoundationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FoundationClassDetailLoaded) {
            return _buildClassContent(context, state.classDetail);
          }
          if (state is FoundationError) {
            return _buildErrorWidget(context, state, classId);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildClassContent(BuildContext context, FoundationClass classDetail) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: const Color(0xFF1565C0),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        classDetail.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        classDetail.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator if any
                if (classDetail.userProgress != null) ...[
                  _buildProgressSection(classDetail),
                  const SizedBox(height: 24),
                ],

                // Main content
                _buildContentSection(classDetail.contentText),
                const SizedBox(height: 32),

                // Quiz section
                _buildQuizSection(context, classDetail),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(FoundationClass classDetail) {
    final progress = classDetail.userProgress!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            value: progress.progressPercent / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress.status == 'completed' ? Colors.green : const Color(0xFF1565C0),
            ),
            strokeWidth: 6,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.status == 'completed'
                      ? 'Completed!'
                      : 'In Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progress.status == 'completed'
                        ? Colors.green
                        : const Color(0xFF1565C0),
                  ),
                ),
                Text(
                  'Score: ${progress.score} points',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(String contentText) {
    // Parse content into sections
    final sections = _parseContent(contentText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        if (section.isHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text(
              section.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              section.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF333333),
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  List<_ContentSection> _parseContent(String content) {
    final sections = <_ContentSection>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Detect headers (all caps or specific keywords)
      final isHeader = trimmedLine == trimmedLine.toUpperCase() &&
              trimmedLine.length > 3 &&
              !trimmedLine.startsWith('-') &&
              !RegExp(r'^\d+\.').hasMatch(trimmedLine) ||
          trimmedLine.startsWith('INTRODUCTION') ||
          trimmedLine.startsWith('CONCLUSION') ||
          trimmedLine.startsWith('KEY SCRIPTURES') ||
          trimmedLine.startsWith('TAKE HOME') ||
          trimmedLine.startsWith('MEMORY VERSE') ||
          trimmedLine.startsWith('STUDY MATERIAL') ||
          trimmedLine.startsWith('ALSO NOTE') ||
          trimmedLine.startsWith('LET US DISCUSS') ||
          trimmedLine.startsWith('WHAT IS') ||
          trimmedLine.startsWith('WHY ') ||
          trimmedLine.startsWith('HOW TO') ||
          trimmedLine.startsWith('THE ') && trimmedLine == trimmedLine.toUpperCase();

      sections.add(_ContentSection(text: trimmedLine, isHeader: isHeader));
    }

    return sections;
  }

  Widget _buildQuizSection(BuildContext context, FoundationClass classDetail) {
    return Container(
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
            '${classDetail.questionsCount} questions available',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: classDetail.questionsCount > 0
                  ? () => _startQuiz(context, classDetail)
                  : null,
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
    );
  }

  void _startQuiz(BuildContext context, FoundationClass classDetail) {
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
        'categoryId': classDetail.id,
        'subcategoryId': '',
        'level': '0',
        'isPlayed': false,
        'isPremiumCategory': false,
        'showCoins': false, // Foundation School doesn't award coins
        // Foundation class info for "Next" navigation
        'foundationClassId': classDetail.id,
        'foundationClassOrder': classDetail.rowOrder,
      },
    );
  }
}

class _ContentSection {
  final String text;
  final bool isHeader;

  _ContentSection({required this.text, required this.isHeader});
}

Widget _buildErrorWidget(BuildContext context, FoundationError state, String classId) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF1565C0),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Foundation', style: TextStyle(color: Colors.white)),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(state.message) ?? 'No internet connection found. check your connection or try again.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<FoundationCubit>()
                  .loadClassDetail(classId),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('tryAgain') ?? 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

