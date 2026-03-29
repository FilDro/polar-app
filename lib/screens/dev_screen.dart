import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'scan_screen.dart';
import 'stream_screen.dart';
import 'recording_screen.dart';
import 'files_screen.dart';

/// Developer shell — wraps the 4 existing debug screens in tabs.
/// Accessible via the /dev route.
class DevShellScreen extends StatefulWidget {
  const DevShellScreen({super.key});

  @override
  State<DevShellScreen> createState() => _DevShellScreenState();
}

class _DevShellScreenState extends State<DevShellScreen> {
  int _index = 0;

  static const _screens = [
    ScanScreen(),
    StreamScreen(),
    RecordingScreen(),
    FilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bluetooth_searching),
            selectedIcon: Icon(Icons.bluetooth_connected),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Stream',
          ),
          NavigationDestination(
            icon: Icon(Icons.fiber_manual_record_outlined),
            selectedIcon: Icon(Icons.fiber_manual_record),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
        ],
      ),
    );
  }
}
