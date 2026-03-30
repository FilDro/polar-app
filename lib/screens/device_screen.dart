import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/device_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _ble = BleService.instance;
  final _deviceService = DeviceService.instance;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _deviceService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _deviceService.removeListener(_onChanged);
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

                const SizedBox(height: KineSpacing.lg),
                Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: KineSpacing.sm),

                if (_deviceService.isBusy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KineSpacing.md),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: KineSpacing.sm),
                        Expanded(
                          child: Text(
                            _deviceService.progressText,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_deviceService.error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KineSpacing.md),
                    child: Text(
                      _deviceService.error,
                      style: const TextStyle(color: KineColors.red3, fontSize: 13),
                    ),
                  ),

                _ActionTile(
                  label: 'Sync Clock',
                  icon: Icons.access_time,
                  onPressed: () => _deviceService.syncTime(),
                  isDestructive: false,
                  colors: colors,
                  disabled: _deviceService.isBusy,
                ),
                _ActionTile(
                  label: 'Setup Auto-Record Trigger',
                  icon: Icons.play_circle_outline,
                  onPressed: () => _deviceService.setupTrigger(
                    'system-start',
                    ['acc', 'gyro', 'mag', 'hr'],
                  ),
                  isDestructive: false,
                  colors: colors,
                  disabled: _deviceService.isBusy,
                ),
                _ActionTile(
                  label: 'Clear All Recordings',
                  icon: Icons.delete_sweep_outlined,
                  onPressed: () => _confirm(
                    context,
                    'Clear All Recordings',
                    'Permanently delete all recording files from the device flash. '
                        'This frees storage for new sessions.',
                    _deviceService.deleteAllRecordings,
                  ),
                  isDestructive: false,
                  colors: colors,
                  disabled: _deviceService.isBusy,
                ),
                _ActionTile(
                  label: 'Delete Telemetry',
                  icon: Icons.bug_report_outlined,
                  onPressed: () => _deviceService.deleteTelemetry(),
                  isDestructive: false,
                  colors: colors,
                  disabled: _deviceService.isBusy,
                ),
                _ActionTile(
                  label: 'Restart Device',
                  icon: Icons.restart_alt,
                  onPressed: () => _confirm(
                    context,
                    'Restart Device',
                    'The device will reboot. All recorded data is preserved.',
                    _deviceService.restartDevice,
                  ),
                  isDestructive: false,
                  colors: colors,
                  disabled: _deviceService.isBusy,
                ),
                _ActionTile(
                  label: 'Factory Reset',
                  icon: Icons.warning_amber_outlined,
                  onPressed: () => _doubleConfirm(context, _deviceService.factoryReset),
                  isDestructive: true,
                  colors: colors,
                  disabled: _deviceService.isBusy,
                ),
              ],
            ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    String body,
    VoidCallback action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true) action();
  }

  Future<void> _doubleConfirm(BuildContext context, VoidCallback action) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Factory Reset'),
        content: const Text(
          'This will permanently wipe ALL data from the device and '
          'restore factory defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: KineColors.red3),
            ),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'FACTORY RESET',
              style: TextStyle(color: KineColors.red3),
            ),
          ),
        ],
      ),
    );
    if (second == true) action();
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

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;
  final KineColors colors;
  final bool disabled;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDestructive,
    required this.colors,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? colors.textMuted
        : (isDestructive ? KineColors.red3 : colors.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(bottom: KineSpacing.xs),
      child: Material(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KineSpacing.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: KineSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
