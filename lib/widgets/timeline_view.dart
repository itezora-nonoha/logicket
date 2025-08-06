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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isLast = index == notes.length - 1;
            
            return Column(
              children: [
                NoteCard(
                  note: note,
                  onTap: () => _navigateToDetail(context, note),
                ),
                if (!isLast) _buildDividerWithInsertButton(context, note.order),
              ],
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

  void _navigateToDetail(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }
}
