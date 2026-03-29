import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../database/database.dart';
import '../services/ble_service.dart';
import '../services/morning_service.dart';
import '../src/rust/api/polar_api.dart' as bridge;
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/readiness_indicator.dart';

/// Full-screen guided morning HRV check experience.
class MorningCheckScreen extends StatefulWidget {
  const MorningCheckScreen({super.key});

  @override
  State<MorningCheckScreen> createState() => _MorningCheckScreenState();
}

class _MorningCheckScreenState extends State<MorningCheckScreen> {
  final _ble = BleService.instance;
  final _morning = MorningCheckService();
  bridge.PolarMorningResult? _computedResult;
  bool _isComputing = false;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _morning.addListener(_onMorningChanged);
    // Auto-start when screen opens
    _morning.startCheck();
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _morning.removeListener(_onMorningChanged);
    // Stop if still running when screen is popped
    if (_morning.isActive) {
      _morning.stopCheck();
    }
    _morning.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onMorningChanged() {
    if (mounted) {
      // When the Rust side signals "computing", we compute the result here.
      // Guard with _isComputing to prevent duplicate calls while the async
      // DB load is in flight (this listener fires on every poll tick).
      if (_morning.phase == 'computing' && _computedResult == null && !_isComputing) {
        _computeResult();
      }
      setState(() {});
    }
  }

  Future<void> _computeResult() async {
    _isComputing = true;
    try {
      final db = AppDatabase.instance;
      final athlete = await db.getActiveAthlete();
      final history = athlete != null
          ? await db.getBaselineHistory(athlete.id)
          : const <double>[];
      final result = bridge.polarComputeMorningResult(baselineHistory: history);
      if (athlete != null) {
        await _saveResult(athlete.id, result);
      }
      if (mounted) setState(() { _computedResult = result; });
    } catch (e) {
      debugPrint('Morning check compute error: $e');
    }
  }

  Future<void> _saveResult(String athleteId, bridge.PolarMorningResult r) async {
    final today = DateTime.now();
    await AppDatabase.instance.upsertWellness(
      DailyWellnessEntriesCompanion(
        athleteId: Value(athleteId),
        date: Value(DateTime(today.year, today.month, today.day)),
        lnRmssd: Value(r.lnRmssd),
        rmssdMs: Value(r.rmssdMs),
        restingHr: Value(r.restingHrBpm.round()),
        readiness: Value(r.readiness),
        stability: Value(r.stability),
        rrCount: Value(r.rrCount),
        dayCount: Value(r.dayCount),
        baselineMean: Value(r.baselineMean > 0 ? r.baselineMean : null),
        baselineSd: Value(r.baselineSd > 0 ? r.baselineSd : null),
        cv7day: Value(r.cv7Day > 0 ? r.cv7Day : null),
      ),
    );
  }

  void _onDone() {
    final result = _computedResult;
    if (result != null) {
      context.pop<Map<String, dynamic>>({
        'readiness': result.readiness,
        'lnRmssd': result.lnRmssd,
        'restingHr': result.restingHrBpm,
      });
    } else {
      context.pop();
    }
  }

  void _onCancel() {
    if (_morning.isActive) {
      _morning.stopCheck();
    }
    context.pop();
  }

  void _onRetry() {
    _computedResult = null;
    _morning.startCheck();
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final phase = _morning.phase;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _onCancel,
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
        ),
        title: const Text('Morning Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(KineSpacing.lg),
        child: _buildPhaseContent(phase, colors),
      ),
    );
  }

  Widget _buildPhaseContent(String phase, KineColors colors) {
    // If we have a computed result, show done state regardless of phase
    if (_computedResult != null) {
      return _buildDone(_computedResult!, colors);
    }

    return switch (phase) {
      'warmup' => _buildWarmup(colors),
      'recording' => _buildRecording(colors),
      'computing' => _buildComputing(colors),
      'error' || _ when _morning.error.isNotEmpty => _buildError(colors),
      _ => _buildIdle(colors),
    };
  }

  Widget _buildIdle(KineColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: KineSpacing.lg),
          Text(
            'Connecting to sensor...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          Text(
            'Make sure your Polar sensor is on and nearby',
            style: TextStyle(fontSize: 14, color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarmup(KineColors colors) {
    final elapsed = _morning.elapsedS;
    final warmupDuration = 25.0;
    final progress = (elapsed / warmupDuration).clamp(0.0, 1.0);
    final hr = _morning.hrBpm;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              color: colors.primary,
              backgroundColor: colors.surfaceBorder,
            ),
          ),
          const SizedBox(height: KineSpacing.lg),
          Text(
            'Warming up...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          Text(
            'Lie down. Breathe normally.',
            style: TextStyle(fontSize: 14, color: colors.textMuted),
          ),
          if (hr > 0) ...[
            const SizedBox(height: KineSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(Icons.favorite, color: KineColors.red3, size: 20),
                const SizedBox(width: KineSpacing.sm),
                Text(
                  '$hr',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: KineSpacing.xs),
                Text(
                  'bpm',
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecording(KineColors colors) {
    final elapsed = _morning.elapsedS;
    // Recording phase is 25s-85s (60 seconds of recording)
    final recordingElapsed = (elapsed - 25).clamp(0.0, 60.0);
    final remaining = (60 - recordingElapsed).ceil();
    final progress = (recordingElapsed / 60.0).clamp(0.0, 1.0);
    final hr = _morning.hrBpm;
    final samples = _morning.ppiCount;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing heart icon + countdown
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: KineColors.red3,
                  backgroundColor: colors.surfaceBorder,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: KineColors.red3, size: 28),
                  const SizedBox(height: KineSpacing.xs),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'seconds',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: KineSpacing.lg),
          Text(
            'Recording...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          Text(
            'Stay still and breathe normally',
            style: TextStyle(fontSize: 14, color: colors.textMuted),
          ),
          const SizedBox(height: KineSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hr > 0) ...[
                _MiniMetric('HR', '$hr bpm', colors),
                const SizedBox(width: KineSpacing.xl),
              ],
              _MiniMetric('Samples', '$samples', colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComputing(KineColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: KineSpacing.lg),
          Text(
            'Analyzing...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(bridge.PolarMorningResult result, KineColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReadinessIndicator(readiness: result.readiness),
          const SizedBox(height: KineSpacing.lg),
          // lnRMSSD row: today's raw value + 7-day mean used for the traffic light
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ResultMetric(
                  'lnRMSSD (today)', result.lnRmssd.toStringAsFixed(2), colors),
              const SizedBox(width: KineSpacing.xl),
              _ResultMetric(
                  'lnRMSSD (7-day)', result.lnRmssd7Day.toStringAsFixed(2), colors),
            ],
          ),
          const SizedBox(height: KineSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ResultMetric(
                'Resting HR',
                '${result.restingHrBpm.round()} bpm',
                colors,
              ),
              const SizedBox(width: KineSpacing.xl),
              _ResultMetric('Stability', result.stability, colors),
            ],
          ),
          const SizedBox(height: KineSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ResultMetric('R-R Intervals', '${result.rrCount}', colors),
              const SizedBox(width: KineSpacing.xl),
              _ResultMetric('Baseline', '${result.dayCount} days', colors),
            ],
          ),
          if (result.dayCount > 0) ...[
            const SizedBox(height: KineSpacing.sm),
            Text(
              'mean ${result.baselineMean.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
          const SizedBox(height: KineSpacing.xl),
          FilledButton(
            onPressed: _onDone,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(KineColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 48),
          const SizedBox(height: KineSpacing.md),
          Text(
            _morning.error,
            style: TextStyle(
              fontSize: 16,
              color: colors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KineSpacing.lg),
          FilledButton.icon(
            onPressed: _onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final KineColors colors;

  const _MiniMetric(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textMuted),
        ),
      ],
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final KineColors colors;

  const _ResultMetric(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: KineSpacing.xs),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textMuted),
        ),
      ],
    );
  }
}
