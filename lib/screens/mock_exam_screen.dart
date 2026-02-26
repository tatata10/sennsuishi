import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/local_database_service.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';

import 'mock_exam_result_screen.dart';

class MockExamScreen extends ConsumerStatefulWidget {
  final List<Question> questions;
  final String title;

  /// 試験時間（秒）。デフォルト60分 = 3600秒
  final int timeLimitSeconds;

  const MockExamScreen({
    super.key,
    required this.questions,
    this.title = '模擬試験',
    this.timeLimitSeconds = 3600,
  });

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;

  // 回答状態を保持: index -> 選んだ選択肢インデックス
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.timeLimitSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _finishExam(timeUp: true);
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerDisplay {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsRemaining < 300) return AppTheme.errorRed; // 残り5分
    if (_secondsRemaining < 600) return Colors.orange; // 残り10分
    return AppTheme.navy;
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _answers[_currentIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _finishExam({bool timeUp = false}) async {
    _timer?.cancel();

    // スコア計算
    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final answered = _answers[i];
      if (answered != null && answered == widget.questions[i].answerIndex) {
        score++;
      }
    }

    final totalAnswered = _answers.length;

    // 結果を保存
    try {
      if (totalAnswered > 0) {
        await LocalDatabaseService.instance.saveQuizResult(
          totalQuestions: widget.questions.length,
          score: score,
          category: '模擬試験',
        );
        // 各問題の回答も保存
        for (int i = 0; i < widget.questions.length; i++) {
          final answered = _answers[i];
          if (answered != null) {
            await LocalDatabaseService.instance.saveAnswer(
              questionId: widget.questions[i].id,
              category: widget.questions[i].category,
              isCorrect: answered == widget.questions[i].answerIndex,
            );
          }
        }
        ref.read(dbUpdateCounterProvider.notifier).state++;
      }
    } catch (e) {
      debugPrint('Mock exam save error: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MockExamResultScreen(
          questions: widget.questions,
          answers: _answers,
          score: score,
          timeUp: timeUp,
          timeLimitSeconds: widget.timeLimitSeconds,
          elapsedSeconds: widget.timeLimitSeconds - _secondsRemaining,
        ),
      ),
    );
  }

  void _showFinishConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('試験を終了しますか？'),
        content: Text(
          '${_answers.length} / ${widget.questions.length} 問 解答済みです。\n未解答の問題は「未回答」として扱われます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishExam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy),
            child: const Text('終了する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final selectedOption = _answers[_currentIndex];
    final answeredCount = _answers.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showFinishConfirm,
        ),
        actions: [
          // タイマー表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _timerColor.withOpacity(0.1),
                border: Border.all(color: _timerColor, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: _timerColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _timerDisplay,
                    style: TextStyle(
                      color: _timerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 全体進捗バー
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '問 ${_currentIndex + 1} / ${widget.questions.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      '解答済み: $answeredCount / ${widget.questions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / widget.questions.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.mintGreen),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // 問題本体
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリバッジ
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      question.category,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 画像
                  if (question.imageUrl != null &&
                      question.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: question.imageUrl!.startsWith('http')
                          ? Image.network(question.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox())
                          : Image.asset(question.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 問題文
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 選択肢（解説なし・正誤表示なし）
                  ...List.generate(question.options.length, (index) {
                    final isSelected = selectedOption == index;
                    return GestureDetector(
                      onTap: () => _selectOption(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.navy : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.navy
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.shade100,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ナビゲーションボタン
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex > 0 ? _prevQuestion : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('前の問題'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _currentIndex < widget.questions.length - 1
                      ? ElevatedButton.icon(
                          onPressed: _nextQuestion,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('次の問題'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _showFinishConfirm,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('試験を終了'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mintGreen,
                            foregroundColor: AppTheme.navy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
