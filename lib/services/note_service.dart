import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NoteService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes {
    List<Note> sortedNotes = _notes.where((note) => !note.isDeleted).toList();
    sortedNotes.sort((a, b) => b.order.compareTo(a.order)); // 降順（新しいものが上）
    return sortedNotes;
  }

  bool get isLoading => _isLoading;

  Future<void> loadNotes(String userId) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('isDeleted', isEqualTo: false)
          .get();

      _notes.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        _notes.add(Note.fromMap(data));
      }

      // サンプルデータがない場合は作成
      if (_notes.isEmpty) {
        await _initSampleData(userId);
      }
    } catch (e) {
      debugPrint('ノート読み込みエラー: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initSampleData(String userId) async {
    final now = DateTime.now();
    final sampleNotes = [
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

\`\`\`
ノートA ← → ノートB
   ↓      ↗
ノートC → ノートD
\`\`\`

このような網目状の構造で知識を蓄積していきます。

> 「知識は孤立していては価値がない」''',
        order: 998.0,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    for (var note in sampleNotes) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .set(note.toMap());
      _notes.add(note);
    }
  }

  Future<void> createNote(String userId, String content, {double? insertAfterOrder}) async {
    if (userId.isEmpty) return;

    final now = DateTime.now();
    double newOrder;

    if (insertAfterOrder != null) {
      // 指定位置に挿入
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
      final maxOrder = _notes.isEmpty ? 0.0 : _notes.map((n) => n.order).reduce((a, b) => a > b ? a : b);
      newOrder = maxOrder + 1.0;
    }

    final note = Note(
      id: _uuid.v4(),
      content: content,
      order: newOrder,
      linkedNotes: _extractLinkedNotes(content),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .set(note.toMap());

      _notes.add(note);
      notifyListeners();
    } catch (e) {
      debugPrint('ノート作成エラー: $e');
      rethrow;
    }
  }

  Future<void> updateNote(String userId, String id, String content) async {
    if (userId.isEmpty) return;

    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      final updatedNote = _notes[index].copyWith(
        content: content,
        linkedNotes: _extractLinkedNotes(content),
        updatedAt: DateTime.now(),
      );

      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(id)
            .update(updatedNote.toMap());

        _notes[index] = updatedNote;
        notifyListeners();
      } catch (e) {
        debugPrint('ノート更新エラー: $e');
        rethrow;
      }
    }
  }

  Future<void> deleteNote(String userId, String id) async {
    if (userId.isEmpty) return;

    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      final deletedNote = _notes[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );

      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(id)
            .update({'isDeleted': true, 'updatedAt': FieldValue.serverTimestamp()});

        _notes[index] = deletedNote;
        notifyListeners();
      } catch (e) {
        debugPrint('ノート削除エラー: $e');
        rethrow;
      }
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
