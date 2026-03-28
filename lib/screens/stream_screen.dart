import 'package:flutter/material.dart';
import '../src/rust/api/polar_api.dart' as bridge;
import '../services/ble_service.dart';
import '../services/stream_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  final _ble = BleService.instance;
  final _stream = StreamService();
  String _selectedConfig = 'hr';

  static const _configs = [
    ('hr', 'Heart Rate', 'HR only (1 Hz)'),
    ('acc', 'Accelerometer', 'ACC 416 Hz (SDK mode)'),
    ('gyro', 'Gyroscope', 'GYRO 416 Hz (SDK mode)'),
    ('imu', 'IMU (ACC+GYRO)', '6DoF 416 Hz (SDK mode)'),
    ('full', 'Full Monitoring', 'HR + ACC + GYRO + MAG 52 Hz'),
  ];

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _stream.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _stream.removeListener(_onChanged);
    _stream.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final isConnected = _ble.isConnected;
    final isStreaming = _stream.isStreaming;
    final state = _stream.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Streaming')),
      body: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConnected)
              _StatusBanner(
                'Connect a sensor first',
                colors.warning,
                colors,
              ),

            // Config selector
            if (!isStreaming) ...[
              Text(
                'Streaming Configuration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: KineSpacing.sm),
              ...List.generate(_configs.length, (i) {
                final (key, label, desc) = _configs[i];
                return RadioListTile<String>(
                  title: Text(label),
                  subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
                  value: key,
                  groupValue: _selectedConfig,
                  onChanged: (v) => setState(() => _selectedConfig = v!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: KineSpacing.md),
            ],

            // Start/Stop button
            FilledButton.icon(
              onPressed: !isConnected
                  ? null
                  : isStreaming
                      ? () => _stream.stopStream()
                      : () => _stream.startStream(_selectedConfig),
              icon: Icon(isStreaming ? Icons.stop : Icons.play_arrow),
              label: Text(isStreaming ? 'Stop Streaming' : 'Start Streaming'),
              style: FilledButton.styleFrom(
                backgroundColor: isStreaming ? colors.error : null,
              ),
            ),

            if (isStreaming && state != null) ...[
              const SizedBox(height: KineSpacing.lg),
              _StreamMetrics(state: state, colors: colors),
              const SizedBox(height: KineSpacing.md),
              Expanded(child: _StreamChart(state: state, colors: colors)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color color;
  final KineColors colors;

  const _StatusBanner(this.text, this.color, this.colors);

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

class _StreamMetrics extends StatelessWidget {
  final bridge.PolarStreamState state;
  final KineColors colors;

  const _StreamMetrics({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hrBpm = state.hrBpm;
    final sampleCount = state.sampleCount.toInt();
    final elapsed = state.elapsedS;

    return Row(
      children: [
        if (hrBpm > 0)
          _MetricCard('HR', '$hrBpm', 'bpm', KineColors.red3, colors),
        _MetricCard(
          'Samples',
          '$sampleCount',
          '',
          colors.primary,
          colors,
        ),
        _MetricCard(
          'Elapsed',
          elapsed.toStringAsFixed(1),
          's',
          colors.textSecondary,
          colors,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final KineColors colors;

  const _MetricCard(this.label, this.value, this.unit, this.accentColor, this.colors);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: KineSpacing.xs),
        color: colors.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.all(KineSpacing.inset),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
              const SizedBox(height: KineSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      ' $unit',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple line chart using CustomPainter.
class _StreamChart extends StatelessWidget {
  final bridge.PolarStreamState state;
  final KineColors colors;

  const _StreamChart({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    final accX = state.chartAccX;
    final accY = state.chartAccY;
    final accZ = state.chartAccZ;

    if (accX.isEmpty) {
      return Center(
        child: Text(
          'Waiting for data...',
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    return Card(
      color: colors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accelerometer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _LinePainter(
                  series: [accX, accY, accZ],
                  seriesColors: [KineColors.red3, KineColors.green2, KineColors.blue3],
                  bgColor: colors.surfaceCard,
                  gridColor: colors.surfaceBorder,
                ),
              ),
            ),
            const SizedBox(height: KineSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot('X', KineColors.red3),
                const SizedBox(width: KineSpacing.md),
                _LegendDot('Y', KineColors.green2),
                const SizedBox(width: KineSpacing.md),
                _LegendDot('Z', KineColors.blue3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: KineColors.of(context).textMuted)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> seriesColors;
  final Color bgColor;
  final Color gridColor;

  _LinePainter({
    required this.series,
    required this.seriesColors,
    required this.bgColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series[0].isEmpty) return;

    // Show last 500 points
    final maxPoints = 500;

    // Find global min/max across all series
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    for (final s in series) {
      final start = s.length > maxPoints ? s.length - maxPoints : 0;
      for (int i = start; i < s.length; i++) {
        if (s[i] < globalMin) globalMin = s[i];
        if (s[i] > globalMax) globalMax = s[i];
      }
    }

    final range = (globalMax - globalMin).abs();
    if (range < 1) return;

    // Draw grid
    final gridPaint = Paint()..color = gridColor.withValues(alpha: 0.3)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw each series
    for (int si = 0; si < series.length; si++) {
      final s = series[si];
      final start = s.length > maxPoints ? s.length - maxPoints : 0;
      final count = s.length - start;
      if (count < 2) continue;

      final paint = Paint()
        ..color = seriesColors[si]
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < count; i++) {
        final x = size.width * i / (count - 1);
        final y = size.height - (s[start + i] - globalMin) / range * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
