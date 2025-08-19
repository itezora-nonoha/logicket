import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasStartedLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, NoteService>(
      builder: (context, authService, noteService, child) {
        // Firebase認証の初期化待ち
        if (!authService.isInitialized) {
          return _buildLoadingScreen('Firebase初期化中...');
        }

        // 認証状態に応じて画面を切り替え
        if (authService.isAuthenticated) {
          // 認証済みの場合、ノートのプリロードを開始
          if (!_hasStartedLoading && authService.userId != null) {
            _hasStartedLoading = true;
            // 次のフレームでロード開始（UI描画をブロックしない）
            WidgetsBinding.instance.addPostFrameCallback((_) {
              noteService.loadNotes(authService.userId!);
            });
          }

          // ノートロード中の場合、ロード状態を表示
          if (noteService.isLoading) {
            return _buildLoadingScreen('ノートを読み込み中...', showSkip: true);
          }

          return const HomeScreen();
        } else {
          _hasStartedLoading = false;
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen(String message, {bool showSkip = false}) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴまたはアプリ名
            Text(
              'Logicket',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 48),
            
            // ローディングインジケーター
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            
            // ロード状況
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'NotoSansJP',
              ),
            ),
            
            // スキップボタン（ノートロード時のみ）
            if (showSkip) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  // ノートサービスのロードを停止してホーム画面へ
                  context.read<NoteService>().cancelLoading();
                  setState(() {});
                },
                child: const Text(
                  'スキップして開始',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NotoSansJP',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}