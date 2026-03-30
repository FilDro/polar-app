import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Singleton service for device management operations.
///
/// Exposes: restart, factory reset, delete recordings, delete telemetry,
/// trigger setup, and manual time sync.
///
/// Polls device_ops state at 1Hz while an operation is in progress,
/// stopping automatically when idle.
class DeviceService extends ChangeNotifier {
  static final DeviceService instance = DeviceService._();
  DeviceService._();

  Timer? _timer;
  bridge.PolarDeviceOpsState? _state;
  bool _disposed = false;

  bool get isBusy => _state?.isBusy ?? false;
  String get progressText => _state?.progressText ?? '';
  String get error => _state?.error ?? '';

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      try {
        _state = bridge.polarPollDeviceOps();
        if (!isBusy) {
          _timer?.cancel();
          _timer = null;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('DeviceService poll error: $e');
      }
    });
  }

  void restartDevice() {
    bridge.polarDeviceRestart();
    _startPolling();
  }

  void factoryReset() {
    bridge.polarDeviceFactoryReset();
    _startPolling();
  }

  void deleteAllRecordings() {
    bridge.polarDeleteAllRecordings();
    _startPolling();
  }

  void deleteTelemetry() {
    bridge.polarDeleteTelemetry();
    _startPolling();
  }

  void setupTrigger(String mode, List<String> types) {
    bridge.polarSetupTrigger(mode: mode, types: types);
    _startPolling();
  }

  void syncTime() {
    bridge.polarSyncTime();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
