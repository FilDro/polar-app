import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Horizontal stacked bar showing HR zone distribution.
///
/// [zonePercent] must have 6 elements (zones 0-5), each a percentage 0-100.
/// Zone colors follow the standard 5-zone model with an additional recovery zone.
class ZoneBar extends StatelessWidget {
  final List<double> zonePercent;
  final double height;

  const ZoneBar({
    super.key,
    required this.zonePercent,
    this.height = 24,
  });

  static const _zoneColors = [
    KineColors.gray2, // Zone 0 — recovery / below threshold
    KineColors.blue3, // Zone 1 — easy
    KineColors.green2, // Zone 2 — moderate
    KineColors.yellow0, // Zone 3 — tempo
    KineColors.orange1, // Zone 4 — threshold
    KineColors.red3, // Zone 5 — max
  ];

  static const _zoneLabels = ['Z0', 'Z1', 'Z2', 'Z3', 'Z4', 'Z5'];

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    // Clamp to 6 zones
    final zones = List.generate(6, (i) {
      if (i < zonePercent.length) return zonePercent[i].clamp(0, 100);
      return 0.0;
    });

    final total = zones.fold(0.0, (a, b) => a + b);
    if (total <= 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No zone data',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(KineRadius.sm),
          child: SizedBox(
            height: height,
            child: Row(
              children: List.generate(6, (i) {
                final pct = zones[i] / total;
                if (pct <= 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (pct * 1000).round(),
                  child: Container(color: _zoneColors[i]),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: KineSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            if (zones[i] <= 0) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _zoneColors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '${_zoneLabels[i]} ${zones[i].round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
