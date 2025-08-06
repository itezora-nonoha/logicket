import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/note_detail_screen.dart';
import '../screens/note_editor_screen.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../models/note.dart';
import 'note_card.dart';


class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NoteService, AuthService>(
      builder: (context, noteService, authService, child) {
        if (noteService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final notes = noteService.notes;
        
        if (notes.isEmpty) {
          return const Center(
            child: Text('ノートがありません\n「+」ボタンで新しいノートを作成しましょう'),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          onReorder: (oldIndex, newIndex) => _reorderNotes(context, notes, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final note = notes[index];
            final isLast = index == notes.length - 1;
            
            return Container(
              key: ValueKey(note.id),
              width: double.infinity,
              child: Column(
                children: [
                  NoteCard(
                    note: note,
                    onTap: () => _navigateToDetail(context, note),
                  ),
                  if (!isLast) _buildDividerWithInsertButton(context, note.order),
                  if (isLast) const SizedBox(height: 8), // 末尾にも余白を追加
                ],
              ),
            );
          },
        );
      },
    );
  }

 Widget _buildDividerWithInsertButton(BuildContext context, double afterOrder) {
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          // 境界線（右端に余白を残す）
          Positioned(
            left: 0,
            right: 36, // プラスボタン分の余白を確保
            top: 12,
            child: Container(
              height: 1,
              color: Colors.grey[300],
            ),
          ),
          // 右端のプラスボタン（画面端から少し内側に）
          Positioned(
            right: 8, // 画面端から8px内側に配置
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToEditor(context, afterOrder),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF33A6B8), // 浅葱色
                        const Color(0xFF33A6B8).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF33A6B8).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(BuildContext context, double insertAfterOrder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(insertAfterOrder: insertAfterOrder),
      ),
    );
  }

  void _reorderNotes(BuildContext context, List<Note> notes, int oldIndex, int newIndex) {
    final noteService = Provider.of<NoteService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.userId == null) return;

    // リストの順序変更に対応（newIndexが移動後の位置より大きくなる場合の調整）
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 新しいorder値を計算
    double newOrder;
    if (newIndex == 0) {
      // 一番上に移動
      newOrder = notes[0].order + 1000;
    } else if (newIndex == notes.length - 1) {
      // 一番下に移動
      newOrder = notes[notes.length - 1].order - 1000;
    } else {
      // 中間に移動
      final prevOrder = notes[newIndex].order;
      final nextOrder = notes[newIndex + 1].order;
      newOrder = (prevOrder + nextOrder) / 2;
    }

    final noteToUpdate = notes[oldIndex];
    noteService.updateNote(
      authService.userId!,
      noteToUpdate.id,
      noteToUpdate.content,
      title: noteToUpdate.title,
      newOrder: newOrder,
    );
  }

  void _navigateToDetail(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }
}
