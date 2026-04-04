import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ── Tables ──────────────────────────────────────────────────────

class DailyWellnessEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get athleteId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get lnRmssd => real()();
  RealColumn get rmssdMs => real()();
  IntColumn get restingHr => integer()();
  TextColumn get readiness => text()(); // green, amber, red, building
  TextColumn get stability => text()(); // stable, variable
  RealColumn get baselineMean => real().nullable()();
  RealColumn get baselineSd => real().nullable()();
  RealColumn get cv7day => real().nullable()();
  IntColumn get rrCount => integer()();
  IntColumn get dayCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {athleteId, date},
  ];
}

class SessionEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get athleteId => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationS => integer()();
  RealColumn get trimpEdwards => real()();
  RealColumn get hrAvg => real()();
  IntColumn get hrMax => integer()();
  IntColumn get hrMin => integer()();
  TextColumn get zoneSecondsJson => text()(); // JSON array [6 elements]
  TextColumn get zonePercentJson => text()(); // JSON array [6 elements]
  TextColumn get label => text().nullable()(); // "Training", "Match", etc.
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

class Athletes extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get sensorId => text().nullable()(); // Polar device ID
  IntColumn get hrMax => integer().nullable()();
  IntColumn get hrRest => integer().nullable()();
  TextColumn get zoneConfigJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ────────────────────────────────────────────────────

@DriftDatabase(tables: [DailyWellnessEntries, SessionEntries, Athletes])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  // ── Wellness DAO methods ──────────────────────────────────────

  /// Delete all wellness entries for an athlete (reset baseline).
  Future<int> clearWellnessData(String athleteId) {
    return (delete(dailyWellnessEntries)
          ..where((t) => t.athleteId.equals(athleteId)))
        .go();
  }

  /// Insert or update a wellness entry (upsert by athlete+date).
  Future<void> upsertWellness(DailyWellnessEntriesCompanion entry) async {
    await into(dailyWellnessEntries).insertOnConflictUpdate(entry);
  }

  /// Get the baseline lnRMSSD values for the last N days (excluding today).
  Future<List<double>> getBaselineHistory(
    String athleteId, {
    int days = 60,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(Duration(days: days));

    final query = select(dailyWellnessEntries)
      ..where((t) => t.athleteId.equals(athleteId))
      ..where((t) => t.date.isBiggerOrEqualValue(cutoff))
      ..where((t) => t.date.isSmallerThanValue(today))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    final rows = await query.get();
    return rows.map((r) => r.lnRmssd).toList();
  }

  /// Get the last 7 days of wellness data.
  Future<List<DailyWellnessEntry>> getLast7Days(String athleteId) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final query = select(dailyWellnessEntries)
      ..where((t) => t.athleteId.equals(athleteId))
      ..where((t) => t.date.isBiggerOrEqualValue(cutoff))
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(7);
    return query.get();
  }

  /// Get today's wellness entry if it exists.
  Future<DailyWellnessEntry?> getTodayWellness(String athleteId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final query = select(dailyWellnessEntries)
      ..where((t) => t.athleteId.equals(athleteId))
      ..where((t) => t.date.isBiggerOrEqualValue(today))
      ..where((t) => t.date.isSmallerThanValue(tomorrow))
      ..limit(1);

    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Get total wellness day count for an athlete.
  Future<int> getWellnessDayCount(String athleteId) async {
    final count = dailyWellnessEntries.id.count();
    final query = selectOnly(dailyWellnessEntries)
      ..addColumns([count])
      ..where(dailyWellnessEntries.athleteId.equals(athleteId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ── Sessions DAO methods ──────────────────────────────────────

  /// Insert a session.
  Future<int> insertSession(SessionEntriesCompanion entry) {
    return into(sessionEntries).insert(entry);
  }

  /// Get sessions for a specific date.
  Future<List<SessionEntry>> getSessionsForDate(
    String athleteId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final query = select(sessionEntries)
      ..where((t) => t.athleteId.equals(athleteId))
      ..where((t) => t.date.isBiggerOrEqualValue(dayStart))
      ..where((t) => t.date.isSmallerThanValue(dayEnd));
    return query.get();
  }

  /// Get daily TRIMP values for load metrics computation.
  Future<List<({DateTime date, double trimp})>> getDailyTrimps(
    String athleteId, {
    int days = 28,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final query = select(sessionEntries)
      ..where((t) => t.athleteId.equals(athleteId))
      ..where((t) => t.date.isBiggerOrEqualValue(cutoff))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    final rows = await query.get();
    return rows.map((r) => (date: r.date, trimp: r.trimpEdwards)).toList();
  }

  /// Get the last session for display on home screen.
  Future<SessionEntry?> getLastSession(String athleteId) async {
    final query = select(sessionEntries)
      ..where((t) => t.athleteId.equals(athleteId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  // ── Athletes DAO methods ──────────────────────────────────────

  /// Get the active athlete (first athlete in the DB for V1 single-user mode).
  Future<Athlete?> getActiveAthlete() async {
    final query = select(athletes)..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Get a specific athlete by id.
  Future<Athlete?> getAthleteById(String athleteId) async {
    final query = select(athletes)
      ..where((t) => t.id.equals(athleteId))
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Insert or update athlete profile.
  Future<void> upsertAthlete(AthletesCompanion athlete) async {
    await into(athletes).insertOnConflictUpdate(athlete);
  }
}

// ── Connection ──────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kine_data.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
