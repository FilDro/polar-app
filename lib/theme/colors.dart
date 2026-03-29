import 'package:flutter/material.dart';

/// KINE design system colors (v3.0) — website convention.
///
/// Near-black background (#0A0A0A), gold primary CTA, translucent surfaces.
/// See design.md sections 2 (Web neutrals) and 3 (Web tokens).
class KineColors extends ThemeExtension<KineColors> {
  // ── Brand colors ────────────────────────────────────────────
  static const gold2 = Color(0xFFFFCF00);
  static const gold3 = Color(0xFFCC9F00);
  static const green2 = Color(0xFF16C47F);
  static const blue3 = Color(0xFF3081DD);
  static const yellow0 = Color(0xFFFFD65A);
  static const orange1 = Color(0xFFFF9D23);
  static const red3 = Color(0xFFF93827);

  // ── Warm gray (data-viz, BLE states — not theme surfaces) ──
  static const gray0 = Color(0xFFEFF1F0);
  static const gray1 = Color(0xFFCED4D1);
  static const gray2 = Color(0xFFA8ADAA);
  static const gray3 = Color(0xFF838785);
  static const gray4 = Color(0xFF606361);
  static const gray5 = Color(0xFF3F4140);
  static const gray6 = Color(0xFF212221);

  // ── Slate palette (KineFlow light theme) ────────────────────
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate700 = Color(0xFF334155);
  static const slate900 = Color(0xFF0F172A);

  // ── Web neutrals (near-black palette) ───────────────────────
  static const webBg = Color(0xFF0A0A0A);
  static const webText = Color(0xFFEEEEE9);
  static const webTextSecondary = Color(0xFFA0A09C);
  static const webTextTertiary = Color(0xFF6B6B68);
  // Composited on #0A0A0A for const-compatibility:
  static const webSurfaceCard = Color(0xFF171717);   // rgba(255,255,255,0.05)
  static const webSurfaceMuted = Color(0xFF1E1E1E);  // rgba(255,255,255,0.08)
  static const webBorder = Color(0xFF282828);         // rgba(255,255,255,0.12)

  // ── BLE connection states (brightness-independent) ──────────
  static const bleDisconnected = gray3;
  static const bleScanning = blue3;
  static const bleConnecting = yellow0;
  static const bleConnected = green2;
  static const bleError = red3;

  // ── Semantic tokens ─────────────────────────────────────────
  final Color surface;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color primary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;

  const KineColors._({
    required this.surface,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.primary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
  });

  // ── Light theme (kept as compile-time fallback) ─────────────
  static const light = KineColors._(
    surface: Colors.white,
    surfaceCard: gray0,
    surfaceElevated: gray1,
    surfaceBorder: gray1,
    textPrimary: gray6,
    textSecondary: gray4,
    textMuted: gray3,
    textDisabled: gray2,
    primary: blue3,
    accent: gold3,
    success: green2,
    warning: Color(0xFFCC7B00), // orange2
    error: red3,
  );

  // ── KineFlow theme (slate light, minimalistic) ──────────────
  static const kineFlow = KineColors._(
    surface: Colors.white,
    surfaceCard: slate50,
    surfaceElevated: slate100,
    surfaceBorder: slate200,
    textPrimary: slate900,
    textSecondary: slate700,
    textMuted: slate500,
    textDisabled: slate400,
    primary: slate900,
    accent: slate700,
    success: Color(0xFF16A34A), // green-600
    warning: Color(0xFFD97706), // amber-600
    error: Color(0xFFDC2626),   // red-600
  );

  // ── Dark theme (website convention) ─────────────────────────
  static const dark = KineColors._(
    surface: webBg,                   // #0A0A0A
    surfaceCard: webSurfaceCard,      // #171717
    surfaceElevated: webSurfaceMuted, // #1E1E1E
    surfaceBorder: webBorder,         // #282828
    textPrimary: webText,             // #EEEEE9
    textSecondary: webTextSecondary,  // #A0A09C
    textMuted: webTextTertiary,       // #6B6B68
    textDisabled: Color(0xFF4A4A48),
    primary: gold2,                   // Gold is the primary CTA
    accent: blue3,                    // Blue = KineSense identity
    success: Color(0xFF1EF09D),       // green1
    warning: orange1,
    error: Color(0xFFFA8985),         // red2
  );

  static KineColors of(BuildContext context) {
    return Theme.of(context).extension<KineColors>() ?? dark;
  }

  static Color bleStateColor(String status) {
    return switch (status) {
      'scanning' => bleScanning,
      'connecting' => bleConnecting,
      'connected' => bleConnected,
      _ => bleDisconnected,
    };
  }

  @override
  KineColors copyWith() => this;

  @override
  KineColors lerp(KineColors? other, double t) => t < 0.5 ? this : (other ?? this);
}
