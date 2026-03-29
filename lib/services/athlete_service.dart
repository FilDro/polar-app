import 'package:flutter/foundation.dart';

/// Manages the local athlete profile.
///
/// For V1 this is a simple in-memory store with sensible defaults.
/// Will be backed by the Drift database once Phase 4 is wired up.
class AthleteService extends ChangeNotifier {
  static final AthleteService instance = AthleteService._();
  AthleteService._();

  String _name = 'Athlete';
  int _hrMax = 195;
  int _hrRest = 55;
  String _sensorId = '';

  String get name => _name;
  int get hrMax => _hrMax;
  int get hrRest => _hrRest;
  String get sensorId => _sensorId;

  void updateName(String name) {
    _name = name;
    notifyListeners();
  }

  void updateHrMax(int hrMax) {
    if (hrMax > 0 && hrMax <= 250) {
      _hrMax = hrMax;
      notifyListeners();
    }
  }

  void updateHrRest(int hrRest) {
    if (hrRest > 0 && hrRest <= 120) {
      _hrRest = hrRest;
      notifyListeners();
    }
  }

  void updateSensorId(String id) {
    _sensorId = id;
    notifyListeners();
  }

  // TODO: Load from DB on init once Phase 4 is wired up
  // Future<void> loadFromDb() async { ... }
}
