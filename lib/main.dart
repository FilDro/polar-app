import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/rust_init.dart';
import 'services/ble_service.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';
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
    return MaterialApp.router(
      title: 'KINE',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
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
        // ── Component overrides ────────────────────────────
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
      ),
      routerConfig: appRouter,
    );
  }
}
