import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';

/// State for daily contest status
sealed class DailyContestState {
  const DailyContestState();
}

final class DailyContestInitial extends DailyContestState {
  const DailyContestInitial();
}

final class DailyContestLoading extends DailyContestState {
  const DailyContestLoading();
}

final class DailyContestStatusLoaded extends DailyContestState {
  const DailyContestStatusLoaded({
    required this.hasPendingContest,
    required this.hasCompleted,
    this.contestId,
    this.contestName,
    this.userScore,
    this.date,
  });

  final bool hasPendingContest;
  final bool hasCompleted;
  final String? contestId;
  final String? contestName;
  final int? userScore;
  final String? date;
}

final class DailyContestError extends DailyContestState {
  const DailyContestError(this.message);
  final String message;
}

/// Cubit to manage daily contest status
class DailyContestCubit extends Cubit<DailyContestState> {
  DailyContestCubit(this._quizRepository) : super(const DailyContestInitial());

  final QuizRepository _quizRepository;

  /// Check if user has a pending daily contest
  /// Set [forceRefresh] to true to bypass cache (e.g., after contest submission)
  Future<void> checkDailyContestStatus({bool forceRefresh = false}) async {
    emit(const DailyContestLoading());

    try {
      final result = await _quizRepository.getDailyContestStatus(forceRefresh: forceRefresh);
      
      emit(DailyContestStatusLoaded(
        hasPendingContest: (result['has_pending_contest'] as bool?) ?? false,
        hasCompleted: (result['has_completed'] as bool?) ?? false,
        contestId: result['contest_id']?.toString(),
        contestName: result['contest_name']?.toString(),
        userScore: result['user_score'] as int?,
        date: result['date']?.toString(),
      ));
    } catch (e) {
      emit(DailyContestError(e.toString()));
    }
  }

  /// Check if there's a pending contest (for badge display)
  bool get hasPendingContest {
    final currentState = state;
    if (currentState is DailyContestStatusLoaded) {
      return currentState.hasPendingContest;
    }
    return false;
  }
}

