import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/utils/datetime_utils.dart';

sealed class ContestState {
  const ContestState();
}

final class ContestInitial extends ContestState {
  const ContestInitial();
}

final class ContestProgress extends ContestState {
  const ContestProgress();
}

final class ContestSuccess extends ContestState {
  const ContestSuccess(this.contestList, {this.isOffline = false});

  final Contests contestList;
  final bool isOffline;
}

final class ContestFailure extends ContestState {
  const ContestFailure(this.errorMessage);

  final String errorMessage;
}

final class ContestCubit extends Cubit<ContestState> {
  ContestCubit(this._quizRepository) : super(const ContestInitial());

  final QuizRepository _quizRepository;

  Future<void> getContest({required String languageId}) async {
    emit(const ContestProgress());
    final (:gmt, :localTimezone) = await DateTimeUtils.getTimeZone();

    try {
      final val = await _quizRepository.getContest(
        languageId: languageId,
        timezone: localTimezone,
        gmt: gmt,
      );
      emit(ContestSuccess(val));
    } on ApiException catch (e) {
      emit(ContestFailure(e.error));
    } catch (e) {
      emit(const ContestFailure(errorCodeNoInternet));
    }
  }
}
