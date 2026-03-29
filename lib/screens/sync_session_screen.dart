import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../services/sync_service.dart';
import '../services/athlete_service.dart';
import '../src/rust/api/polar_api.dart' as bridge;
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/zone_bar.dart';

/// Full-screen session sync and summary.
class SyncSessionScreen extends StatefulWidget {
  const SyncSessionScreen({super.key});

  @override
  State<SyncSessionScreen> createState() => _SyncSessionScreenState();
}

class _SyncSessionScreenState extends State<SyncSessionScreen> {
  final _ble = BleService.instance;
  final _athlete = AthleteService.instance;
  final _sync = SyncSessionService();
  String _selectedLabel = 'Training';

  static const _labels = ['Training', 'Match', 'Gym', 'Other'];

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _sync.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _sync.removeListener(_onSyncChanged);
    _sync.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onSyncChanged() {
    if (mounted) {
      // Auto-process when sync completes
      if (_sync.syncComplete && _sync.sessionSummary == null) {
        _sync.processSession(
          hrMax: _athlete.hrMax,
          hrRest: _athlete.hrRest,
        );
      }
      setState(() {});
    }
  }

  void _onSave() {
    // TODO: Store session in DB once Phase 4 is wired up
    final summary = _sync.sessionSummary;
    if (summary != null) {
      context.pop<Map<String, dynamic>>({
        'trimp': summary.trimpEdwards,
        'durationS': summary.durationS,
        'date': summary.startTime,
        'label': _selectedLabel,
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final isConnected = _ble.isConnected;
    final isSyncing = _sync.isSyncing;
    final summary = _sync.sessionSummary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
        ),
        title: const Text('Sync Training'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConnected)
              _Banner('Connect a sensor first', colors.warning, colors),

            if (summary != null)
              Expanded(child: _SummaryView(
                summary: summary,
                selectedLabel: _selectedLabel,
                labels: _labels,
                onLabelChanged: (l) => setState(() => _selectedLabel = l),
                onSave: _onSave,
                colors: colors,
              ))
            else ...[
              // Sync button
              if (!isSyncing)
                FilledButton.icon(
                  onPressed: !isConnected ? null : () => _sync.startSync(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Training Data'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),

              // Progress
              if (isSyncing) ...[
                const SizedBox(height: KineSpacing.lg),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: KineSpacing.md),
                      Text(
                        'Syncing...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (_sync.progressText.isNotEmpty) ...[
                        const SizedBox(height: KineSpacing.sm),
                        Text(
                          _sync.progressText,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Error
              if (_sync.error.isNotEmpty) ...[
                const SizedBox(height: KineSpacing.md),
                Text(
                  _sync.error,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],

              // Show sync-complete-but-no-HR-data state
              if (_sync.syncComplete && summary == null) ...[
                const SizedBox(height: KineSpacing.lg),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          color: colors.textMuted, size: 48),
                      const SizedBox(height: KineSpacing.md),
                      Text(
                        'Sync complete, but no HR data was found.\nMake sure the sensor recorded a training session.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: KineSpacing.lg),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  final bridge.PolarSessionSummary summary;
  final String selectedLabel;
  final List<String> labels;
  final ValueChanged<String> onLabelChanged;
  final VoidCallback onSave;
  final KineColors colors;

  const _SummaryView({
    required this.summary,
    required this.selectedLabel,
    required this.labels,
    required this.onLabelChanged,
    required this.onSave,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (summary.durationS / 60).round();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TRIMP headline
          Card(
            color: colors.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(KineSpacing.md),
              child: Column(
                children: [
                  Text(
                    'TRIMP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: KineSpacing.sm),
                  Text(
                    summary.trimpEdwards.round().toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KineSpacing.md),

          // HR stats row
          Row(
            children: [
              _StatCard('Duration', '$minutes min', colors),
              const SizedBox(width: KineSpacing.sm),
              _StatCard('Avg HR', '${summary.hrAvg.round()} bpm', colors),
            ],
          ),
          const SizedBox(height: KineSpacing.sm),
          Row(
            children: [
              _StatCard('Max HR', '${summary.hrMax} bpm', colors),
              const SizedBox(width: KineSpacing.sm),
              _StatCard('Min HR', '${summary.hrMin} bpm', colors),
            ],
          ),
          const SizedBox(height: KineSpacing.md),

          // Zone distribution
          Text(
            'HR Zone Distribution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          ZoneBar(zonePercent: summary.zonePercent.toList()),

          const SizedBox(height: KineSpacing.lg),

          // Label picker
          Text(
            'Session Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          SegmentedButton<String>(
            segments: labels
                .map((l) => ButtonSegment(value: l, label: Text(l)))
                .toList(),
            selected: {selectedLabel},
            onSelectionChanged: (s) => onLabelChanged(s.first),
          ),

          const SizedBox(height: KineSpacing.lg),

          // Save button
          FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Save & Done'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final KineColors colors;

  const _StatCard(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: colors.surfaceCard,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(KineSpacing.inset),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
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
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  final KineColors colors;

  const _Banner(this.text, this.color, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.inset),
      margin: const EdgeInsets.only(bottom: KineSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KineRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(color: colors.textPrimary, fontSize: 13)),
    );
  }
}
