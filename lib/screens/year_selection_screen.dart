import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/question_loader.dart';
import '../services/local_database_service.dart';
import '../services/rewarded_ad_manager.dart';
import '../models/question_model.dart';
import '../providers/unlock_provider.dart';
import '../providers/progress_provider.dart';
import 'quiz_screen.dart';

class YearSelectionScreen extends ConsumerStatefulWidget {
  const YearSelectionScreen({super.key});

  @override
  ConsumerState<YearSelectionScreen> createState() =>
      _YearSelectionScreenState();
}

class _YearSelectionScreenState extends ConsumerState<YearSelectionScreen> {
  final _adManager = RewardedAdManager();
  List<String> availableYears = [];
  Map<String, String> examTitles = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableYears();
  }

  Future<void> _loadAvailableYears() async {
    final ids = await QuestionLoader.getAvailableYears();
    final Map<String, String> titles = {};
    for (final id in ids) {
      titles[id] = await QuestionLoader.getExamTitle(id);
    }
    if (mounted) {
      setState(() {
        availableYears = ids;
        examTitles = titles;
        isLoading = false;
      });
    }
  }

  Future<void> _onYearTap(
      String id, String displayTitle, bool isUnlocked) async {
    if (!isUnlocked) {
      _showUnlockDialog(id, displayTitle);
      return;
    }

    List<Question> questions = [];
    try {
      questions = await LocalDatabaseService.instance.getQuestionsByYear(id);
    } catch (e) {
      debugPrint('Cloud loading failed, falling back to asset: $e');
    }
    if (questions.isEmpty) {
      questions = await QuestionLoader.loadQuestionsByYear(id);
    }

    if (questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('問題の読み込みに失敗しました')),
      );
      return;
    }

    // 常にシャッフルして出題
    questions.shuffle();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          title: displayTitle,
        ),
      ),
    );
  }

  void _showUnlockDialog(String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('過去問を解放'),
        content: Text('動画広告を1回視聴して「$title」を解放しますか？\n（一度解放するとずっと利用できます）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startAd(id, title);
            },
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('視聴して解放'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _startAd(String id, String title) {
    _adManager.loadAd(
      onUserEarnedReward: (reward) async {
        // 視聴完了
        await LocalDatabaseService.instance.incrementAdViewCount('year_$id');
        // プロバイダーを更新してUIに反映
        ref.read(dbUpdateCounterProvider.notifier).state++;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$title」を解放しました！')),
        );

        // 少し待ってから画面遷移（DBの反映を確実にするため）
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        _onYearTap(id, title, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('年度別 過去問'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : availableYears.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '過去問データがありません',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableYears.length,
                  itemBuilder: (context, index) {
                    final id = availableYears[index];
                    final displayTitle = examTitles[id] ?? '試験 $id';

                    return Consumer(builder: (context, ref, child) {
                      // 令和6年(2581)は無料で解放、それ以外は1回視聴が必要
                      final requiredViews = (id == '2581') ? 0 : 1;
                      final unlockAsync = ref.watch(isUnlockedProvider(
                          (itemKey: 'year_$id', requiredViews: requiredViews)));
                      final isUnlocked = unlockAsync.value ?? (id == '2581');

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _onYearTap(id, displayTitle, isUnlocked),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? AppTheme.navy.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isUnlocked
                                        ? Icons.calendar_today
                                        : Icons.lock,
                                    color: isUnlocked
                                        ? AppTheme.navy
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayTitle,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked
                                              ? AppTheme.navy
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isUnlocked ? '潜水士試験 過去問' : '広告視聴で解放',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isUnlocked
                                      ? Icons.arrow_forward_ios
                                      : Icons.play_circle_outline,
                                  color:
                                      isUnlocked ? AppTheme.navy : Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
    );
  }
}
