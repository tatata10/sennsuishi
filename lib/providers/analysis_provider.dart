import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import 'progress_provider.dart';

class CategoryStats {
  final String category;
  final int total;
  final int correct;
  final int weaknessCount;

  CategoryStats({
    required this.category,
    required this.total,
    required this.correct,
    required this.weaknessCount,
  });

  double get accuracy => total == 0 ? 0 : correct / total;
}

final categoryAnalysisProvider =
    FutureProvider<List<CategoryStats>>((ref) async {
  ref.watch(dbUpdateCounterProvider);

  // Cloudから分析データを取得
  final analysis = await SupabaseService.instance.getCategoryAnalysis();

  // Cloudから弱点統計を取得
  final Map<String, int> weaknesses =
      await SupabaseService.instance.getWeaknessStats();

  return analysis.map((row) {
    final cat = row['category'] as String;
    return CategoryStats(
      category: cat,
      total: row['total'] as int,
      correct: row['correct'] as int,
      weaknessCount: weaknesses[cat] ?? 0,
    );
  }).toList();
});

// Overall trend data
final recentScoresProvider = FutureProvider<List<double>>((ref) async {
  ref.watch(dbUpdateCounterProvider);

  final history = await SupabaseService.instance.getQuizHistory();
  return history
      .map((h) => (h['score'] as int) / (h['total_questions'] as int))
      .toList()
      .reversed
      .toList();
});
