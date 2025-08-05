import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'note_editor_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ノート詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditor(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ノート内容
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: MarkdownBody(
                  data: note.content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16, height: 1.6),
                    h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    code: TextStyle(
                      backgroundColor: Colors.grey[100],
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    blockquote: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.grey[50],
                    ),
                  ),
                  onTapLink: (text, href, title) {
                    if (href?.startsWith('[[') == true && href?.endsWith(']]') == true) {
                      final noteId = href!.substring(2, href.length - 2);
                      _handleNoteLink(context, noteId);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // メタ情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'メタ情報',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetaRow(Icons.schedule, '作成日時', _formatDateTime(note.createdAt)),
                    const SizedBox(height: 8),
                    _buildMetaRow(Icons.update, '更新日時', _formatDateTime(note.updatedAt)),
                    const SizedBox(height: 8),
                    _buildMetaRow(Icons.sort, '順序', '${note.order}'),
                    if (note.linkedNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildMetaRow(Icons.link, 'リンク数', '${note.linkedNotes.length}個'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // バックリンク
            Consumer<NoteService>(
              builder: (context, noteService, child) {
                final backlinks = noteService.getBacklinks(note.id);
                
                if (backlinks.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'バックリンク (${backlinks.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...backlinks.map((backlink) => _buildBacklinkItem(context, backlink)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildBacklinkItem(BuildContext context, Note backlink) {
    return InkWell(
      onTap: () => _navigateToNote(context, backlink),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPreviewText(backlink.content),
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(backlink.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
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

  void _navigateToEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );
  }

  void _navigateToNote(BuildContext context, Note targetNote) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: targetNote),
      ),
    );
  }

  void _handleNoteLink(BuildContext context, String noteId) {
    final noteService = context.read<NoteService>();
    final linkedNote = noteService.getNoteById(noteId);
    
    if (linkedNote != null) {
      _navigateToNote(context, linkedNote);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('リンクエラー'),
          content: Text('ノート "$noteId" が見つかりません'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ノートを削除'),
        content: const Text('このノートを削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<NoteService>().deleteNote(note.id);
              if (context.mounted) {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(); // 詳細画面を閉じる
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ノートを削除しました')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
    