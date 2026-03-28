import 'package:flutter/material.dart';

/// KINE design system colors (v3.0).
/// Accessed via KineColors.of(context).
class KineColors extends ThemeExtension<KineColors> {
  // Brand
  static const gold2 = Color(0xFFFFCF00);
  static const green2 = Color(0xFF16C47F);
  static const blue3 = Color(0xFF3081DD);
  static const yellow0 = Color(0xFFFFD65A);
  static const orange1 = Color(0xFFFF9D23);
  static const red3 = Color(0xFFF93827);

  // Neutrals (warm gray)
  static const gray0 = Color(0xFFEFF1F0);
  static const gray1 = Color(0xFFCED4D1);
  static const gray2 = Color(0xFFA8ADAA);
  static const gray3 = Color(0xFF838785);
  static const gray4 = Color(0xFF606361);
  static const gray5 = Color(0xFF3F4140);
  static const gray6 = Color(0xFF212221);

  // BLE connection states
  static const bleDisconnected = gray3;
  static const bleScanning = blue3;
  static const bleConnecting = yellow0;
  static const bleConnected = green2;
  static const bleError = red3;

  // Semantic tokens
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
    accent: Color(0xFFCC9F00), // gold3
    success: green2,
    warning: Color(0xFFCC7B00), // orange2
    error: red3,
  );

  static const dark = KineColors._(
    surface: gray6,
    surfaceCard: gray5,
    surfaceElevated: gray4,
    surfaceBorder: gray4,
    textPrimary: gray0,
    textSecondary: gray1,
    textMuted: gray3,
    textDisabled: gray3,
    primary: Color(0xFF75A6F6), // blue2
    accent: gold2,
    success: Color(0xFF1EF09D), // green1
    warning: orange1,
    error: Color(0xFFFA8985), // red2
  );

  static KineColors of(BuildContext context) {
    return Theme.of(context).extension<KineColors>() ?? light;
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
