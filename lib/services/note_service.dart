import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NoteService extends ChangeNotifier {
  final List<Note> _notes = [];
  final Uuid _uuid = const Uuid();
  double _lastOrder = 1000.0;

  List<Note> get notes {
    List<Note> sortedNotes = _notes.where((note) => !note.isDeleted).toList();
    sortedNotes.sort((a, b) => b.order.compareTo(a.order)); // 降順（新しいものが上）
    return sortedNotes;
  }

  NoteService() {
    _initSampleData();
  }

  void _initSampleData() {
    final now = DateTime.now();
    _notes.addAll([
      Note(
        id: _uuid.v4(),
        content: '''# ツェッテルカステンとは

ツェッテルカステンは知識管理の手法です。

- アイデアを小さな単位で記録
- ノート間のリンクで知識を関連付け
- 創発的思考を促進

[[note2]] も参照してください。''',
        order: 1000.0,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Note(
        id: 'note2',
        content: '''## 創発的思考について

個々のアイデアが組み合わさることで、新しい洞察が生まれる現象。

**特徴：**
- 予期しない関連性の発見
- 複雑系の性質
- 非線形的な発展

この概念は [[note3]] で詳しく説明しています。''',
        order: 999.0,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      Note(
        id: 'note3',
        content: '''## 知識の関連付け

```
ノートA ← → ノートB
   ↓      ↗
ノートC → ノートD
```

このような網目状の構造で知識を蓄積していきます。

> 「知識は孤立していては価値がない」''',
        order: 998.0,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ]);
    notifyListeners();
  }

  Future<void> createNote(String content, {double? insertAfterOrder}) async {
    final now = DateTime.now();
    double newOrder;

    if (insertAfterOrder != null) {
      // 指定位置に挿入
      final afterNote = _notes.where((n) => n.order == insertAfterOrder).firstOrNull;
      final beforeNote = _notes
          .where((n) => !n.isDeleted && n.order < insertAfterOrder)
          .fold<Note?>(null, (prev, curr) => 
              prev == null || curr.order > prev.order ? curr : prev);
      
      if (beforeNote != null) {
        newOrder = (insertAfterOrder + beforeNote.order) / 2;
      } else {
        newOrder = insertAfterOrder - 1.0;
      }
    } else {
      // 先頭に挿入
      newOrder = _lastOrder + 1.0;
      _lastOrder = newOrder;
    }

    final note = Note(
      id: _uuid.v4(),
      content: content,
      order: newOrder,
      linkedNotes: _extractLinkedNotes(content),
      createdAt: now,
      updatedAt: now,
    );

    _notes.add(note);
    notifyListeners();
  }

  Future<void> updateNote(String id, String content) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        content: content,
        linkedNotes: _extractLinkedNotes(content),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> reorderNote(String id, double newOrder) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        order: newOrder,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Note? getNoteById(String id) {
    return _notes.where((note) => note.id == id && !note.isDeleted).firstOrNull;
  }

  List<Note> getBacklinks(String noteId) {
    return _notes
        .where((note) => !note.isDeleted && note.linkedNotes.contains(noteId))
        .toList();
  }

  List<String> _extractLinkedNotes(String content) {
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }
}
