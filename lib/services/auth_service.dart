import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'athlete_service.dart';
import 'cloud_sync_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  bool _sessionSyncInProgress = false;

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
  String? get userEmail => currentUser?.email;
  bool get initialized => _initialized;
  bool get ready => _initialized && !_sessionSyncInProgress;
  bool get canAccessAthleteApp => isAuthenticated && !isCoach;

  String? get userRole {
    return currentUser?.userMetadata?['role'] as String?;
  }

  bool get isCoach => userRole == 'coach';
  bool get isAthlete => userRole == 'athlete';

  String _error = '';
  String get error => _error;

  bool _loading = false;
  bool get loading => _loading;

  /// Initialize auth state and start reacting to session changes.
  Future<void> init() async {
    if (_initialized) return;

    final client = _client;
    if (client == null) {
      _initialized = true;
      notifyListeners();
      return;
    }

    _authSubscription = client.auth.onAuthStateChange.listen((state) {
      unawaited(_syncSession(state.session));
    });

    await _syncSession(client.auth.currentSession);
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    if (_error.isEmpty) return;
    _error = '';
    notifyListeners();
  }

  /// Sign up with email, password, and name for the athlete testing build.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
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
        data: {'name': name, 'role': 'athlete'},
      );

      // Testing build assumes email confirmation is disabled, but sign in
      // explicitly if Supabase returns no immediate session.
      if (client.auth.currentSession == null) {
        await client.auth.signInWithPassword(email: email, password: password);
      }

      await _syncSession(client.auth.currentSession);
      return canAccessAthleteApp;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password.
  Future<bool> signIn({required String email, required String password}) async {
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
      await client.auth.signInWithPassword(email: email, password: password);

      await _syncSession(client.auth.currentSession);
      return canAccessAthleteApp;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _error = '';
    _loading = true;
    notifyListeners();
    try {
      await _client?.auth.signOut();
    } catch (_) {}
    AthleteService.instance.clear();
    _loading = false;
    notifyListeners();
  }

  Future<void> _syncSession(Session? session) async {
    _sessionSyncInProgress = true;
    notifyListeners();

    try {
      if (session == null) {
        AthleteService.instance.clear();
        return;
      }

      if (!_supportsAthleteSession(session)) {
        _error = 'This testing build supports athlete accounts only.';
        try {
          await _client?.auth.signOut();
        } catch (_) {}
        AthleteService.instance.clear();
        return;
      }

      await AthleteService.instance.init();

      // Hydrate wellness & session history from Supabase
      final uid = session.user.id;
      await Future.wait([
        CloudSyncService.instance.pullWellness(uid),
        CloudSyncService.instance.pullSessions(uid),
      ]);
    } catch (e) {
      _error = 'Failed to load athlete profile. Please sign in again.';
      debugPrint('AuthService session sync failed: $e');
      try {
        await _client?.auth.signOut();
      } catch (_) {}
      AthleteService.instance.clear();
    } finally {
      _sessionSyncInProgress = false;
      notifyListeners();
    }
  }

  String? _roleForSession(Session session) {
    return session.user.userMetadata?['role'] as String?;
  }

  bool _supportsAthleteSession(Session session) {
    final role = _roleForSession(session);
    return role == null || role == 'athlete';
  }
}
