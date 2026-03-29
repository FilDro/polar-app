import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Large circular indicator showing readiness state.
///
/// [readiness] should be one of: "green", "amber", "red", or null (no data).
class ReadinessIndicator extends StatelessWidget {
  final String? readiness;
  final double size;

  const ReadinessIndicator({
    super.key,
    required this.readiness,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final (fillColor, label) = _resolveState(readiness, colors);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor.withValues(alpha: 0.18),
        border: Border.all(color: fillColor, width: 4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: size * 0.14,
          fontWeight: FontWeight.w700,
          color: fillColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static (Color, String) _resolveState(String? readiness, KineColors colors) {
    return switch (readiness?.toLowerCase()) {
      'green' => (KineColors.green2, 'GREEN'),
      'amber' => (KineColors.yellow0, 'AMBER'),
      'red' => (KineColors.red3, 'RED'),
      _ => (colors.textMuted, '?'),
    };
  }
}

/// Small dot used in list rows to indicate readiness.
class ReadinessDot extends StatelessWidget {
  final String? readiness;
  final double size;

  const ReadinessDot({
    super.key,
    required this.readiness,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (readiness?.toLowerCase()) {
      'green' => KineColors.green2,
      'amber' => KineColors.yellow0,
      'red' => KineColors.red3,
      _ => KineColors.gray3,
    };

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: KineSpacing.sm),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
