import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web用のSQLite初期化
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    // Windows/Linux用のSQLite初期化
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: DiverPassportApp(),
    ),
  );
}

class DiverPassportApp extends StatelessWidget {
  const DiverPassportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '潜水士 合格パスポート',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
