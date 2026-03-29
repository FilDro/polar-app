import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get userId => currentUser?.id;

  String? get userRole {
    return currentUser?.userMetadata?['role'] as String?;
  }

  bool get isCoach => userRole == 'coach';
  bool get isAthlete => userRole == 'athlete';

  String _error = '';
  String get error => _error;

  bool _loading = false;
  bool get loading => _loading;

  /// Sign up with email, password, name, and role.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'coach' or 'athlete'
  }) async {
    final client = _client;
    if (client == null) {
      _error = 'Not connected to cloud';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      _error = 'Not connected to cloud';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (_) {}
    notifyListeners();
  }
}
