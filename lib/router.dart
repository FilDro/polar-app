import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/morning_check_screen.dart';
import 'screens/sync_session_screen.dart';
import 'screens/dev_screen.dart';
import 'screens/coach/coach_shell_screen.dart';
import 'screens/coach/readiness_grid_screen.dart';
import 'screens/coach/session_overview_screen.dart';
import 'screens/coach/trends_screen.dart';
import 'screens/coach/team_summary_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Application router using go_router.
///
/// Route tree:
/// ```
///   / → ShellRoute (athlete tabs)
///     /home       → HomeScreen (tab 0)
///     /history    → HistoryScreen (tab 1)
///     /settings   → SettingsScreen (tab 2)
///   /morning-check → MorningCheckScreen (push, full screen)
///   /sync-session  → SyncSessionScreen (push, full screen)
///   /dev           → DevShellScreen (existing debug screens)
///   /coach → ShellRoute (coach dashboard tabs)
///     /coach/readiness → ReadinessGridScreen (tab 0)
///     /coach/sessions  → SessionOverviewScreen (tab 1)
///     /coach/trends    → TrendsScreen (tab 2)
///     /coach/team      → TeamSummaryScreen (tab 3)
/// ```
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Athlete tab shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _AthleteShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Coach dashboard tab shell
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return CoachShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/coach/readiness',
              builder: (context, state) => const ReadinessGridScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/coach/sessions',
              builder: (context, state) => const SessionOverviewScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/coach/trends',
              builder: (context, state) => const TrendsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/coach/team',
              builder: (context, state) => const TeamSummaryScreen(),
            ),
          ],
        ),
      ],
    ),

    // Full-screen push routes (use root navigator)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/morning-check',
      builder: (context, state) => const MorningCheckScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/sync-session',
      builder: (context, state) => const SyncSessionScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/dev',
      builder: (context, state) => const DevShellScreen(),
    ),
  ],
);

/// Shell widget for the athlete tab navigation.
class _AthleteShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AthleteShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
