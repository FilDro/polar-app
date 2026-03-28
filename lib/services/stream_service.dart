import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Per-session service that polls streaming data at ~30Hz.
class StreamService extends ChangeNotifier {
  Timer? _timer;
  bridge.PolarStreamState? _state;
  bool _disposed = false;

  bridge.PolarStreamState? get state => _state;
  bool get isStreaming => _state?.isStreaming ?? false;

  void startStream(String config) {
    try {
      bridge.polarStartStream(config: config);
      _startPolling();
    } catch (e) {
      debugPrint('StreamService start error: $e');
    }
  }

  void stopStream() {
    _stopPolling();
    try {
      bridge.polarStopStream();
    } catch (e) {
      debugPrint('StreamService stop error: $e');
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_disposed) return;
    try {
      _state = bridge.polarPollStream();
      notifyListeners();
    } catch (e) {
      debugPrint('StreamService poll error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
