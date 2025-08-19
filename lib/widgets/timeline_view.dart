import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/note_detail_screen.dart';
import '../screens/note_editor_screen.dart';
import '../screens/note_merging_screen.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../models/note.dart';
import 'note_card.dart';


class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => TimelineViewState();
}

class TimelineViewState extends State<TimelineView> {
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};
  final ScrollController _scrollController = ScrollController();

  void toggleSelectionMode() {
    // 現在のスクロール位置を記録
    double currentScrollOffset = 0.0;
    if (_scrollController.hasClients) {
      currentScrollOffset = _scrollController.offset;
    }
    
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNoteIds.clear();
      }
    });
    
    // スクロール位置を復元（少し遅延させてレイアウトが確定してから実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && currentScrollOffset > 0) {
        _scrollController.animateTo(
          currentScrollOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _navigateToMergingScreen(List<Note> notes) {
    if (_selectedNoteIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '2件以上のノートを選択してください',
            style: TextStyle(fontFamily: 'NotoSansJP'),
          ),
        ),
      );
      return;
    }

    final selectedNotes = notes.where((note) => _selectedNoteIds.contains(note.id)).toList();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteMergingScreen(selectedNotes: selectedNotes),
      ),
    ).then((_) {
      // まとめ画面から戻ったら選択モードを終了
      setState(() {
        _isSelectionMode = false;
        _selectedNoteIds.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NoteService, AuthService>(
      builder: (context, noteService, authService, child) {
        final notes = noteService.notes;
        
        // デバッグ用：ノート数を確認
        debugPrint('TimelineView: 全体で${noteService.notes.length}件、表示対象${notes.length}件');
        
        // ローディング中かつノートがない場合
        if (noteService.isLoading && notes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('ノートを読み込み中...'),
              ],
            ),
          );
        }
        
        // ローディング完了してノートがない場合
        if (!noteService.isLoading && notes.isEmpty) {
          return const Center(
            child: Text('ノートがありません\n「+」ボタンで新しいノートを作成しましょう'),
          );
        }
        

        final mainContent = Column(
          children: [
            // 選択モード時のヘッダー
            if (_isSelectionMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
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
                      _selectedNoteIds.isEmpty 
                          ? 'まとめたいノートを選択してください'
                          : '${_selectedNoteIds.length}件選択中',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                        fontFamily: 'NotoSansJP',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedNoteIds.clear();
                        });
                      },
                      child: Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontFamily: 'NotoSansJP',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // メインのリスト
            Expanded(
              child: _isSelectionMode
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length + (noteService.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // ローディングインジケーター表示
                        if (index == notes.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        debugPrint('選択モード ListView.builder: itemBuilder called for index $index');
                        final note = notes[index];
                        final isLast = index == notes.length - 1;
                        final isSelected = _selectedNoteIds.contains(note.id);
                        
                        return Column(
                          children: [
                            NoteCard(
                              note: note,
                              isSelectionMode: _isSelectionMode,
                              isSelected: isSelected,
                              onTap: () => _toggleNoteSelection(note.id),
                            ),
                            if (isLast && !noteService.isLoading) const SizedBox(height: 8),
                          ],
                        );
                      },
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: notes.length,
                            onReorder: (oldIndex, newIndex) => _reorderNotes(context, notes, oldIndex, newIndex),
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              final isLast = index == notes.length - 1;
                              final isSelected = _selectedNoteIds.contains(note.id);
                              
                              return Container(
                                key: ValueKey(note.id),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    NoteCard(
                                      note: note,
                                      isSelectionMode: _isSelectionMode,
                                      isSelected: isSelected,
                                      onTap: () => _navigateToDetail(context, note),
                                    ),
                                    if (!isLast) 
                                      _buildDividerWithInsertButton(context, note.order),
                                    if (isLast && !noteService.isLoading) const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // ローディングインジケーター
                        if (noteService.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
        
        // 選択モード時のFloatingActionButtonを重ねて表示
        if (_isSelectionMode && _selectedNoteIds.length >= 2) {
          return Stack(
            children: [
              mainContent,
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _navigateToMergingScreen(notes),
                  icon: const Icon(Icons.library_add),
                  label: Text(
                    '${_selectedNoteIds.length}件をまとめる',
                    style: const TextStyle(fontFamily: 'NotoSansJP'),
                  ),
                ),
              ),
            ],
          );
        }
        
        return mainContent;
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

  void _reorderNotes(BuildContext context, List<Note> notes, int oldIndex, int newIndex) {
    final noteService = Provider.of<NoteService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.userId == null) return;

    // リストの順序変更に対応（newIndexが移動後の位置より大きくなる場合の調整）
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 新しいorder値を計算
    double newOrder;
    if (newIndex == 0) {
      // 一番上に移動
      newOrder = notes[0].order + 1000;
    } else if (newIndex == notes.length - 1) {
      // 一番下に移動
      newOrder = notes[notes.length - 1].order - 1000;
    } else {
      // 中間に移動
      final prevOrder = notes[newIndex].order;
      final nextOrder = notes[newIndex + 1].order;
      newOrder = (prevOrder + nextOrder) / 2;
    }

    final noteToUpdate = notes[oldIndex];
    noteService.updateNote(
      authService.userId!,
      noteToUpdate.id,
      noteToUpdate.content,
      title: noteToUpdate.title,
      newOrder: newOrder,
    );
  }

  void _navigateToDetail(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
