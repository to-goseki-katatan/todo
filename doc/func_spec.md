# UbuntuネイティブTODOアプリ仕様書（Flutter版）

## 🎯 基本方針
- 完全オフライン動作（オンライン機能なし）
- 軽量・高速・ミニマル設計
- 永続化されたローカルデータ
- ウィジェット風のUI（ウィンドウ枠なし、クロスプラットフォーム対応）

---

## ✅ 機能一覧

- TODOタスクを箇条書きで表示
- 各行にチェックボックスを表示
- チェックを入れると完了状態（打ち消し線やグレーアウト）になる
- 「緊急」「重要」「通常」の3カテゴリに分類可能
- タスクはドラッグ＆ドロップで順序変更可能
- タスクは行単位で削除可能
- PC起動時に自動的にアプリが立ち上がる（Linuxデスクトップ自動起動対応）
- ウィンドウ枠を持たないウィジェット風表示
- データは永続化され、PC再起動後も保持される

---

## 🧱 技術スタック（Flutter版）

| 項目         | 候補技術                         |
|--------------|----------------------------------|
| 言語         | Dart（Flutter）                  |
| UI           | Flutter（Material/自作Widget）   |
| データ保存   | SQLite（sqfliteパッケージ）      |
| 自動起動     | Linux: `.desktop`ファイル生成・配置 |
| ウィジェット | `WindowBorder.none`/`WindowManager`等で枠なし表示 |

---

## 🗂 データ構造（SQLite例）

```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  category TEXT CHECK(category IN ('緊急','重要','通常')),
  completed BOOLEAN DEFAULT 0,
  position INTEGER
);
```

## 🎨 UI構成案

- タスク一覧：縦に並ぶリスト（チェックボックス＋テキスト＋削除ボタン）
- 並び替え：リスト全体がドラッグ可能（ReorderableListView等を利用）
- 新規追加：下部に入力欄＋追加ボタン
- ウィンドウ：枠なし、透明度調整可能、常に前面表示オプション（WindowManagerパッケージ等）

## 📌 備考

- オフライン動作を前提とするため、外部APIやクラウド連携は不要
- 永続化のため、SQLiteファイルはユーザーディレクトリに保存
- 自動起動はUbuntuの「Startup Applications」機能を利用（.desktopファイル生成）
- Flutterのクロスプラットフォーム性を活かし、他OS対応も容易


