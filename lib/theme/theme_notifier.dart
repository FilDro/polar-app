import 'package:flutter/foundation.dart';

/// Available app themes.
enum AppTheme {
  /// Near-black background, gold primary, Oswald. Original KINE web convention.
  dark,

  /// White background, slate palette, Inter. Minimalistic / low-visual-tax.
  kineFlow,
}

/// Singleton notifier that drives theme switching across the app.
/// Access via [ThemeNotifier.instance]; listen via [ValueListenableBuilder].
class ThemeNotifier extends ValueNotifier<AppTheme> {
  ThemeNotifier._() : super(AppTheme.dark);

  static final instance = ThemeNotifier._();

  bool get isKineFlow => value == AppTheme.kineFlow;

  void setTheme(AppTheme theme) => value = theme;
}
