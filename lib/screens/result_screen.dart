import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/quiz_provider.dart';
import 'home_screen.dart';
import 'weakness_screen.dart';
import '../providers/progress_provider.dart';

class ResultScreen extends ConsumerWidget {
  final int score;
  final int totalQuestions;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = (score / totalQuestions) * 100;
    final isPass = percentage >= 60;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isPass ? AppTheme.navy : const Color(0xFF4A1414),
              isPass ? const Color(0xFF2C3E50) : const Color(0xFF2D0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              children: [
                // Header Icon
                _buildHeaderIcon(isPass),
                const SizedBox(height: 20),
                Text(
                  isPass ? '素晴らしい成績！' : '次に期待しています！',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPass ? '合格圏内に到達しました' : '合格まであと少しです',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const Spacer(),

                // Result Card
                _buildResultCard(percentage),

                const Spacer(),

                // Action Buttons
                Column(
                  children: [
                    if (!isPass || score < totalQuestions)
                      _buildActionButton(
                        context,
                        '間違えた問題を復習する',
                        Icons.history_edu,
                        Colors.amber[800]!,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const WeaknessScreen()),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      'ホームに戻る',
                      Icons.home,
                      AppTheme.mintGreen,
                      () {
                        ref.invalidate(quizProvider);
                        ref.invalidate(progressProvider);
                        ref.invalidate(quizHistoryProvider);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      isPrimary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(bool isPass) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isPass ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
        size: 80,
        color: isPass ? Colors.amber : Colors.white,
      ),
    );
  }

  Widget _buildResultCard(double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 14,
                  backgroundColor: Colors.grey.shade100,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 60 ? AppTheme.navy : AppTheme.errorRed,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score / $totalQuestions',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Text(
                    'Correct',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '正答率: ${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap,
      {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white.withOpacity(0.1),
          foregroundColor: isPrimary ? AppTheme.navy : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Colors.white30),
          ),
          elevation: isPrimary ? 4 : 0,
        ),
      ),
    );
  }
}
