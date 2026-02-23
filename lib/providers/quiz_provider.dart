import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/database_helper.dart';
import 'progress_provider.dart';

// State for a single quiz session
class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final int? selectedOptionIndex;
  final bool isAnswered;
  final int score;
  final bool isCompleted;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOptionIndex,
    this.isAnswered = false,
    this.score = 0,
    this.isCompleted = false,
  });

  Question get currentQuestion => questions[currentIndex];
  bool get isCorrect =>
      isAnswered && selectedOptionIndex == currentQuestion.answerIndex;
  bool get isFinished => currentIndex >= questions.length;

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? selectedOptionIndex,
    bool? isAnswered,
    int? score,
    bool? isCompleted,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;
  QuizNotifier({required this.ref}) : super(const QuizState());

  void loadQuestions(List<Question> questions) {
    state = QuizState(questions: questions);
  }

  Future<void> _notifyDbUpdate() async {
    ref.read(dbUpdateCounterProvider.notifier).state++;
  }

  Future<void> answer(int optionIndex) async {
    if (state.isAnswered) return;

    final isCorrect = optionIndex == state.currentQuestion.answerIndex;

    // Save result for this specific question
    try {
      await DatabaseHelper.instance.markQuestionAnswered(
        state.currentQuestion.id,
        state.currentQuestion.category,
        isCorrect,
      );

      if (!isCorrect) {
        // Save to weaknesses
        await DatabaseHelper.instance
            .saveQuestion(state.currentQuestion, isWrong: true);
      } else {
        // Remove from weaknesses if they got it right
        await DatabaseHelper.instance.removeWrongFlag(state.currentQuestion.id);
      }

      _notifyDbUpdate();
    } catch (e) {
      // ignore database errors to allow the quiz to continue even if setup failed
      print('Database error in answer: $e');
    }

    state = state.copyWith(
      selectedOptionIndex: optionIndex,
      isAnswered: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  Future<void> nextQuestion() async {
    if (state.currentIndex < state.questions.length - 1) {
      state = QuizState(
        questions: state.questions,
        currentIndex: state.currentIndex + 1,
        score: state.score,
        // Reset per-question state
        isAnswered: false,
        selectedOptionIndex: null,
      );
    } else {
      // Save final quiz result
      try {
        await DatabaseHelper.instance.saveQuizResult(
          state.questions.length,
          state.score,
          state.questions.first.category,
        );

        _notifyDbUpdate();
      } catch (e) {
        print('Database error in nextQuestion: $e');
      }

      // Mark as completed instead of looping
      state = state.copyWith(isCompleted: true);
    }
  }

  void reset() {
    state = const QuizState();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref: ref);
});
