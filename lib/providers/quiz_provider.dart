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
  final bool isInfiniteMode;
  final int totalAnswered; // 無限モード用：累計回答数

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOptionIndex,
    this.isAnswered = false,
    this.score = 0,
    this.isCompleted = false,
    this.isInfiniteMode = false,
    this.totalAnswered = 0,
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
    bool? isInfiniteMode,
    int? totalAnswered,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
      isInfiniteMode: isInfiniteMode ?? this.isInfiniteMode,
      totalAnswered: totalAnswered ?? this.totalAnswered,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;
  // 無限モード用: 全問プール
  List<Question> _infinitePool = [];

  QuizNotifier({required this.ref}) : super(const QuizState());

  void loadQuestions(List<Question> questions, {bool infiniteMode = false}) {
    _infinitePool = infiniteMode ? List<Question>.from(questions) : [];
    state = QuizState(
      questions: questions,
      isInfiniteMode: infiniteMode,
    );
  }

  Future<void> _notifyDbUpdate() async {
    ref.read(dbUpdateCounterProvider.notifier).state++;
  }

  Future<void> answer(int optionIndex) async {
    if (state.isAnswered) return;

    final isCorrect = optionIndex == state.currentQuestion.answerIndex;
    final currentQuestion = state.currentQuestion;

    state = state.copyWith(
      selectedOptionIndex: optionIndex,
      isAnswered: true,
      score: isCorrect ? state.score + 1 : state.score,
    );

    try {
      await SupabaseService.instance.saveAnswer(
        questionId: currentQuestion.id,
        category: currentQuestion.category,
        isCorrect: isCorrect,
      );

      await SupabaseService.instance.toggleFavorite(
        currentQuestion.id,
        false,
      );

      _notifyDbUpdate();
    } catch (e) {
      print('Supabase error in answer: $e');
    }
  }

  Future<void> nextQuestion() async {
    if (state.currentIndex < state.questions.length - 1) {
      // まだ問題が残っている
      state = QuizState(
        questions: state.questions,
        currentIndex: state.currentIndex + 1,
        score: state.score,
        isAnswered: false,
        selectedOptionIndex: null,
        isInfiniteMode: state.isInfiniteMode,
        totalAnswered: state.totalAnswered + 1,
      );
    } else if (state.isInfiniteMode) {
      // 無限モード：再シャッフルして最初から
      final newList = List<Question>.from(_infinitePool)..shuffle();
      state = QuizState(
        questions: newList,
        currentIndex: 0,
        score: state.score,
        isAnswered: false,
        selectedOptionIndex: null,
        isInfiniteMode: true,
        totalAnswered: state.totalAnswered + 1,
      );
    } else {
      // 通常モード：完了
      state = state.copyWith(
        isCompleted: true,
        totalAnswered: state.totalAnswered + 1,
      );
      await saveCurrentResult();
    }
  }

  Future<void> saveCurrentResult() async {
    if (state.questions.isEmpty) return;

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
    _infinitePool = [];
    state = const QuizState();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref: ref);
});
