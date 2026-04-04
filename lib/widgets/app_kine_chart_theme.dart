import 'package:flutter/material.dart';
import 'package:kine_charts/kine_charts.dart';

import '../theme/colors.dart';

/// Bridges the app's design tokens into kine_charts light/dark theming.
class AppKineChartTheme extends StatelessWidget {
  final Widget child;

  const AppKineChartTheme({super.key, required this.child});

  static KineTheme themeFor(BuildContext context) {
    final colors = KineColors.of(context);
    final brightness = Theme.of(context).brightness;
    final base = brightness == Brightness.dark
        ? KineTheme.dark()
        : KineTheme.light();
    final axisColor = colors.surfaceBorder.withValues(
      alpha: brightness == Brightness.dark ? 0.90 : 0.75,
    );
    final gridColor = colors.surfaceBorder.withValues(
      alpha: brightness == Brightness.dark ? 0.60 : 0.45,
    );

    return base.copyWith(
      colorPalette: const [
        KineColors.blue3,
        KineColors.green2,
        KineColors.yellow0,
        KineColors.orange1,
        KineColors.red3,
        KineColors.gray2,
      ],
      backgroundColor: colors.surface,
      chartBackgroundColor: colors.surfaceCard,
      axisLineColor: axisColor,
      gridLineColor: gridColor,
      labelTextColor: colors.textMuted,
      legendTextColor: colors.textSecondary,
      valueTextColor: colors.textSecondary,
      titleTextColor: colors.textPrimary,
      highlightColor: colors.primary,
      tooltipBackgroundColor: colors.surfaceElevated,
      tooltipTextColor: colors.textPrimary,
      noDataTextColor: colors.textMuted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KineThemeScope(theme: themeFor(context), child: child);
  }
}
