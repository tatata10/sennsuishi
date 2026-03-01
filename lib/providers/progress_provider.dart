import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_database_service.dart';

final dbUpdateCounterProvider = StateProvider<int>((ref) => 0);

final progressProvider = FutureProvider<double>((ref) async {
  ref.watch(dbUpdateCounterProvider);

  // 内部DBから分析データを取得
  final analysis = await LocalDatabaseService.instance.getCategoryAnalysis();
  if (analysis.isEmpty) return 0.0;

  int totalCorrect = 0;
  for (var cat in analysis) {
    totalCorrect += (cat['correct'] as int? ?? 0);
  }

  // 全12回 * 各40問 = 480問
  const totalPossibleQuestions = 480.0;
  return (totalCorrect / totalPossibleQuestions).clamp(0.0, 1.0);
});

final quizHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dbUpdateCounterProvider);

  return await LocalDatabaseService.instance.getQuizHistory();
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // SharedPreferencesからニックネームを取得
  final prefs = await SharedPreferences.getInstance();
  final nickname = prefs.getString('user_nickname');
  if (nickname != null) {
    return {'nickname': nickname};
  }
  return null;
});

final streakProvider = FutureProvider<int>((ref) async {
  ref.watch(dbUpdateCounterProvider);
  return await LocalDatabaseService.instance.calculateStreak();
});
