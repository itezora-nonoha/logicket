import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../widgets/responsive_layout.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileCard(context),
      desktop: _buildDesktopCard(context),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトルがある場合は表示
              if (note.title != null && note.title!.trim().isNotEmpty) ...[
                Text(
                  note.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansJP',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              _buildContent(context),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトルがある場合は表示
                if (note.title != null && note.title!.trim().isNotEmpty) ...[
                  Text(
                    note.title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansJP',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildContent(context),
                const SizedBox(height: 16),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        MarkdownBody(
          data: note.content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 14, 
              height: 1.4,
              fontFamily: 'NotoSansJP',
            ),
            h1: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansJP',
            ),
            h2: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansJP',
            ),
            h3: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansJP',
            ),
            code: TextStyle(
              backgroundColor: Colors.grey[100],
              fontFamily: 'Consolas, Monaco, Courier, monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onTapLink: (text, href, title) {
            if (href?.startsWith('[[') == true && href?.endsWith(']]') == true) {
              final noteId = href!.substring(2, href.length - 2);
              _handleNoteLink(context, noteId);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SizedBox(
      height: 20, // フッターの高さを統一
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _formatDate(note.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'NotoSansJP',
              ),
            ),
          ),
          // リンク数
          if (note.linkedNotes.isNotEmpty) ...[
            Icon(
              Icons.link,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${note.linkedNotes.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(width: 12),
          ],
          // ノートID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ID: ${_safeSubstring(note.id, 0, 8)}...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontFamily: 'Consolas, Monaco, Courier, monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _safeSubstring(String text, int start, int length) {
    if (text.isEmpty) return '';
    if (start >= text.length) return '';
    
    final end = start + length;
    if (end <= text.length) {
      return text.substring(start, end);
    } else {
      return text.substring(start);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  void _handleNoteLink(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リンク', style: TextStyle(fontFamily: 'NotoSansJP')),
        content: Text('ノート "$noteId" への参照です', style: const TextStyle(fontFamily: 'NotoSansJP')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる', style: TextStyle(fontFamily: 'NotoSansJP')),
          ),
        ],
      ),
    );
  }
}
