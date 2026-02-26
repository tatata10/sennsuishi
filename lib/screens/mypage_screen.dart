import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/progress_provider.dart';
import '../services/local_database_service.dart';
import '../providers/saved_questions_provider.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.navy,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              data: (profile) => Text(
                '${profile?['nickname'] ?? '学習者'} さん',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('学習者 さん'),
            ),
            const SizedBox(height: 8),
            const Text('潜水士 合格を目指して学習中'),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildStatRow(
                        '現在の達成率',
                        progressAsync.when(
                          data: (p) => '${(p * 100).toStringAsFixed(1)}%',
                          loading: () => '...',
                          error: (_, __) => '0%',
                        ),
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      const Divider(height: 30),
                      _buildStatRow(
                        '学習記録',
                        '12日間継続中',
                        Icons.calendar_month,
                        Colors.orange,
                      ),
                      const Divider(height: 30),
                      _buildStatRow(
                        '獲得バッジ',
                        '3個',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildListTile(
                context, '学習リマインダー', Icons.notifications_none, () {}),
            _buildListTile(context, 'データのリセット', Icons.refresh, () {
              // Show confirmation dialog
              _showResetDialog(context, ref);
            }, textColor: AppTheme.errorRed),
            _buildListTile(context, 'アプリについて', Icons.info_outline, () {}),
            const SizedBox(height: 40),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy)),
      ],
    );
  }

  Widget _buildListTile(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データのリセット'),
        content: const Text('これまでの学習記録とお気に入りがすべて削除されます。本当によろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await LocalDatabaseService.instance.resetUserData();
              ref.invalidate(progressProvider);
              ref.invalidate(quizHistoryProvider);
              ref.invalidate(wrongQuestionsProvider);
              ref.invalidate(favoriteQuestionsProvider);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('すべてのデータをリセットしました')),
                );
              }
            },
            child: const Text('リセットする',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}
