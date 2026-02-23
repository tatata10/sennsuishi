import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
import '../widgets/quiz_option_button.dart';
import '../theme/app_theme.dart';
import '../providers/saved_questions_provider.dart';
import '../data/mock_data.dart'; // Ensure mock data is loaded
import 'result_screen.dart';

import '../models/question_model.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final List<Question>? questions;
  final String? title;

  const QuizScreen({super.key, this.questions, this.title});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  void initState() {
    super.initState();
    // Load questions from parameters or use mock data
    Future.microtask(() {
      if (widget.questions != null && widget.questions!.isNotEmpty) {
        ref.read(quizProvider.notifier).loadQuestions(widget.questions!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(quizProvider, (previous, next) {
      if (next.isCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              score: next.score,
              totalQuestions: next.questions.length,
            ),
          ),
        );
      }
    });

    final quizState = ref.watch(quizProvider);

    if (quizState.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = quizState.questions[quizState.currentIndex];
    final isAnswered = quizState.isAnswered;
    final isCorrect =
        isAnswered && quizState.selectedOptionIndex == question.answerIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? question.category),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isFavAsync = ref.watch(isFavoriteProvider(question.id));
              return IconButton(
                icon: Icon(
                  isFavAsync.maybeWhen(
                    data: (isFav) =>
                        isFav ? Icons.bookmark : Icons.bookmark_border,
                    orElse: () => Icons.bookmark_border,
                  ),
                  color: isFavAsync.maybeWhen(
                    data: (isFav) => isFav ? Colors.amber : null,
                    orElse: () => null,
                  ),
                ),
                onPressed: () {
                  final currentQuestion =
                      quizState.questions[quizState.currentIndex];
                  ref
                      .read(savedQuestionsProvider.notifier)
                      .toggleFavorite(currentQuestion);

                  final isCurrentlyFav = isFavAsync.asData?.value ?? false;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          isCurrentlyFav ? 'お気に入りから削除しました' : 'お気に入りに保存しました'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            LinearProgressIndicator(
              value: (quizState.currentIndex + 1) / quizState.questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.mintGreen),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Q${quizState.currentIndex + 1}',
                          style: AppTheme.theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.navy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            question.category,
                            style:
                                AppTheme.theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Question Image (if any)
                    if (question.imageUrl != null &&
                        question.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          question.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.broken_image,
                                      color: Colors.grey, size: 48),
                                  SizedBox(height: 8),
                                  Text('画像が読み込めませんでした',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Question Text
                    Text(
                      question.question,
                      style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 20, // Slightly larger as requested
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Options
                    ...List.generate(question.options.length, (index) {
                      return QuizOptionButton(
                        index: index,
                        text: question.options[index],
                        isSelected: quizState.selectedOptionIndex == index,
                        isCorrect: index == question.answerIndex,
                        isAnswered: isAnswered,
                        onTap: () {
                          ref.read(quizProvider.notifier).answer(index);
                        },
                      );
                    }),

                    // Explanation Section (Only visible after answering)
                    if (isAnswered) ...[
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.mintGreen.withOpacity(0.1)
                              : AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCorrect
                                ? AppTheme.mintGreen
                                : AppTheme.errorRed,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect
                                      ? AppTheme.navy
                                      : AppTheme.errorRed,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCorrect ? '正解！' : '不正解...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? AppTheme.navy
                                        : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '解説',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Space for floating button
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAnswered
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(quizProvider.notifier).nextQuestion();
              },
              backgroundColor: AppTheme.navy,
              icon: Icon(
                quizState.currentIndex == quizState.questions.length - 1
                    ? Icons.check_circle
                    : Icons.arrow_forward,
              ),
              label: Text(
                quizState.currentIndex == quizState.questions.length - 1
                    ? '結果を見る'
                    : '次の問題へ',
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
