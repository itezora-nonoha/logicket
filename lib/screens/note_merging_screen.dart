import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../models/note.dart';

class NoteMergingScreen extends StatefulWidget {
  final List<Note> selectedNotes;

  const NoteMergingScreen({
    super.key,
    required this.selectedNotes,
  });

  @override
  State<NoteMergingScreen> createState() => _NoteMergingScreenState();
}

class _NoteMergingScreenState extends State<NoteMergingScreen> {
  static const int _maxContentLength = 200;
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  DateTime? _inspirationDate;
  bool _isLoading = false;
  int _currentContentLength = 0;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    
    final mergedContent = _mergeNotesContent();
    _titleController = TextEditingController();
    _contentController = TextEditingController(text: mergedContent);
    _inspirationDate = DateTime.now();
    
    // 初期テキストを保存
    _previousText = _contentController.text;
    _currentContentLength = _contentController.text.length;
    
    // テキスト変更リスナーを追加
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _mergeNotesContent() {
    final buffer = StringBuffer();
    
    for (int i = 0; i < widget.selectedNotes.length; i++) {
      final note = widget.selectedNotes[i];
      
      // タイトルがある場合はマークダウンヘッダーとして追加
      if (note.title != null && note.title!.trim().isNotEmpty) {
        buffer.writeln('## ${note.title!.trim()}');
        buffer.writeln();
      }
      
      // 本文を追加
      buffer.writeln(note.content.trim());
      
      // 最後のノート以外は区切り線を追加
      if (i < widget.selectedNotes.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  void _onTextChanged() {
    final currentText = _contentController.text;
    final selection = _contentController.selection;
    
    // 文字数を更新
    setState(() {
      _currentContentLength = currentText.length;
    });
    
    // テキストが変更され、改行が追加されたかチェック
    if (currentText.length > _previousText.length && 
        currentText.endsWith('\n') && 
        selection.isValid) {
      
      final cursorPosition = selection.baseOffset;
      
      // 改行の直前の行を取得
      final beforeNewline = currentText.substring(0, cursorPosition - 1);
      final lastNewlineIndex = beforeNewline.lastIndexOf('\n');
      final previousLineStart = lastNewlineIndex == -1 ? 0 : lastNewlineIndex + 1;
      final previousLine = beforeNewline.substring(previousLineStart);
      
      // 前の行が箇条書き形式（"- "で始まる）かチェック
      if (previousLine.startsWith('- ')) {
        // 箇条書きマーカーを自動挿入
        final newText = '$currentText- ';
        
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(
          offset: newText.length,
        );
        
        // 箇条書きマーカー追加後に文字数を再更新
        setState(() {
          _currentContentLength = newText.length;
        });
      }
    }
    
    _previousText = currentText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ノートをまとめる',
          style: TextStyle(fontFamily: 'NotoSansJP'),
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
              onPressed: _saveMergedNote,
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
                    Icons.merge_type,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.selectedNotes.length}件のノートをまとめています',
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
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'タイトル（任意）',
                hintText: 'まとめノートのタイトルを入力...',
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
            
            // 発想日入力欄
            InkWell(
              onTap: _selectInspirationDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '発想日（任意）',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontFamily: 'NotoSansJP'),
                  contentPadding: EdgeInsets.all(16),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _inspirationDate != null
                      ? _formatDate(_inspirationDate!)
                      : '発想した日を選択...',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'NotoSansJP',
                    color: _inspirationDate != null 
                        ? Colors.black87 
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 本文入力欄
            Expanded(
              child: TextField(
                controller: _contentController,
                expands: false,
                maxLines: 15,        // 固定の最大行数
                minLines: 8,         // 固定の最小行数
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: '本文',
                  hintText: '選択したノートの内容を編集・まとめ直してください',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _currentContentLength > _maxContentLength 
                          ? Colors.red 
                          : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _currentContentLength > _maxContentLength 
                          ? Colors.red 
                          : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _currentContentLength > _maxContentLength 
                          ? Colors.red 
                          : Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                  ),
                  labelStyle: const TextStyle(fontFamily: 'NotoSansJP'),
                  hintStyle: const TextStyle(fontFamily: 'NotoSansJP'),
                  contentPadding: const EdgeInsets.all(16),
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'NotoSansJP',
                ),
              ),
            ),
            
            // 文字数表示
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$_currentContentLength / $_maxContentLength',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentContentLength > _maxContentLength 
                          ? Colors.red 
                          : Colors.grey[600],
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMergedNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontFamily: 'NotoSansJP'),
                ),
                child: Text(_isLoading ? '保存中...' : 'まとめを保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMergedNote() async {
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
      
      // 新しいまとめノートを作成
      await noteService.createNote(
        userId,
        _contentController.text.trim(),
        title: title,
        inspirationDate: _inspirationDate ?? DateTime.now(),
      );
      
      // ノートを再読み込みして最新のノートを取得
      await noteService.loadNotes(userId);
      final newNote = noteService.notes.first; // 最新のノート

      // 元のノートにリンクを挿入してアーカイブ
      await _processOriginalNotes(noteService, userId, newNote);

      if (mounted) {
        // ホーム画面まで戻る
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ノートをまとめて保存しました',
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
              'まとめの保存に失敗しました: $e',
              style: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processOriginalNotes(NoteService noteService, String userId, Note newNote) async {
    for (final originalNote in widget.selectedNotes) {
      // 元ノートの本文末尾にリンクを挿入
      final linkText = '\n\n～ [[${newNote.linkHash}]] としてまとめ済み ～';
      final updatedContent = originalNote.content + linkText;
      
      // 元ノートを更新（リンク挿入）
      await noteService.updateNote(
        userId,
        originalNote.id,
        updatedContent,
        title: originalNote.title,
        inspirationDate: originalNote.inspirationDate,
      );
      
      // 元ノートをアーカイブ
      await noteService.archiveNote(userId, originalNote.id);
    }
  }

  Future<void> _selectInspirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _inspirationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _inspirationDate) {
      setState(() {
        _inspirationDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}