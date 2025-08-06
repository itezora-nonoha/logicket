import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'user_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ユーザー情報カード
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _getInitials(user?.displayName ?? user?.email ?? 'U'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : '未設定',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user?.email ?? '匿名ユーザー'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 設定項目
              _buildSectionTitle(context, 'アプリ設定'),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('通知設定'),
                      subtitle: const Text('プッシュ通知の設定'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 通知設定画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('通知設定は今後実装予定です')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('テーマ設定'),
                      subtitle: const Text('アプリの外観を変更'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: テーマ設定画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('テーマ設定は今後実装予定です')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('データバックアップ'),
                      subtitle: const Text('ノートデータのバックアップ'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: バックアップ画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('バックアップ機能は今後実装予定です')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionTitle(context, 'サポート'),
              const SizedBox(height: 8),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('ヘルプ'),
                      subtitle: const Text('使い方とよくある質問'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: ヘルプ画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ヘルプは今後実装予定です')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text('フィードバック'),
                      subtitle: const Text('ご意見・ご要望をお聞かせください'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: フィードバック画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('フィードバック機能は今後実装予定です')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('アプリについて'),
                      subtitle: const Text('バージョン情報と利用規約'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Logicket',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2024 Logicket. All rights reserved.',
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                'Logicketは、思考を整理し、アイデアを記録するためのノートアプリです。',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // ログアウトボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
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
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('ログアウト'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
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