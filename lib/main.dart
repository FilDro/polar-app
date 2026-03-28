import 'package:flutter/material.dart';
import 'services/rust_init.dart';
import 'services/ble_service.dart';
import 'theme/colors.dart';
import 'screens/scan_screen.dart';
import 'screens/stream_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/files_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initRustBridge();
  } catch (e) {
    debugPrint('Rust bridge init FAILED: $e');
  }
  BleService.instance.startPolling();
  runApp(const PolarApp());
}

class PolarApp extends StatelessWidget {
  const PolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: KineColors.blue3,
        brightness: Brightness.light,
        useMaterial3: true,
        extensions: const [KineColors.light],
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: KineColors.blue3,
        brightness: Brightness.dark,
        useMaterial3: true,
        extensions: const [KineColors.dark],
      ),
      home: const HomeScreen(),
    );
  }
}

/// Tab-based home screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
