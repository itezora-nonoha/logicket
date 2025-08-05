import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/note_detail_screen.dart';
import '../services/note_service.dart';
import '../models/note.dart';
import 'note_card.dart';
import '../screens/note_editor_screen.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteService>(
      builder: (context, noteService, child) {
        final notes = noteService.notes;
        
        if (notes.isEmpty) {
          return const Center(
            child: Text('ノートがありません\n「+」ボタンで新しいノートを作成しましょう'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length + notes.length - 1, // ノート + 挿入ポイント
          itemBuilder: (context, index) {
            if (index.isEven) {
              // ノートカード
              final noteIndex = index ~/ 2;
              final note = notes[noteIndex];
              return NoteCard(
                note: note,
                onTap: () => _navigateToDetail(context, note),
              );
            } else {
              // 挿入ポイント
              final noteIndex = (index - 1) ~/ 2;
              final afterNote = notes[noteIndex];
              return _buildInsertionPoint(context, afterNote.order);
            }
          },
        );
      },
    );
  }

  Widget _buildInsertionPoint(BuildContext context, double afterOrder) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _navigateToEditor(context, afterOrder),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ここに挿入',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  void _navigateToDetail(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }
}
