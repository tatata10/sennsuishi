import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/progress_provider.dart';
import '../providers/analysis_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(quizHistoryProvider);
    final trendAsync = ref.watch(recentScoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習履歴'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.navy,
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return _buildEmptyState();
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(history),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      '正答率の推移',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  _buildTrendChart(trendAsync),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                    child: Text(
                      '最近の実施結果',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(history[index]);
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'まだ学習履歴がありません',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('クイズを解くとここに履歴が表示されます'),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<Map<String, dynamic>> history) {
    int total = history.length;
    double avg = total == 0
        ? 0
        : history
                .map((e) => (e['score'] as int) / (e['total_questions'] as int))
                .reduce((a, b) => a + b) /
            total;
    int passCount = history
        .where(
            (e) => (e['score'] as int) / (e['total_questions'] as int) >= 0.6)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navy.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('実施回数', '$total', Icons.assignment_outlined),
            _buildStatItem(
                '平均正解率', '${(avg * 100).toInt()}%', Icons.analytics_outlined),
            _buildStatItem('合格回数', '$passCount', Icons.check_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.mintGreen, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildTrendChart(AsyncValue<List<double>> trendAsync) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: trendAsync.when(
        data: (scores) {
          if (scores.isEmpty) return const Center(child: Text('データなし'));
          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: scores
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: AppTheme.navy,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.navy.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final total = item['total_questions'] as int;
    final score = item['score'] as int;
    final category = item['category'] as String;
    final timestamp = item['timestamp'] as int;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final dateStr = DateFormat('MM/dd HH:mm').format(date);
    final percentage = (score / total);
    final isPass = percentage >= 0.6;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (isPass ? AppTheme.mintGreen : AppTheme.errorRed)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                color: isPass ? AppTheme.navy : AppTheme.errorRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.navy),
        ),
        subtitle: Text(dateStr,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$score / $total',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy),
            ),
            Text(
              isPass ? '合格圏内' : '努力が必要',
              style: TextStyle(
                fontSize: 11,
                color: isPass ? AppTheme.navy : AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
