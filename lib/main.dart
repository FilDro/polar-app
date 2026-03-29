import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/rust_init.dart';
import 'services/ble_service.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';
import 'theme/theme_notifier.dart';
import 'theme/typography.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initRustBridge();
  } catch (e) {
    debugPrint('Rust bridge init FAILED: $e');
  }

  // Initialize Supabase (non-blocking if offline)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed (offline mode): $e');
  }

  BleService.instance.startPolling();
  runApp(const PolarApp());
}

class PolarApp extends StatelessWidget {
  const PolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeNotifier.instance,
      builder: (context, appTheme, _) {
        return MaterialApp.router(
          title: 'KINE',
          debugShowCheckedModeBanner: false,
          themeMode: switch (appTheme) {
            AppTheme.kineFlow => ThemeMode.light,
            AppTheme.dark     => ThemeMode.dark,
            AppTheme.kineApp  => ThemeMode.system,
          },
          theme: appTheme == AppTheme.kineApp
              ? _kineAppLightTheme()
              : _kineFlowTheme(),
          darkTheme: appTheme == AppTheme.kineApp
              ? _kineAppDarkTheme()
              : _kineDarkTheme(),
          routerConfig: appRouter,
        );
      },
    );
  }
}

// ── Theme builders ───────────────────────────────────────────────

ThemeData _kineAppLightTheme() => ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: KineColors.blue3,
        onPrimary: Colors.white,
        secondary: KineColors.gray4,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: KineColors.gray6,
        surfaceContainerHighest: KineColors.gray0,
        error: KineColors.red3,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      extensions: [KineColors.light, KineTypography.web],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KineColors.blue3,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KineColors.gray6,
          side: const BorderSide(color: KineColors.gray1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: KineColors.gray6,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: KineColors.gray1, width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: KineColors.blue3.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? KineColors.blue3 : KineColors.gray3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? KineColors.blue3 : KineColors.gray3,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: KineColors.gray0,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KineRadius.lg),
          side: const BorderSide(color: KineColors.gray1, width: 0.5),
        ),
      ),
    );

ThemeData _kineAppDarkTheme() => ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: KineColors.blue2,
        onPrimary: Colors.white,
        secondary: KineColors.gray3,
        onSecondary: Colors.white,
        surface: KineColors.gray6,
        onSurface: KineColors.gray0,
        surfaceContainerHighest: KineColors.gray5,
        error: const Color(0xFFFA8985), // red2
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: KineColors.gray6,
      extensions: [KineColors.appDark, KineTypography.web],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KineColors.blue2,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KineColors.gray0,
          side: const BorderSide(color: KineColors.gray4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KineColors.gray6,
        foregroundColor: KineColors.gray0,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: KineColors.gray4, width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KineColors.gray6,
        indicatorColor: KineColors.blue2.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            color: selected ? KineColors.blue2 : KineColors.gray3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? KineColors.blue2 : KineColors.gray3,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: KineColors.gray5,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KineRadius.lg),
          side: const BorderSide(color: KineColors.gray4, width: 0.5),
        ),
      ),
    );

ThemeData _kineDarkTheme() => ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: KineColors.gold2,
        onPrimary: KineColors.webBg,
        secondary: KineColors.blue3,
        onSecondary: Colors.white,
        surface: KineColors.webBg,
        onSurface: KineColors.webText,
        surfaceContainerHighest: KineColors.webSurfaceMuted,
        error: KineColors.red3,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: KineColors.webBg,
      textTheme: kineWebTextTheme,
      extensions: [KineColors.dark, KineTypography.web],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KineColors.gold2,
          foregroundColor: KineColors.webBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KineColors.webText,
          side: const BorderSide(color: KineColors.webBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KineColors.webBg,
        foregroundColor: KineColors.webText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KineColors.webBg,
        indicatorColor: KineColors.gold2.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            color: selected ? KineColors.gold2 : KineColors.webTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? KineColors.gold2 : KineColors.webTextSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: KineColors.webSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KineRadius.lg),
          side: const BorderSide(color: KineColors.webBorder, width: 0.5),
        ),
      ),
    );

ThemeData _kineFlowTheme() => ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: KineColors.slate900,
        onPrimary: Colors.white,
        secondary: KineColors.slate700,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: KineColors.slate900,
        surfaceContainerHighest: KineColors.slate100,
        error: const Color(0xFFDC2626),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: kineFlowTextTheme,
      extensions: [KineColors.kineFlow, KineTypography.web],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KineColors.slate900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KineColors.slate900,
          side: const BorderSide(color: KineColors.slate200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KineRadius.md),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: KineColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: KineColors.slate200, width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: KineColors.slate900.withValues(alpha: 0.08),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? KineColors.slate900 : KineColors.slate500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? KineColors.slate900 : KineColors.slate500,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: KineColors.slate50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KineRadius.lg),
          side: const BorderSide(color: KineColors.slate200, width: 0.5),
        ),
      ),
    );
