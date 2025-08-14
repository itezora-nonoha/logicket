import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/responsive_layout.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
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
      elevation: isSelected ? 2 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 選択モード時のチェックボックス
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap?.call(),
                ),
                const SizedBox(width: 8),
              ],
              
              // メインコンテンツ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトルがある場合は表示
                    if (note.title != null && note.title!.trim().isNotEmpty) ...[
                      Text(
                        note.title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
        elevation: isSelected ? 2 : 1,
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 選択モード時のチェックボックス
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // メインコンテンツ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトルがある場合は表示
                      if (note.title != null && note.title!.trim().isNotEmpty) ...[
                        Text(
                          note.title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 選択モード時はより多くの内容を表示
    // final displayContent = isSelectionMode 
    //     ? (note.content.length > 300 ? '${note.content.substring(0, 300)}...' : note.content)
    //     : _safeSubstring(note.content, 0, 150);
    
    return Column(
      children: [
        MarkdownBody(
          data: _convertInternalLinks(note.content),
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 14, 
              height: 1.4,
            ),
            h1: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
            h2: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
            ),
            h3: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
            ),
            code: TextStyle(
              backgroundColor: Colors.grey[100],
              fontFamily: 'Consolas, Monaco, Courier, monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SizedBox(
      height: 20, // フッターの高さを統一
      child: Consumer<NoteService>(
        builder: (context, noteService, child) {
          final backlinkCount = noteService.getBacklinks(note.id).length;
          
          return Row(
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
                        ),
                ),
              ),
              // バックリンク数
              if (backlinkCount > 0) ...[
                Icon(
                  Icons.link,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '$backlinkCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                        ),
                ),
                const SizedBox(width: 12),
              ],
              // コピーボタン
              InkWell(
                onTap: () => _copyNoteContent(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    Icons.content_copy,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ノートID（linkHash表示）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LinkID: ${note.linkHash}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: 'Consolas, Monaco, Courier, monospace',
                  ),
                ),
              ),
            ],
          );
        },
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

  void _copyNoteContent(BuildContext context) {
    // コピーする内容を準備
    String copyText = '';
    
    // タイトルがある場合は含める。タイトルはh1とする
    if (note.title != null && note.title!.trim().isNotEmpty) {
      copyText += '# ${note.title!}\n\n';
    }
    
    // 本文を追加
    copyText += note.content;
    
    // メタ情報を追加
    copyText += '\n';
    // copyText += '\n\n---\n';
    // copyText += 'ノートID: ${note.id}\n';
    // copyText += '作成日時: ${_formatDateTime(note.createdAt)}\n';
    // copyText += '更新日時: ${_formatDateTime(note.updatedAt)}';
    
    // クリップボードにコピー
    Clipboard.setData(ClipboardData(text: copyText)).then((_) {
      // コピー完了の視覚的フィードバック
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.content_copy,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'ノートをクリップボードにコピーしました',
                style: const TextStyle(),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }).catchError((error) {
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'コピーに失敗しました: $error',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // 触覚フィードバック（デバイスが対応している場合）
    HapticFeedback.mediumImpact();
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleNoteLink(BuildContext context, String linkHash) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リンク'),
        content: Text('ノート "$linkHash" への参照です'),
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
