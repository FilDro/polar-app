import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../services/athlete_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/theme_notifier.dart';

/// Settings tab — athlete profile, HR config, sensor, and dev tools link.
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
    if (mounted) setState(() {});
  }

  void _showSignInDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: KineSpacing.sm),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await _auth.signIn(
                email: emailCtrl.text.trim(),
                password: passCtrl.text,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_auth.error)),
                );
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showSignUpDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'athlete';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Sign Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: KineSpacing.sm),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              const SizedBox(height: KineSpacing.sm),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: KineSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'athlete', label: Text('Athlete')),
                  ButtonSegment(value: 'coach', label: Text('Coach')),
                ],
                selected: {selectedRole},
                onSelectionChanged: (v) {
                  setDialogState(() => selectedRole = v.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await _auth.signUp(
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text,
                  name: nameCtrl.text.trim(),
                  role: selectedRole,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Account created. Check email to confirm.'
                          : _auth.error),
                    ),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
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
          // Cloud Account section
          _SectionHeader('Cloud Account', colors),
          const SizedBox(height: KineSpacing.sm),
          if (_auth.isAuthenticated) ...[
            Card(
              color: colors.surfaceCard,
              child: Padding(
                padding: const EdgeInsets.all(KineSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auth.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Role: ${_auth.userRole ?? 'unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                await _auth.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showSignInDialog,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSignUpDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: KineSpacing.lg),

          // Profile section
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

          // Appearance section
          _SectionHeader('Appearance', colors),
          const SizedBox(height: KineSpacing.sm),
          ValueListenableBuilder<AppTheme>(
            valueListenable: ThemeNotifier.instance,
            builder: (context, appTheme, _) => SegmentedButton<AppTheme>(
              segments: const [
                ButtonSegment(
                  value: AppTheme.dark,
                  label: Text('KINE Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: AppTheme.kineFlow,
                  label: Text('KineFlow'),
                  icon: Icon(Icons.light_mode),
                ),
              ],
              selected: {appTheme},
              onSelectionChanged: (v) => ThemeNotifier.instance.setTheme(v.first),
            ),
          ),

          const SizedBox(height: KineSpacing.lg),

          // HR Configuration
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

          // Sensor section
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

          // Show discovered devices for quick connect
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

          // Coach dashboard link
          FilledButton.icon(
            onPressed: () => context.go('/coach/readiness'),
            icon: const Icon(Icons.dashboard),
            label: const Text('Coach Dashboard'),
          ),

          const SizedBox(height: KineSpacing.sm),

          // Developer tools link
          OutlinedButton.icon(
            onPressed: () => context.push('/dev'),
            icon: const Icon(Icons.developer_mode),
            label: const Text('Developer Tools'),
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
