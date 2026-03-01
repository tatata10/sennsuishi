import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import '../services/question_loader.dart'; // Added import

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sensuishi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        category TEXT,
        text TEXT,
        options TEXT,
        correct_answer_index INTEGER,
        explanation TEXT,
        image_url TEXT,
        exam_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT,
        category TEXT,
        is_correct INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_favorites (
        question_id TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_questions INTEGER,
        score INTEGER,
        category TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_unlock_progress (
        item_key TEXT PRIMARY KEY,
        views_count INTEGER,
        updated_at TEXT
      )
    ''');
  }

  // --- Questions ---

  Future<void> insertQuestions(List<Question> questions) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var q in questions) {
      batch.insert(
        'questions',
        {
          'id': q.id,
          'category': q.category,
          'text': q.question,
          'options': jsonEncode(q.options),
          'correct_answer_index': q.answerIndex,
          'explanation': q.explanation,
          'image_url': q.imageUrl,
          'exam_id': q.id.split('_').first,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Question>> getQuestions() async {
    final db = await instance.database;
    final result = await db.query('questions');
    return result.map((json) => _questionFromMap(json)).toList();
  }

  Future<List<Question>> getQuestionsByYear(String examId) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'id LIKE ?',
      whereArgs: ['${examId}_%'],
    );
    return result.map((json) => _questionFromMap(json)).toList();
  }

  Future<List<Question>> getQuestionsByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'category = ?',
      whereArgs: [category],
    );
    return result.map((json) => _questionFromMap(json)).toList();
  }

  Question _questionFromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      category: map['category'] as String,
      question: map['text'] as String,
      options: List<String>.from(jsonDecode(map['options'] as String)),
      answerIndex: map['correct_answer_index'] as int,
      explanation: map['explanation'] as String,
      imageUrl: map['image_url'] as String?,
    );
  }

  // --- Favorites ---

  Future<bool> isFavorite(String questionId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_favorites',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
    return result.isNotEmpty;
  }

  Future<void> toggleFavorite(String questionId, bool isFavorite) async {
    final db = await instance.database;
    if (isFavorite) {
      await db.insert(
        'user_favorites',
        {'question_id': questionId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        'user_favorites',
        where: 'question_id = ?',
        whereArgs: [questionId],
      );
    }
  }

  Future<List<Question>> getFavoriteQuestions() async {
    final db = await instance.database;
    final favs = await db.query('user_favorites');
    final ids = favs.map((f) => f['question_id'] as String).toList();
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final result = await db.query(
      'questions',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return result.map((json) => _questionFromMap(json)).toList();
  }

  // --- Progress & History ---

  Future<void> saveAnswer({
    required String questionId,
    required String category,
    required bool isCorrect,
  }) async {
    final db = await instance.database;
    await db.insert('user_progress', {
      'question_id': questionId,
      'category': category,
      'is_correct': isCorrect ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveQuizResult({
    required int totalQuestions,
    required int score,
    required String category,
  }) async {
    final db = await instance.database;
    await db.insert('quiz_history', {
      'total_questions': totalQuestions,
      'score': score,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    final db = await instance.database;
    return await db.query('quiz_history', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getCategoryAnalysis() async {
    final db = await instance.database;
    final result =
        await db.query('user_progress', columns: ['category', 'is_correct']);

    final Map<String, Map<String, int>> stats = {};

    for (var item in result) {
      final category = item['category'] as String? ?? 'その他';
      final isCorrect = (item['is_correct'] as int) == 1;

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
  }

  Future<List<Question>> getWeakQuestions() async {
    final db = await instance.database;
    final result = await db.query(
      'user_progress',
      columns: ['question_id'],
      where: 'is_correct = 0',
      groupBy: 'question_id',
    );

    final ids = result.map((f) => f['question_id'] as String).toList();
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final questionsResult = await db.query(
      'questions',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return questionsResult.map((json) => _questionFromMap(json)).toList();
  }

  Future<Map<String, int>> getWeaknessStats() async {
    final db = await instance.database;
    final result = await db.query(
      'user_progress',
      columns: ['category'],
      where: 'is_correct = 0',
    );

    final Map<String, int> stats = {};
    for (var item in result) {
      final category = item['category'] as String? ?? 'その他';
      stats[category] = (stats[category] ?? 0) + 1;
    }
    return stats;
  }

  Future<int> calculateStreak() async {
    final db = await instance.database;
    final result = await db.query(
      'quiz_history',
      columns: ['created_at'],
      orderBy: 'created_at DESC',
    );

    if (result.isEmpty) return 0;

    final Set<String> uniqueDays = result
        .map((row) => (row['created_at'] as String).substring(0, 10))
        .toSet();

    if (uniqueDays.isEmpty) return 0;

    final List<DateTime> sortedDays = uniqueDays
        .map((day) => DateTime.parse(day))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // もし最後に学習したのが今日でも昨日でもないなら、ストリークは0（または最後に学習した日が基準なら1だが、継続中としては途切れている）
    if (sortedDays.first.isBefore(yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < sortedDays.length - 1; i++) {
      final current = sortedDays[i];
      final next = sortedDays[i + 1];

      if (current.subtract(const Duration(days: 1)).isAtSameMomentAs(next)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // --- Rewards & Unlocks ---

  Future<int> getAdVewCount(String itemKey) async {
    final db = await instance.database;
    final result = await db.query(
      'user_unlock_progress',
      where: 'item_key = ?',
      whereArgs: [itemKey],
    );
    if (result.isEmpty) return 0;
    return result.first['views_count'] as int? ?? 0;
  }

  Future<void> incrementAdViewCount(String itemKey) async {
    final db = await instance.database;
    final currentCount = await getAdVewCount(itemKey);
    await db.insert(
      'user_unlock_progress',
      {
        'item_key': itemKey,
        'views_count': currentCount + 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isItemUnlocked(String itemKey, int requiredViews) async {
    final views = await getAdVewCount(itemKey);
    return views >= requiredViews;
  }

  Future<void> seedDatabase() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM questions'));
    if (count != null && count > 0) return;

    final years = await QuestionLoader.getAvailableYears();
    for (var year in years) {
      final questions = await QuestionLoader.loadQuestionsByYear(year);
      await insertQuestions(questions);
    }
  }

  Future<void> resetUserData() async {
    final db = await instance.database;
    await db.delete('user_progress');
    await db.delete('user_favorites');
    await db.delete('quiz_history');
    await db.delete('user_unlock_progress');
  }
}
