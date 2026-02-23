import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class QuestionLoader {
  /// JSONファイルから問題を読み込む
  static Future<List<Question>> loadQuestionsFromAsset(
      String assetPath, String examId) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final List<dynamic> questionsJson =
          jsonData['questions'] as List<dynamic>;

      return questionsJson
          .map((json) =>
              Question.fromJson(json as Map<String, dynamic>, examId: examId))
          .toList();
    } catch (e) {
      print('Error loading questions from $assetPath: $e');
      return [];
    }
  }

  /// 年度別の問題を読み込む
  static Future<List<Question>> loadQuestionsByYear(String id) async {
    final assetPath = 'assets/questions/scraped_$id.json';
    return loadQuestionsFromAsset(assetPath, id);
  }

  /// 利用可能な試験IDのリストを取得
  static Future<List<String>> getAvailableYears() async {
    // スクレイピングで取得した全12回分の試験ID
    return [
      '2581',
      '2580',
      '2579',
      '2578',
      '2577',
      '2576',
      '2575',
      '2574',
      '2573',
      '2572',
      '2571',
      '2570'
    ];
  }

  /// 試験のタイトルを取得
  static Future<String> getExamTitle(String id) async {
    try {
      final assetPath = 'assets/questions/scraped_$id.json';
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return jsonData['title'] as String? ?? '潜水士試験 $id';
    } catch (e) {
      return '潜水士試験 $id';
    }
  }

  /// カテゴリー別に問題をフィルタリング
  static List<Question> filterByCategory(
    List<Question> questions,
    String category,
  ) {
    return questions.where((q) => q.category == category).toList();
  }

  /// すべてのカテゴリーを取得
  static Set<String> getCategories(List<Question> questions) {
    return questions.map((q) => q.category).toSet();
  }
}
