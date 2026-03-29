import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Service that drives the morning HRV check.
///
/// Polls [polarPollMorningCheck()] at ~10Hz during an active check.
/// The compute step (calling [polarComputeMorningResult]) is intentionally
/// left to the screen so it can supply baseline history without creating
/// a circular dependency on the database layer.
class MorningCheckService extends ChangeNotifier {
  Timer? _timer;
  bridge.PolarMorningCheckState? _state;
  bool _disposed = false;

  bridge.PolarMorningCheckState? get state => _state;

  String get phase => _state?.phase ?? 'idle';
  double get elapsedS => _state?.elapsedS ?? 0;
  int get hrBpm => _state?.hrBpm ?? 0;
  int get ppiCount => _state?.ppiCount ?? 0;
  bridge.PolarMorningResult? get result => _state?.result;
  String get error => _state?.error ?? '';

  bool get isActive =>
      phase == 'warmup' || phase == 'recording' || phase == 'computing';

  /// Start the morning check on the Rust side and begin polling.
  void startCheck() {
    try {
      bridge.polarStartMorningCheck();
      _startPolling();
    } catch (e) {
      debugPrint('MorningCheckService start error: $e');
    }
  }

  /// Stop the morning check.
  void stopCheck() {
    _stopPolling();
    try {
      bridge.polarStopMorningCheck();
    } catch (e) {
      debugPrint('MorningCheckService stop error: $e');
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_disposed) return;
    try {
      _state = bridge.polarPollMorningCheck();
      notifyListeners();
    } catch (e) {
      debugPrint('MorningCheckService poll error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
