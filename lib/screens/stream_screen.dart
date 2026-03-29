import 'dart:collection';
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

  // HR history buffer (Dart-side, ~1Hz data)
  final _hrHistory = Queue<double>();
  static const _hrMaxPoints = 120; // 2 minutes at 1Hz

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
    if (!mounted) return;
    // Accumulate HR history
    final state = _stream.state;
    if (state != null && state.hrBpm > 0) {
      _hrHistory.addLast(state.hrBpm.toDouble());
      while (_hrHistory.length > _hrMaxPoints) {
        _hrHistory.removeFirst();
      }
    }
    setState(() {});
  }

  void _startStream(String config) {
    _hrHistory.clear();
    _stream.startStream(config);
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
              _StatusBanner('Connect a sensor first', colors.warning, colors),

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
                      : () => _startStream(_selectedConfig),
              icon: Icon(isStreaming ? Icons.stop : Icons.play_arrow),
              label: Text(isStreaming ? 'Stop Streaming' : 'Start Streaming'),
              style: FilledButton.styleFrom(
                backgroundColor: isStreaming ? colors.error : null,
              ),
            ),

            if (isStreaming && state != null) ...[
              const SizedBox(height: KineSpacing.md),
              _StreamMetrics(state: state, colors: colors),
              const SizedBox(height: KineSpacing.sm),
              Expanded(
                child: _ChartArea(
                  state: state,
                  hrHistory: _hrHistory.toList(),
                  colors: colors,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status banner ────────────────────────────────────────────

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

// ── Metrics row ──────────────────────────────────────────────

class _StreamMetrics extends StatelessWidget {
  final bridge.PolarStreamState state;
  final KineColors colors;

  const _StreamMetrics({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (state.hrBpm > 0)
          _MetricCard('HR', '${state.hrBpm}', 'bpm', KineColors.red3, colors),
        _MetricCard('Samples', '${state.sampleCount.toInt()}', '', colors.primary, colors),
        _MetricCard('Elapsed', state.elapsedS.toStringAsFixed(1), 's', colors.textSecondary, colors),
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
              Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted)),
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
                    Text(' $unit', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chart area — shows HR, ACC, GYRO based on available data ─

class _ChartArea extends StatelessWidget {
  final bridge.PolarStreamState state;
  final List<double> hrHistory;
  final KineColors colors;

  const _ChartArea({
    required this.state,
    required this.hrHistory,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasHr = hrHistory.length >= 2;
    final hasAcc = state.chartAccX.isNotEmpty;
    final hasGyro = state.chartGyroX.isNotEmpty;

    final charts = <Widget>[];

    if (hasHr) {
      charts.add(Expanded(
        child: _ChartCard(
          title: 'Heart Rate (bpm)',
          chart: CustomPaint(
            size: Size.infinite,
            painter: _SingleLinePainter(
              data: hrHistory,
              color: KineColors.red3,
              gridColor: colors.surfaceBorder,
              showYLabels: true,
            ),
          ),
          colors: colors,
        ),
      ));
    }

    if (hasAcc) {
      charts.add(Expanded(
        child: _ChartCard(
          title: 'Accelerometer (mg)',
          chart: CustomPaint(
            size: Size.infinite,
            painter: _MultiLinePainter(
              series: [state.chartAccX, state.chartAccY, state.chartAccZ],
              seriesColors: [KineColors.red3, KineColors.green2, KineColors.blue3],
              gridColor: colors.surfaceBorder,
            ),
          ),
          legend: const ['X', 'Y', 'Z'],
          legendColors: const [KineColors.red3, KineColors.green2, KineColors.blue3],
          colors: colors,
        ),
      ));
    }

    if (hasGyro) {
      charts.add(Expanded(
        child: _ChartCard(
          title: 'Gyroscope (dps)',
          chart: CustomPaint(
            size: Size.infinite,
            painter: _MultiLinePainter(
              series: [state.chartGyroX, state.chartGyroY, state.chartGyroZ],
              seriesColors: [KineColors.red3, KineColors.green2, KineColors.blue3],
              gridColor: colors.surfaceBorder,
            ),
          ),
          legend: const ['X', 'Y', 'Z'],
          legendColors: const [KineColors.red3, KineColors.green2, KineColors.blue3],
          colors: colors,
        ),
      ));
    }

    if (charts.isEmpty) {
      return Center(
        child: Text('Waiting for data...', style: TextStyle(color: colors.textMuted)),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < charts.length; i++) ...[
          if (i > 0) const SizedBox(height: KineSpacing.sm),
          charts[i],
        ],
      ],
    );
  }
}

// ── Chart card wrapper ───────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final List<String>? legend;
  final List<Color>? legendColors;
  final KineColors colors;

  const _ChartCard({
    required this.title,
    required this.chart,
    this.legend,
    this.legendColors,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
            const SizedBox(height: KineSpacing.xs),
            Expanded(child: chart),
            if (legend != null && legendColors != null) ...[
              const SizedBox(height: KineSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < legend!.length; i++) ...[
                    if (i > 0) const SizedBox(width: KineSpacing.md),
                    _LegendDot(legend![i], legendColors![i]),
                  ],
                ],
              ),
            ],
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
        Text(label, style: TextStyle(fontSize: 10, color: KineColors.of(context).textMuted)),
      ],
    );
  }
}

// ── Single-line painter (HR) ─────────────────────────────────

class _SingleLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color gridColor;
  final bool showYLabels;

  _SingleLinePainter({
    required this.data,
    required this.color,
    required this.gridColor,
    this.showYLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final leftPad = showYLabels ? 36.0 : 0.0;
    final chartW = size.width - leftPad;
    final chartH = size.height;

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    // Ensure some padding
    final padding = (maxVal - minVal) * 0.1;
    if (padding < 2) {
      minVal -= 5;
      maxVal += 5;
    } else {
      minVal -= padding;
      maxVal += padding;
    }
    final range = maxVal - minVal;

    // Grid
    final gridPaint = Paint()..color = gridColor.withValues(alpha: 0.3)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * i / 4;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      if (showYLabels) {
        final val = maxVal - (range * i / 4);
        final tp = TextPainter(
          text: TextSpan(
            text: val.toStringAsFixed(0),
            style: TextStyle(fontSize: 9, color: gridColor.withValues(alpha: 0.6)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
      }
    }

    // Line
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = leftPad + chartW * i / (data.length - 1);
      final y = chartH - (data[i] - minVal) / range * chartH;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SingleLinePainter old) => true;
}

// ── Multi-line painter (ACC/GYRO) ────────────────────────────

class _MultiLinePainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> seriesColors;
  final Color gridColor;

  _MultiLinePainter({
    required this.series,
    required this.seriesColors,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series[0].isEmpty) return;

    const maxPoints = 500;

    // Global min/max across all series
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
    if (range < 0.01) return;

    // Grid
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
        ..strokeWidth = 1.0
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
  bool shouldRepaint(covariant _MultiLinePainter old) => true;
}
