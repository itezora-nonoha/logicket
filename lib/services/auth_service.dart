import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isInitialized = false;

  String? get userId => _user?.uid;
  bool get isAuthenticated => _user != null;
  User? get currentUser => _user;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initAuth();
  }

  void _initAuth() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      notifyListeners();
      
      // ユーザーがnullの場合のみ匿名ログインを試行
      if (user == null && _isInitialized) {
        _attemptAnonymousSignIn();
      }
    });
  }

  Future<void> _attemptAnonymousSignIn() async {
    try {
      await signInAnonymously();
    } catch (e) {
      debugPrint('自動匿名ログイン失敗: $e');
      // 必要に応じて再試行ロジックを追加
    }
  }

  Future<void> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      _user = result.user;
      notifyListeners();
      debugPrint('匿名ログイン成功: ${_user?.uid}');
    } catch (e) {
      debugPrint('匿名ログインエラー: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ログアウトエラー: $e');
    }
  }
}
