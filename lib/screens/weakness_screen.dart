import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_questions_provider.dart';
import '../theme/app_theme.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';

class WeaknessScreen extends ConsumerWidget {
  const WeaknessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('管理・復習'),
          bottom: const TabBar(
            indicatorColor: AppTheme.mintGreen,
            tabs: [
              Tab(text: '弱点問題', icon: Icon(Icons.warning_amber_rounded)),
              Tab(text: 'お気に入り', icon: Icon(Icons.star)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _QuestionList(isWrong: true),
            _QuestionList(isWrong: false),
          ],
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            final wrongQuestionsAsync = ref.watch(wrongQuestionsProvider);
            return wrongQuestionsAsync.maybeWhen(
              data: (questions) => questions.isNotEmpty
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        ref
                            .read(quizProvider.notifier)
                            .loadQuestions(questions);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const QuizScreen(title: '弱点克服クイズ')),
                        );
                      },
                      backgroundColor: AppTheme.errorRed,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('弱点克服クイズ開始'),
                    )
                  : const SizedBox(),
              orElse: () => const SizedBox(),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionList extends ConsumerWidget {
  final bool isWrong;
  const _QuestionList({required this.isWrong});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = isWrong
        ? ref.watch(wrongQuestionsProvider)
        : ref.watch(favoriteQuestionsProvider);

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isWrong ? Icons.check_circle_outline : Icons.star_border,
                    size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isWrong ? '弱点問題はありません！' : 'お気に入りはありません',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    isWrong
                        ? '間違えた問題がここに自動的に追加され、学習をサポートします。'
                        : 'クイズ中にお気に入り登録した問題がここに表示されます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text(
                  question.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  question.category,
                  style: const TextStyle(fontSize: 12, color: AppTheme.navy),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWrong
                        ? AppTheme.errorRed.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWrong ? Icons.warning_amber_rounded : Icons.star,
                    color: isWrong ? AppTheme.errorRed : Colors.amber,
                    size: 20,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text('【正解】',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.mintGreen)),
                        const SizedBox(height: 4),
                        Text(question.options[question.answerIndex]),
                        const SizedBox(height: 12),
                        const Text('【解説】',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(question.explanation),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                if (isWrong) {
                                  ref
                                      .read(savedQuestionsProvider.notifier)
                                      .removeWrongFlag(question.id);
                                } else {
                                  ref
                                      .read(savedQuestionsProvider.notifier)
                                      .toggleFavorite(question);
                                }
                              },
                              icon: Icon(
                                  isWrong ? Icons.check : Icons.delete_outline,
                                  size: 18),
                              label: Text(isWrong ? '克服済みにする' : '解除する'),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
    );
  }
}
