import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api/polar_api.dart' as bridge;

/// Singleton service that polls BLE connection state at ~2Hz.
class BleService extends ChangeNotifier {
  static final BleService instance = BleService._();
  BleService._();

  Timer? _timer;
  bridge.PolarConnectionState? _state;
  bool _disposed = false;

  bridge.PolarConnectionState? get state => _state;

  String get status => _state?.status ?? 'disconnected';
  bool get isConnected => status == 'connected';
  bool get isScanning => status == 'scanning';
  String get deviceName => _state?.deviceName ?? '';
  int get battery => _state?.batteryPercent ?? -1;
  List<bridge.PolarScannedDevice> get devices => _state?.devices ?? [];
  String get error => _state?.error ?? '';

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_disposed) return;
    try {
      _state = bridge.polarPollConnection();
      notifyListeners();
    } catch (e) {
      debugPrint('BleService poll error: $e');
    }
  }

  void startScan() {
    try {
      bridge.polarStartScan();
    } catch (e) {
      debugPrint('BleService scan error: $e');
    }
  }

  void connect(String identifier) {
    try {
      bridge.polarConnect(identifier: identifier);
    } catch (e) {
      debugPrint('BleService connect error: $e');
    }
  }

  void disconnect() {
    try {
      bridge.polarDisconnect();
    } catch (e) {
      debugPrint('BleService disconnect error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}
