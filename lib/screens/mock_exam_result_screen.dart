import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import '../providers/quiz_provider.dart';
import '../providers/progress_provider.dart';
import '../services/ad_helper.dart';

class MockExamResultScreen extends ConsumerWidget {
  final List<Question> questions;
  final Map<int, int> answers;
  final int score;
  final bool timeUp;
  final int timeLimitSeconds;
  final int elapsedSeconds;

  const MockExamResultScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.score,
    required this.timeUp,
    required this.timeLimitSeconds,
    required this.elapsedSeconds,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m分${s.toString().padLeft(2, '0')}秒';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = questions.length;
    final percentage = total > 0 ? (score / total * 100) : 0.0;
    final isPass = percentage >= 60;
    final unanswered = total - answers.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPass
                ? [AppTheme.navy, const Color(0xFF1a3a5c)]
                : [const Color(0xFF4A1414), const Color(0xFF2D0A0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (timeUp)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_off,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('時間切れ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (timeUp) const SizedBox(height: 12),
                    Icon(
                      isPass
                          ? Icons.emoji_events
                          : Icons.sentiment_dissatisfied,
                      size: 70,
                      color: isPass ? Colors.amber : Colors.white60,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPass ? '合格圏内！' : 'もう一度挑戦！',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // スコアカード
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBlock('正解', '$score問', Colors.green),
                      _buildStatBlock(
                          '正答率',
                          '${percentage.toStringAsFixed(1)}%',
                          isPass ? AppTheme.navy : AppTheme.errorRed),
                      _buildStatBlock('未解答', '$unanswered問', Colors.grey),
                      _buildStatBlock(
                          '経過時間', _formatDuration(elapsedSeconds), Colors.blue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 解説リスト
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.list_alt, color: AppTheme.navy),
                            SizedBox(width: 8),
                            Text(
                              '問題別 正誤・解説',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: questions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final q = questions[i];
                            final userAnswer = answers[i];
                            final isCorrect = userAnswer != null &&
                                userAnswer == q.answerIndex;
                            final isUnanswered = userAnswer == null;

                            return _ResultTile(
                              index: i,
                              question: q,
                              userAnswer: userAnswer,
                              isCorrect: isCorrect,
                              isUnanswered: isUnanswered,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ボタン
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(quizProvider);
                      ref.invalidate(progressProvider);
                      ref.invalidate(quizHistoryProvider);

                      // 広告を表示してからホームに戻る
                      AdHelper.showInterstitialAd(onAdClosed: () {
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      });
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('ホームに戻る'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ResultTile extends StatefulWidget {
  final int index;
  final Question question;
  final int? userAnswer;
  final bool isCorrect;
  final bool isUnanswered;

  const _ResultTile({
    required this.index,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.isUnanswered,
  });

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    Color statusColor = widget.isUnanswered
        ? Colors.grey
        : widget.isCorrect
            ? Colors.green
            : AppTheme.errorRed;
    String statusLabel = widget.isUnanswered
        ? '未'
        : widget.isCorrect
            ? '○'
            : '✕';

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 問題番号 + 正誤
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '問 ${widget.index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        widget.question.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ユーザーの回答
                    if (!widget.isUnanswered) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('あなたの回答: ',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          Expanded(
                            child: Text(
                              widget.question.options[widget.userAnswer!],
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isCorrect
                                    ? Colors.green
                                    : AppTheme.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // 正解
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('正解: ',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        Expanded(
                          child: Text(
                            widget
                                .question.options[widget.question.answerIndex],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 解説
                    if (widget.question.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.question.explanation,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
