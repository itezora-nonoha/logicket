// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class AuthService extends ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   User? _user;

//   String? get userId => _user?.uid;
//   bool get isAuthenticated => _user != null;
//   User? get currentUser => _user;

//   AuthService() {
//     _initAuth();
//   }

//   void _initAuth() {
//     _auth.authStateChanges().listen((User? user) {
//       _user = user;
//       notifyListeners();
//     });
    
//     // 自動的に匿名ログイン
//     if (_auth.currentUser == null) {
//       signInAnonymously();
//     }
//   }

//   Future<void> signInAnonymously() async {
//     try {
//       final UserCredential result = await _auth.signInAnonymously();
//       _user = result.user;
//       notifyListeners();
//     } catch (e) {
//       debugPrint('匿名ログインエラー: $e');
//     }
//   }

//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//       _user = null;
//       notifyListeners();
//     } catch (e) {
//       debugPrint('ログアウトエラー: $e');
//     }
//   }
// }
