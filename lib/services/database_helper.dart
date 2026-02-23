import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/question_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitializing = false;

  DatabaseHelper._init();

  // データベースのインスタンスを取得（多重初期化防止）
  Future<Database> get database async {
    if (_database != null) return _database!;

    // 初期化中の場合は完了を待機する仕組み
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_database != null) return _database!;
    }

    _isInitializing = true;
    try {
      _database = await _initDB('sensuishi.db');
    } catch (e) {
      debugPrint('Database initialization error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('Opening database at: $path');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createHistoryTables(db);
    }
    if (oldVersion < 3) {
      // Add category column to answered_questions if it doesn't exist
      await db.execute(
          'ALTER TABLE answered_questions ADD COLUMN category TEXT DEFAULT "その他"');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE saved_questions ADD COLUMN image_url TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE saved_questions (
        id TEXT PRIMARY KEY,
        category TEXT,
        question TEXT,
        options TEXT,
        answer_index INTEGER,
        explanation TEXT,
        image_url TEXT,
        is_wrong INTEGER,
        is_favorite INTEGER,
        timestamp INTEGER
      )
    ''');

    await _createHistoryTables(db);
  }

  Future<void> _createHistoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE quiz_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_questions INTEGER,
        score INTEGER,
        category TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE answered_questions (
        question_id TEXT PRIMARY KEY,
        category TEXT,
        is_correct INTEGER,
        timestamp INTEGER
      )
    ''');
  }

  // Save or Update a question
  Future<void> saveQuestion(Question question,
      {bool? isWrong, bool? isFavorite}) async {
    final db = await instance.database;

    // Check if it exists first to preserve existing flags if only updating one
    final existing = await db.query(
      'saved_questions',
      where: 'id = ?',
      whereArgs: [question.id],
    );

    int wrongVal = isWrong == true ? 1 : 0;
    int favVal = isFavorite == true ? 1 : 0;

    if (existing.isNotEmpty) {
      final current = existing.first;
      if (isWrong == null) wrongVal = current['is_wrong'] as int;
      if (isFavorite == null) favVal = current['is_favorite'] as int;
    }

    // Prepare map
    final map = question.toMap();
    map['is_wrong'] = wrongVal;
    map['is_favorite'] = favVal;
    map['timestamp'] = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'saved_questions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeWrongFlag(String id) async {
    final db = await instance.database;
    final existing =
        await db.query('saved_questions', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      if ((existing.first['is_favorite'] as int) == 0) {
        await db.delete('saved_questions', where: 'id = ?', whereArgs: [id]);
      } else {
        await db.update('saved_questions', {'is_wrong': 0},
            where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  Future<List<Question>> getWrongQuestions() async {
    final db = await instance.database;
    final result = await db.query(
      'saved_questions',
      where: 'is_wrong = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => Question.fromMap(json)).toList();
  }

  Future<List<Question>> getFavoriteQuestions() async {
    final db = await instance.database;
    final result = await db.query(
      'saved_questions',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => Question.fromMap(json)).toList();
  }

  Future<bool> isFavorite(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'saved_questions',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return false;
    return result.first['is_favorite'] == 1;
  }

  // --- Quiz History & Progress ---

  Future<void> saveQuizResult(int total, int score, String category) async {
    final db = await instance.database;
    await db.insert('quiz_history', {
      'total_questions': total,
      'score': score,
      'category': category,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> markQuestionAnswered(
      String questionId, String category, bool isCorrect) async {
    final db = await instance.database;
    await db.insert(
      'answered_questions',
      {
        'question_id': questionId,
        'category': category,
        'is_correct': isCorrect ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCategoryAnalysis() async {
    final db = await instance.database;
    // Get stats from answered_questions
    return await db.rawQuery('''
      SELECT 
        category, 
        COUNT(*) as total, 
        SUM(is_correct) as correct 
      FROM answered_questions 
      GROUP BY category
    ''');
  }

  Future<Map<String, int>> getWeaknessStats() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM saved_questions 
      WHERE is_wrong = 1 
      GROUP BY category
    ''');

    final Map<String, int> stats = {};
    for (var row in result) {
      stats[row['category'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<double> getOverallProgress() async {
    final db = await instance.database;

    // Count unique questions answered correctly
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM answered_questions WHERE is_correct = 1');
    final count = Sqflite.firstIntValue(result) ?? 0;

    // 全12回 * 各40問 = 480問
    const totalPossibleQuestions = 480.0;
    return (count / totalPossibleQuestions).clamp(0.0, 1.0);
  }

  Future<List<Map<String, dynamic>>> getRecentHistory() async {
    final db = await instance.database;
    return await db.query('quiz_history', orderBy: 'timestamp DESC', limit: 10);
  }

  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete('saved_questions');
    await db.delete('quiz_history');
    await db.delete('answered_questions');
  }
}
