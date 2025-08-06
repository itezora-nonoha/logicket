import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../models/note.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final double? insertAfterOrder;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.insertAfterOrder,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null ? '新しいノート' : 'ノートを編集',
          style: const TextStyle(fontFamily: 'NotoSansJP'),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveNote,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSansJP',
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.insertAfterOrder != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '指定された位置に挿入されます',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                        fontFamily: 'NotoSansJP',
                      ),
                    ),
                  ],
                ),
              ),
            
            // タイトル入力欄
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル（任意）',
                hintText: 'ノートのタイトルを入力...',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontFamily: 'NotoSansJP'),
                hintStyle: TextStyle(fontFamily: 'NotoSansJP'),
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'NotoSansJP',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 本文入力欄
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: '本文',
                  hintText: 'マークダウンでノートを書いてください...\n\n[[ノートID]] でリンクを作成できます',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontFamily: 'NotoSansJP'),
                  hintStyle: TextStyle(fontFamily: 'NotoSansJP'),
                  contentPadding: EdgeInsets.all(16),
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'NotoSansJP',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontFamily: 'NotoSansJP'),
                ),
                child: Text(_isLoading ? '保存中...' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ノートの本文が空です',
            style: TextStyle(fontFamily: 'NotoSansJP'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final noteService = context.read<NoteService>();
      final authService = context.read<AuthService>();
      final userId = authService.userId!;
      
      final title = _titleController.text.trim().isEmpty 
          ? null 
          : _titleController.text.trim();
      
      if (widget.note == null) {
        // 新規作成
        await noteService.createNote(
          userId,
          _contentController.text.trim(),
          title: title,
          insertAfterOrder: widget.insertAfterOrder,
        );
      } else {
        // 更新
        await noteService.updateNote(
          userId, 
          widget.note!.id, 
          _contentController.text.trim(),
          title: title,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ノートを保存しました',
              style: TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存に失敗しました: $e',
              style: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
