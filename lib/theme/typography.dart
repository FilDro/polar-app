import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KineFlow text theme — Inter for all UI text.
/// Slate-palette light design: clean, non-taxing, high readability.
final TextTheme kineFlowTextTheme = TextTheme(
  displayLarge:  GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700),
  displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600),
  displaySmall:  GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
  headlineLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500),
  headlineMedium:GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
  headlineSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
  titleLarge:    GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500),
  titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
  titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
  bodyLarge:     GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400),
  bodyMedium:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
  bodySmall:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
  labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
  labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
);

/// KINE web-convention text theme.
/// Oswald for all UI text, Source Code Pro for data/metrics.
final TextTheme kineWebTextTheme = TextTheme(
  // Display — Oswald
  displayLarge: GoogleFonts.oswald(fontSize: 34, fontWeight: FontWeight.w700),
  displayMedium: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.w600),
  displaySmall: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.w600),
  // Headline — Oswald
  headlineLarge: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.w500),
  headlineMedium: GoogleFonts.oswald(fontSize: 17, fontWeight: FontWeight.w600),
  headlineSmall: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.w600),
  // Title — Oswald
  titleLarge: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.w500),
  titleMedium: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.w500),
  titleSmall: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.w500),
  // Body — Oswald light
  bodyLarge: GoogleFonts.oswald(fontSize: 17, fontWeight: FontWeight.w400),
  bodyMedium: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.w400),
  bodySmall: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.w400),
  // Label — Oswald
  labelLarge: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.w500),
  labelMedium: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.w500),
);

/// Data/metric typography tokens via ThemeExtension.
/// Access via KineTypography.of(context).
class KineTypography extends ThemeExtension<KineTypography> {
  final TextStyle metricHero;
  final TextStyle metricValue;
  final TextStyle metricLabel;
  final TextStyle dataRegular;
  final TextStyle dataSmall;
  final TextStyle dataCaption;

  const KineTypography._({
    required this.metricHero,
    required this.metricValue,
    required this.metricLabel,
    required this.dataRegular,
    required this.dataSmall,
    required this.dataCaption,
  });

  static final web = KineTypography._(
    metricHero: GoogleFonts.sourceCodePro(fontSize: 72, fontWeight: FontWeight.w700),
    metricValue: GoogleFonts.sourceCodePro(fontSize: 20, fontWeight: FontWeight.w700),
    metricLabel: GoogleFonts.sourceCodePro(fontSize: 12, fontWeight: FontWeight.w400),
    dataRegular: GoogleFonts.sourceCodePro(fontSize: 17, fontWeight: FontWeight.w400),
    dataSmall: GoogleFonts.sourceCodePro(fontSize: 15, fontWeight: FontWeight.w400),
    dataCaption: GoogleFonts.sourceCodePro(fontSize: 12, fontWeight: FontWeight.w500),
  );

  static KineTypography of(BuildContext context) {
    return Theme.of(context).extension<KineTypography>() ?? web;
  }

  @override
  KineTypography copyWith() => this;

  @override
  KineTypography lerp(KineTypography? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
