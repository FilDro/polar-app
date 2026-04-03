import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';

/// Manages the local athlete profile, backed by Drift and mirrored to Supabase.
///
/// Call [init] at startup and after sign-in. Call [clear] after sign-out.
/// athlete.id == auth.uid() — this is the invariant that wires RLS on Supabase.
class AthleteService extends ChangeNotifier {
  static final AthleteService instance = AthleteService._();
  AthleteService._();

  Athlete? _dbRow;

  String? get athleteId => _dbRow?.id;
  String get name => _dbRow?.name ?? 'Athlete';
  int get hrMax => _dbRow?.hrMax ?? 195;
  int get hrRest => _dbRow?.hrRest ?? 55;
  String get sensorId => _dbRow?.sensorId ?? '';

  // ── Init / teardown ────────────────────────────────────────────

  /// Load athlete from Drift. If none exists and user is authenticated,
  /// hydrate from Supabase first, then create only if the cloud row does not exist.
  Future<void> init() async {
    final uid = _currentUid();
    if (uid == null) {
      clear();
      return;
    }

    final db = AppDatabase.instance;
    _dbRow = await db.getAthleteById(uid);

    if (_dbRow == null) {
      final hydrated = await _hydrateAthleteFromSupabase(uid);
      if (!hydrated) {
        await _createAthlete(uid);
      }
    }

    notifyListeners();
  }

  /// Clear in-memory state after sign-out.
  void clear() {
    _dbRow = null;
    notifyListeners();
  }

  // ── Update helpers (async, persist to Drift immediately) ───────

  Future<void> updateName(String name) async {
    if (_dbRow == null) return;
    await _upsert(_dbRow!.copyWith(name: name));
  }

  Future<void> updateHrMax(int hrMax) async {
    if (_dbRow == null || hrMax <= 0 || hrMax > 250) return;
    await _upsert(_dbRow!.copyWith(hrMax: Value(hrMax)));
  }

  Future<void> updateHrRest(int hrRest) async {
    if (_dbRow == null || hrRest <= 0 || hrRest > 120) return;
    await _upsert(_dbRow!.copyWith(hrRest: Value(hrRest)));
  }

  Future<void> updateSensorId(String id) async {
    if (_dbRow == null) return;
    await _upsert(_dbRow!.copyWith(sensorId: Value(id)));
  }

  // ── Private helpers ────────────────────────────────────────────

  String? _currentUid() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _createAthlete(String uid) async {
    final db = AppDatabase.instance;
    final name = _currentName();
    await db.upsertAthlete(
      AthletesCompanion(
        id: Value(uid),
        name: Value(name),
        hrMax: const Value(195),
        hrRest: const Value(55),
      ),
    );
    _dbRow = await db.getAthleteById(uid);

    // Mirror to Supabase — best-effort, silently fails when offline
    try {
      await Supabase.instance.client.from('athletes').upsert({
        'id': uid,
        'name': name,
        'hr_max': 195,
        'hr_rest': 55,
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('AthleteService: Supabase athlete create failed: $e');
    }
  }

  Future<bool> _hydrateAthleteFromSupabase(String uid) async {
    try {
      final row = await Supabase.instance.client
          .from('athletes')
          .select('id, name, sensor_id, hr_max, hr_rest')
          .eq('id', uid)
          .maybeSingle();

      if (row == null) {
        return false;
      }

      final db = AppDatabase.instance;
      await db.upsertAthlete(
        AthletesCompanion(
          id: Value(uid),
          name: Value((row['name'] as String?)?.trim().isNotEmpty == true
              ? row['name'] as String
              : 'Athlete'),
          sensorId: Value(row['sensor_id'] as String?),
          hrMax: Value((row['hr_max'] as num?)?.toInt() ?? 195),
          hrRest: Value((row['hr_rest'] as num?)?.toInt() ?? 55),
        ),
      );
      _dbRow = await db.getAthleteById(uid);
      return _dbRow != null;
    } catch (e) {
      debugPrint('AthleteService: Supabase athlete hydrate failed: $e');
      rethrow;
    }
  }

  Future<void> _upsert(Athlete updated) async {
    await AppDatabase.instance.upsertAthlete(
      AthletesCompanion(
        id: Value(updated.id),
        name: Value(updated.name),
        sensorId: Value(updated.sensorId),
        hrMax: Value(updated.hrMax),
        hrRest: Value(updated.hrRest),
      ),
    );
    _dbRow = updated;
    notifyListeners();

    // Mirror updates to Supabase — best-effort for testing build.
    try {
      await Supabase.instance.client.from('athletes').upsert({
        'id': updated.id,
        'name': updated.name,
        'sensor_id': updated.sensorId,
        'hr_max': updated.hrMax,
        'hr_rest': updated.hrRest,
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('AthleteService: Supabase athlete update failed: $e');
    }
  }

  String _currentName() {
    try {
      final metadataName =
          Supabase.instance.client.auth.currentUser?.userMetadata?['name'];
      if (metadataName is String && metadataName.trim().isNotEmpty) {
        return metadataName.trim();
      }
    } catch (_) {}
    return 'Athlete';
  }
}
