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
    List<Question> filteredQuestions = [];

    // 1. Cloudから特定のカテゴリーの問題を直接取得
    try {
      filteredQuestions =
          await SupabaseService.instance.getQuestionsByCategory(categoryName);
    } catch (e) {
      print(
          'Cloud loading failed for category, falling back to all-asset search');
    }

    // 2. Cloudが空または失敗した場合は、ローカルの全Assetから探す（旧ロジック）
    if (filteredQuestions.isEmpty) {
      final availableYears = await QuestionLoader.getAvailableYears();
      List<Question> allQuestions = [];
      for (final year in availableYears) {
        final yearQuestions = await QuestionLoader.loadQuestionsByYear(year);
        allQuestions.addAll(yearQuestions);
      }
      filteredQuestions =
          QuestionLoader.filterByCategory(allQuestions, categoryName);
    }

    if (filteredQuestions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$categoryNameの問題が見つかりませんでした')),
      );
      return;
    }

    // ランダムに並び替えて出題（オプション）
    filteredQuestions.shuffle();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: filteredQuestions.take(10).toList(), // 10問ずつ
          title: '$categoryName 対策',
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _startCategoryQuiz(category['name']),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: category['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'],
                        color: category['color'],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['description'],
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
          );
        },
      ),
    );
  }
}
