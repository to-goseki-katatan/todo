import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';

// モデルクラス（カテゴリ情報をItemEntryから除去）
abstract class ListEntry {}
class GroupHeader extends ListEntry {
  final String groupName;
  GroupHeader(this.groupName);
}
class ItemEntry extends ListEntry {
  final String id;
  final String name;
  bool completed;
  ItemEntry({required this.id, required this.name, this.completed = false});
}

class Entry {
  String id;
  String type; // 'header' or 'item'
  String title;
  bool completed;
  int position;

  Entry({
    required this.id,
    required this.type,
    required this.title,
    this.completed = false,
    required this.position,
  });

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'].toString(),
      type: map['type'],
      title: map['title'] ?? '',
      completed: map['completed'] == 1,
      position: map['position'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'completed': completed ? 1 : 0,
      'position': position,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(400, 400));
  await windowManager.setSize(const Size(500, 600)); // デフォルトサイズ
  await windowManager.center();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Widget',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'TODOリスト'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ...existing code...
  // KeyEventでカテゴリ変更
  void _handleTextFieldKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          if (_categoryIndex > 0) _categoryIndex--;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          if (_categoryIndex < _categories.length - 1) _categoryIndex++;
        });
      }
    }
  }
  Widget _buildEmergencyHeader() {
    return Padding(
      key: ValueKey('header_緊急'),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text('緊急', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
  List<Entry> _entries = [];
  bool _loading = true;
  List<ListEntry> displayList = [];

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  int _categoryIndex = 0; // 0:通常, 1:重要, 2:緊急
  final List<String> _categories = ['通常', '重要', '緊急'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final db = DBHelper();
    final data = await db.getEntries();
    setState(() {
      _entries = data.map((e) => Entry.fromMap(e)).toList();
      _loading = false;
      displayList.clear();
      final sortedEntries = [..._entries]..sort((a, b) => a.position.compareTo(b.position));
      for (final entry in sortedEntries) {
        if (entry.type == 'header' && entry.title != '緊急') {
          displayList.add(GroupHeader(entry.title));
        } else if (entry.type == 'item') {
          displayList.add(ItemEntry(id: entry.id, name: entry.title, completed: entry.completed));
        }
      }
    });
  }

  // タスク追加時は選択カテゴリの見出し直下に挿入
  Future<void> _addTask() async {
  await _loadEntries(); // 追加前にDBとdisplayListを同期
  final db = DBHelper();
  final headerId = _categories[_categoryIndex];
    // 1. headerのposition取得
    int headerIndex = headerId == '緊急' ? -1 : _entries.indexWhere((e) => e.type == 'header' && e.title == headerId);
    final headerPos = headerIndex == -1 ? -1 :_entries[headerIndex].position;
    // 2. header.positionより大きい全レコードのpositionを+1
    for (final entry in _entries) {
      if (entry.position > headerPos) {
        entry.position += 1;
        await db.updateEntry(entry.id, entry.toMap());
      }
    }
    // 3. 新itemをheader.position+1で追加
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    int insertPos = headerId == '緊急' ? 0 : headerPos + 1;
    final newEntry = Entry(id: newId, type: 'item', title: _titleController.text, completed: false, position: insertPos);
    await db.insertEntry(newEntry.toMap());
    _titleController.clear();
    setState(() {
      int headerIdx = displayList.indexWhere((e) => e is GroupHeader && e.groupName == headerId);
      if (headerIdx != -1) {
        displayList.insert(headerIdx + 1, ItemEntry(id: newEntry.id, name: newEntry.title, completed: false));
      } else {
        displayList.add(ItemEntry(id: newEntry.id, name: newEntry.title, completed: false));
      }
    });
    await _loadEntries();
  }

  Future<void> _deleteTask(String id) async {
    final db = DBHelper();
    await db.deleteEntry(id);
    setState(() {
      displayList.removeWhere((e) => e is ItemEntry && e.id == id);
    });
    await _loadEntries();
  }

  Future<void> _toggleComplete(Entry entry) async {
    // displayListのみ即時更新
    setState(() {
      for (var e in displayList) {
        if (e is ItemEntry && e.id == entry.id) {
          e.completed = !e.completed;
        }
      }
    });
    // DBは非同期で更新
    final db = DBHelper();
    await db.updateEntry(entry.id, {
      'completed': entry.completed ? 0 : 1,
    });
  }

  // getDisplayList()もカテゴリ情報を使わず、DBからposition順にGroupHeaderとItemEntryを構築
  List<ListEntry> getDisplayList() {
    return displayList;
  }

  Widget _categorySlider() {
    return Column(
      children: [
        Container(
          width: 120, // スライダー幅を狭く
          child: Stack(
            alignment: Alignment.center,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
                  activeTickMarkColor: Colors.black,
                  inactiveTickMarkColor: Colors.black,
                  showValueIndicator: ShowValueIndicator.never,
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _categoryIndex.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: _categories[_categoryIndex],
                  onChanged: (val) {
                    setState(() {
                      _categoryIndex = val.round();
                    });
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < _categories.length; i++)
                      Text(
                        _categories[i],
                        style: TextStyle(
                          fontWeight: _categoryIndex == i ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) {
                            // RawKeyEvent -> KeyEvent変換
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                setState(() {
                                  if (_categoryIndex > 0) _categoryIndex--;
                                });
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                setState(() {
                                  if (_categoryIndex < _categories.length - 1) _categoryIndex++;
                                });
                              }
                            }
                          },
                          child: TextField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'タスク内容',
                            ),
                            onSubmitted: (val) async {
                              if (val.trim().isNotEmpty) {
                                await _addTask();
                                FocusScope.of(context).requestFocus(_titleFocusNode);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        width: 140, // スライダー領域を固定
                        alignment: Alignment.centerRight,
                        child: _categorySlider(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTask,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    header: _buildEmergencyHeader(),
                    onReorder: (oldIndex, newIndex) async {
                      final displayList = getDisplayList();
                      final dragged = displayList[oldIndex];
                      if (oldIndex < newIndex) newIndex -= 1;
                      setState(() {
                        final item = displayList.removeAt(oldIndex);
                        displayList.insert(newIndex, item);
                      });
                      for (int i = 0; i < displayList.length; i++) {
                        final entry = displayList[i];
                        if (entry is GroupHeader) {
                          final dbEntry = _entries.firstWhere((e) => e.type == 'header' && e.title == entry.groupName);
                          await DBHelper().updateEntry(dbEntry.id, {'position': i});
                        } else if (entry is ItemEntry) {
                          await DBHelper().updateEntry(entry.id, {'position': i});
                        }
                      }
                      if (dragged is GroupHeader) {
                        final dbEntry = _entries.firstWhere((e) => e.type == 'header' && e.title == dragged.groupName);
                        await DBHelper().updateEntry(dbEntry.id, {'position': newIndex});
                      } else if (dragged is ItemEntry) {
                        await DBHelper().updateEntry(dragged.id, {'position': newIndex});
                      }
                    },
                    buildDefaultDragHandles: true,
                    children: getDisplayList()
                      .map<Widget>((entry) {
                        if (entry is GroupHeader) {
                          return ReorderableDragStartListener(
                            key: ValueKey('header_${entry.groupName}'),
                            index: getDisplayList().indexOf(entry),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text(entry.groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          );
                        } else if (entry is ItemEntry) {
                          return ListTile(
                            key: ValueKey(entry.id),
                            leading: Checkbox(
                              value: entry.completed,
                              onChanged: (val) {
                                _toggleComplete(Entry(
                                  id: entry.id,
                                  type: 'item',
                                  title: entry.name,
                                  completed: entry.completed,
                                  position: 0,
                                ));
                              },
                            ),
                            title: Text(
                              entry.name,
                              style: TextStyle(
                                decoration: entry.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: entry.completed ? Colors.grey : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteTask(entry.id);
                              },
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
