import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // Local DB doesn't have profiles in this implementation yet,
  // but we return a mock one for now.
  return {'nickname': 'ユーザー'};
});
