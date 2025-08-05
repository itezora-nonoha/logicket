import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  String? _userId;
  bool _isAuthenticated = true; // 仮想認証：常にログイン状態

  String? get userId => _userId ?? 'demo_user';
  bool get isAuthenticated => _isAuthenticated;

  AuthService() {
    _initAuth();
  }

  void _initAuth() {
    _userId = 'demo_user';
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _userId = 'demo_user';
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _userId = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
