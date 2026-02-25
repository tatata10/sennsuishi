import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/question_loader.dart';
import '../services/supabase_service.dart';
import '../models/question_model.dart';
import 'quiz_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final List<Map<String, dynamic>> categories = [
    {
      'name': '高気圧障害',
      'icon': Icons.healing,
      'color': Colors.red.shade400,
      'description': '減圧症、窒素酔い、酸素中毒など'
    },
    {
      'name': '送気・器具',
      'icon': Icons.plumbing,
      'color': Colors.blue.shade400,
      'description': '潜水器具、送気設備など'
    },
    {
      'name': '潜水業務',
      'icon': Icons.work,
      'color': Colors.green.shade400,
      'description': '潜水作業の基礎、物理法則など'
    },
    {
      'name': '法令',
      'icon': Icons.gavel,
      'color': Colors.orange.shade400,
      'description': '高気圧作業安全衛生規則など'
    },
    {
      'name': '生理',
      'icon': Icons.person,
      'color': Colors.purple.shade400,
      'description': '人体への影響、生理学など'
    },
  ];

  Future<void> _startCategoryQuiz(String categoryName) async {
    List<Question> questions = [];

    try {
      questions =
          await SupabaseService.instance.getQuestionsByCategory(categoryName);
    } catch (_) {}

    if (questions.isEmpty) {
      final availableYears = await QuestionLoader.getAvailableYears();
      List<Question> allQuestions = [];
      for (final year in availableYears) {
        allQuestions.addAll(await QuestionLoader.loadQuestionsByYear(year));
      }
      questions = QuestionLoader.filterByCategory(allQuestions, categoryName);
    }

    if (questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${categoryName}の問題が見つかりませんでした')),
      );
      return;
    }

    questions.shuffle();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions.take(10).toList(),
          title: '分野別 $categoryName',
        ),
      ),
    );
  }

  /// 全分野ごちゃまぜランダム
  Future<void> _startAllMixQuiz() async {
    List<Question> questions = [];

    try {
      questions = await SupabaseService.instance.getQuestions();
    } catch (_) {}

    if (questions.isEmpty) {
      final availableYears = await QuestionLoader.getAvailableYears();
      for (final year in availableYears) {
        questions.addAll(await QuestionLoader.loadQuestionsByYear(year));
      }
    }

    if (questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('問題の読み込みに失敗しました')),
      );
      return;
    }

    questions.shuffle();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          isInfiniteMode: true,
          title: '分野別 全分野ランダム',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分野別 対策'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 全分野ランダムカード（先頭） ───
          Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: _startAllMixQuiz,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.indigo.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shuffle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '全分野ランダム',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '終了までエンドレスに出題',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 各分野カード ───
          ...categories.map(
            (category) => Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _startCategoryQuiz(category['name'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (category['color'] as Color)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: category['color'] as Color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['name'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.navy,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
