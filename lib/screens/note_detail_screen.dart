import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'note_editor_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteService>(
      builder: (context, noteService, child) {
        // 最新のノート情報を取得
        final latestNote = noteService.getNoteById(_currentNote.id);
        if (latestNote != null) {
          _currentNote = latestNote;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ノート詳細',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEditor(context),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'archive') {
                    await _archiveNote(context);
                  } else if (value == 'unarchive') {
                    await _unarchiveNote(context);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  // アーカイブ済みの場合はアーカイブ解除、そうでなければアーカイブ
                  if (_currentNote.isArchived)
                    PopupMenuItem(
                      value: 'unarchive',
                      child: Row(
                        children: [
                          Icon(Icons.unarchive, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'アーカイブ解除',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontFamily: 'NotoSansJP',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'アーカイブ',
                            style: TextStyle(
                              color: Colors.orange[700],
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アーカイブ済みノートのバナー
                if (_currentNote.isArchived) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.archive,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'このノートはアーカイブされています',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // ノート内容
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトルがある場合は表示
                        if (_currentNote.title != null && _currentNote.title!.trim().isNotEmpty) ...[
                          Text(
                            _currentNote.title!,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansJP',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        MarkdownBody(
                          data: _convertInternalLinks(_currentNote.content),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 16, 
                              height: 1.6,
                              fontFamily: 'NotoSansJP',
                            ),
                            h1: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansJP',
                            ),
                            h2: const TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansJP',
                            ),
                            h3: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansJP',
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.grey[100],
                              fontFamily: 'Consolas, Monaco, Courier, monospace',
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            blockquote: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                              fontFamily: 'NotoSansJP',
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: Colors.grey[50],
                            ),
                            a: TextStyle(
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onTapLink: (text, href, title) {
                            if (href?.startsWith('note://') == true) {
                              final linkHash = href!.substring(7); // "note://" を除去
                              _handleNoteLink(context, linkHash);
                            }
                          },
                        ),
                      ],
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
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_currentNote.inspirationDate != null) ...[
                          _buildMetaRow(Icons.lightbulb_outline, '発想日', _formatDate(_currentNote.inspirationDate!)),
                          const SizedBox(height: 8),
                        ],
                        _buildMetaRow(Icons.schedule, '作成日時', _formatDateTime(_currentNote.createdAt)),
                        const SizedBox(height: 8),
                        _buildMetaRow(Icons.update, '更新日時', _formatDateTime(_currentNote.updatedAt)),
                        const SizedBox(height: 8),
                        _buildMetaRow(Icons.sort, '順序', '${_currentNote.order}'),
                        if (_currentNote.linkedNotes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildMetaRow(Icons.link, 'リンク数', '${_currentNote.linkedNotes.length}個'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // バックリンク
                Builder(
                  builder: (context) {
                    final backlinks = noteService.getBacklinks(_currentNote.id);
                    debugPrint('Backlinks for note ${_currentNote.id} (${_currentNote.linkHash}): ${backlinks.length}件');
                    
                    if (backlinks.isEmpty) {
                      debugPrint('No backlinks found for note ${_currentNote.id}');
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
                                fontFamily: 'NotoSansJP',
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
      },
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
            fontFamily: 'NotoSansJP',
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'NotoSansJP',
            ),
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
            if (backlink.title != null && backlink.title!.trim().isNotEmpty) ...[
              Text(
                backlink.title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansJP',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              _getPreviewText(backlink.content),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'NotoSansJP',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(backlink.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'NotoSansJP',
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  void _navigateToEditor(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: _currentNote),
      ),
    );
    // 編集画面から戻ってきた時に最新データを反映
    if (mounted) {
      setState(() {});
    }
  }

  /// [[ノートID]] 形式を [ノートID](note://ノートID) 形式に変換
  String _convertInternalLinks(String content) {
    return content.replaceAllMapped(
      RegExp(r'\[\[([^\]]+)\]\]'),
      (match) {
        final noteId = match.group(1)!;
        return '[$noteId](note://$noteId)';
      },
    );
  }

  void _navigateToNote(BuildContext context, Note targetNote) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: targetNote),
      ),
    );
  }

  void _handleNoteLink(BuildContext context, String linkHash) {
    final noteService = context.read<NoteService>();
    final linkedNote = noteService.getNoteByLinkHash(linkHash);
    
    if (linkedNote != null) {
      _navigateToNote(context, linkedNote);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'リンクエラー',
            style: TextStyle(fontFamily: 'NotoSansJP'),
          ),
          content: Text(
            'ノート "$linkHash" が見つかりません',
            style: const TextStyle(fontFamily: 'NotoSansJP'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '閉じる',
                style: TextStyle(fontFamily: 'NotoSansJP'),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _archiveNote(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      await context.read<NoteService>().archiveNote(authService.userId!, _currentNote.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // 詳細画面を閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ノートをアーカイブしました',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'アーカイブに失敗しました: $e',
              style: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unarchiveNote(BuildContext context) async {
    try {
      final noteService = context.read<NoteService>();
      final authService = context.read<AuthService>();
      final userId = authService.userId!;
      await noteService.unarchiveNote(userId, _currentNote.id);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 詳細画面を閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ノートをアーカイブから解除しました',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'アーカイブ解除に失敗しました: $e',
              style: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ノートを削除',
          style: TextStyle(fontFamily: 'NotoSansJP'),
        ),
        content: const Text(
          'このノートを削除しますか？この操作は取り消せません。',
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
              await context.read<NoteService>().deleteNote(authService.userId!, _currentNote.id);
              if (context.mounted) {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(); // 詳細画面を閉じる
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
