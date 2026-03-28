import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Service for file listing, downloading, and sync. Polled at ~1Hz.
class FilesService extends ChangeNotifier {
  Timer? _timer;
  bridge.PolarFilesState? _state;
  bool _disposed = false;

  bridge.PolarFilesState? get state => _state;
  bool get isSyncing => _state?.isSyncing ?? false;
  List<bridge.PolarFileEntry> get entries => _state?.entries ?? [];
  List<bridge.PolarDownloadedCsv> get downloads => _state?.downloadedCsvs ?? [];
  String get progressText => _state?.progressText ?? '';

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_disposed) return;
    try {
      _state = bridge.polarPollFiles();
      notifyListeners();
    } catch (e) {
      debugPrint('FilesService poll error: $e');
    }
  }

  void listFiles() {
    try {
      bridge.polarListFiles();
      startPolling();
    } catch (e) {
      debugPrint('FilesService list error: $e');
    }
  }

  void syncFiles() {
    try {
      bridge.polarSyncFiles();
      startPolling();
    } catch (e) {
      debugPrint('FilesService sync error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}
