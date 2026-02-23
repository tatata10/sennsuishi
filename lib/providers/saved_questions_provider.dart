import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/database_helper.dart';
import 'progress_provider.dart';

class SavedQuestionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  SavedQuestionsNotifier({required this.ref})
      : super(const AsyncValue.data(null));

  Future<void> _notifyDbUpdate() async {
    ref.read(dbUpdateCounterProvider.notifier).state++;
  }

  Future<void> saveWrongQuestion(Question question) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.saveQuestion(question, isWrong: true);
      _notifyDbUpdate();
    });
  }

  Future<void> toggleFavorite(Question question) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final isCurrentlyFavorite =
          await DatabaseHelper.instance.isFavorite(question.id);
      await DatabaseHelper.instance
          .saveQuestion(question, isFavorite: !isCurrentlyFavorite);
      _notifyDbUpdate();
    });
  }

  Future<void> removeWrongFlag(String id) async {
    await DatabaseHelper.instance.removeWrongFlag(id);
    _notifyDbUpdate();
  }
}

final savedQuestionsProvider =
    StateNotifierProvider<SavedQuestionsNotifier, AsyncValue<void>>((ref) {
  return SavedQuestionsNotifier(ref: ref);
});

// Providers for fetching lists
final wrongQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  ref.watch(dbUpdateCounterProvider);
  return await DatabaseHelper.instance.getWrongQuestions();
});

final favoriteQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  ref.watch(dbUpdateCounterProvider);
  return await DatabaseHelper.instance.getFavoriteQuestions();
});

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, id) async {
  ref.watch(dbUpdateCounterProvider);
  return await DatabaseHelper.instance.isFavorite(id);
});
