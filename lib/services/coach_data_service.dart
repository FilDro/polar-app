import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coach_models.dart';

/// Service that loads coach dashboard data from Supabase.
///
/// For V1, gracefully falls back to sample data when the backend
/// is unavailable so the UI can render and be tested.
class CoachDataService extends ChangeNotifier {
  static final CoachDataService instance = CoachDataService._();
  CoachDataService._();

  // --- State ---

  bool _loading = false;
  bool get loading => _loading;

  String _error = '';
  String get error => _error;

  List<AthleteReadiness> _todayReadiness = [];
  List<AthleteReadiness> get todayReadiness => _todayReadiness;

  List<AthleteSession> _todaySessions = [];
  List<AthleteSession> get todaySessions => _todaySessions;

  // Roster for athlete picker in trends tab
  List<({String id, String name})> _roster = [];
  List<({String id, String name})> get roster => _roster;

  AthleteTrend? _currentTrend;
  AthleteTrend? get currentTrend => _currentTrend;

  List<TeamAthleteRow> _teamRows = [];
  List<TeamAthleteRow> get teamRows => _teamRows;

  List<TeamAlert> _alerts = [];
  List<TeamAlert> get alerts => _alerts;

  int get totalRoster => _roster.length;
  int get checkedInCount =>
      _todayReadiness.where((r) => r.hasData).length;

  // --- Supabase client ---

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // --- Load methods ---

  /// Load today's morning readiness for all team athletes.
  Future<void> loadTodayReadiness() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final client = _client;
      if (client == null) throw Exception('Not connected to cloud');

      final today = _todayString();

      final res = await client
          .from('daily_wellness')
          .select('*, athletes(id, name)')
          .eq('date', today);

      final rosterRes = await client.from('athletes').select('id, name');

      final rosterList = (rosterRes as List)
          .map((r) => (id: r['id'] as String, name: r['name'] as String))
          .toList();
      _roster = rosterList;

      final checkedIn = <String, Map<String, dynamic>>{};
      for (final row in (res as List)) {
        final athleteId = row['athlete_id'] as String;
        checkedIn[athleteId] = row;
      }

      _todayReadiness = rosterList.map((a) {
        final data = checkedIn[a.id];
        if (data != null) {
          return AthleteReadiness(
            athleteId: a.id,
            name: a.name,
            readiness: data['readiness'] as String? ?? '',
            restingHr: data['resting_hr'] as int? ?? 0,
            lnRmssd: (data['ln_rmssd'] as num?)?.toDouble() ?? 0.0,
            hasData: true,
          );
        } else {
          return AthleteReadiness(
            athleteId: a.id,
            name: a.name,
            readiness: '',
            restingHr: 0,
            lnRmssd: 0.0,
            hasData: false,
          );
        }
      }).toList()
        ..sort((a, b) => a.sortPriority.compareTo(b.sortPriority));

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      // Fall back to sample data so the UI is testable
      _loadSampleReadiness();
      notifyListeners();
    }
  }

  /// Load today's sessions for all athletes.
  Future<void> loadTodaySessions() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final client = _client;
      if (client == null) throw Exception('Not connected to cloud');

      final today = _todayString();

      final res = await client
          .from('sessions')
          .select('*, athletes(id, name)')
          .eq('date', today)
          .order('trimp_edwards', ascending: false);

      _todaySessions = (res as List).map((row) {
        final zones = row['hr_zones'] as Map<String, dynamic>? ?? {};
        final zp = zones['zone_percent'] as Map<String, dynamic>? ?? {};
        return AthleteSession(
          athleteId: row['athlete_id'] as String,
          name: (row['athletes'] as Map?)?['name'] as String? ?? '?',
          trimp: (row['trimp_edwards'] as num?)?.toDouble() ?? 0.0,
          hrAvg: row['hr_avg'] as int? ?? 0,
          hrMax: row['hr_max'] as int? ?? 0,
          durationMin: ((row['duration_s'] as int? ?? 0) / 60).round(),
          zonePercent: [
            (zp['below_z1'] as num?)?.toDouble() ?? 0,
            (zp['z1'] as num?)?.toDouble() ?? 0,
            (zp['z2'] as num?)?.toDouble() ?? 0,
            (zp['z3'] as num?)?.toDouble() ?? 0,
            (zp['z4'] as num?)?.toDouble() ?? 0,
            (zp['z5'] as num?)?.toDouble() ?? 0,
          ],
        );
      }).toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      _loadSampleSessions();
      notifyListeners();
    }
  }

  /// Load trend data for one athlete over [days] days.
  Future<void> loadAthleteTrend(String athleteId,
      {int days = 28}) async {
    _loading = true;
    _error = '';
    _currentTrend = null;
    notifyListeners();

    try {
      final client = _client;
      if (client == null) throw Exception('Not connected to cloud');

      final startDate = DateTime.now().subtract(Duration(days: days));
      final startStr =
          '${startDate.year}-${_pad(startDate.month)}-${_pad(startDate.day)}';

      final athleteRes =
          await client.from('athletes').select('name').eq('id', athleteId).single();
      final name = athleteRes['name'] as String;

      final wellnessRes = await client
          .from('daily_wellness')
          .select()
          .eq('athlete_id', athleteId)
          .gte('date', startStr)
          .order('date');

      final sessionsRes = await client
          .from('sessions')
          .select()
          .eq('athlete_id', athleteId)
          .gte('date', startStr)
          .order('date');

      // Build day-by-day map
      final dayMap = <String, AthleteTrendDay>{};
      for (final w in (wellnessRes as List)) {
        final date = w['date'] as String;
        dayMap[date] = AthleteTrendDay(
          date: DateTime.parse(date),
          lnRmssd: (w['ln_rmssd'] as num?)?.toDouble(),
          readiness: w['readiness'] as String?,
          restingHr: w['resting_hr'] as int?,
        );
      }
      for (final s in (sessionsRes as List)) {
        final date = s['date'] as String;
        final existing = dayMap[date];
        dayMap[date] = AthleteTrendDay(
          date: DateTime.parse(date),
          lnRmssd: existing?.lnRmssd,
          readiness: existing?.readiness,
          restingHr: existing?.restingHr,
          trimp: (s['trimp_edwards'] as num?)?.toDouble(),
        );
      }

      final trendDays = dayMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Compute ACWR, monotony, strain
      final now = DateTime.now();
      final last7 = trendDays
          .where((d) => now.difference(d.date).inDays < 7)
          .toList();
      final last28 = trendDays
          .where((d) => now.difference(d.date).inDays < 28)
          .toList();

      final acuteLoad = last7.fold(0.0, (s, d) => s + (d.trimp ?? 0));
      final dailyTrimpLast28 =
          last28.map((d) => d.trimp ?? 0.0).toList();
      final chronicLoad = dailyTrimpLast28.isEmpty
          ? 0.0
          : (dailyTrimpLast28.fold(0.0, (s, v) => s + v) / 28) * 7;

      double? acwr;
      if (chronicLoad > 0) {
        acwr = acuteLoad / chronicLoad;
      }

      // Monotony = mean(7d TRIMP) / sd(7d TRIMP)
      double? monotony;
      double? strain;
      if (last7.isNotEmpty) {
        final trimps7 = last7.map((d) => d.trimp ?? 0.0).toList();
        final mean7 =
            trimps7.fold(0.0, (s, v) => s + v) / trimps7.length;
        final variance7 = trimps7.fold(
                0.0, (s, v) => s + (v - mean7) * (v - mean7)) /
            trimps7.length;
        final sd7 = _sqrt(variance7);
        if (sd7 > 0) {
          monotony = mean7 / sd7;
          strain = acuteLoad * monotony;
        }
      }

      _currentTrend = AthleteTrend(
        athleteId: athleteId,
        name: name,
        days: trendDays,
        acuteLoad: acuteLoad,
        chronicLoad: chronicLoad,
        acwr: acwr,
        monotony: monotony,
        strain: strain,
      );

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      _loadSampleTrend(athleteId, days: days);
      notifyListeners();
    }
  }

  /// Load team summary for the current week.
  Future<void> loadTeamSummary() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final client = _client;
      if (client == null) throw Exception('Not connected to cloud');

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr =
          '${weekStart.year}-${_pad(weekStart.month)}-${_pad(weekStart.day)}';
      final last28Start = now.subtract(const Duration(days: 28));
      final last28Str =
          '${last28Start.year}-${_pad(last28Start.month)}-${_pad(last28Start.day)}';

      final rosterRes = await client.from('athletes').select('id, name');
      _roster = (rosterRes as List)
          .map((r) => (id: r['id'] as String, name: r['name'] as String))
          .toList();

      // Fetch this week's sessions and last 28 days
      final weekSessions = await client
          .from('sessions')
          .select('athlete_id, trimp_edwards')
          .gte('date', weekStartStr);

      final last28Sessions = await client
          .from('sessions')
          .select('athlete_id, trimp_edwards, date')
          .gte('date', last28Str);

      // Today's readiness
      final todayStr = _todayString();
      final todayWellness = await client
          .from('daily_wellness')
          .select('athlete_id, readiness')
          .eq('date', todayStr);

      // Last 7 days readiness for red day count
      final last7Start = now.subtract(const Duration(days: 7));
      final last7Str =
          '${last7Start.year}-${_pad(last7Start.month)}-${_pad(last7Start.day)}';
      final last7Wellness = await client
          .from('daily_wellness')
          .select('athlete_id, readiness')
          .gte('date', last7Str);

      // Build per-athlete maps
      final weekTrimps = <String, double>{};
      for (final s in (weekSessions as List)) {
        final id = s['athlete_id'] as String;
        weekTrimps[id] =
            (weekTrimps[id] ?? 0) + ((s['trimp_edwards'] as num?)?.toDouble() ?? 0);
      }

      // 28-day chronic for each athlete
      final chronicMap = <String, double>{};
      for (final s in (last28Sessions as List)) {
        final id = s['athlete_id'] as String;
        chronicMap[id] =
            (chronicMap[id] ?? 0) + ((s['trimp_edwards'] as num?)?.toDouble() ?? 0);
      }

      final todayReadinessMap = <String, String>{};
      for (final w in (todayWellness as List)) {
        todayReadinessMap[w['athlete_id'] as String] =
            w['readiness'] as String? ?? '';
      }

      final redDayMap = <String, int>{};
      for (final w in (last7Wellness as List)) {
        final id = w['athlete_id'] as String;
        if (w['readiness'] == 'red') {
          redDayMap[id] = (redDayMap[id] ?? 0) + 1;
        }
      }

      _teamRows = _roster.map((a) {
        final weekTrimp = weekTrimps[a.id] ?? 0;
        final chronicTotal = chronicMap[a.id] ?? 0;
        final chronic = (chronicTotal / 28) * 7;
        double? acwr;
        if (chronic > 0) acwr = weekTrimp / chronic;

        return TeamAthleteRow(
          athleteId: a.id,
          name: a.name,
          weekTrimp: weekTrimp,
          acwr: acwr,
          riskLevel: _acwrRisk(acwr),
          readiness: todayReadinessMap[a.id] ?? '',
          redDays: redDayMap[a.id] ?? 0,
        );
      }).toList();

      // Generate alerts
      _alerts = _computeAlerts(_teamRows);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      _loadSampleTeam();
      notifyListeners();
    }
  }

  // --- Alert computation ---

  List<TeamAlert> _computeAlerts(List<TeamAthleteRow> rows) {
    final alerts = <TeamAlert>[];

    for (final row in rows) {
      // ACWR > 1.5 = high
      if (row.acwr != null && row.acwr! > 1.5) {
        alerts.add(TeamAlert(
          message:
              '${row.name}: ACWR ${row.acwr!.toStringAsFixed(2)} — high injury risk',
          priority: 'high',
        ));
      }

      // Red readiness 3+ consecutive days
      if (row.redDays >= 3) {
        alerts.add(TeamAlert(
          message:
              '${row.name}: RED readiness ${row.redDays} consecutive days',
          priority: 'high',
        ));
      }
    }

    // Missing check-in today
    final missingCount = rows.where((r) => r.readiness.isEmpty).length;
    if (missingCount > 0) {
      alerts.add(TeamAlert(
        message: '$missingCount athlete${missingCount == 1 ? '' : 's'}'
            ' ha${missingCount == 1 ? 's' : 've'} not checked in today',
        priority: 'low',
      ));
    }

    alerts.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
    return alerts;
  }

  // --- Sample / fallback data ---

  void _loadSampleReadiness() {
    const names = [
      'Kowalski',
      'Nowak',
      'Wisniewski',
      'Lewandowski',
      'Kaminski',
      'Wojcik',
      'Zielinski',
      'Szymanski',
      'Wozniak',
      'Dabrowski',
      'Kozlowski',
      'Jankowski',
      'Mazur',
      'Kwiatkowski',
      'Krawczyk',
      'Piotrowski',
      'Grabowski',
      'Nowakowski',
      'Pawlowski',
      'Michalski',
      'Adamczyk',
      'Dudek',
    ];

    const readinessValues = [
      'green', 'green', 'amber', 'red', 'green', 'green', 'green', '', //
      'green', 'green', 'amber', 'green', 'green', 'red', 'green', 'green',
      'green', 'green', '', '', '', '',
    ];

    const hrs = [54, 61, 68, 72, 58, 55, 52, 0, 56, 59, 65, 57, 53, 74, 60, 55, 58, 54, 0, 0, 0, 0];
    const rmssd = [4.31, 4.18, 3.89, 3.42, 4.25, 4.35, 4.41, 0.0, 4.22, 4.15, 3.95, 4.28, 4.38, 3.51, 4.12, 4.33, 4.19, 4.30, 0.0, 0.0, 0.0, 0.0];

    _roster = List.generate(names.length,
        (i) => (id: 'sample-$i', name: names[i]));

    _todayReadiness = List.generate(names.length, (i) {
      final r = readinessValues[i];
      return AthleteReadiness(
        athleteId: 'sample-$i',
        name: names[i],
        readiness: r,
        restingHr: hrs[i],
        lnRmssd: rmssd[i],
        hasData: r.isNotEmpty,
      );
    })
      ..sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
  }

  void _loadSampleSessions() {
    _todaySessions = [
      const AthleteSession(
        athleteId: 'sample-3',
        name: 'Lewandowski',
        trimp: 243,
        hrAvg: 156,
        hrMax: 192,
        durationMin: 86,
        zonePercent: [3.6, 15.2, 26.8, 22.1, 18.4, 13.9],
      ),
      const AthleteSession(
        athleteId: 'sample-0',
        name: 'Kowalski',
        trimp: 187,
        hrAvg: 142,
        hrMax: 188,
        durationMin: 86,
        zonePercent: [5.1, 22.3, 30.2, 20.5, 14.2, 7.7],
      ),
      const AthleteSession(
        athleteId: 'sample-1',
        name: 'Nowak',
        trimp: 175,
        hrAvg: 138,
        hrMax: 181,
        durationMin: 86,
        zonePercent: [6.2, 25.4, 31.1, 18.8, 12.3, 6.2],
      ),
      const AthleteSession(
        athleteId: 'sample-2',
        name: 'Wisniewski',
        trimp: 162,
        hrAvg: 135,
        hrMax: 178,
        durationMin: 82,
        zonePercent: [7.8, 28.1, 29.5, 17.2, 11.5, 5.9],
      ),
      const AthleteSession(
        athleteId: 'sample-4',
        name: 'Kaminski',
        trimp: 155,
        hrAvg: 132,
        hrMax: 175,
        durationMin: 86,
        zonePercent: [9.1, 30.0, 28.8, 16.4, 10.2, 5.5],
      ),
      const AthleteSession(
        athleteId: 'sample-5',
        name: 'Wojcik',
        trimp: 148,
        hrAvg: 128,
        hrMax: 172,
        durationMin: 84,
        zonePercent: [10.5, 32.2, 27.8, 15.1, 9.5, 4.9],
      ),
      const AthleteSession(
        athleteId: 'sample-6',
        name: 'Zielinski',
        trimp: 140,
        hrAvg: 125,
        hrMax: 170,
        durationMin: 86,
        zonePercent: [12.0, 34.1, 26.3, 14.0, 8.8, 4.8],
      ),
      const AthleteSession(
        athleteId: 'sample-8',
        name: 'Wozniak',
        trimp: 132,
        hrAvg: 122,
        hrMax: 168,
        durationMin: 80,
        zonePercent: [13.4, 35.6, 25.0, 13.2, 8.2, 4.6],
      ),
    ];
  }

  void _loadSampleTrend(String athleteId, {int days = 28}) {
    final now = DateTime.now();
    final trendDays = List.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final hasSession = date.weekday <= 5; // M-F training
      final hasMorning = i % 7 != 6; // skip one day per week

      return AthleteTrendDay(
        date: date,
        lnRmssd: hasMorning ? 4.0 + (i % 7) * 0.08 - (i % 3) * 0.05 : null,
        readiness: hasMorning
            ? (i == 5 || i == 12 ? 'amber' : (i == 19 ? 'red' : 'green'))
            : null,
        restingHr: hasMorning ? 55 + (i % 5) : null,
        trimp: hasSession ? 120.0 + (i % 7) * 20 - (i % 3) * 15 : null,
      );
    });

    final last7 =
        trendDays.where((d) => now.difference(d.date).inDays < 7).toList();
    final acuteLoad = last7.fold(0.0, (s, d) => s + (d.trimp ?? 0));
    final allTrimp = trendDays.map((d) => d.trimp ?? 0.0).toList();
    final chronicLoad =
        (allTrimp.fold(0.0, (s, v) => s + v) / 28) * 7;
    double? acwr;
    if (chronicLoad > 0) acwr = acuteLoad / chronicLoad;

    final trimps7 = last7.map((d) => d.trimp ?? 0.0).toList();
    final mean7 =
        trimps7.isEmpty ? 0.0 : trimps7.fold(0.0, (s, v) => s + v) / trimps7.length;
    final variance7 = trimps7.isEmpty
        ? 0.0
        : trimps7.fold(0.0, (s, v) => s + (v - mean7) * (v - mean7)) /
            trimps7.length;
    final sd7 = _sqrt(variance7);
    double? monotony;
    double? strain;
    if (sd7 > 0) {
      monotony = mean7 / sd7;
      strain = acuteLoad * monotony;
    }

    final name = _roster
        .where((r) => r.id == athleteId)
        .map((r) => r.name)
        .firstOrNull ?? 'Athlete';

    _currentTrend = AthleteTrend(
      athleteId: athleteId,
      name: name,
      days: trendDays,
      acuteLoad: acuteLoad,
      chronicLoad: chronicLoad,
      acwr: acwr,
      monotony: monotony,
      strain: strain,
    );
  }

  void _loadSampleTeam() {
    if (_roster.isEmpty) {
      _loadSampleReadiness(); // Populates roster
    }

    final sampleAcwr = [1.52, 1.24, 1.11, 0.72, 1.15, 1.08, 0.95, null, 1.02, 1.18, 0.88, 1.05, 1.12, 1.42, 0.91, 1.01, 1.22, 1.09, null, null, null, null];
    final sampleWeekTrimp = <double>[823, 612, 580, 445, 520, 510, 490, 0, 475, 540, 395, 505, 530, 680, 440, 485, 560, 500, 0, 0, 0, 0];
    final sampleReadiness = ['amber', 'green', 'green', 'green', 'green', 'green', 'green', '', 'green', 'green', 'amber', 'green', 'green', 'red', 'green', 'green', 'green', 'green', '', '', '', ''];
    final sampleRedDays = [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0];

    _teamRows = List.generate(_roster.length, (i) {
      final acwr = i < sampleAcwr.length ? sampleAcwr[i] : null;
      return TeamAthleteRow(
        athleteId: _roster[i].id,
        name: _roster[i].name,
        weekTrimp: i < sampleWeekTrimp.length ? sampleWeekTrimp[i] : 0,
        acwr: acwr,
        riskLevel: _acwrRisk(acwr),
        readiness: i < sampleReadiness.length ? sampleReadiness[i] : '',
        redDays: i < sampleRedDays.length ? sampleRedDays[i] : 0,
      );
    });

    _alerts = _computeAlerts(_teamRows);
  }

  // --- Helpers ---

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _acwrRisk(double? acwr) {
    if (acwr == null) return '';
    if (acwr < 0.8) return 'LOW';
    if (acwr <= 1.3) return 'OPTIMAL';
    if (acwr <= 1.5) return 'ELEVATED';
    return 'HIGH';
  }

  /// Integer square root helper to avoid dart:math import ambiguity.
  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }
}
