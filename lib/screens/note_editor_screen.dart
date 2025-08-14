import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/note.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final double? insertAfterOrder;

  const NoteEditorScreen({super.key, this.note, this.insertAfterOrder});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const int _maxContentLength = 200;

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;
  DateTime? _inspirationDate;
  bool _isLoading = false;
  int _currentContentLength = 0;
  
  // デバッグ用変数
  bool _showDebugInfo = false;
  double _xCaret = 0.0;
  double _yCaret = 0.0;
  double _painterWidth = 0.0;
  double _painterHeight = 0.0;
  double _preferredLineHeight = 0.0;
  Size _physicalSize = Size.zero;
  Size _devicePixelRatio = Size.zero;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _contentFocusNode = FocusNode();
    _inspirationDate = widget.note?.inspirationDate;

    // 初期テキストを保存
    _previousText = _contentController.text;
    _currentContentLength = _contentController.text.length;

    // テキスト変更リスナーを追加
    _contentController.addListener(_onTextChanged);
    
    // フォーカス変更リスナーを追加
    _contentFocusNode.addListener(() {
      setState(() {
        // フォーカス状態の変更に応じてUI更新
      });
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  String _previousText = '';

  void _onTextChanged() {
    final currentText = _contentController.text;
    final value = _contentController.value;
    final selection = value.selection;

    setState(() {
      _currentContentLength = currentText.length;
    });

    // IME日本語入力中は何もしない
    if (value.composing.isValid) {
      _previousText = currentText;
      return;
    }

    if (currentText.length > _previousText.length &&
        currentText.endsWith('\n') &&
        selection.isValid) {
      final cursorPosition = selection.baseOffset;
      final beforeNewline = currentText.substring(0, cursorPosition - 1);
      final lastNewlineIndex = beforeNewline.lastIndexOf('\n');
      final previousLineStart = lastNewlineIndex == -1
          ? 0
          : lastNewlineIndex + 1;
      final previousLine = beforeNewline.substring(previousLineStart);

      if (previousLine.startsWith('- ')) {
        final newText = '$currentText- ';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
        setState(() {
          _currentContentLength = newText.length;
        });
      }
    }

    _previousText = currentText;
    
    // デバッグモードの場合、キャレット位置を更新
    if (_showDebugInfo) {
      _updateCaretOffset(currentText);
    }
  }
  
  void _updateCaretOffset(String text) {
    try {
      // FlutterViewを取得
      FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
      
      // 物理ピクセルサイズと論理ピクセルサイズ
      _physicalSize = view.physicalSize;
      _devicePixelRatio = view.physicalSize / view.devicePixelRatio;
      
      TextPainter painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          style: const TextStyle(fontSize: 16, height: 1.4),
          text: text,
        ),
      );
      
      painter.layout(
        maxWidth: _devicePixelRatio.width - 64, // パディング考慮
      );
      
      TextPosition cursorTextPosition = _contentController.selection.base;
      Rect caretPrototype = Rect.fromLTWH(
        0.0,
        0.0,
        1.0, // カーソル幅
        painter.preferredLineHeight,
      );
      
      Offset caretOffset = painter.getOffsetForCaret(cursorTextPosition, caretPrototype);
      
      setState(() {
        _xCaret = caretOffset.dx;
        _yCaret = caretOffset.dy;
        _painterWidth = painter.width;
        _painterHeight = painter.height;
        _preferredLineHeight = painter.preferredLineHeight;
      });
    } catch (e) {
      // エラーが発生した場合は無視
    }
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
          // デバッグモード切り替えボタン
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
                if (_showDebugInfo) {
                  _updateCaretOffset(_contentController.text);
                }
              });
            },
            tooltip: 'デバッグ情報の表示切り替え',
          ),
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
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.insertAfterOrder != null && !_showDebugInfo)
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

            // タイトル入力欄（デバッグモード時は非表示）
            if (!_showDebugInfo)
              TextField(
              controller: _titleController,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'タイトル（任意）',
                hintText: 'ノートのタイトルを入力...',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontFamily: 'NotoSansJP'),
                hintStyle: TextStyle(fontFamily: 'NotoSansJP'),
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 16),
              ),

            if (!_showDebugInfo) const SizedBox(height: 16),

            // 発想日入力欄（デバッグモード時は非表示）
            if (!_showDebugInfo)
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

            if (!_showDebugInfo) const SizedBox(height: 16),

            // 本文入力欄とデバッグ情報を並列表示
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 本文入力欄
                  Expanded(
                    flex: _showDebugInfo ? 2 : 1,
                    child: Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        return settingsService.useEditableText
                            ? _buildEditableTextInput(context)
                            : _buildTextFieldInput(context);
                      },
                    ),
                  ),
                  
                  // デバッグ情報表示
                  if (_showDebugInfo) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TextField デバッグ情報',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDebugInfoText(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
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
        // 発想日が空の場合は作成日を設定
        final DateTime inspirationDate = _inspirationDate ?? DateTime.now();
        await noteService.createNote(
          userId,
          _contentController.text.trim(),
          title: title,
          inspirationDate: inspirationDate,
          insertAfterOrder: widget.insertAfterOrder,
        );
      } else {
        // 更新
        await noteService.updateNote(
          userId,
          widget.note!.id,
          _contentController.text.trim(),
          title: title,
          inspirationDate: _inspirationDate,
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

  Widget _buildEditableTextInput(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _contentFocusNode.requestFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _currentContentLength > _maxContentLength
                ? Colors.red
                : (_contentFocusNode.hasFocus
                    ? Theme.of(context).primaryColor
                    : Colors.grey),
            width: _contentFocusNode.hasFocus ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ラベル
            Container(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: Text(
                '本文',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentContentLength > _maxContentLength
                      ? Colors.red
                      : (_contentFocusNode.hasFocus
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600]),
                ),
              ),
            ),
            // EditableTextウィジェット
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Stack(
                      children: [
                        // ヒントテキスト
                        if (_contentController.text.isEmpty)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: IgnorePointer(
                              child: Text(
                                'マークダウン記法が使用できます',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          ),
                        // EditableText本体
                        EditableText(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                          ),
                          strutStyle: const StrutStyle(
                            fontSize: 16,
                            height: 1.4,
                            forceStrutHeight: false,
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          cursorWidth: 1.0,
                          backgroundCursorColor: Colors.grey[300] ?? Colors.grey,
                          maxLines: null,
                          minLines: 8,
                          textAlign: TextAlign.start,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
                          selectionControls: MaterialTextSelectionControls(),
                          showCursor: true,
                          readOnly: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldInput(BuildContext context) {
    return TextField(
      controller: _contentController,
      maxLines: null,
      expands: true,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.top,
      cursorWidth: 1.0,

      decoration: InputDecoration(
        labelText: '本文',
        hintText: 'マークダウン記法が使用できます',
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
        contentPadding: const EdgeInsets.all(16),
        alignLabelWithHint: true,
      ),
      strutStyle: const StrutStyle(
        fontSize: 16,
        height: 1.4,
        forceStrutHeight: true,
      ),
      style: const TextStyle(
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildDebugInfoText() {
    final debugData = {
      "xCaret": _xCaret.toStringAsFixed(1),
      "yCaret": _yCaret.toStringAsFixed(1),
      "yCaretBottom": (_yCaret + _preferredLineHeight).toStringAsFixed(1),
      "Painter Width": _painterWidth.toStringAsFixed(1),
      "Painter Height": _painterHeight.toStringAsFixed(1),
      "Preferred Line Height": _preferredLineHeight.toStringAsFixed(1),
      "Physical Size": "${_physicalSize.width.toStringAsFixed(0)} x ${_physicalSize.height.toStringAsFixed(0)}",
      "Device Pixel Ratio": "${_devicePixelRatio.width.toStringAsFixed(1)} x ${_devicePixelRatio.height.toStringAsFixed(1)}",
      "Selection Start": _contentController.selection.start.toString(),
      "Selection End": _contentController.selection.end.toString(),
      "Text Length": _contentController.text.length.toString(),
      "Composing Start": _contentController.value.composing.start.toString(),
      "Composing End": _contentController.value.composing.end.toString(),
    };

    return Text(
      debugData.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'),
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[700],
        fontFamily: 'monospace',
        height: 1.2,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
