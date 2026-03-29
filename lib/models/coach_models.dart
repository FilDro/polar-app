// Data classes for the coach dashboard.
//
// These mirror the Supabase schema but are plain Dart objects
// for UI consumption. No ORM or code generation needed.

class AthleteReadiness {
  final String athleteId;
  final String name;
  final String readiness; // green, amber, red, or empty for no data
  final int restingHr;
  final double lnRmssd;
  final bool hasData;

  const AthleteReadiness({
    required this.athleteId,
    required this.name,
    required this.readiness,
    required this.restingHr,
    required this.lnRmssd,
    required this.hasData,
  });

  /// Sort priority: red=0, amber=1, green=2, missing=3.
  int get sortPriority => switch (readiness) {
        'red' => 0,
        'amber' => 1,
        'green' => 2,
        _ => 3,
      };
}

class AthleteSession {
  final String athleteId;
  final String name;
  final double trimp;
  final int hrAvg;
  final int hrMax;
  final int durationMin;
  final List<double> zonePercent; // 6 elements: Z0-Z5

  const AthleteSession({
    required this.athleteId,
    required this.name,
    required this.trimp,
    required this.hrAvg,
    required this.hrMax,
    required this.durationMin,
    required this.zonePercent,
  });
}

class AthleteTrendDay {
  final DateTime date;
  final double? lnRmssd;
  final String? readiness;
  final int? restingHr;
  final double? trimp;

  const AthleteTrendDay({
    required this.date,
    this.lnRmssd,
    this.readiness,
    this.restingHr,
    this.trimp,
  });
}

class AthleteTrend {
  final String athleteId;
  final String name;
  final List<AthleteTrendDay> days;
  final double acuteLoad;
  final double chronicLoad;
  final double? acwr;
  final double? monotony;
  final double? strain;

  const AthleteTrend({
    required this.athleteId,
    required this.name,
    required this.days,
    required this.acuteLoad,
    required this.chronicLoad,
    this.acwr,
    this.monotony,
    this.strain,
  });
}

class TeamAthleteRow {
  final String athleteId;
  final String name;
  final double weekTrimp;
  final double? acwr;
  final String riskLevel; // LOW, OPTIMAL, ELEVATED, HIGH
  final String readiness; // green, amber, red, or empty
  final int redDays; // count of red readiness days this week

  const TeamAthleteRow({
    required this.athleteId,
    required this.name,
    required this.weekTrimp,
    this.acwr,
    required this.riskLevel,
    required this.readiness,
    required this.redDays,
  });
}

class TeamAlert {
  final String message;
  final String priority; // high, medium, low

  const TeamAlert({
    required this.message,
    required this.priority,
  });

  int get sortPriority => switch (priority) {
        'high' => 0,
        'medium' => 1,
        'low' => 2,
        _ => 3,
      };
}
