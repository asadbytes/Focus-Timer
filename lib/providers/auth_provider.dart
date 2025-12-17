import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:focus_timer/models/session.dart';
import 'package:focus_timer/models/sync_operation.dart';
import 'package:focus_timer/models/task.dart';
import 'package:hive_flutter/adapters.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Add callback for post-login data fetch
  Future<void> Function()? onLoginSuccess;

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();

      if (onLoginSuccess != null) {
        await _clearLocalData();
        await onLoginSuccess!();
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _isLoading = false;
      notifyListeners();

      // Trigger data fetch callback if set
      if (onLoginSuccess != null) {
        await _clearLocalData();
        await onLoginSuccess!();
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _clearLocalData();
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case "weak-password":
        return "Password should be at least 6 characters";

      case "email-already-in-use":
        return "An account already exists with this email";

      case "user-not-found":
        return "No account found with this email";

      case "wrong-password":
        return "Incorrect password";

      case "invalid-email":
        return "Invalid email address";

      default:
        return "Authentication failed. Please try again.";
    }
  }

  Future<void> _clearLocalData() async {
    print('🗑️ Clearing local Hive data before cloud sync...');

    final sessionsBox = Hive.box<Session>('sessionsBox');
    final tasksBox = Hive.box<Task>('tasksBox');
    final syncQueue = Hive.box<SyncOperation>('syncQueue');

    await sessionsBox.clear();
    await tasksBox.clear();
    await syncQueue.clear(); // Clear pending operations too

    print('✅ Local data cleared');
  }
}
