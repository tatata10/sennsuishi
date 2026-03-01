import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/local_database_service.dart';
import '../services/question_loader.dart';
import '../models/question_model.dart';
import 'mock_exam_screen.dart';
import '../services/ad_helper.dart';

/// 模擬試験モード：年度を選んで過去問40問を時間制限付きで解く
class MockExamYearSetupScreen extends StatefulWidget {
  const MockExamYearSetupScreen({super.key});

  @override
  State<MockExamYearSetupScreen> createState() =>
      _MockExamYearSetupScreenState();
}

class _MockExamYearSetupScreenState extends State<MockExamYearSetupScreen> {
  List<String> _availableYears = [];
  Map<String, String> _examTitles = {};
  bool _isLoadingYears = true;
  String? _selectedYear;
  int _selectedTimeLimitMinutes = 60;
  bool _isStarting = false;

  final List<int> _timeLimits = [30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    final ids = await QuestionLoader.getAvailableYears();
    final Map<String, String> titles = {};
    for (final id in ids) {
      titles[id] = await QuestionLoader.getExamTitle(id);
    }
    if (mounted) {
      setState(() {
        _availableYears = ids;
        _examTitles = titles;
        _selectedYear = ids.isNotEmpty ? ids.first : null;
        _isLoadingYears = false;
      });
    }
  }

  Future<void> _startExam() async {
    if (_selectedYear == null) return;
    setState(() => _isStarting = true);

    try {
      List<Question> questions = [];

      // Supabaseから取得
      try {
        questions = await LocalDatabaseService.instance
            .getQuestionsByYear(_selectedYear!);
      } catch (_) {}

      // フォールバック: アセットから取得
      if (questions.isEmpty) {
        questions = await QuestionLoader.loadQuestionsByYear(_selectedYear!);
      }

      if (questions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('問題の読み込みに失敗しました')),
        );
        return;
      }

      final title = _examTitles[_selectedYear!] ?? '模擬試験';

      if (!mounted) return;

      // 広告を表示してから遷移
      AdHelper.showInterstitialAd(onAdClosed: () {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MockExamScreen(
              questions: questions,
              title: '模擬試験 - $title',
              timeLimitSeconds: _selectedTimeLimitMinutes * 60,
            ),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模擬試験')),
      body: _isLoadingYears
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
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
                        const Icon(Icons.assignment_turned_in,
                            color: Colors.white, size: 56),
                        const SizedBox(height: 12),
                        const Text('模擬試験モード',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          '年度を選んで本番形式で挑戦！\n途中に解説は表示されません',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _chip(Icons.calendar_today, '年度別出題'),
                            const SizedBox(width: 8),
                            _chip(Icons.timer, '時間制限あり'),
                            const SizedBox(width: 8),
                            _chip(Icons.bar_chart, '採点・解説'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 年度選択
                  const Text('出題年度を選択',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableYears.length,
                    itemBuilder: (context, index) {
                      final id = _availableYears[index];
                      final title = _examTitles[id] ?? '試験 $id';
                      final isSelected = _selectedYear == id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedYear = id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.navy : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.navy
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: AppTheme.mintGreen, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // 制限時間
                  const Text('制限時間',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy)),
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
                              color: isSelected
                                  ? AppTheme.navy
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$minutes分',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : AppTheme.navy,
                                ),
                              ),
                              if (minutes == 60)
                                Text(
                                  '本番相当',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // 開始ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isStarting || _selectedYear == null
                          ? null
                          : _startExam,
                      icon: _isStarting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_circle_fill, size: 28),
                      label: Text(
                        _isStarting ? '問題を読み込み中...' : '試験開始',
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

  Widget _chip(IconData icon, String label) {
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
