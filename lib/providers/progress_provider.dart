import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';

final dbUpdateCounterProvider = StateProvider<int>((ref) => 0);

final progressProvider = FutureProvider<double>((ref) async {
  ref.watch(dbUpdateCounterProvider);
  return await DatabaseHelper.instance.getOverallProgress();
});

final quizHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dbUpdateCounterProvider);
  return await DatabaseHelper.instance.getRecentHistory();
});
