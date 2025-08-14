import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'note_detail_screen.dart';

class ArchivedNotesScreen extends StatelessWidget {
  const ArchivedNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'アーカイブ',
          style: TextStyle(fontFamily: 'NotoSansJP'),
        ),
      ),
      body: Consumer<NoteService>(
        builder: (context, noteService, child) {
          final archivedNotes = noteService.archivedNotes;
          
          if (noteService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (archivedNotes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'アーカイブされたノートはありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archivedNotes.length,
            itemBuilder: (context, index) {
              final note = archivedNotes[index];
              return _buildArchivedNoteCard(context, note);
            },
          );
        },
      ),
    );
  }

  Widget _buildArchivedNoteCard(BuildContext context, Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToNoteDetail(context, note),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.title != null && note.title!.trim().isNotEmpty) ...[
                          Text(
                            note.title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansJP',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          _getPreviewText(note.content),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontFamily: 'NotoSansJP',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'unarchive') {
                        _showUnarchiveDialog(context, note);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'unarchive',
                        child: Row(
                          children: [
                            Icon(Icons.unarchive, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'アーカイブ解除',
                              style: TextStyle(
                                color: Colors.blue,
                                fontFamily: 'NotoSansJP',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              '削除',
                              style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'NotoSansJP',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'アーカイブ: ${_formatDateTime(note.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                  if (note.inspirationDate != null) ...[
                    const Spacer(),
                    Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '発想: ${_formatDate(note.inspirationDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'NotoSansJP',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    // マークダウン記法を簡単に除去してプレビューテキストを生成
    String preview = content.replaceAll(RegExp(r'#+\s*'), '');
    preview = preview.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    preview = preview.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    preview = preview.replaceAll(RegExp(r'`(.*?)`'), r'$1');
    preview = preview.replaceAll(RegExp(r'\n+'), ' ');
    return preview.trim();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  void _navigateToNoteDetail(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }

  void _showUnarchiveDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'アーカイブを解除',
          style: TextStyle(fontFamily: 'NotoSansJP'),
        ),
        content: const Text(
          'このノートのアーカイブを解除して、タイムラインに戻しますか？',
          style: TextStyle(fontFamily: 'NotoSansJP'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'キャンセル',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authService = context.read<AuthService>();
              await context.read<NoteService>().unarchiveNote(authService.userId!, note.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ノートのアーカイブを解除しました',
                      style: TextStyle(fontFamily: 'NotoSansJP'),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text(
              'アーカイブ解除',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ノートを削除',
          style: TextStyle(fontFamily: 'NotoSansJP'),
        ),
        content: const Text(
          'このノートを完全に削除しますか？この操作は取り消せません。',
          style: TextStyle(fontFamily: 'NotoSansJP'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'キャンセル',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authService = context.read<AuthService>();
              await context.read<NoteService>().deleteNote(authService.userId!, note.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ノートを削除しました',
                      style: TextStyle(fontFamily: 'NotoSansJP'),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              '削除',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        ],
      ),
    );
  }
}