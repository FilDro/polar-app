import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/recording_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _ble = BleService.instance;
  final _recording = RecordingService();

  // Toggle state for each recording type
  final Map<String, bool> _selectedTypes = {
    'acc': true,
    'gyro': true,
    'mag': true,
    'hr': true,
    'ppg': false,
    'ppi': false,
  };

  static const _typeLabels = {
    'acc': ('Accelerometer', '52 Hz, 3-axis milliG'),
    'gyro': ('Gyroscope', '52 Hz, 3-axis deg/s'),
    'mag': ('Magnetometer', '50 Hz, 3-axis Gauss'),
    'hr': ('Heart Rate', '~1 Hz, bpm'),
    'ppg': ('PPG (Optical)', '55 Hz, 4-channel raw'),
    'ppi': ('PPI (R-R Interval)', 'Variable, ms'),
  };

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _recording.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _recording.removeListener(_onChanged);
    _recording.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<String> get _activeSelections =>
      _selectedTypes.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final isConnected = _ble.isConnected;
    final isRecording = _recording.isRecording;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Recording')),
      body: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConnected)
              _Banner('Connect a sensor first', colors.warning, colors),

            // Recording type toggles
            Text(
              'Recording Types',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            ..._typeLabels.entries.map((entry) {
              final (label, desc) = entry.value;
              return CheckboxListTile(
                title: Text(label),
                subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
                value: _selectedTypes[entry.key],
                onChanged: isRecording
                    ? null
                    : (v) => setState(() => _selectedTypes[entry.key] = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: KineSpacing.md),

            // Start/Stop
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !isConnected || isRecording || _activeSelections.isEmpty
                        ? null
                        : () => _recording.startRecording(_activeSelections),
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start Recording'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                    ),
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !isRecording
                        ? null
                        : () => _recording.stopRecording(_activeSelections),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: KineSpacing.sm),

            // Check status
            OutlinedButton.icon(
              onPressed: !isConnected ? null : () => _recording.checkStatus(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status'),
            ),

            const SizedBox(height: KineSpacing.md),

            // Status display
            if (_recording.statusText.isNotEmpty)
              Card(
                color: colors.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(KineSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isRecording ? Icons.fiber_manual_record : Icons.info_outline,
                            color: isRecording ? colors.error : colors.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: KineSpacing.sm),
                          Text(
                            _recording.statusText,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_recording.activeTypes.isNotEmpty) ...[
                        const SizedBox(height: KineSpacing.sm),
                        Wrap(
                          spacing: KineSpacing.sm,
                          children: _recording.activeTypes.map((t) {
                            return Chip(
                              label: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Trigger section
            Text(
              'Auto-Recording Trigger',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: !isConnected ? null : () => _recording.getTrigger(),
                    child: const Text('Get Trigger'),
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !isConnected
                        ? null
                        : () => _recording.setTrigger('system-start'),
                    child: const Text('Set: System Start'),
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !isConnected
                        ? null
                        : () => _recording.setTrigger('disabled'),
                    child: const Text('Disable'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  final KineColors colors;

  const _Banner(this.text, this.color, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.inset),
      margin: const EdgeInsets.only(bottom: KineSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KineRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
    );
  }
}
