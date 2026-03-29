import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

/// Shell for the coach dashboard with 4-tab bottom navigation.
class CoachShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CoachShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: colors.textSecondary),
            selectedIcon: Icon(Icons.grid_view, color: colors.primary),
            label: 'Readiness',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined, color: colors.textSecondary),
            selectedIcon: Icon(Icons.fitness_center, color: colors.primary),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined, color: colors.textSecondary),
            selectedIcon: Icon(Icons.trending_up, color: colors.primary),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: colors.textSecondary),
            selectedIcon: Icon(Icons.groups, color: colors.primary),
            label: 'Team',
          ),
        ],
      ),
    );
  }
}
