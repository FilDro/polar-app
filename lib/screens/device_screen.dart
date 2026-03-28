import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _ble = BleService.instance;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final state = _ble.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Info')),
      body: state == null
          ? const Center(child: Text('Not connected'))
          : ListView(
              padding: const EdgeInsets.all(KineSpacing.md),
              children: [
                _InfoTile('Device', state.deviceName, colors),
                _InfoTile('Model', state.model, colors),
                _InfoTile('Firmware', state.firmware, colors),
                _InfoTile('Serial', state.serial, colors),
                _InfoTile(
                  'Battery',
                  state.batteryPercent >= 0 ? '${state.batteryPercent}%' : 'Unknown',
                  colors,
                ),
                _InfoTile(
                  'Disk Space',
                  state.diskTotalKb > 0
                      ? '${state.diskFreeKb} / ${state.diskTotalKb} KB free'
                      : 'Unknown',
                  colors,
                ),
                _InfoTile('Status', state.status, colors),
              ],
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final KineColors colors;

  const _InfoTile(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KineSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
