import 'package:flutter/material.dart';
import '../database/database.dart';
import '../services/ble_service.dart';
import '../services/athlete_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Settings tab — athlete account, profile, HR config, and sensor pairing.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ble = BleService.instance;
  final _athlete = AthleteService.instance;
  final _auth = AuthService.instance;

  late TextEditingController _nameCtrl;
  late TextEditingController _hrMaxCtrl;
  late TextEditingController _hrRestCtrl;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _athlete.addListener(_onChanged);
    _auth.addListener(_onChanged);
    _nameCtrl = TextEditingController(text: _athlete.name);
    _hrMaxCtrl = TextEditingController(text: '${_athlete.hrMax}');
    _hrRestCtrl = TextEditingController(text: '${_athlete.hrRest}');
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _athlete.removeListener(_onChanged);
    _auth.removeListener(_onChanged);
    _nameCtrl.dispose();
    _hrMaxCtrl.dispose();
    _hrRestCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;

    if (_nameCtrl.text != _athlete.name) {
      _nameCtrl.text = _athlete.name;
    }
    if (_hrMaxCtrl.text != '${_athlete.hrMax}') {
      _hrMaxCtrl.text = '${_athlete.hrMax}';
    }
    if (_hrRestCtrl.text != '${_athlete.hrRest}') {
      _hrRestCtrl.text = '${_athlete.hrRest}';
    }

    setState(() {});
  }

  Future<void> _confirmResetBaseline(
    BuildContext context,
    KineColors colors,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Baseline?'),
        content: const Text(
          'This deletes all morning check history. '
          'Your readiness baseline will start fresh from today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final athleteId = _athlete.athleteId;
    if (athleteId == null) return;

    final deleted = await AppDatabase.instance.clearWellnessData(athleteId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared $deleted wellness entries.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(KineSpacing.md),
        children: [
          _SectionHeader('Account', colors),
          const SizedBox(height: KineSpacing.sm),
          Card(
            color: colors.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(KineSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _auth.userEmail ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Athlete account',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: KineSpacing.lg),

          _SectionHeader('Profile', colors),
          const SizedBox(height: KineSpacing.sm),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _athlete.updateName(v),
          ),

          const SizedBox(height: KineSpacing.lg),

          _SectionHeader('Heart Rate Configuration', colors),
          const SizedBox(height: KineSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hrMaxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'HR Max',
                    border: OutlineInputBorder(),
                    suffixText: 'bpm',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) _athlete.updateHrMax(n);
                  },
                ),
              ),
              const SizedBox(width: KineSpacing.md),
              Expanded(
                child: TextField(
                  controller: _hrRestCtrl,
                  decoration: const InputDecoration(
                    labelText: 'HR Rest',
                    border: OutlineInputBorder(),
                    suffixText: 'bpm',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) _athlete.updateHrRest(n);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: KineSpacing.lg),

          _SectionHeader('Sensor', colors),
          const SizedBox(height: KineSpacing.sm),
          Card(
            color: colors.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(KineSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: KineColors.bleStateColor(_ble.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: KineSpacing.inset),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ble.isConnected
                              ? _ble.deviceName
                              : 'No sensor connected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          _ble.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_ble.battery >= 0)
                    Text(
                      '${_ble.battery}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          OutlinedButton.icon(
            onPressed: _ble.isScanning ? null : () => _ble.startScan(),
            icon: _ble.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(_ble.isScanning ? 'Scanning...' : 'Pair Sensor'),
          ),

          if (_ble.devices.isNotEmpty) ...[
            const SizedBox(height: KineSpacing.sm),
            ...List.generate(_ble.devices.length, (i) {
              final d = _ble.devices[i];
              return Card(
                margin: const EdgeInsets.only(bottom: KineSpacing.xs),
                child: ListTile(
                  leading: Icon(Icons.sensors, color: colors.primary),
                  title: Text(d.name),
                  subtitle: Text('RSSI: ${d.rssi} dBm'),
                  trailing: FilledButton(
                    onPressed: () {
                      _ble.connect(d.identifier);
                      _athlete.updateSensorId(d.identifier);
                    },
                    child: const Text('Connect'),
                  ),
                  dense: true,
                ),
              );
            }),
          ],

          const SizedBox(height: KineSpacing.xl),

          _SectionHeader('Data', colors),
          const SizedBox(height: KineSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _confirmResetBaseline(context, colors),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset Baseline'),
          ),

          const SizedBox(height: KineSpacing.xl),

          FilledButton.icon(
            onPressed: _auth.loading
                ? null
                : () async {
                    await _auth.signOut();
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final KineColors colors;

  const _SectionHeader(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }
}
