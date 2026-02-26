import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/local_database_service.dart';
import '../models/question_model.dart';
import 'mock_exam_screen.dart';

class MockExamSetupScreen extends StatefulWidget {
  const MockExamSetupScreen({super.key});

  @override
  State<MockExamSetupScreen> createState() => _MockExamSetupScreenState();
}

class _MockExamSetupScreenState extends State<MockExamSetupScreen> {
  int _selectedTimeLimitMinutes = 60;
  int _selectedQuestionCount = 40;
  bool _isLoading = false;

  final List<int> _timeLimits = [30, 45, 60, 90];
  final List<int> _questionCounts = [10, 20, 40];

  Future<void> _startExam() async {
    setState(() => _isLoading = true);
    try {
      // ローカルDBから全問ランダムで取得
      List<Question> questions =
          await LocalDatabaseService.instance.getQuestions();

      if (questions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('問題の読み込みに失敗しました')),
        );
        return;
      }

      // シャッフルして指定問題数だけ使う
      questions.shuffle();
      if (questions.length > _selectedQuestionCount) {
        questions = questions.sublist(0, _selectedQuestionCount);
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MockExamScreen(
            questions: questions,
            title: '模擬試験（$_selectedQuestionCount問・$_selectedTimeLimitMinutes分）',
            timeLimitSeconds: _selectedTimeLimitMinutes * 60,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('力試しモード'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーカード
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navy, Color(0xFF1a5276)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.casino, color: Colors.white, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    '力試しモード',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '全問題からランダムに出題！\n分野を越えた総合力をテスト\n試験終了後に一括表示されます',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureChip(Icons.shuffle, 'ランダム出題'),
                      const SizedBox(width: 8),
                      _buildFeatureChip(Icons.timer, '時間制限あり'),
                      const SizedBox(width: 8),
                      _buildFeatureChip(Icons.bar_chart, '結果分析'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 問題数設定
            const Text(
              '問題数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _questionCounts.map((count) {
                final isSelected = _selectedQuestionCount == count;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedQuestionCount = count),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.navy : Colors.white,
                        border: Border.all(
                          color:
                              isSelected ? AppTheme.navy : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count問',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.navy,
                            ),
                          ),
                          if (count == 40)
                            Text(
                              '本番相当',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // 制限時間設定
            const Text(
              '制限時間',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeLimits.map((minutes) {
                final isSelected = _selectedTimeLimitMinutes == minutes;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedTimeLimitMinutes = minutes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.navy : Colors.white,
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.navy : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      '$minutes分',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.navy,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 設定サマリー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '1問あたり約${(_selectedTimeLimitMinutes * 60 / _selectedQuestionCount).toStringAsFixed(0)}秒。'
                      '本番試験は40問60分（1問90秒）が目安です。',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 開始ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startExam,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_circle_fill, size: 28),
                label: Text(
                  _isLoading ? '問題を読み込み中...' : '試験開始',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}
