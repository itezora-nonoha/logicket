import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../widgets/timeline_view.dart';
import '../widgets/responsive_layout.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';
import 'archived_notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<TimelineViewState> _timelineKey = GlobalKey<TimelineViewState>();

  List<Widget> get _pages => [
    TimelineView(key: _timelineKey),
    const _SearchPage(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final noteService = context.read<NoteService>();
      
      if (authService.isAuthenticated && authService.userId != null) {
        noteService.loadNotes(authService.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logicket'),
        elevation: 1,
        actions: [
          if (_selectedIndex == 0) // タイムライン画面でのみ表示
            IconButton(
              icon: const Icon(Icons.library_add),
              onPressed: () {
                // TimelineViewに選択モードを切り替える指示を送る
                _toggleTimelineSelectionMode();
              },
              tooltip: 'ノートをまとめる',
            ),
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final user = authService.currentUser;
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Text(
                    _getInitials(user?.displayName ?? user?.email ?? 'U'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                      break;
                    case 'logout':
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('ログアウト'),
                          content: const Text('ログアウトしますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('ログアウト'),
                            ),
                          ],
                        ),
                      );
                      
                      if (result == true && context.mounted) {
                        await authService.signOut();
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 12),
                        Text(user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : user?.email ?? '匿名ユーザー'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.account_circle),
                        SizedBox(width: 12),
                        Text('プロフィール'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 12),
                        Text('ログアウト'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _navigateToEditor(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.timeline),
                label: Text('Timeline'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Logicket'),
                automaticallyImplyLeading: false,
                actions: [
                  if (_selectedIndex == 0) // タイムライン画面でのみ表示
                    IconButton(
                      icon: const Icon(Icons.library_add),
                      onPressed: () {
                        // TimelineViewに選択モードを切り替える指示を送る
                        _toggleTimelineSelectionMode();
                      },
                      tooltip: 'ノートをまとめる',
                    ),
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      final user = authService.currentUser;
                      return PopupMenuButton<String>(
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Text(
                            _getInitials(user?.displayName ?? user?.email ?? 'U'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'profile':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UserProfileScreen(),
                                ),
                              );
                              break;
                            case 'logout':
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('ログアウト'),
                                  content: const Text('ログアウトしますか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('ログアウト'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (result == true && context.mounted) {
                                await authService.signOut();
                              }
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 12),
                                Text(user?.displayName?.isNotEmpty == true
                                    ? user!.displayName!
                                    : user?.email ?? '匿名ユーザー'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.account_circle),
                                SizedBox(width: 12),
                                Text('プロフィール'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 12),
                                Text('ログアウト'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              body: _pages[_selectedIndex],
              floatingActionButton: _selectedIndex == 0
                  ? FloatingActionButton(
                      onPressed: () => _navigateToEditor(),
                      child: const Icon(Icons.add),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor({double? insertAfterOrder}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(insertAfterOrder: insertAfterOrder),
      ),
    );
  }


  void _toggleTimelineSelectionMode() {
    _timelineKey.currentState?.toggleSelectionMode();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ノートの管理',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansJP',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.archive, color: Colors.orange[700]),
              title: const Text(
                'アーカイブ',
                style: TextStyle(fontFamily: 'NotoSansJP'),
              ),
              subtitle: const Text(
                'アーカイブされたノートを確認',
                style: TextStyle(fontFamily: 'NotoSansJP'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ArchivedNotesScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.search, color: Colors.blue[700]),
              title: const Text(
                'ノート検索',
                style: TextStyle(fontFamily: 'NotoSansJP'),
              ),
              subtitle: const Text(
                'ノートの内容を検索（準備中）',
                style: TextStyle(fontFamily: 'NotoSansJP'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              enabled: false,
              onTap: () {
                // TODO: 検索機能を実装
              },
            ),
          ),
        ],
      ),
    );
  }
}
