// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DailyWellnessEntriesTable extends DailyWellnessEntries
    with TableInfo<$DailyWellnessEntriesTable, DailyWellnessEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyWellnessEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<String> athleteId = GeneratedColumn<String>(
    'athlete_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lnRmssdMeta = const VerificationMeta(
    'lnRmssd',
  );
  @override
  late final GeneratedColumn<double> lnRmssd = GeneratedColumn<double>(
    'ln_rmssd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rmssdMsMeta = const VerificationMeta(
    'rmssdMs',
  );
  @override
  late final GeneratedColumn<double> rmssdMs = GeneratedColumn<double>(
    'rmssd_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restingHrMeta = const VerificationMeta(
    'restingHr',
  );
  @override
  late final GeneratedColumn<int> restingHr = GeneratedColumn<int>(
    'resting_hr',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readinessMeta = const VerificationMeta(
    'readiness',
  );
  @override
  late final GeneratedColumn<String> readiness = GeneratedColumn<String>(
    'readiness',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<String> stability = GeneratedColumn<String>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baselineMeanMeta = const VerificationMeta(
    'baselineMean',
  );
  @override
  late final GeneratedColumn<double> baselineMean = GeneratedColumn<double>(
    'baseline_mean',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineSdMeta = const VerificationMeta(
    'baselineSd',
  );
  @override
  late final GeneratedColumn<double> baselineSd = GeneratedColumn<double>(
    'baseline_sd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cv7dayMeta = const VerificationMeta('cv7day');
  @override
  late final GeneratedColumn<double> cv7day = GeneratedColumn<double>(
    'cv7day',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrCountMeta = const VerificationMeta(
    'rrCount',
  );
  @override
  late final GeneratedColumn<int> rrCount = GeneratedColumn<int>(
    'rr_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayCountMeta = const VerificationMeta(
    'dayCount',
  );
  @override
  late final GeneratedColumn<int> dayCount = GeneratedColumn<int>(
    'day_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    athleteId,
    date,
    lnRmssd,
    rmssdMs,
    restingHr,
    readiness,
    stability,
    baselineMean,
    baselineSd,
    cv7day,
    rrCount,
    dayCount,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_wellness_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyWellnessEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_athleteIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('ln_rmssd')) {
      context.handle(
        _lnRmssdMeta,
        lnRmssd.isAcceptableOrUnknown(data['ln_rmssd']!, _lnRmssdMeta),
      );
    } else if (isInserting) {
      context.missing(_lnRmssdMeta);
    }
    if (data.containsKey('rmssd_ms')) {
      context.handle(
        _rmssdMsMeta,
        rmssdMs.isAcceptableOrUnknown(data['rmssd_ms']!, _rmssdMsMeta),
      );
    } else if (isInserting) {
      context.missing(_rmssdMsMeta);
    }
    if (data.containsKey('resting_hr')) {
      context.handle(
        _restingHrMeta,
        restingHr.isAcceptableOrUnknown(data['resting_hr']!, _restingHrMeta),
      );
    } else if (isInserting) {
      context.missing(_restingHrMeta);
    }
    if (data.containsKey('readiness')) {
      context.handle(
        _readinessMeta,
        readiness.isAcceptableOrUnknown(data['readiness']!, _readinessMeta),
      );
    } else if (isInserting) {
      context.missing(_readinessMeta);
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    } else if (isInserting) {
      context.missing(_stabilityMeta);
    }
    if (data.containsKey('baseline_mean')) {
      context.handle(
        _baselineMeanMeta,
        baselineMean.isAcceptableOrUnknown(
          data['baseline_mean']!,
          _baselineMeanMeta,
        ),
      );
    }
    if (data.containsKey('baseline_sd')) {
      context.handle(
        _baselineSdMeta,
        baselineSd.isAcceptableOrUnknown(data['baseline_sd']!, _baselineSdMeta),
      );
    }
    if (data.containsKey('cv7day')) {
      context.handle(
        _cv7dayMeta,
        cv7day.isAcceptableOrUnknown(data['cv7day']!, _cv7dayMeta),
      );
    }
    if (data.containsKey('rr_count')) {
      context.handle(
        _rrCountMeta,
        rrCount.isAcceptableOrUnknown(data['rr_count']!, _rrCountMeta),
      );
    } else if (isInserting) {
      context.missing(_rrCountMeta);
    }
    if (data.containsKey('day_count')) {
      context.handle(
        _dayCountMeta,
        dayCount.isAcceptableOrUnknown(data['day_count']!, _dayCountMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {athleteId, date},
  ];
  @override
  DailyWellnessEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyWellnessEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}athlete_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      lnRmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ln_rmssd'],
      )!,
      rmssdMs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd_ms'],
      )!,
      restingHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resting_hr'],
      )!,
      readiness: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}readiness'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stability'],
      )!,
      baselineMean: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}baseline_mean'],
      ),
      baselineSd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}baseline_sd'],
      ),
      cv7day: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cv7day'],
      ),
      rrCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rr_count'],
      )!,
      dayCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_count'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $DailyWellnessEntriesTable createAlias(String alias) {
    return $DailyWellnessEntriesTable(attachedDatabase, alias);
  }
}

class DailyWellnessEntry extends DataClass
    implements Insertable<DailyWellnessEntry> {
  final int id;
  final String athleteId;
  final DateTime date;
  final double lnRmssd;
  final double rmssdMs;
  final int restingHr;
  final String readiness;
  final String stability;
  final double? baselineMean;
  final double? baselineSd;
  final double? cv7day;
  final int rrCount;
  final int dayCount;
  final DateTime? syncedAt;
  const DailyWellnessEntry({
    required this.id,
    required this.athleteId,
    required this.date,
    required this.lnRmssd,
    required this.rmssdMs,
    required this.restingHr,
    required this.readiness,
    required this.stability,
    this.baselineMean,
    this.baselineSd,
    this.cv7day,
    required this.rrCount,
    required this.dayCount,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['athlete_id'] = Variable<String>(athleteId);
    map['date'] = Variable<DateTime>(date);
    map['ln_rmssd'] = Variable<double>(lnRmssd);
    map['rmssd_ms'] = Variable<double>(rmssdMs);
    map['resting_hr'] = Variable<int>(restingHr);
    map['readiness'] = Variable<String>(readiness);
    map['stability'] = Variable<String>(stability);
    if (!nullToAbsent || baselineMean != null) {
      map['baseline_mean'] = Variable<double>(baselineMean);
    }
    if (!nullToAbsent || baselineSd != null) {
      map['baseline_sd'] = Variable<double>(baselineSd);
    }
    if (!nullToAbsent || cv7day != null) {
      map['cv7day'] = Variable<double>(cv7day);
    }
    map['rr_count'] = Variable<int>(rrCount);
    map['day_count'] = Variable<int>(dayCount);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  DailyWellnessEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyWellnessEntriesCompanion(
      id: Value(id),
      athleteId: Value(athleteId),
      date: Value(date),
      lnRmssd: Value(lnRmssd),
      rmssdMs: Value(rmssdMs),
      restingHr: Value(restingHr),
      readiness: Value(readiness),
      stability: Value(stability),
      baselineMean: baselineMean == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineMean),
      baselineSd: baselineSd == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineSd),
      cv7day: cv7day == null && nullToAbsent
          ? const Value.absent()
          : Value(cv7day),
      rrCount: Value(rrCount),
      dayCount: Value(dayCount),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory DailyWellnessEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyWellnessEntry(
      id: serializer.fromJson<int>(json['id']),
      athleteId: serializer.fromJson<String>(json['athleteId']),
      date: serializer.fromJson<DateTime>(json['date']),
      lnRmssd: serializer.fromJson<double>(json['lnRmssd']),
      rmssdMs: serializer.fromJson<double>(json['rmssdMs']),
      restingHr: serializer.fromJson<int>(json['restingHr']),
      readiness: serializer.fromJson<String>(json['readiness']),
      stability: serializer.fromJson<String>(json['stability']),
      baselineMean: serializer.fromJson<double?>(json['baselineMean']),
      baselineSd: serializer.fromJson<double?>(json['baselineSd']),
      cv7day: serializer.fromJson<double?>(json['cv7day']),
      rrCount: serializer.fromJson<int>(json['rrCount']),
      dayCount: serializer.fromJson<int>(json['dayCount']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'athleteId': serializer.toJson<String>(athleteId),
      'date': serializer.toJson<DateTime>(date),
      'lnRmssd': serializer.toJson<double>(lnRmssd),
      'rmssdMs': serializer.toJson<double>(rmssdMs),
      'restingHr': serializer.toJson<int>(restingHr),
      'readiness': serializer.toJson<String>(readiness),
      'stability': serializer.toJson<String>(stability),
      'baselineMean': serializer.toJson<double?>(baselineMean),
      'baselineSd': serializer.toJson<double?>(baselineSd),
      'cv7day': serializer.toJson<double?>(cv7day),
      'rrCount': serializer.toJson<int>(rrCount),
      'dayCount': serializer.toJson<int>(dayCount),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  DailyWellnessEntry copyWith({
    int? id,
    String? athleteId,
    DateTime? date,
    double? lnRmssd,
    double? rmssdMs,
    int? restingHr,
    String? readiness,
    String? stability,
    Value<double?> baselineMean = const Value.absent(),
    Value<double?> baselineSd = const Value.absent(),
    Value<double?> cv7day = const Value.absent(),
    int? rrCount,
    int? dayCount,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => DailyWellnessEntry(
    id: id ?? this.id,
    athleteId: athleteId ?? this.athleteId,
    date: date ?? this.date,
    lnRmssd: lnRmssd ?? this.lnRmssd,
    rmssdMs: rmssdMs ?? this.rmssdMs,
    restingHr: restingHr ?? this.restingHr,
    readiness: readiness ?? this.readiness,
    stability: stability ?? this.stability,
    baselineMean: baselineMean.present ? baselineMean.value : this.baselineMean,
    baselineSd: baselineSd.present ? baselineSd.value : this.baselineSd,
    cv7day: cv7day.present ? cv7day.value : this.cv7day,
    rrCount: rrCount ?? this.rrCount,
    dayCount: dayCount ?? this.dayCount,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  DailyWellnessEntry copyWithCompanion(DailyWellnessEntriesCompanion data) {
    return DailyWellnessEntry(
      id: data.id.present ? data.id.value : this.id,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      date: data.date.present ? data.date.value : this.date,
      lnRmssd: data.lnRmssd.present ? data.lnRmssd.value : this.lnRmssd,
      rmssdMs: data.rmssdMs.present ? data.rmssdMs.value : this.rmssdMs,
      restingHr: data.restingHr.present ? data.restingHr.value : this.restingHr,
      readiness: data.readiness.present ? data.readiness.value : this.readiness,
      stability: data.stability.present ? data.stability.value : this.stability,
      baselineMean: data.baselineMean.present
          ? data.baselineMean.value
          : this.baselineMean,
      baselineSd: data.baselineSd.present
          ? data.baselineSd.value
          : this.baselineSd,
      cv7day: data.cv7day.present ? data.cv7day.value : this.cv7day,
      rrCount: data.rrCount.present ? data.rrCount.value : this.rrCount,
      dayCount: data.dayCount.present ? data.dayCount.value : this.dayCount,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyWellnessEntry(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('date: $date, ')
          ..write('lnRmssd: $lnRmssd, ')
          ..write('rmssdMs: $rmssdMs, ')
          ..write('restingHr: $restingHr, ')
          ..write('readiness: $readiness, ')
          ..write('stability: $stability, ')
          ..write('baselineMean: $baselineMean, ')
          ..write('baselineSd: $baselineSd, ')
          ..write('cv7day: $cv7day, ')
          ..write('rrCount: $rrCount, ')
          ..write('dayCount: $dayCount, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    athleteId,
    date,
    lnRmssd,
    rmssdMs,
    restingHr,
    readiness,
    stability,
    baselineMean,
    baselineSd,
    cv7day,
    rrCount,
    dayCount,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyWellnessEntry &&
          other.id == this.id &&
          other.athleteId == this.athleteId &&
          other.date == this.date &&
          other.lnRmssd == this.lnRmssd &&
          other.rmssdMs == this.rmssdMs &&
          other.restingHr == this.restingHr &&
          other.readiness == this.readiness &&
          other.stability == this.stability &&
          other.baselineMean == this.baselineMean &&
          other.baselineSd == this.baselineSd &&
          other.cv7day == this.cv7day &&
          other.rrCount == this.rrCount &&
          other.dayCount == this.dayCount &&
          other.syncedAt == this.syncedAt);
}

class DailyWellnessEntriesCompanion
    extends UpdateCompanion<DailyWellnessEntry> {
  final Value<int> id;
  final Value<String> athleteId;
  final Value<DateTime> date;
  final Value<double> lnRmssd;
  final Value<double> rmssdMs;
  final Value<int> restingHr;
  final Value<String> readiness;
  final Value<String> stability;
  final Value<double?> baselineMean;
  final Value<double?> baselineSd;
  final Value<double?> cv7day;
  final Value<int> rrCount;
  final Value<int> dayCount;
  final Value<DateTime?> syncedAt;
  const DailyWellnessEntriesCompanion({
    this.id = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.date = const Value.absent(),
    this.lnRmssd = const Value.absent(),
    this.rmssdMs = const Value.absent(),
    this.restingHr = const Value.absent(),
    this.readiness = const Value.absent(),
    this.stability = const Value.absent(),
    this.baselineMean = const Value.absent(),
    this.baselineSd = const Value.absent(),
    this.cv7day = const Value.absent(),
    this.rrCount = const Value.absent(),
    this.dayCount = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  DailyWellnessEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String athleteId,
    required DateTime date,
    required double lnRmssd,
    required double rmssdMs,
    required int restingHr,
    required String readiness,
    required String stability,
    this.baselineMean = const Value.absent(),
    this.baselineSd = const Value.absent(),
    this.cv7day = const Value.absent(),
    required int rrCount,
    this.dayCount = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : athleteId = Value(athleteId),
       date = Value(date),
       lnRmssd = Value(lnRmssd),
       rmssdMs = Value(rmssdMs),
       restingHr = Value(restingHr),
       readiness = Value(readiness),
       stability = Value(stability),
       rrCount = Value(rrCount);
  static Insertable<DailyWellnessEntry> custom({
    Expression<int>? id,
    Expression<String>? athleteId,
    Expression<DateTime>? date,
    Expression<double>? lnRmssd,
    Expression<double>? rmssdMs,
    Expression<int>? restingHr,
    Expression<String>? readiness,
    Expression<String>? stability,
    Expression<double>? baselineMean,
    Expression<double>? baselineSd,
    Expression<double>? cv7day,
    Expression<int>? rrCount,
    Expression<int>? dayCount,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (athleteId != null) 'athlete_id': athleteId,
      if (date != null) 'date': date,
      if (lnRmssd != null) 'ln_rmssd': lnRmssd,
      if (rmssdMs != null) 'rmssd_ms': rmssdMs,
      if (restingHr != null) 'resting_hr': restingHr,
      if (readiness != null) 'readiness': readiness,
      if (stability != null) 'stability': stability,
      if (baselineMean != null) 'baseline_mean': baselineMean,
      if (baselineSd != null) 'baseline_sd': baselineSd,
      if (cv7day != null) 'cv7day': cv7day,
      if (rrCount != null) 'rr_count': rrCount,
      if (dayCount != null) 'day_count': dayCount,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  DailyWellnessEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? athleteId,
    Value<DateTime>? date,
    Value<double>? lnRmssd,
    Value<double>? rmssdMs,
    Value<int>? restingHr,
    Value<String>? readiness,
    Value<String>? stability,
    Value<double?>? baselineMean,
    Value<double?>? baselineSd,
    Value<double?>? cv7day,
    Value<int>? rrCount,
    Value<int>? dayCount,
    Value<DateTime?>? syncedAt,
  }) {
    return DailyWellnessEntriesCompanion(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      lnRmssd: lnRmssd ?? this.lnRmssd,
      rmssdMs: rmssdMs ?? this.rmssdMs,
      restingHr: restingHr ?? this.restingHr,
      readiness: readiness ?? this.readiness,
      stability: stability ?? this.stability,
      baselineMean: baselineMean ?? this.baselineMean,
      baselineSd: baselineSd ?? this.baselineSd,
      cv7day: cv7day ?? this.cv7day,
      rrCount: rrCount ?? this.rrCount,
      dayCount: dayCount ?? this.dayCount,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<String>(athleteId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (lnRmssd.present) {
      map['ln_rmssd'] = Variable<double>(lnRmssd.value);
    }
    if (rmssdMs.present) {
      map['rmssd_ms'] = Variable<double>(rmssdMs.value);
    }
    if (restingHr.present) {
      map['resting_hr'] = Variable<int>(restingHr.value);
    }
    if (readiness.present) {
      map['readiness'] = Variable<String>(readiness.value);
    }
    if (stability.present) {
      map['stability'] = Variable<String>(stability.value);
    }
    if (baselineMean.present) {
      map['baseline_mean'] = Variable<double>(baselineMean.value);
    }
    if (baselineSd.present) {
      map['baseline_sd'] = Variable<double>(baselineSd.value);
    }
    if (cv7day.present) {
      map['cv7day'] = Variable<double>(cv7day.value);
    }
    if (rrCount.present) {
      map['rr_count'] = Variable<int>(rrCount.value);
    }
    if (dayCount.present) {
      map['day_count'] = Variable<int>(dayCount.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyWellnessEntriesCompanion(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('date: $date, ')
          ..write('lnRmssd: $lnRmssd, ')
          ..write('rmssdMs: $rmssdMs, ')
          ..write('restingHr: $restingHr, ')
          ..write('readiness: $readiness, ')
          ..write('stability: $stability, ')
          ..write('baselineMean: $baselineMean, ')
          ..write('baselineSd: $baselineSd, ')
          ..write('cv7day: $cv7day, ')
          ..write('rrCount: $rrCount, ')
          ..write('dayCount: $dayCount, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionEntriesTable extends SessionEntries
    with TableInfo<$SessionEntriesTable, SessionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<String> athleteId = GeneratedColumn<String>(
    'athlete_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trimpEdwardsMeta = const VerificationMeta(
    'trimpEdwards',
  );
  @override
  late final GeneratedColumn<double> trimpEdwards = GeneratedColumn<double>(
    'trimp_edwards',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrAvgMeta = const VerificationMeta('hrAvg');
  @override
  late final GeneratedColumn<double> hrAvg = GeneratedColumn<double>(
    'hr_avg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrMaxMeta = const VerificationMeta('hrMax');
  @override
  late final GeneratedColumn<int> hrMax = GeneratedColumn<int>(
    'hr_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrMinMeta = const VerificationMeta('hrMin');
  @override
  late final GeneratedColumn<int> hrMin = GeneratedColumn<int>(
    'hr_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneSecondsJsonMeta = const VerificationMeta(
    'zoneSecondsJson',
  );
  @override
  late final GeneratedColumn<String> zoneSecondsJson = GeneratedColumn<String>(
    'zone_seconds_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zonePercentJsonMeta = const VerificationMeta(
    'zonePercentJson',
  );
  @override
  late final GeneratedColumn<String> zonePercentJson = GeneratedColumn<String>(
    'zone_percent_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    athleteId,
    date,
    startTime,
    endTime,
    durationS,
    trimpEdwards,
    hrAvg,
    hrMax,
    hrMin,
    zoneSecondsJson,
    zonePercentJson,
    label,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_athleteIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    } else if (isInserting) {
      context.missing(_durationSMeta);
    }
    if (data.containsKey('trimp_edwards')) {
      context.handle(
        _trimpEdwardsMeta,
        trimpEdwards.isAcceptableOrUnknown(
          data['trimp_edwards']!,
          _trimpEdwardsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trimpEdwardsMeta);
    }
    if (data.containsKey('hr_avg')) {
      context.handle(
        _hrAvgMeta,
        hrAvg.isAcceptableOrUnknown(data['hr_avg']!, _hrAvgMeta),
      );
    } else if (isInserting) {
      context.missing(_hrAvgMeta);
    }
    if (data.containsKey('hr_max')) {
      context.handle(
        _hrMaxMeta,
        hrMax.isAcceptableOrUnknown(data['hr_max']!, _hrMaxMeta),
      );
    } else if (isInserting) {
      context.missing(_hrMaxMeta);
    }
    if (data.containsKey('hr_min')) {
      context.handle(
        _hrMinMeta,
        hrMin.isAcceptableOrUnknown(data['hr_min']!, _hrMinMeta),
      );
    } else if (isInserting) {
      context.missing(_hrMinMeta);
    }
    if (data.containsKey('zone_seconds_json')) {
      context.handle(
        _zoneSecondsJsonMeta,
        zoneSecondsJson.isAcceptableOrUnknown(
          data['zone_seconds_json']!,
          _zoneSecondsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zoneSecondsJsonMeta);
    }
    if (data.containsKey('zone_percent_json')) {
      context.handle(
        _zonePercentJsonMeta,
        zonePercentJson.isAcceptableOrUnknown(
          data['zone_percent_json']!,
          _zonePercentJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zonePercentJsonMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}athlete_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      )!,
      trimpEdwards: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}trimp_edwards'],
      )!,
      hrAvg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hr_avg'],
      )!,
      hrMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_max'],
      )!,
      hrMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_min'],
      )!,
      zoneSecondsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_seconds_json'],
      )!,
      zonePercentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_percent_json'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $SessionEntriesTable createAlias(String alias) {
    return $SessionEntriesTable(attachedDatabase, alias);
  }
}

class SessionEntry extends DataClass implements Insertable<SessionEntry> {
  final int id;
  final String athleteId;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationS;
  final double trimpEdwards;
  final double hrAvg;
  final int hrMax;
  final int hrMin;
  final String zoneSecondsJson;
  final String zonePercentJson;
  final String? label;
  final DateTime? syncedAt;
  const SessionEntry({
    required this.id,
    required this.athleteId,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.durationS,
    required this.trimpEdwards,
    required this.hrAvg,
    required this.hrMax,
    required this.hrMin,
    required this.zoneSecondsJson,
    required this.zonePercentJson,
    this.label,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['athlete_id'] = Variable<String>(athleteId);
    map['date'] = Variable<DateTime>(date);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration_s'] = Variable<int>(durationS);
    map['trimp_edwards'] = Variable<double>(trimpEdwards);
    map['hr_avg'] = Variable<double>(hrAvg);
    map['hr_max'] = Variable<int>(hrMax);
    map['hr_min'] = Variable<int>(hrMin);
    map['zone_seconds_json'] = Variable<String>(zoneSecondsJson);
    map['zone_percent_json'] = Variable<String>(zonePercentJson);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SessionEntriesCompanion toCompanion(bool nullToAbsent) {
    return SessionEntriesCompanion(
      id: Value(id),
      athleteId: Value(athleteId),
      date: Value(date),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationS: Value(durationS),
      trimpEdwards: Value(trimpEdwards),
      hrAvg: Value(hrAvg),
      hrMax: Value(hrMax),
      hrMin: Value(hrMin),
      zoneSecondsJson: Value(zoneSecondsJson),
      zonePercentJson: Value(zonePercentJson),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SessionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionEntry(
      id: serializer.fromJson<int>(json['id']),
      athleteId: serializer.fromJson<String>(json['athleteId']),
      date: serializer.fromJson<DateTime>(json['date']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationS: serializer.fromJson<int>(json['durationS']),
      trimpEdwards: serializer.fromJson<double>(json['trimpEdwards']),
      hrAvg: serializer.fromJson<double>(json['hrAvg']),
      hrMax: serializer.fromJson<int>(json['hrMax']),
      hrMin: serializer.fromJson<int>(json['hrMin']),
      zoneSecondsJson: serializer.fromJson<String>(json['zoneSecondsJson']),
      zonePercentJson: serializer.fromJson<String>(json['zonePercentJson']),
      label: serializer.fromJson<String?>(json['label']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'athleteId': serializer.toJson<String>(athleteId),
      'date': serializer.toJson<DateTime>(date),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationS': serializer.toJson<int>(durationS),
      'trimpEdwards': serializer.toJson<double>(trimpEdwards),
      'hrAvg': serializer.toJson<double>(hrAvg),
      'hrMax': serializer.toJson<int>(hrMax),
      'hrMin': serializer.toJson<int>(hrMin),
      'zoneSecondsJson': serializer.toJson<String>(zoneSecondsJson),
      'zonePercentJson': serializer.toJson<String>(zonePercentJson),
      'label': serializer.toJson<String?>(label),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SessionEntry copyWith({
    int? id,
    String? athleteId,
    DateTime? date,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    int? durationS,
    double? trimpEdwards,
    double? hrAvg,
    int? hrMax,
    int? hrMin,
    String? zoneSecondsJson,
    String? zonePercentJson,
    Value<String?> label = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => SessionEntry(
    id: id ?? this.id,
    athleteId: athleteId ?? this.athleteId,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    durationS: durationS ?? this.durationS,
    trimpEdwards: trimpEdwards ?? this.trimpEdwards,
    hrAvg: hrAvg ?? this.hrAvg,
    hrMax: hrMax ?? this.hrMax,
    hrMin: hrMin ?? this.hrMin,
    zoneSecondsJson: zoneSecondsJson ?? this.zoneSecondsJson,
    zonePercentJson: zonePercentJson ?? this.zonePercentJson,
    label: label.present ? label.value : this.label,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  SessionEntry copyWithCompanion(SessionEntriesCompanion data) {
    return SessionEntry(
      id: data.id.present ? data.id.value : this.id,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      trimpEdwards: data.trimpEdwards.present
          ? data.trimpEdwards.value
          : this.trimpEdwards,
      hrAvg: data.hrAvg.present ? data.hrAvg.value : this.hrAvg,
      hrMax: data.hrMax.present ? data.hrMax.value : this.hrMax,
      hrMin: data.hrMin.present ? data.hrMin.value : this.hrMin,
      zoneSecondsJson: data.zoneSecondsJson.present
          ? data.zoneSecondsJson.value
          : this.zoneSecondsJson,
      zonePercentJson: data.zonePercentJson.present
          ? data.zonePercentJson.value
          : this.zonePercentJson,
      label: data.label.present ? data.label.value : this.label,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionEntry(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationS: $durationS, ')
          ..write('trimpEdwards: $trimpEdwards, ')
          ..write('hrAvg: $hrAvg, ')
          ..write('hrMax: $hrMax, ')
          ..write('hrMin: $hrMin, ')
          ..write('zoneSecondsJson: $zoneSecondsJson, ')
          ..write('zonePercentJson: $zonePercentJson, ')
          ..write('label: $label, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    athleteId,
    date,
    startTime,
    endTime,
    durationS,
    trimpEdwards,
    hrAvg,
    hrMax,
    hrMin,
    zoneSecondsJson,
    zonePercentJson,
    label,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionEntry &&
          other.id == this.id &&
          other.athleteId == this.athleteId &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationS == this.durationS &&
          other.trimpEdwards == this.trimpEdwards &&
          other.hrAvg == this.hrAvg &&
          other.hrMax == this.hrMax &&
          other.hrMin == this.hrMin &&
          other.zoneSecondsJson == this.zoneSecondsJson &&
          other.zonePercentJson == this.zonePercentJson &&
          other.label == this.label &&
          other.syncedAt == this.syncedAt);
}

class SessionEntriesCompanion extends UpdateCompanion<SessionEntry> {
  final Value<int> id;
  final Value<String> athleteId;
  final Value<DateTime> date;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> durationS;
  final Value<double> trimpEdwards;
  final Value<double> hrAvg;
  final Value<int> hrMax;
  final Value<int> hrMin;
  final Value<String> zoneSecondsJson;
  final Value<String> zonePercentJson;
  final Value<String?> label;
  final Value<DateTime?> syncedAt;
  const SessionEntriesCompanion({
    this.id = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationS = const Value.absent(),
    this.trimpEdwards = const Value.absent(),
    this.hrAvg = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.hrMin = const Value.absent(),
    this.zoneSecondsJson = const Value.absent(),
    this.zonePercentJson = const Value.absent(),
    this.label = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  SessionEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String athleteId,
    required DateTime date,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    required int durationS,
    required double trimpEdwards,
    required double hrAvg,
    required int hrMax,
    required int hrMin,
    required String zoneSecondsJson,
    required String zonePercentJson,
    this.label = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : athleteId = Value(athleteId),
       date = Value(date),
       startTime = Value(startTime),
       durationS = Value(durationS),
       trimpEdwards = Value(trimpEdwards),
       hrAvg = Value(hrAvg),
       hrMax = Value(hrMax),
       hrMin = Value(hrMin),
       zoneSecondsJson = Value(zoneSecondsJson),
       zonePercentJson = Value(zonePercentJson);
  static Insertable<SessionEntry> custom({
    Expression<int>? id,
    Expression<String>? athleteId,
    Expression<DateTime>? date,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationS,
    Expression<double>? trimpEdwards,
    Expression<double>? hrAvg,
    Expression<int>? hrMax,
    Expression<int>? hrMin,
    Expression<String>? zoneSecondsJson,
    Expression<String>? zonePercentJson,
    Expression<String>? label,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (athleteId != null) 'athlete_id': athleteId,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationS != null) 'duration_s': durationS,
      if (trimpEdwards != null) 'trimp_edwards': trimpEdwards,
      if (hrAvg != null) 'hr_avg': hrAvg,
      if (hrMax != null) 'hr_max': hrMax,
      if (hrMin != null) 'hr_min': hrMin,
      if (zoneSecondsJson != null) 'zone_seconds_json': zoneSecondsJson,
      if (zonePercentJson != null) 'zone_percent_json': zonePercentJson,
      if (label != null) 'label': label,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  SessionEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? athleteId,
    Value<DateTime>? date,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<int>? durationS,
    Value<double>? trimpEdwards,
    Value<double>? hrAvg,
    Value<int>? hrMax,
    Value<int>? hrMin,
    Value<String>? zoneSecondsJson,
    Value<String>? zonePercentJson,
    Value<String?>? label,
    Value<DateTime?>? syncedAt,
  }) {
    return SessionEntriesCompanion(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationS: durationS ?? this.durationS,
      trimpEdwards: trimpEdwards ?? this.trimpEdwards,
      hrAvg: hrAvg ?? this.hrAvg,
      hrMax: hrMax ?? this.hrMax,
      hrMin: hrMin ?? this.hrMin,
      zoneSecondsJson: zoneSecondsJson ?? this.zoneSecondsJson,
      zonePercentJson: zonePercentJson ?? this.zonePercentJson,
      label: label ?? this.label,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<String>(athleteId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (trimpEdwards.present) {
      map['trimp_edwards'] = Variable<double>(trimpEdwards.value);
    }
    if (hrAvg.present) {
      map['hr_avg'] = Variable<double>(hrAvg.value);
    }
    if (hrMax.present) {
      map['hr_max'] = Variable<int>(hrMax.value);
    }
    if (hrMin.present) {
      map['hr_min'] = Variable<int>(hrMin.value);
    }
    if (zoneSecondsJson.present) {
      map['zone_seconds_json'] = Variable<String>(zoneSecondsJson.value);
    }
    if (zonePercentJson.present) {
      map['zone_percent_json'] = Variable<String>(zonePercentJson.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationS: $durationS, ')
          ..write('trimpEdwards: $trimpEdwards, ')
          ..write('hrAvg: $hrAvg, ')
          ..write('hrMax: $hrMax, ')
          ..write('hrMin: $hrMin, ')
          ..write('zoneSecondsJson: $zoneSecondsJson, ')
          ..write('zonePercentJson: $zonePercentJson, ')
          ..write('label: $label, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $AthletesTable extends Athletes with TableInfo<$AthletesTable, Athlete> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AthletesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sensorIdMeta = const VerificationMeta(
    'sensorId',
  );
  @override
  late final GeneratedColumn<String> sensorId = GeneratedColumn<String>(
    'sensor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrMaxMeta = const VerificationMeta('hrMax');
  @override
  late final GeneratedColumn<int> hrMax = GeneratedColumn<int>(
    'hr_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrRestMeta = const VerificationMeta('hrRest');
  @override
  late final GeneratedColumn<int> hrRest = GeneratedColumn<int>(
    'hr_rest',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zoneConfigJsonMeta = const VerificationMeta(
    'zoneConfigJson',
  );
  @override
  late final GeneratedColumn<String> zoneConfigJson = GeneratedColumn<String>(
    'zone_config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sensorId,
    hrMax,
    hrRest,
    zoneConfigJson,
    dateOfBirth,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'athletes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Athlete> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sensor_id')) {
      context.handle(
        _sensorIdMeta,
        sensorId.isAcceptableOrUnknown(data['sensor_id']!, _sensorIdMeta),
      );
    }
    if (data.containsKey('hr_max')) {
      context.handle(
        _hrMaxMeta,
        hrMax.isAcceptableOrUnknown(data['hr_max']!, _hrMaxMeta),
      );
    }
    if (data.containsKey('hr_rest')) {
      context.handle(
        _hrRestMeta,
        hrRest.isAcceptableOrUnknown(data['hr_rest']!, _hrRestMeta),
      );
    }
    if (data.containsKey('zone_config_json')) {
      context.handle(
        _zoneConfigJsonMeta,
        zoneConfigJson.isAcceptableOrUnknown(
          data['zone_config_json']!,
          _zoneConfigJsonMeta,
        ),
      );
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Athlete map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Athlete(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sensorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sensor_id'],
      ),
      hrMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_max'],
      ),
      hrRest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_rest'],
      ),
      zoneConfigJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_config_json'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_of_birth'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AthletesTable createAlias(String alias) {
    return $AthletesTable(attachedDatabase, alias);
  }
}

class Athlete extends DataClass implements Insertable<Athlete> {
  final String id;
  final String name;
  final String? sensorId;
  final int? hrMax;
  final int? hrRest;
  final String zoneConfigJson;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  const Athlete({
    required this.id,
    required this.name,
    this.sensorId,
    this.hrMax,
    this.hrRest,
    required this.zoneConfigJson,
    this.dateOfBirth,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sensorId != null) {
      map['sensor_id'] = Variable<String>(sensorId);
    }
    if (!nullToAbsent || hrMax != null) {
      map['hr_max'] = Variable<int>(hrMax);
    }
    if (!nullToAbsent || hrRest != null) {
      map['hr_rest'] = Variable<int>(hrRest);
    }
    map['zone_config_json'] = Variable<String>(zoneConfigJson);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AthletesCompanion toCompanion(bool nullToAbsent) {
    return AthletesCompanion(
      id: Value(id),
      name: Value(name),
      sensorId: sensorId == null && nullToAbsent
          ? const Value.absent()
          : Value(sensorId),
      hrMax: hrMax == null && nullToAbsent
          ? const Value.absent()
          : Value(hrMax),
      hrRest: hrRest == null && nullToAbsent
          ? const Value.absent()
          : Value(hrRest),
      zoneConfigJson: Value(zoneConfigJson),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      createdAt: Value(createdAt),
    );
  }

  factory Athlete.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Athlete(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sensorId: serializer.fromJson<String?>(json['sensorId']),
      hrMax: serializer.fromJson<int?>(json['hrMax']),
      hrRest: serializer.fromJson<int?>(json['hrRest']),
      zoneConfigJson: serializer.fromJson<String>(json['zoneConfigJson']),
      dateOfBirth: serializer.fromJson<DateTime?>(json['dateOfBirth']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sensorId': serializer.toJson<String?>(sensorId),
      'hrMax': serializer.toJson<int?>(hrMax),
      'hrRest': serializer.toJson<int?>(hrRest),
      'zoneConfigJson': serializer.toJson<String>(zoneConfigJson),
      'dateOfBirth': serializer.toJson<DateTime?>(dateOfBirth),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Athlete copyWith({
    String? id,
    String? name,
    Value<String?> sensorId = const Value.absent(),
    Value<int?> hrMax = const Value.absent(),
    Value<int?> hrRest = const Value.absent(),
    String? zoneConfigJson,
    Value<DateTime?> dateOfBirth = const Value.absent(),
    DateTime? createdAt,
  }) => Athlete(
    id: id ?? this.id,
    name: name ?? this.name,
    sensorId: sensorId.present ? sensorId.value : this.sensorId,
    hrMax: hrMax.present ? hrMax.value : this.hrMax,
    hrRest: hrRest.present ? hrRest.value : this.hrRest,
    zoneConfigJson: zoneConfigJson ?? this.zoneConfigJson,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    createdAt: createdAt ?? this.createdAt,
  );
  Athlete copyWithCompanion(AthletesCompanion data) {
    return Athlete(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sensorId: data.sensorId.present ? data.sensorId.value : this.sensorId,
      hrMax: data.hrMax.present ? data.hrMax.value : this.hrMax,
      hrRest: data.hrRest.present ? data.hrRest.value : this.hrRest,
      zoneConfigJson: data.zoneConfigJson.present
          ? data.zoneConfigJson.value
          : this.zoneConfigJson,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Athlete(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sensorId: $sensorId, ')
          ..write('hrMax: $hrMax, ')
          ..write('hrRest: $hrRest, ')
          ..write('zoneConfigJson: $zoneConfigJson, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sensorId,
    hrMax,
    hrRest,
    zoneConfigJson,
    dateOfBirth,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Athlete &&
          other.id == this.id &&
          other.name == this.name &&
          other.sensorId == this.sensorId &&
          other.hrMax == this.hrMax &&
          other.hrRest == this.hrRest &&
          other.zoneConfigJson == this.zoneConfigJson &&
          other.dateOfBirth == this.dateOfBirth &&
          other.createdAt == this.createdAt);
}

class AthletesCompanion extends UpdateCompanion<Athlete> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> sensorId;
  final Value<int?> hrMax;
  final Value<int?> hrRest;
  final Value<String> zoneConfigJson;
  final Value<DateTime?> dateOfBirth;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AthletesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sensorId = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.hrRest = const Value.absent(),
    this.zoneConfigJson = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AthletesCompanion.insert({
    required String id,
    required String name,
    this.sensorId = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.hrRest = const Value.absent(),
    this.zoneConfigJson = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Athlete> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sensorId,
    Expression<int>? hrMax,
    Expression<int>? hrRest,
    Expression<String>? zoneConfigJson,
    Expression<DateTime>? dateOfBirth,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sensorId != null) 'sensor_id': sensorId,
      if (hrMax != null) 'hr_max': hrMax,
      if (hrRest != null) 'hr_rest': hrRest,
      if (zoneConfigJson != null) 'zone_config_json': zoneConfigJson,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AthletesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? sensorId,
    Value<int?>? hrMax,
    Value<int?>? hrRest,
    Value<String>? zoneConfigJson,
    Value<DateTime?>? dateOfBirth,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AthletesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sensorId: sensorId ?? this.sensorId,
      hrMax: hrMax ?? this.hrMax,
      hrRest: hrRest ?? this.hrRest,
      zoneConfigJson: zoneConfigJson ?? this.zoneConfigJson,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sensorId.present) {
      map['sensor_id'] = Variable<String>(sensorId.value);
    }
    if (hrMax.present) {
      map['hr_max'] = Variable<int>(hrMax.value);
    }
    if (hrRest.present) {
      map['hr_rest'] = Variable<int>(hrRest.value);
    }
    if (zoneConfigJson.present) {
      map['zone_config_json'] = Variable<String>(zoneConfigJson.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AthletesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sensorId: $sensorId, ')
          ..write('hrMax: $hrMax, ')
          ..write('hrRest: $hrRest, ')
          ..write('zoneConfigJson: $zoneConfigJson, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyWellnessEntriesTable dailyWellnessEntries =
      $DailyWellnessEntriesTable(this);
  late final $SessionEntriesTable sessionEntries = $SessionEntriesTable(this);
  late final $AthletesTable athletes = $AthletesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyWellnessEntries,
    sessionEntries,
    athletes,
  ];
}

typedef $$DailyWellnessEntriesTableCreateCompanionBuilder =
    DailyWellnessEntriesCompanion Function({
      Value<int> id,
      required String athleteId,
      required DateTime date,
      required double lnRmssd,
      required double rmssdMs,
      required int restingHr,
      required String readiness,
      required String stability,
      Value<double?> baselineMean,
      Value<double?> baselineSd,
      Value<double?> cv7day,
      required int rrCount,
      Value<int> dayCount,
      Value<DateTime?> syncedAt,
    });
typedef $$DailyWellnessEntriesTableUpdateCompanionBuilder =
    DailyWellnessEntriesCompanion Function({
      Value<int> id,
      Value<String> athleteId,
      Value<DateTime> date,
      Value<double> lnRmssd,
      Value<double> rmssdMs,
      Value<int> restingHr,
      Value<String> readiness,
      Value<String> stability,
      Value<double?> baselineMean,
      Value<double?> baselineSd,
      Value<double?> cv7day,
      Value<int> rrCount,
      Value<int> dayCount,
      Value<DateTime?> syncedAt,
    });

class $$DailyWellnessEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyWellnessEntriesTable> {
  $$DailyWellnessEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lnRmssd => $composableBuilder(
    column: $table.lnRmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssdMs => $composableBuilder(
    column: $table.rmssdMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restingHr => $composableBuilder(
    column: $table.restingHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readiness => $composableBuilder(
    column: $table.readiness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baselineMean => $composableBuilder(
    column: $table.baselineMean,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baselineSd => $composableBuilder(
    column: $table.baselineSd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cv7day => $composableBuilder(
    column: $table.cv7day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rrCount => $composableBuilder(
    column: $table.rrCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayCount => $composableBuilder(
    column: $table.dayCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyWellnessEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyWellnessEntriesTable> {
  $$DailyWellnessEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lnRmssd => $composableBuilder(
    column: $table.lnRmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssdMs => $composableBuilder(
    column: $table.rmssdMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restingHr => $composableBuilder(
    column: $table.restingHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readiness => $composableBuilder(
    column: $table.readiness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baselineMean => $composableBuilder(
    column: $table.baselineMean,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baselineSd => $composableBuilder(
    column: $table.baselineSd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cv7day => $composableBuilder(
    column: $table.cv7day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rrCount => $composableBuilder(
    column: $table.rrCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayCount => $composableBuilder(
    column: $table.dayCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyWellnessEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyWellnessEntriesTable> {
  $$DailyWellnessEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get athleteId =>
      $composableBuilder(column: $table.athleteId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get lnRmssd =>
      $composableBuilder(column: $table.lnRmssd, builder: (column) => column);

  GeneratedColumn<double> get rmssdMs =>
      $composableBuilder(column: $table.rmssdMs, builder: (column) => column);

  GeneratedColumn<int> get restingHr =>
      $composableBuilder(column: $table.restingHr, builder: (column) => column);

  GeneratedColumn<String> get readiness =>
      $composableBuilder(column: $table.readiness, builder: (column) => column);

  GeneratedColumn<String> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get baselineMean => $composableBuilder(
    column: $table.baselineMean,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baselineSd => $composableBuilder(
    column: $table.baselineSd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cv7day =>
      $composableBuilder(column: $table.cv7day, builder: (column) => column);

  GeneratedColumn<int> get rrCount =>
      $composableBuilder(column: $table.rrCount, builder: (column) => column);

  GeneratedColumn<int> get dayCount =>
      $composableBuilder(column: $table.dayCount, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DailyWellnessEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyWellnessEntriesTable,
          DailyWellnessEntry,
          $$DailyWellnessEntriesTableFilterComposer,
          $$DailyWellnessEntriesTableOrderingComposer,
          $$DailyWellnessEntriesTableAnnotationComposer,
          $$DailyWellnessEntriesTableCreateCompanionBuilder,
          $$DailyWellnessEntriesTableUpdateCompanionBuilder,
          (
            DailyWellnessEntry,
            BaseReferences<
              _$AppDatabase,
              $DailyWellnessEntriesTable,
              DailyWellnessEntry
            >,
          ),
          DailyWellnessEntry,
          PrefetchHooks Function()
        > {
  $$DailyWellnessEntriesTableTableManager(
    _$AppDatabase db,
    $DailyWellnessEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyWellnessEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyWellnessEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyWellnessEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> athleteId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> lnRmssd = const Value.absent(),
                Value<double> rmssdMs = const Value.absent(),
                Value<int> restingHr = const Value.absent(),
                Value<String> readiness = const Value.absent(),
                Value<String> stability = const Value.absent(),
                Value<double?> baselineMean = const Value.absent(),
                Value<double?> baselineSd = const Value.absent(),
                Value<double?> cv7day = const Value.absent(),
                Value<int> rrCount = const Value.absent(),
                Value<int> dayCount = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => DailyWellnessEntriesCompanion(
                id: id,
                athleteId: athleteId,
                date: date,
                lnRmssd: lnRmssd,
                rmssdMs: rmssdMs,
                restingHr: restingHr,
                readiness: readiness,
                stability: stability,
                baselineMean: baselineMean,
                baselineSd: baselineSd,
                cv7day: cv7day,
                rrCount: rrCount,
                dayCount: dayCount,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String athleteId,
                required DateTime date,
                required double lnRmssd,
                required double rmssdMs,
                required int restingHr,
                required String readiness,
                required String stability,
                Value<double?> baselineMean = const Value.absent(),
                Value<double?> baselineSd = const Value.absent(),
                Value<double?> cv7day = const Value.absent(),
                required int rrCount,
                Value<int> dayCount = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => DailyWellnessEntriesCompanion.insert(
                id: id,
                athleteId: athleteId,
                date: date,
                lnRmssd: lnRmssd,
                rmssdMs: rmssdMs,
                restingHr: restingHr,
                readiness: readiness,
                stability: stability,
                baselineMean: baselineMean,
                baselineSd: baselineSd,
                cv7day: cv7day,
                rrCount: rrCount,
                dayCount: dayCount,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyWellnessEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyWellnessEntriesTable,
      DailyWellnessEntry,
      $$DailyWellnessEntriesTableFilterComposer,
      $$DailyWellnessEntriesTableOrderingComposer,
      $$DailyWellnessEntriesTableAnnotationComposer,
      $$DailyWellnessEntriesTableCreateCompanionBuilder,
      $$DailyWellnessEntriesTableUpdateCompanionBuilder,
      (
        DailyWellnessEntry,
        BaseReferences<
          _$AppDatabase,
          $DailyWellnessEntriesTable,
          DailyWellnessEntry
        >,
      ),
      DailyWellnessEntry,
      PrefetchHooks Function()
    >;
typedef $$SessionEntriesTableCreateCompanionBuilder =
    SessionEntriesCompanion Function({
      Value<int> id,
      required String athleteId,
      required DateTime date,
      required DateTime startTime,
      Value<DateTime?> endTime,
      required int durationS,
      required double trimpEdwards,
      required double hrAvg,
      required int hrMax,
      required int hrMin,
      required String zoneSecondsJson,
      required String zonePercentJson,
      Value<String?> label,
      Value<DateTime?> syncedAt,
    });
typedef $$SessionEntriesTableUpdateCompanionBuilder =
    SessionEntriesCompanion Function({
      Value<int> id,
      Value<String> athleteId,
      Value<DateTime> date,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<int> durationS,
      Value<double> trimpEdwards,
      Value<double> hrAvg,
      Value<int> hrMax,
      Value<int> hrMin,
      Value<String> zoneSecondsJson,
      Value<String> zonePercentJson,
      Value<String?> label,
      Value<DateTime?> syncedAt,
    });

class $$SessionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionEntriesTable> {
  $$SessionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get trimpEdwards => $composableBuilder(
    column: $table.trimpEdwards,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hrAvg => $composableBuilder(
    column: $table.hrAvg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrMin => $composableBuilder(
    column: $table.hrMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneSecondsJson => $composableBuilder(
    column: $table.zoneSecondsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zonePercentJson => $composableBuilder(
    column: $table.zonePercentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionEntriesTable> {
  $$SessionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get athleteId => $composableBuilder(
    column: $table.athleteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get trimpEdwards => $composableBuilder(
    column: $table.trimpEdwards,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hrAvg => $composableBuilder(
    column: $table.hrAvg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrMin => $composableBuilder(
    column: $table.hrMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneSecondsJson => $composableBuilder(
    column: $table.zoneSecondsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zonePercentJson => $composableBuilder(
    column: $table.zonePercentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionEntriesTable> {
  $$SessionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get athleteId =>
      $composableBuilder(column: $table.athleteId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get trimpEdwards => $composableBuilder(
    column: $table.trimpEdwards,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hrAvg =>
      $composableBuilder(column: $table.hrAvg, builder: (column) => column);

  GeneratedColumn<int> get hrMax =>
      $composableBuilder(column: $table.hrMax, builder: (column) => column);

  GeneratedColumn<int> get hrMin =>
      $composableBuilder(column: $table.hrMin, builder: (column) => column);

  GeneratedColumn<String> get zoneSecondsJson => $composableBuilder(
    column: $table.zoneSecondsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zonePercentJson => $composableBuilder(
    column: $table.zonePercentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SessionEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionEntriesTable,
          SessionEntry,
          $$SessionEntriesTableFilterComposer,
          $$SessionEntriesTableOrderingComposer,
          $$SessionEntriesTableAnnotationComposer,
          $$SessionEntriesTableCreateCompanionBuilder,
          $$SessionEntriesTableUpdateCompanionBuilder,
          (
            SessionEntry,
            BaseReferences<_$AppDatabase, $SessionEntriesTable, SessionEntry>,
          ),
          SessionEntry,
          PrefetchHooks Function()
        > {
  $$SessionEntriesTableTableManager(
    _$AppDatabase db,
    $SessionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> athleteId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> trimpEdwards = const Value.absent(),
                Value<double> hrAvg = const Value.absent(),
                Value<int> hrMax = const Value.absent(),
                Value<int> hrMin = const Value.absent(),
                Value<String> zoneSecondsJson = const Value.absent(),
                Value<String> zonePercentJson = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => SessionEntriesCompanion(
                id: id,
                athleteId: athleteId,
                date: date,
                startTime: startTime,
                endTime: endTime,
                durationS: durationS,
                trimpEdwards: trimpEdwards,
                hrAvg: hrAvg,
                hrMax: hrMax,
                hrMin: hrMin,
                zoneSecondsJson: zoneSecondsJson,
                zonePercentJson: zonePercentJson,
                label: label,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String athleteId,
                required DateTime date,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                required int durationS,
                required double trimpEdwards,
                required double hrAvg,
                required int hrMax,
                required int hrMin,
                required String zoneSecondsJson,
                required String zonePercentJson,
                Value<String?> label = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => SessionEntriesCompanion.insert(
                id: id,
                athleteId: athleteId,
                date: date,
                startTime: startTime,
                endTime: endTime,
                durationS: durationS,
                trimpEdwards: trimpEdwards,
                hrAvg: hrAvg,
                hrMax: hrMax,
                hrMin: hrMin,
                zoneSecondsJson: zoneSecondsJson,
                zonePercentJson: zonePercentJson,
                label: label,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionEntriesTable,
      SessionEntry,
      $$SessionEntriesTableFilterComposer,
      $$SessionEntriesTableOrderingComposer,
      $$SessionEntriesTableAnnotationComposer,
      $$SessionEntriesTableCreateCompanionBuilder,
      $$SessionEntriesTableUpdateCompanionBuilder,
      (
        SessionEntry,
        BaseReferences<_$AppDatabase, $SessionEntriesTable, SessionEntry>,
      ),
      SessionEntry,
      PrefetchHooks Function()
    >;
typedef $$AthletesTableCreateCompanionBuilder =
    AthletesCompanion Function({
      required String id,
      required String name,
      Value<String?> sensorId,
      Value<int?> hrMax,
      Value<int?> hrRest,
      Value<String> zoneConfigJson,
      Value<DateTime?> dateOfBirth,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AthletesTableUpdateCompanionBuilder =
    AthletesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> sensorId,
      Value<int?> hrMax,
      Value<int?> hrRest,
      Value<String> zoneConfigJson,
      Value<DateTime?> dateOfBirth,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AthletesTableFilterComposer
    extends Composer<_$AppDatabase, $AthletesTable> {
  $$AthletesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensorId => $composableBuilder(
    column: $table.sensorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrRest => $composableBuilder(
    column: $table.hrRest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneConfigJson => $composableBuilder(
    column: $table.zoneConfigJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AthletesTableOrderingComposer
    extends Composer<_$AppDatabase, $AthletesTable> {
  $$AthletesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensorId => $composableBuilder(
    column: $table.sensorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrRest => $composableBuilder(
    column: $table.hrRest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneConfigJson => $composableBuilder(
    column: $table.zoneConfigJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AthletesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AthletesTable> {
  $$AthletesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sensorId =>
      $composableBuilder(column: $table.sensorId, builder: (column) => column);

  GeneratedColumn<int> get hrMax =>
      $composableBuilder(column: $table.hrMax, builder: (column) => column);

  GeneratedColumn<int> get hrRest =>
      $composableBuilder(column: $table.hrRest, builder: (column) => column);

  GeneratedColumn<String> get zoneConfigJson => $composableBuilder(
    column: $table.zoneConfigJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AthletesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AthletesTable,
          Athlete,
          $$AthletesTableFilterComposer,
          $$AthletesTableOrderingComposer,
          $$AthletesTableAnnotationComposer,
          $$AthletesTableCreateCompanionBuilder,
          $$AthletesTableUpdateCompanionBuilder,
          (Athlete, BaseReferences<_$AppDatabase, $AthletesTable, Athlete>),
          Athlete,
          PrefetchHooks Function()
        > {
  $$AthletesTableTableManager(_$AppDatabase db, $AthletesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AthletesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AthletesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AthletesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sensorId = const Value.absent(),
                Value<int?> hrMax = const Value.absent(),
                Value<int?> hrRest = const Value.absent(),
                Value<String> zoneConfigJson = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AthletesCompanion(
                id: id,
                name: name,
                sensorId: sensorId,
                hrMax: hrMax,
                hrRest: hrRest,
                zoneConfigJson: zoneConfigJson,
                dateOfBirth: dateOfBirth,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> sensorId = const Value.absent(),
                Value<int?> hrMax = const Value.absent(),
                Value<int?> hrRest = const Value.absent(),
                Value<String> zoneConfigJson = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AthletesCompanion.insert(
                id: id,
                name: name,
                sensorId: sensorId,
                hrMax: hrMax,
                hrRest: hrRest,
                zoneConfigJson: zoneConfigJson,
                dateOfBirth: dateOfBirth,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AthletesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AthletesTable,
      Athlete,
      $$AthletesTableFilterComposer,
      $$AthletesTableOrderingComposer,
      $$AthletesTableAnnotationComposer,
      $$AthletesTableCreateCompanionBuilder,
      $$AthletesTableUpdateCompanionBuilder,
      (Athlete, BaseReferences<_$AppDatabase, $AthletesTable, Athlete>),
      Athlete,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyWellnessEntriesTableTableManager get dailyWellnessEntries =>
      $$DailyWellnessEntriesTableTableManager(_db, _db.dailyWellnessEntries);
  $$SessionEntriesTableTableManager get sessionEntries =>
      $$SessionEntriesTableTableManager(_db, _db.sessionEntries);
  $$AthletesTableTableManager get athletes =>
      $$AthletesTableTableManager(_db, _db.athletes);
}
