import 'package:flutter/material.dart';
import 'package:kine_charts/kine_charts.dart';

import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_kine_chart_theme.dart';
import '../../widgets/readiness_indicator.dart';

/// PRD 8.3 — Per-athlete longitudinal load trends with ACWR.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final _service = CoachDataService.instance;
  final GlobalKey<BarChartState> _trimpChartKey = GlobalKey<BarChartState>();
  final GlobalKey<LineChartState> _hrvChartKey = GlobalKey<LineChartState>();

  Object? _trimpChartToken;
  Object? _hrvChartToken;
  String? _selectedAthleteId;
  int _periodDays = 28;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _ensureRoster();
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _ensureRoster() async {
    if (_service.roster.isEmpty) {
      await _service.loadTodayReadiness();
    }
    if (_service.roster.isNotEmpty && _selectedAthleteId == null) {
      _selectedAthleteId = _service.roster.first.id;
      _loadTrend();
    }
  }

  Future<void> _loadTrend() async {
    if (_selectedAthleteId == null) return;
    await _service.loadAthleteTrend(_selectedAthleteId!, days: _periodDays);
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Trends'),
        actions: [
          if (_selectedAthleteId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _service.loading ? null : _loadTrend,
            ),
        ],
      ),
      body: _buildContent(colors),
    );
  }

  Widget _buildContent(KineColors colors) {
    if (_service.roster.isEmpty && _service.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(KineSpacing.md),
      children: [
        _buildAthleteSelector(colors),
        const SizedBox(height: KineSpacing.md),
        _buildPeriodSelector(colors),
        const SizedBox(height: KineSpacing.md),
        if (_service.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: KineSpacing.sm),
            child: Text(
              'Using sample data — ${_service.error}',
              style: TextStyle(fontSize: 12, color: colors.warning),
            ),
          ),
        if (_selectedAthleteId == null)
          _emptyState(colors)
        else if (_service.loading && _service.currentTrend == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(KineSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_service.currentTrend != null)
          _buildTrendContent(colors),
      ],
    );
  }

  Widget _buildAthleteSelector(KineColors colors) {
    final roster = _service.roster;
    if (roster.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      initialValue: _selectedAthleteId,
      decoration: InputDecoration(
        labelText: 'Athlete',
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: colors.textSecondary),
      ),
      items: roster.map((athlete) {
        return DropdownMenuItem(value: athlete.id, child: Text(athlete.name));
      }).toList(),
      onChanged: (id) {
        setState(() => _selectedAthleteId = id);
        _loadTrend();
      },
    );
  }

  Widget _buildPeriodSelector(KineColors colors) {
    return Row(
      children: [
        Text('Period:', style: TextStyle(color: colors.textSecondary)),
        const SizedBox(width: KineSpacing.sm),
        for (final days in [7, 14, 28])
          Padding(
            padding: const EdgeInsets.only(right: KineSpacing.sm),
            child: ChoiceChip(
              label: Text('${days}d'),
              selected: _periodDays == days,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _periodDays = days);
                  _loadTrend();
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTrendContent(KineColors colors) {
    final trend = _service.currentTrend!;
    final windowDays = _trendWindow(trend);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Load Trends — ${trend.name}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        Text(
          'Last $_periodDays days',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        const SizedBox(height: KineSpacing.lg),
        _buildMetricsRow(trend, colors),
        const SizedBox(height: KineSpacing.lg),
        _buildReadinessStreak(trend, colors),
        const SizedBox(height: KineSpacing.lg),
        _buildSection('TRIMP (daily)', colors),
        const SizedBox(height: KineSpacing.sm),
        _buildTrimpChart(windowDays, colors),
        const SizedBox(height: KineSpacing.lg),
        _buildSection('lnRMSSD (morning)', colors),
        const SizedBox(height: KineSpacing.sm),
        _buildHrvChart(windowDays, colors),
        const SizedBox(height: KineSpacing.lg),
        _buildSection('Resting HR', colors),
        const SizedBox(height: KineSpacing.sm),
        _buildRestingHrSparkline(windowDays, colors),
      ],
    );
  }

  Widget _buildMetricsRow(AthleteTrend trend, KineColors colors) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _metricTile(
                'ACWR',
                _formatAcwr(trend.acwr),
                _acwrColor(trend.acwr),
                colors,
              ),
              _metricTile(
                'Monotony',
                trend.monotony?.toStringAsFixed(1) ?? '—',
                null,
                colors,
              ),
              _metricTile(
                'Strain',
                trend.strain?.toStringAsFixed(0) ?? '—',
                null,
                colors,
              ),
            ],
          ),
          const SizedBox(height: KineSpacing.sm),
          Row(
            children: [
              _metricTile(
                'Acute',
                trend.acuteLoad.toStringAsFixed(0),
                null,
                colors,
              ),
              _metricTile(
                'Chronic',
                trend.chronicLoad.toStringAsFixed(0),
                null,
                colors,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    String label,
    String value,
    Color? valueColor,
    KineColors colors,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAcwr(double? acwr) {
    if (acwr == null) return '—';
    final risk = switch (acwr) {
      < 0.8 => 'low',
      <= 1.3 => 'optimal',
      <= 1.5 => 'elevated',
      _ => 'HIGH',
    };
    return '${acwr.toStringAsFixed(2)} ($risk)';
  }

  Color? _acwrColor(double? acwr) {
    if (acwr == null) return null;
    if (acwr > 1.5) return KineColors.red3;
    if (acwr > 1.3) return KineColors.orange1;
    if (acwr >= 0.8) return KineColors.green2;
    return KineColors.blue3;
  }

  Widget _buildReadinessStreak(AthleteTrend trend, KineColors colors) {
    final last7 = trend.days.length > 7
        ? trend.days.sublist(trend.days.length - 7)
        : trend.days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Readiness (last 7 days)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: KineSpacing.sm),
        Row(
          children: last7.map((day) {
            return Padding(
              padding: const EdgeInsets.only(right: KineSpacing.sm),
              child: Column(
                children: [
                  ReadinessDot(readiness: day.readiness, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    _weekdayShort(day.date),
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, KineColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildTrimpChart(List<AthleteTrendDay> windowDays, KineColors colors) {
    final values = windowDays.map((day) => day.trimp ?? 0.0).toList();
    final hasSessionData = values.any((value) => value > 0);

    if (!hasSessionData) {
      return Text('No session data', style: TextStyle(color: colors.textMuted));
    }

    final entries = <BarChartDataEntry>[];
    final barColors = <Color>[];
    for (var index = 0; index < windowDays.length; index++) {
      final value = values[index];
      entries.add(BarChartDataEntry(x: index.toDouble(), y: value));
      barColors.add(_trimpColor(value));
    }

    final dataSet = BarDataSet(entries, label: 'TRIMP')
      ..colors = barColors
      ..cornerRadius = 6;
    final data = BarData([dataSet])
      ..barWidth = windowDays.length > 14 ? 0.58 : 0.72;

    _configureTrimpChart(windowDays);

    return _buildChartCard(
      colors: colors,
      height: 160,
      child: AppKineChartTheme(
        child: BarChart(key: _trimpChartKey, data: data, touchEnabled: false),
      ),
    );
  }

  Widget _buildHrvChart(List<AthleteTrendDay> windowDays, KineColors colors) {
    final entries = <ChartDataEntry>[];
    for (var index = 0; index < windowDays.length; index++) {
      final value = windowDays[index].lnRmssd;
      if (value != null) {
        entries.add(ChartDataEntry(x: index.toDouble(), y: value));
      }
    }

    if (entries.isEmpty) {
      return Text('No HRV data', style: TextStyle(color: colors.textMuted));
    }

    final mean =
        entries.fold<double>(0.0, (sum, entry) => sum + entry.y) /
        entries.length;
    final lineColor = KineColors.green2;
    final dataSet = LineDataSet(entries, label: 'lnRMSSD')
      ..mode = LineDataSetMode.cubicBezier
      ..cubicIntensity = 0.18
      ..lineWidth = 2.4
      ..colors = [lineColor]
      ..circleColors = [lineColor]
      ..circleHoleColor = colors.surfaceCard
      ..circleRadius = entries.length <= 14 ? 3.0 : 2.4
      ..circleHoleRadius = 1.5
      ..drawCirclesEnabled = entries.length <= 14
      ..drawFilledEnabled = entries.length > 1
      ..fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.0),
        ],
      );

    _configureHrvChart(windowDays);

    return _buildChartCard(
      colors: colors,
      height: 120,
      child: AppKineChartTheme(
        child: LineChart(
          key: _hrvChartKey,
          data: LineData([dataSet]),
          touchEnabled: false,
          annotations: [
            HLineAnnotation(
              y: mean,
              color: colors.textMuted.withValues(alpha: 0.85),
              lineWidth: 1.0,
              dashPattern: const [4.0, 3.0],
              label: 'Baseline ${mean.toStringAsFixed(2)}',
              labelStyle: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestingHrSparkline(
    List<AthleteTrendDay> windowDays,
    KineColors colors,
  ) {
    final values = windowDays
        .where((day) => day.restingHr != null)
        .map((day) => day.restingHr!.toDouble())
        .toList();

    if (values.isEmpty) {
      return Text(
        'No resting HR data',
        style: TextStyle(color: colors.textMuted),
      );
    }

    final latest = values.last.round();
    final minHr = values.reduce((a, b) => a < b ? a : b).round();
    final maxHr = values.reduce((a, b) => a > b ? a : b).round();
    final sparkColor = _restingHrColor(values);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: KineSpacing.md,
        vertical: KineSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$latest bpm',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Range $minHr-$maxHr',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KineSpacing.md),
          Expanded(
            child: AppKineChartTheme(
              child: SparklineChart(
                data: SparklineData(
                  values: values,
                  color: sparkColor,
                  lineWidth: 2.0,
                  showArea: true,
                  areaAlpha: 18,
                  showEndDot: true,
                  dotRadius: 2.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required KineColors colors,
    required double height,
    required Widget child,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(
        KineSpacing.sm,
        KineSpacing.sm,
        KineSpacing.sm,
        KineSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
      ),
      child: child,
    );
  }

  void _configureTrimpChart(List<AthleteTrendDay> windowDays) {
    final token = Object.hashAll([
      Theme.of(context).brightness,
      _periodDays,
      for (final day in windowDays) day.trimp ?? -1.0,
    ]);
    if (_trimpChartToken == token) return;
    _trimpChartToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _trimpChartKey.currentState;
      if (!mounted || state == null) return;

      state.animateOnDataChange = false;
      state.highlightPerTapEnabled = false;
      state.dragXEnabled = false;
      state.dragYEnabled = false;
      state.scaleXEnabled = false;
      state.scaleYEnabled = false;
      state.pinchZoomEnabled = false;
      state.doubleTapToZoomEnabled = false;
      state.legend.enabled = false;
      state.rightAxis.enabled = false;
      state.leftAxis.axisMinimum = 0;
      state.leftAxis.spaceTop = 0.15;
      state.leftAxis.spaceBottom = 0;
      state.leftAxis.drawAxisLineEnabled = false;
      state.leftAxis.setLabelCount(4, true);
      state.xAxis.drawGridLinesEnabled = false;
      state.xAxis.drawAxisLineEnabled = false;
      state.xAxis.labelPosition = XAxisLabelPosition.bottom;
      state.xAxis.granularityEnabled = true;
      state.xAxis.granularity = 1;
      state.xAxis.setLabelCount(_chartLabelCount(windowDays.length), true);
      state.xAxisRenderer.formatter = FuncAxisValueFormatter((value) {
        final index = value.round().clamp(0, windowDays.length - 1);
        return _axisDateLabel(windowDays[index].date);
      });
      state.yAxisRendererLeft.formatter = const FuncAxisValueFormatter(
        _wholeNumberLabel,
      );
      state.notifyDataSetChanged();
    });
  }

  void _configureHrvChart(List<AthleteTrendDay> windowDays) {
    final token = Object.hashAll([
      Theme.of(context).brightness,
      _periodDays,
      for (final day in windowDays) day.lnRmssd ?? -1.0,
    ]);
    if (_hrvChartToken == token) return;
    _hrvChartToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _hrvChartKey.currentState;
      if (!mounted || state == null) return;

      state.animateOnDataChange = false;
      state.highlightPerTapEnabled = false;
      state.dragXEnabled = false;
      state.dragYEnabled = false;
      state.scaleXEnabled = false;
      state.scaleYEnabled = false;
      state.pinchZoomEnabled = false;
      state.doubleTapToZoomEnabled = false;
      state.legend.enabled = false;
      state.rightAxis.enabled = false;
      state.leftAxis.spaceTop = 0.18;
      state.leftAxis.spaceBottom = 0.18;
      state.leftAxis.drawAxisLineEnabled = false;
      state.leftAxis.setLabelCount(4, true);
      state.xAxis.drawGridLinesEnabled = false;
      state.xAxis.drawAxisLineEnabled = false;
      state.xAxis.labelPosition = XAxisLabelPosition.bottom;
      state.xAxis.granularityEnabled = true;
      state.xAxis.granularity = 1;
      state.xAxis.setLabelCount(_chartLabelCount(windowDays.length), true);
      state.xAxisRenderer.formatter = FuncAxisValueFormatter((value) {
        final index = value.round().clamp(0, windowDays.length - 1);
        return _axisDateLabel(windowDays[index].date);
      });
      state.yAxisRendererLeft.formatter = const FuncAxisValueFormatter(
        _decimalLabel,
      );
      state.notifyDataSetChanged();
    });
  }

  List<AthleteTrendDay> _trendWindow(AthleteTrend trend) {
    final dayMap = <String, AthleteTrendDay>{
      for (final day in trend.days) _dateKey(day.date): day,
    };
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);

    return List.generate(_periodDays, (index) {
      final date = end.subtract(Duration(days: _periodDays - 1 - index));
      return dayMap[_dateKey(date)] ?? AthleteTrendDay(date: date);
    });
  }

  int _chartLabelCount(int dayCount) {
    if (dayCount <= 7) return dayCount;
    if (dayCount <= 14) return 7;
    return 6;
  }

  String _axisDateLabel(DateTime date) {
    if (_periodDays <= 7) {
      return _weekdayShort(date);
    }
    return _shortDate(date);
  }

  Color _trimpColor(double value) {
    if (value <= 0) return KineColors.gray2.withValues(alpha: 0.55);
    if (value < 80) return KineColors.blue3;
    if (value < 140) return KineColors.green2;
    if (value < 190) return KineColors.yellow0;
    if (value < 240) return KineColors.orange1;
    return KineColors.red3;
  }

  Color _restingHrColor(List<double> values) {
    final mean =
        values.fold<double>(0.0, (sum, value) => sum + value) / values.length;
    final latest = values.last;
    if (latest >= mean + 2.5) return KineColors.red3;
    if (latest >= mean + 1.0) return KineColors.orange1;
    if (latest <= mean - 1.5) return KineColors.green2;
    return KineColors.blue3;
  }

  Widget _emptyState(KineColors colors) {
    return Padding(
      padding: const EdgeInsets.all(KineSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 48, color: colors.textMuted),
          const SizedBox(height: KineSpacing.md),
          Text(
            'Select an athlete to view trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) =>
      '${date.day}/${date.month.toString().padLeft(2, '0')}';

  String _weekdayShort(DateTime date) =>
      const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][date.weekday - 1];

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _wholeNumberLabel(double value) => value.toStringAsFixed(0);

  static String _decimalLabel(double value) => value.toStringAsFixed(1);
}
