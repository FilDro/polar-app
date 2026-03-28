import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'device_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ble = BleService.instance;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onBleChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onBleChanged);
    super.dispose();
  }

  void _onBleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final isConnected = _ble.isConnected;
    final isScanning = _ble.isScanning;
    final devices = _ble.devices;
    final statusColor = KineColors.bleStateColor(_ble.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polar Sensor'),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: KineSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Text(
                  _ble.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connected device card
            if (isConnected) ...[
              _ConnectedCard(
                deviceName: _ble.deviceName,
                battery: _ble.battery,
                onDisconnect: () => _ble.disconnect(),
                onInfo: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeviceScreen()),
                  );
                },
              ),
              const SizedBox(height: KineSpacing.lg),
            ],

            // Scan button
            FilledButton.icon(
              onPressed: isScanning ? null : () => _ble.startScan(),
              icon: isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
            ),

            if (_ble.error.isNotEmpty) ...[
              const SizedBox(height: KineSpacing.sm),
              Text(
                _ble.error,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: KineSpacing.md),

            // Device list
            if (devices.isNotEmpty) ...[
              Text(
                'Discovered Devices',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: KineSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: KineSpacing.sm),
                  itemBuilder: (context, i) {
                    final d = devices[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.sensors, color: colors.primary),
                        title: Text(d.name),
                        subtitle: Text('ID: ${d.identifier}  RSSI: ${d.rssi} dBm'),
                        trailing: FilledButton(
                          onPressed: () => _ble.connect(d.identifier),
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Spacer(),
              Center(
                child: Text(
                  isScanning
                      ? 'Searching for Polar sensors...'
                      : 'Tap Scan to discover nearby Polar sensors',
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  final String deviceName;
  final int battery;
  final VoidCallback onDisconnect;
  final VoidCallback onInfo;

  const _ConnectedCard({
    required this.deviceName,
    required this.battery,
    required this.onDisconnect,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Card(
      color: colors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Row(
          children: [
            Icon(Icons.bluetooth_connected, color: KineColors.bleConnected, size: 32),
            const SizedBox(width: KineSpacing.inset),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (battery >= 0)
                    Text(
                      'Battery: $battery%',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onInfo,
              icon: Icon(Icons.info_outline, color: colors.primary),
              tooltip: 'Device Info',
            ),
            IconButton(
              onPressed: onDisconnect,
              icon: Icon(Icons.link_off, color: colors.error),
              tooltip: 'Disconnect',
            ),
          ],
        ),
      ),
    );
  }
}
