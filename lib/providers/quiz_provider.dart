import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/supabase_service.dart';
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
    final currentQuestion = state.currentQuestion;

    // Update state immediately for better UX responsiveness
    state = state.copyWith(
      selectedOptionIndex: optionIndex,
      isAnswered: true,
      score: isCorrect ? state.score + 1 : state.score,
    );

    // Save result for this specific question in the background (Cloud)
    try {
      await SupabaseService.instance.saveAnswer(
        questionId: currentQuestion.id,
        category: currentQuestion.category,
        isCorrect: isCorrect,
      );

      await SupabaseService.instance.toggleFavorite(
        currentQuestion.id,
        false, // Note: Future logic could handle "wrong as weakness" if needed
      );

      _notifyDbUpdate();
    } catch (e) {
      print('Supabase error in answer: $e');
    }
  }

  Future<void> nextQuestion() async {
    if (state.currentIndex < state.questions.length - 1) {
      state = QuizState(
        questions: state.questions,
        currentIndex: state.currentIndex + 1,
        score: state.score,
        isAnswered: false,
        selectedOptionIndex: null,
      );
    } else {
      // Mark as completed immediately for UI responsiveness
      state = state.copyWith(isCompleted: true);

      // Save final quiz result to Cloud in the background
      await saveCurrentResult();
    }
  }

  Future<void> saveCurrentResult() async {
    if (state.questions.isEmpty) return;

    // How many questions were actually attempted?
    // If the current question IS answered, then currentIndex + 1 have been done.
    // If NOT answered, then only currentIndex have been completed.
    final attemptedCount =
        state.isAnswered ? state.currentIndex + 1 : state.currentIndex;

    if (attemptedCount == 0) return;

    try {
      await SupabaseService.instance.saveQuizResult(
        totalQuestions: attemptedCount,
        score: state.score,
        category: state.questions.first.category,
      );

      _notifyDbUpdate();
    } catch (e) {
      print('Supabase error in saveCurrentResult: $e');
    }
  }

  void reset() {
    state = const QuizState();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref: ref);
});
