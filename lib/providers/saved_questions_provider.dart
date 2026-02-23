import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/supabase_service.dart';
import 'progress_provider.dart';

class SavedQuestionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  SavedQuestionsNotifier({required this.ref})
      : super(const AsyncValue.data(null));

  Future<void> _notifyDbUpdate() async {
    ref.read(dbUpdateCounterProvider.notifier).state++;
  }

  Future<void> saveWrongQuestion(Question question) async {
    // Note: Cloud tracking of wrong questions is handled via user_progress
    // but if we want a specific "bookmark" for wrong questions,
    // we would use a flag in Supabase.
    _notifyDbUpdate();
  }

  Future<void> toggleFavorite(Question question) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 1. Cloudの状態を確認・更新
      final isCurrentlyFavorite =
          await SupabaseService.instance.isFavorite(question.id);
      await SupabaseService.instance
          .toggleFavorite(question.id, !isCurrentlyFavorite);

      _notifyDbUpdate();
    });
  }

  Future<void> removeWrongFlag(String id) async {
    // Cloud would handle this via progress or a dedicated table
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
  return await SupabaseService.instance.getWeakQuestions();
});

final favoriteQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  ref.watch(dbUpdateCounterProvider);
  return await SupabaseService.instance.getFavoriteQuestions();
});

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, id) async {
  ref.watch(dbUpdateCounterProvider);
  return await SupabaseService.instance.isFavorite(id);
});
