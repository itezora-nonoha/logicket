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
    });
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      notifyListeners();
      debugPrint('メールログイン成功: ${_user?.uid}');
      return result;
    } catch (e) {
      debugPrint('メールログインエラー: $e');
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      notifyListeners();
      debugPrint('ユーザー作成成功: ${_user?.uid}');
      return result;
    } catch (e) {
      debugPrint('ユーザー作成エラー: $e');
      rethrow;
    }
  }

  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://logicket.firebaseapp.com/finishSignUp',
        handleCodeInApp: true,
        androidPackageName: 'com.example.logicket',
        iOSBundleId: 'com.example.logicket',
      );
      
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      debugPrint('サインインリンクを送信: $email');
    } catch (e) {
      debugPrint('サインインリンク送信エラー: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailLink(String email, String emailLink) async {
    try {
      final UserCredential result = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      _user = result.user;
      notifyListeners();
      debugPrint('メールリンクログイン成功: ${_user?.uid}');
      return result;
    } catch (e) {
      debugPrint('メールリンクログインエラー: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('パスワードリセットメール送信: $email');
    } catch (e) {
      debugPrint('パスワードリセットメール送信エラー: $e');
      rethrow;
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

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _user?.updateDisplayName(displayName);
      await _user?.reload();
      _user = _auth.currentUser;
      notifyListeners();
      debugPrint('表示名更新成功: $displayName');
    } catch (e) {
      debugPrint('表示名更新エラー: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
        debugPrint('メール確認送信成功');
      }
    } catch (e) {
      debugPrint('メール確認送信エラー: $e');
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
