import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/supabase_service.dart';
import 'services/ad_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // Supabaseの初期化（URLとKeyは lib/config/supabase_config.dart で設定）
  if (SupabaseConfig.url != 'YOUR_SUPABASE_URL') {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // 匿名ログインの実行（ユーザーIDを確保するため）
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
  }

  // 広告の初期化
  await AdHelper.init();

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
      title: '潜水士 合格パスポート',
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
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      // ユーザーがいない環境（初動）
      return const WelcomeScreen();
    }

    // プロフィールがあるか確認
    return FutureBuilder(
      future: SupabaseService.instance.getProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // プロフィールがあればホームへ
          return const HomeScreen();
        } else {
          // プロフィールがなければ初期設定（歓迎画面）へ
          return const WelcomeScreen();
        }
      },
    );
  }
}
