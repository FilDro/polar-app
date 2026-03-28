import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Service for offline recording control, polled at ~1Hz.
class RecordingService extends ChangeNotifier {
  Timer? _timer;
  bridge.PolarRecordingState? _state;
  bool _disposed = false;

  bridge.PolarRecordingState? get state => _state;
  bool get isRecording => _state?.isRecording ?? false;
  List<String> get activeTypes => _state?.activeTypes ?? [];
  String get statusText => _state?.statusText ?? '';

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
      _state = bridge.polarPollRecording();
      notifyListeners();
    } catch (e) {
      debugPrint('RecordingService poll error: $e');
    }
  }

  void startRecording(List<String> types) {
    try {
      bridge.polarStartRecording(types: types);
      startPolling();
    } catch (e) {
      debugPrint('RecordingService start error: $e');
    }
  }

  void stopRecording(List<String> types) {
    try {
      bridge.polarStopRecording(types: types);
    } catch (e) {
      debugPrint('RecordingService stop error: $e');
    }
  }

  void checkStatus() {
    try {
      bridge.polarCheckRecordingStatus();
    } catch (e) {
      debugPrint('RecordingService status error: $e');
    }
  }

  void setTrigger(String mode) {
    try {
      bridge.polarSetTrigger(mode: mode);
    } catch (e) {
      debugPrint('RecordingService trigger error: $e');
    }
  }

  void getTrigger() {
    try {
      bridge.polarGetTrigger();
    } catch (e) {
      debugPrint('RecordingService get trigger error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}
