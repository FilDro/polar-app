import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._();
  CloudSyncService._();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _canSync =>
      _client != null && AuthService.instance.isAuthenticated;

  /// Upload a morning wellness entry to Supabase.
  /// Call after saving locally to Drift.
  Future<bool> syncWellness({
    required String athleteId,
    required DateTime date,
    required int restingHr,
    required double lnRmssd,
    required double rmssdMs,
    required int rrCount,
    required String readiness,
    double? baselineMean,
    double? baselineSd,
    double? cv7day,
  }) async {
    if (!_canSync) return false;

    try {
      await _client!.from('daily_wellness').upsert({
        'athlete_id': athleteId,
        'date': date.toIso8601String().substring(0, 10),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'resting_hr': restingHr,
        'ln_rmssd': lnRmssd,
        'rmssd_ms': rmssdMs,
        'rr_count': rrCount,
        'readiness': readiness,
        'baseline_mean': baselineMean,
        'baseline_sd': baselineSd,
        'cv_7day': cv7day,
      }, onConflict: 'athlete_id,date');
      return true;
    } catch (e) {
      debugPrint('Wellness sync failed: $e');
      return false;
    }
  }

  /// Upload a training session to Supabase.
  Future<bool> syncSession({
    required String athleteId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int durationS,
    required double trimpEdwards,
    int? hrAvg,
    int? hrMax,
    required Map<String, dynamic> hrZones,
  }) async {
    if (!_canSync) return false;

    try {
      await _client!.from('sessions').insert({
        'athlete_id': athleteId,
        'date': date.toIso8601String().substring(0, 10),
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'duration_s': durationS,
        'trimp_edwards': trimpEdwards,
        'hr_avg': hrAvg,
        'hr_max': hrMax,
        'hr_zones': hrZones,
      });
      return true;
    } catch (e) {
      debugPrint('Session sync failed: $e');
      return false;
    }
  }
}
