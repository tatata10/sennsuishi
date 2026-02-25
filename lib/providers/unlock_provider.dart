import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import 'progress_provider.dart';

// 特定アイテムの視聴回数を取得するプロバイダー
final adViewCountProvider =
    FutureProvider.family<int, String>((ref, itemKey) async {
  ref.watch(dbUpdateCounterProvider); // DB更新時に再取得
  return await SupabaseService.instance.getAdVewCount(itemKey);
});

// 解放済みかどうかを判定するプロバイダー
final isUnlockedProvider =
    FutureProvider.family<bool, ({String itemKey, int requiredViews})>(
        (ref, arg) async {
  final views = ref.watch(adViewCountProvider(arg.itemKey)).value ?? 0;
  return views >= arg.requiredViews;
});
