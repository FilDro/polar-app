import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Service for syncing training files and computing session summaries.
///
/// Wraps the existing files polling pattern. After sync completes, the screen
/// can call [processSession] to compute TRIMP from the downloaded HR data.
class SyncSessionService extends ChangeNotifier {
  Timer? _timer;
  bridge.PolarFilesState? _state;
  bridge.PolarSessionSummary? _sessionSummary;
  bool _disposed = false;

  bridge.PolarFilesState? get state => _state;

  bool get isSyncing => _state?.isSyncing ?? false;
  String get progressText => _state?.progressText ?? '';
  String get error => _state?.error ?? '';
  List<bridge.PolarDownloadedCsv> get downloads =>
      _state?.downloadedCsvs ?? [];
  bridge.PolarSessionSummary? get sessionSummary => _sessionSummary;

  /// True when sync has finished and downloads are available.
  bool get syncComplete =>
      _state != null && !isSyncing && downloads.isNotEmpty;

  /// Start syncing files from the sensor.
  void startSync() {
    _sessionSummary = null;
    try {
      bridge.polarSyncFiles();
      _startPolling();
    } catch (e) {
      debugPrint('SyncSessionService sync error: $e');
    }
  }

  /// Process the downloaded HR data into a session summary.
  /// [hrMax] and [hrRest] come from the athlete profile.
  void processSession({required int hrMax, required int hrRest}) {
    try {
      _sessionSummary = bridge.polarProcessSession(
        hrMax: hrMax,
        hrRest: hrRest,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('SyncSessionService process error: $e');
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_disposed) return;
    try {
      final prev = _state;
      _state = bridge.polarPollFiles();

      // Auto-stop polling once sync finishes
      if (prev?.isSyncing == true && !isSyncing) {
        _stopPolling();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('SyncSessionService poll error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
