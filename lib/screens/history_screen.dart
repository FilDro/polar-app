import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/readiness_indicator.dart';

/// History tab — shows recent wellness entries and sessions.
///
/// V1 is a placeholder. Entries will be loaded from the DB once Phase 4
/// is wired up. Charts (fl_chart) will come in a later phase.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    // TODO: Load from DB once Phase 4 is wired up
    final entries = <_HistoryEntry>[];

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(KineSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: colors.textMuted,
                    ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(KineSpacing.md),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: KineSpacing.sm),
              itemBuilder: (context, i) {
                final e = entries[i];
                return _HistoryRow(entry: e, colors: colors);
              },
            ),
    );
  }
}

/// Placeholder model for history list items.
class _HistoryEntry {
  final String date;
  final String? readiness;
  final double? lnRmssd;
  final double? trimp;

  const _HistoryEntry({
    required this.date,
    this.readiness,
    this.lnRmssd,
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
                      if (entry.lnRmssd != null && entry.trimp != null)
                        Text(
                          '  |  ',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
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
