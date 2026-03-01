import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/local_database_service.dart';
import 'services/ad_helper.dart';
import 'theme/app_theme.dart';
import 'providers/progress_provider.dart';

void main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // 広告の初期化
  await AdHelper.init();

  // ローカルDBの初期化とデータ投入
  await LocalDatabaseService.instance.seedDatabase();

  runApp(
    const ProviderScope(
      child: DiverPassportApp(),
    ),
  );
}

class DiverPassportApp extends ConsumerWidget {
  const DiverPassportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '潜水士　合格ラボ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // プロフィール状態を監視（Supabase/Local両方をチェックするように provider で実装済み）
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile != null) {
          // プロフィールがあればホームへ
          return const HomeScreen();
        } else {
          // プロフィールがなければ初期設定（歓迎画面）へ
          // ただし、Supabaseが設定されていない「完全ローカルモード」ならHomeScreenへ直行する選択肢もあるが、
          // ユーザー要望に合わせて、最初は名前入力を促すフローを維持する。
          return const WelcomeScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) {
        // エラー時は安全のためにホームへ（またはログ画面）
        debugPrint('AuthGate Error: $err');
        return const HomeScreen();
      },
    );
  }
}
