import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseService._init();

  // --- Auth & Profile ---
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> createProfile(String nickname) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').upsert({
      'id': userId,
      'nickname': nickname,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- Questions ---

  Future<bool> isFavorite(String questionId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('user_favorites')
        .select()
        .match({'user_id': userId, 'question_id': questionId}).maybeSingle();

    return response != null;
  }

  Future<List<Question>> getQuestions() async {
    final response = await _client.from('questions').select();
    return (response as List).map((json) => Question.fromMap(json)).toList();
  }

  Future<List<Question>> getQuestionsByYear(String examId) async {
    // ID prefix match (e.g., '2581_')
    final response =
        await _client.from('questions').select().like('id', '${examId}_%');
    return (response as List).map((json) => Question.fromMap(json)).toList();
  }

  Future<List<Question>> getQuestionsByCategory(String category) async {
    final response =
        await _client.from('questions').select().eq('category', category);
    return (response as List).map((json) => Question.fromMap(json)).toList();
  }

  // --- Progress & History ---

  Future<void> saveAnswer({
    required String questionId,
    required String category,
    required bool isCorrect,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('user_progress').upsert({
      'user_id': userId,
      'question_id': questionId,
      'category': category,
      'is_correct': isCorrect,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleFavorite(String questionId, bool isFavorite) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    if (isFavorite) {
      await _client.from('user_favorites').upsert({
        'user_id': userId,
        'question_id': questionId,
      });
    } else {
      await _client
          .from('user_favorites')
          .delete()
          .match({'user_id': userId, 'question_id': questionId});
    }
  }

  Future<void> saveQuizResult({
    required int totalQuestions,
    required int score,
    required String category,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('quiz_history').insert({
      'user_id': userId,
      'total_questions': totalQuestions,
      'score': score,
      'category': category,
    });
  }

  // --- Admin/Seeding ---

  Future<void> uploadQuestions(List<Question> questions) async {
    final List<Map<String, dynamic>> data =
        questions.map((q) => q.toMap(forSupabase: true)).toList();
    await _client.from('questions').upsert(data);
  }

  // --- Analysis ---

  Future<void> resetUserData() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('user_progress').delete().eq('user_id', userId);
    await _client.from('user_favorites').delete().eq('user_id', userId);
    await _client.from('quiz_history').delete().eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('quiz_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting quiz history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryAnalysis() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_progress')
          .select('category, is_correct')
          .eq('user_id', userId);

      final data = response as List;
      final Map<String, Map<String, int>> stats = {};

      for (var item in data) {
        final category = item['category'] as String? ?? 'その他';
        final isCorrect = item['is_correct'] as bool? ?? false;

        stats.putIfAbsent(category, () => {'total': 0, 'correct': 0});
        stats[category]!['total'] = stats[category]!['total']! + 1;
        if (isCorrect) {
          stats[category]!['correct'] = stats[category]!['correct']! + 1;
        }
      }

      return stats.entries
          .map((e) => {
                'category': e.key,
                'total': e.value['total'],
                'correct': e.value['correct'],
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting category analysis: $e');
      return [];
    }
  }

  Future<List<Question>> getFavoriteQuestions() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final favResponse = await _client
          .from('user_favorites')
          .select('question_id')
          .eq('user_id', userId);

      final List<String> favIds =
          (favResponse as List).map((f) => f['question_id'] as String).toList();

      if (favIds.isEmpty) return [];

      final questionsResponse =
          await _client.from('questions').select().filter('id', 'in', favIds);

      return (questionsResponse as List)
          .map((json) => Question.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting favorite questions: $e');
      return [];
    }
  }

  Future<List<Question>> getWeakQuestions() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final weakResponse = await _client
          .from('user_progress')
          .select('question_id')
          .eq('user_id', userId)
          .eq('is_correct', false);

      final List<String> weakIds = (weakResponse as List)
          .map((f) => f['question_id'] as String)
          .toList();

      if (weakIds.isEmpty) return [];

      final questionsResponse =
          await _client.from('questions').select().filter('id', 'in', weakIds);

      return (questionsResponse as List)
          .map((json) => Question.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting weak questions: $e');
      return [];
    }
  }

  Future<Map<String, int>> getWeaknessStats() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return {};

      final response = await _client
          .from('user_progress')
          .select('category')
          .eq('user_id', userId)
          .eq('is_correct', false);

      final data = response as List;
      final Map<String, int> stats = {};

      for (var item in data) {
        final category = item['category'] as String? ?? 'その他';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting weakness stats: $e');
      return {};
    }
  }
  // --- Rewards & Unlocks ---

  Future<int> getAdVewCount(String itemKey) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('user_unlock_progress')
          .select('views_count')
          .match({'user_id': userId, 'item_key': itemKey}).maybeSingle();

      if (response == null) return 0;
      return response['views_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting ad view count: $e');
      return 0;
    }
  }

  Future<void> incrementAdViewCount(String itemKey) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;

      final currentCount = await getAdVewCount(itemKey);

      await _client.from('user_unlock_progress').upsert({
        'user_id': userId,
        'item_key': itemKey,
        'views_count': currentCount + 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error incrementing ad view count: $e');
    }
  }

  Future<bool> isItemUnlocked(String itemKey, int requiredViews) async {
    final views = await getAdVewCount(itemKey);
    return views >= requiredViews;
  }
}
