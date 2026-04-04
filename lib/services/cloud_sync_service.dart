import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
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

  /// Pull wellness history from Supabase into local Drift DB.
  Future<int> pullWellness(String athleteId) async {
    if (!_canSync) return 0;

    try {
      final rows = await _client!
          .from('daily_wellness')
          .select(
            'athlete_id, date, resting_hr, ln_rmssd, rmssd_ms, rr_count, '
            'readiness, baseline_mean, baseline_sd, cv_7day',
          )
          .eq('athlete_id', athleteId)
          .order('date');

      final db = AppDatabase.instance;
      int count = 0;
      for (final row in rows) {
        final date = DateTime.parse(row['date'] as String);
        await db.upsertWellness(DailyWellnessEntriesCompanion(
          athleteId: Value(athleteId),
          date: Value(date),
          restingHr: Value((row['resting_hr'] as num).toInt()),
          lnRmssd: Value((row['ln_rmssd'] as num).toDouble()),
          rmssdMs: Value((row['rmssd_ms'] as num).toDouble()),
          rrCount: Value((row['rr_count'] as num).toInt()),
          readiness: Value(row['readiness'] as String? ?? 'building'),
          stability: const Value(''),
          baselineMean: Value((row['baseline_mean'] as num?)?.toDouble()),
          baselineSd: Value((row['baseline_sd'] as num?)?.toDouble()),
          cv7day: Value((row['cv_7day'] as num?)?.toDouble()),
          dayCount: const Value(0),
        ));
        count++;
      }
      debugPrint('CloudSync: pulled $count wellness entries');
      return count;
    } catch (e) {
      debugPrint('Wellness pull failed: $e');
      return 0;
    }
  }

  /// Pull session history from Supabase into local Drift DB.
  Future<int> pullSessions(String athleteId) async {
    if (!_canSync) return 0;

    try {
      final rows = await _client!
          .from('sessions')
          .select(
            'athlete_id, date, start_time, end_time, duration_s, '
            'trimp_edwards, hr_avg, hr_max, hr_zones',
          )
          .eq('athlete_id', athleteId)
          .order('date');

      final db = AppDatabase.instance;
      int count = 0;
      for (final row in rows) {
        final startTime = DateTime.parse(row['start_time'] as String);

        if (await db.sessionExists(athleteId, startTime)) continue;

        final endTimeStr = row['end_time'] as String?;
        final hrZones = row['hr_zones'] as Map<String, dynamic>? ?? {};

        await db.insertSession(SessionEntriesCompanion.insert(
          athleteId: athleteId,
          date: DateTime.parse(row['date'] as String),
          startTime: startTime,
          endTime: Value(endTimeStr != null ? DateTime.parse(endTimeStr) : null),
          durationS: (row['duration_s'] as num).toInt(),
          trimpEdwards: (row['trimp_edwards'] as num).toDouble(),
          hrAvg: (row['hr_avg'] as num?)?.toDouble() ?? 0.0,
          hrMax: (row['hr_max'] as num?)?.toInt() ?? 0,
          hrMin: 0,
          zoneSecondsJson: jsonEncode(hrZones['zone_seconds'] ?? {}),
          zonePercentJson: jsonEncode(hrZones['zone_percent'] ?? {}),
        ));
        count++;
      }
      debugPrint('CloudSync: pulled $count session entries');
      return count;
    } catch (e) {
      debugPrint('Session pull failed: $e');
      return 0;
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
