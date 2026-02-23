# 潜水士 合格パスポート

国家資格「潜水士」の学習用アプリケーションです。

## セットアップ手順

このプロジェクトはファイル構造のみ生成されています。実行するには以下の手順を行ってください。

1. **プラットフォームフォルダの生成**
   Flutter SDKがインストールされている環境で、以下のコマンドを実行してAndroid/iOS/Web用のプロジェクトファイルを生成してください。
   ```bash
   flutter create . --project-name=sensuishi_app
   ```
   ※ 既存の `lib/` や `pubspec.yaml` は上書きされません（衝突時は確認されます）。

2. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

3. **アプリの実行**
   ```bash
   flutter run
   ```

## 機能概要

- **ホーム画面**: 学習進捗の可視化、主要機能へのアクセス
- **クイズ機能**: 分野別・年度別学習
- **データ管理**: SQLiteによるお気に入り・弱点保存

## 技術スタック
- Flutter
- Riverpod (State Management)
- SQLite (Local DB)
- FL Chart (Graphs)
