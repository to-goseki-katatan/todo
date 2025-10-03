-- tasksテーブル定義
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  category TEXT CHECK(category IN ('緊急','重要','通常')),
  completed BOOLEAN DEFAULT 0,
  position INTEGER
);
