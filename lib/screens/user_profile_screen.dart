import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _displayNameController.text = authService.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateDisplayName(_displayNameController.text.trim());
      
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('確認メールを送信しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー情報'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: '編集',
            ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          
          if (user == null) {
            return const Center(
              child: Text('ユーザー情報を取得できませんでした'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // プロフィール画像（今後の実装用）
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _getInitials(user.displayName ?? user.email ?? 'U'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 基本情報セクション
                _buildSectionTitle('基本情報'),
                const SizedBox(height: 16),
                
                // 表示名
                if (_isEditing) ...[
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: '表示名',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().length > 50) {
                          return '表示名は50文字以内で入力してください';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('保存'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _displayNameController.text = user.displayName ?? '';
                          });
                        },
                        child: const Text('キャンセル'),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildInfoCard(
                    icon: Icons.person,
                    title: '表示名',
                    content: user.displayName?.isNotEmpty == true 
                        ? user.displayName! 
                        : '未設定',
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // メールアドレス
                _buildInfoCard(
                  icon: Icons.email,
                  title: 'メールアドレス',
                  content: user.email ?? '匿名ユーザー',
                  trailing: user.email != null
                      ? (user.emailVerified
                          ? const Chip(
                              label: Text('確認済み'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : TextButton(
                              onPressed: _sendEmailVerification,
                              child: const Text('確認メール送信'),
                            ))
                      : null,
                ),
                
                const SizedBox(height: 16),
                
                // UID（デバッグ用）
                _buildInfoCard(
                  icon: Icons.fingerprint,
                  title: 'ユーザーID',
                  content: user.uid,
                  isSelectable: true,
                ),
                
                const SizedBox(height: 16),
                
                // 作成日時
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'アカウント作成日',
                  content: user.metadata.creationTime != null
                      ? _formatDateTime(user.metadata.creationTime!)
                      : '不明',
                ),
                
                const SizedBox(height: 16),
                
                // 最終ログイン
                _buildInfoCard(
                  icon: Icons.access_time,
                  title: '最終ログイン',
                  content: user.metadata.lastSignInTime != null
                      ? _formatDateTime(user.metadata.lastSignInTime!)
                      : '不明',
                ),
                
                const SizedBox(height: 32),
                
                // アカウント管理セクション
                _buildSectionTitle('アカウント管理'),
                const SizedBox(height: 16),
                
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
                      
                      if (result == true && mounted) {
                        await authService.signOut();
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('ログアウト'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    Widget? trailing,
    bool isSelectable = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  isSelectable
                      ? SelectableText(
                          content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : Text(
                          content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}