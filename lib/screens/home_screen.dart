import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/readiness_indicator.dart';

/// Athlete home screen — shows today's readiness and last session summary.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ble = BleService.instance;

  // TODO: Replace with DB-backed state once Phase 4 is wired up
  String? _todayReadiness;
  double? _todayLnRmssd;
  double? _todayRestingHr;
  // Last session
  double? _lastTrimp;
  double? _lastDurationS;
  String? _lastSessionDate;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Called when returning from the morning check screen with a result.
  void _onMorningCheckResult(Map<String, dynamic>? result) {
    if (result == null) return;
    setState(() {
      _todayReadiness = result['readiness'] as String?;
      _todayLnRmssd = result['lnRmssd'] as double?;
      _todayRestingHr = result['restingHr'] as double?;
    });
  }

  /// Called when returning from the sync session screen with a result.
  void _onSyncResult(Map<String, dynamic>? result) {
    if (result == null) return;
    setState(() {
      _lastTrimp = result['trimp'] as double?;
      _lastDurationS = result['durationS'] as double?;
      _lastSessionDate = result['date'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final hasCheckToday = _todayReadiness != null;
    final hasSession = _lastTrimp != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KINE'),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: KineSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: KineColors.bleStateColor(_ble.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Text(
                  _ble.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Readiness section
            Center(
              child: ReadinessIndicator(readiness: _todayReadiness),
            ),
            const SizedBox(height: KineSpacing.lg),

            if (hasCheckToday) ...[
              _WellnessCard(
                readiness: _todayReadiness!,
                lnRmssd: _todayLnRmssd ?? 0,
                restingHr: _todayRestingHr ?? 0,
                colors: colors,
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () async {
                  final result = await context.push<Map<String, dynamic>>(
                    '/morning-check',
                  );
                  _onMorningCheckResult(result);
                },
                icon: const Icon(Icons.favorite_border),
                label: const Text('Record Morning Check'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],

            const SizedBox(height: KineSpacing.lg),

            // Last session section
            if (hasSession)
              _SessionCard(
                trimp: _lastTrimp!,
                durationS: _lastDurationS ?? 0,
                date: _lastSessionDate ?? '',
                colors: colors,
              )
            else
              Card(
                color: colors.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(KineSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.directions_run,
                          color: colors.textMuted, size: 32),
                      const SizedBox(width: KineSpacing.inset),
                      Expanded(
                        child: Text(
                          'No sessions yet',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: KineSpacing.md),

            FilledButton.icon(
              onPressed: () async {
                final result = await context.push<Map<String, dynamic>>(
                  '/sync-session',
                );
                _onSyncResult(result);
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Training Data'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellnessCard extends StatelessWidget {
  final String readiness;
  final double lnRmssd;
  final double restingHr;
  final KineColors colors;

  const _WellnessCard({
    required this.readiness,
    required this.lnRmssd,
    required this.restingHr,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Morning Check',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.inset),
            Row(
              children: [
                _Metric('lnRMSSD', lnRmssd.toStringAsFixed(2), colors),
                _Metric(
                    'Resting HR', '${restingHr.round()} bpm', colors),
                _Metric('Readiness', readiness.toUpperCase(), colors),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final double trimp;
  final double durationS;
  final String date;
  final KineColors colors;

  const _SessionCard({
    required this.trimp,
    required this.durationS,
    required this.date,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (durationS / 60).round();
    return Card(
      color: colors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Last Session',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: KineSpacing.inset),
            Row(
              children: [
                _Metric('TRIMP', trimp.round().toString(), colors),
                _Metric('Duration', '$minutes min', colors),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final KineColors colors;

  const _Metric(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: KineSpacing.xs),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
