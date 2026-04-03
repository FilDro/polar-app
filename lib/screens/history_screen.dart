import 'package:flutter/material.dart';
import '../database/database.dart';
import '../services/athlete_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/readiness_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<_HistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final athleteId = AthleteService.instance.athleteId;
    if (athleteId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final db = AppDatabase.instance;
    final wellnessRows = await db.getLast7Days(athleteId);
    final wellnessMap = {for (final w in wellnessRows) _dateKey(w.date): w};
    final dates = wellnessRows.map((w) => _dateKey(w.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final entries = <_HistoryEntry>[];
    for (final dateKey in dates) {
      final w = wellnessMap[dateKey];
      final sessions =
          await db.getSessionsForDate(athleteId, DateTime.parse(dateKey));
      entries.add(_HistoryEntry(
        date: dateKey,
        readiness: w?.readiness,
        lnRmssd: w?.lnRmssd,
        restingHr: w?.restingHr,
        trimp: sessions.isNotEmpty ? sessions.first.trimpEdwards : null,
      ));
    }

    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(KineSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 64, color: colors.textMuted),
                    const SizedBox(height: KineSpacing.md),
                    Text(
                      'No history yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: KineSpacing.sm),
                    Text(
                      'Morning checks and training sessions will appear here.',
                      style: TextStyle(fontSize: 14, color: colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(KineSpacing.md),
              itemCount: _entries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: KineSpacing.sm),
              itemBuilder: (context, i) =>
                  _HistoryRow(entry: _entries[i], colors: colors),
            ),
    );
  }
}

class _HistoryEntry {
  final String date;
  final String? readiness;
  final double? lnRmssd;
  final int? restingHr;
  final double? trimp;

  const _HistoryEntry({
    required this.date,
    this.readiness,
    this.lnRmssd,
    this.restingHr,
    this.trimp,
  });
}

class _HistoryRow extends StatelessWidget {
  final _HistoryEntry entry;
  final KineColors colors;

  const _HistoryRow({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.inset),
        child: Row(
          children: [
            ReadinessDot(readiness: entry.readiness),
            const SizedBox(width: KineSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.date,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: KineSpacing.xs),
                  Row(
                    children: [
                      if (entry.lnRmssd != null)
                        Text(
                          'lnRMSSD ${entry.lnRmssd!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      if (entry.lnRmssd != null && entry.restingHr != null)
                        Text('  |  ',
                            style: TextStyle(
                                fontSize: 12, color: colors.textMuted)),
                      if (entry.restingHr != null)
                        Text(
                          '${entry.restingHr} bpm',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      if ((entry.lnRmssd != null || entry.restingHr != null) &&
                          entry.trimp != null)
                        Text('  |  ',
                            style: TextStyle(
                                fontSize: 12, color: colors.textMuted)),
                      if (entry.trimp != null)
                        Text(
                          'TRIMP ${entry.trimp!.round()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
