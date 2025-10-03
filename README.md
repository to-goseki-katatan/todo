# TODOアプリ（Flutter版）

## 概要
- Ubuntu/Linux向けウィジェット風TODOアプリ
- Flutterデスクトップ対応
- 「緊急」「重要」「通常」カテゴリ管理
- タスク追加・削除・並び替え・完了状態管理
- SQLiteによるローカル永続化

## 主な機能
- タスクの追加・削除・編集・完了状態切替
- カテゴリ管理（スライダー・左右キーで変更）
- 並び替え（ドラッグ＆ドロップ）
- 永続化（PC再起動後もデータ保持）

## データ保存場所
- `~/.local/share/<appname>/`（例: `~/.local/share/todo-widget/todo.db`）

## 使用方法
1. タスク内容を入力し、Enterキーまたは追加ボタンで追加
2. 入力欄左右キーでカテゴリ変更
3. チェックボックスで完了状態切替
4. 削除ボタンでタスク削除
5. リストをドラッグして並び替え

## 設計資料
- `doc/design.md`：設計方針・DB構造・機能シーケンス
- `doc/func_spec.md`：機能仕様・UI構成・データ構造

## 開発者向けガイド

### プロジェクトディレクトリ構成（例）

```
todo/
├── todo_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── db_helper.dart
│   │   └── ...
│   ├── pubspec.yaml
│   └── ...
├── doc/
│   ├── design.md
│   ├── func_spec.md
│   └── implementation_tasks.md
└── README.md
```

### 開発環境セットアップ

1. Flutter/Dart SDKインストール
   - https://docs.flutter.dev/get-started/install
2. 必要パッケージインストール
   - `cd todo_app`
   - `flutter pub get`
3. Linuxデスクトップでの実行
   - `flutter run -d linux`
4. DB初期化はアプリ起動時に自動実行
5. 依存パッケージ例
   - `sqflite`（SQLite操作）
   - `window_manager`（ウィンドウ制御）

### 開発Tips
- DB構造やUI仕様は `doc/` 以下の設計資料を参照
- 変更・拡張時は設計資料も随時更新

---

ご不明点・追加要望は `doc/` 以下の資料やコメント欄をご参照ください。


## ライセンス

このプロジェクトは Apache License Version 2.0 で公開されています。
詳しくは LICENSE ファイルをご参照ください。