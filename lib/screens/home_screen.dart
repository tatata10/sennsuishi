import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/home_menu_button.dart';
import '../widgets/progress_circular.dart';
import 'weakness_screen.dart';
import 'formula_screen.dart';
import 'year_selection_screen.dart';
import 'category_selection_screen.dart';
import 'history_screen.dart';
import 'mypage_screen.dart';
import 'analysis_screen.dart';
import '../providers/progress_provider.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      _buildHomeContent(context, ref),
      const HistoryScreen(),
      const MyPageScreen(),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '学習履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
        selectedItemColor: AppTheme.navy,
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('潜水士 合格パスポート'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(progressProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    progressAsync.when(
                      data: (progress) =>
                          ProgressCircular(percentage: progress),
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) =>
                          const ProgressCircular(percentage: 0),
                    ),
                    const SizedBox(height: 10),
                    progressAsync.when(
                      data: (progress) => Text(
                        progress < 0.5 ? 'まずまずの滑り出しです！' : '合格まであと一歩です！',
                        style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      loading: () => const SizedBox(),
                      error: (err, stack) => const SizedBox(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'メインメニュー',
                style: AppTheme.theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    HomeMenuButton(
                      title: '年度別 過去問',
                      icon: Icons.calendar_today,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const YearSelectionScreen()),
                        );
                      },
                    ),
                    HomeMenuButton(
                      title: '分野別 対策',
                      icon: Icons.category,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CategorySelectionScreen()),
                        );
                      },
                    ),
                    HomeMenuButton(
                      title: '苦手分析',
                      icon: Icons.analytics_outlined,
                      color: AppTheme.mintGreen,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const AnalysisScreen()),
                        );
                      },
                    ),
                    HomeMenuButton(
                      title: '弱点克服・保存',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.errorRed,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const WeaknessScreen()),
                        );
                      },
                    ),
                    HomeMenuButton(
                      title: '重要公式集',
                      icon: Icons.functions,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const FormulaScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
