import 'package:flutter/material.dart';
import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/readiness_indicator.dart';

/// PRD 8.3 — Per-athlete longitudinal load trends with ACWR.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final _service = CoachDataService.instance;

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
        // Athlete selector
        _buildAthleteSelector(colors),
        const SizedBox(height: KineSpacing.md),

        // Period selector
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
      items: roster.map((a) {
        return DropdownMenuItem(value: a.id, child: Text(a.name));
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
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

        // ACWR / Monotony / Strain metrics
        _buildMetricsRow(trend, colors),
        const SizedBox(height: KineSpacing.lg),

        // Readiness streak (last 7 days)
        _buildReadinessStreak(trend, colors),
        const SizedBox(height: KineSpacing.lg),

        // TRIMP daily values
        _buildSection('TRIMP (daily)', colors),
        const SizedBox(height: KineSpacing.sm),
        _buildTrimpBars(trend, colors),
        const SizedBox(height: KineSpacing.lg),

        // lnRMSSD daily values
        _buildSection('lnRMSSD (morning)', colors),
        const SizedBox(height: KineSpacing.sm),
        _buildHrvValues(trend, colors),
        const SizedBox(height: KineSpacing.lg),

        // Resting HR
        _buildSection('Resting HR', colors),
        const SizedBox(height: KineSpacing.sm),
        _buildRestingHrValues(trend, colors),
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
              _metricTile('ACWR', _formatAcwr(trend.acwr), _acwrColor(trend.acwr), colors),
              _metricTile('Monotony', trend.monotony?.toStringAsFixed(1) ?? '—', null, colors),
              _metricTile('Strain', trend.strain?.toStringAsFixed(0) ?? '—', null, colors),
            ],
          ),
          const SizedBox(height: KineSpacing.sm),
          Row(
            children: [
              _metricTile('Acute', trend.acuteLoad.toStringAsFixed(0), null, colors),
              _metricTile('Chronic', trend.chronicLoad.toStringAsFixed(0), null, colors),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color? valueColor, KineColors colors) {
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
                  ReadinessDot(
                    readiness: day.readiness,
                    size: 20,
                  ),
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

  /// Simple horizontal bar chart for TRIMP values using Container widgets.
  Widget _buildTrimpBars(AthleteTrend trend, KineColors colors) {
    final daysWithTrimp =
        trend.days.where((d) => d.trimp != null).toList();

    if (daysWithTrimp.isEmpty) {
      return Text('No session data', style: TextStyle(color: colors.textMuted));
    }

    final maxTrimp =
        daysWithTrimp.fold(0.0, (m, d) => d.trimp! > m ? d.trimp! : m);
    if (maxTrimp <= 0) {
      return Text('No session data', style: TextStyle(color: colors.textMuted));
    }

    return Column(
      children: daysWithTrimp.map((day) {
        final fraction = day.trimp! / maxTrimp;
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  _shortDate(day.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 14,
                        width: constraints.maxWidth * fraction,
                        decoration: BoxDecoration(
                          color: KineColors.blue3.withValues(alpha: 0.7),
                          borderRadius:
                              BorderRadius.circular(KineRadius.sm),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: KineSpacing.sm),
              SizedBox(
                width: 36,
                child: Text(
                  day.trimp!.round().toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Text list of lnRMSSD values.
  Widget _buildHrvValues(AthleteTrend trend, KineColors colors) {
    final daysWithHrv =
        trend.days.where((d) => d.lnRmssd != null).toList();

    if (daysWithHrv.isEmpty) {
      return Text('No HRV data', style: TextStyle(color: colors.textMuted));
    }

    return Wrap(
      spacing: KineSpacing.md,
      runSpacing: KineSpacing.xs,
      children: daysWithHrv.map((day) {
        return SizedBox(
          width: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _shortDate(day.date),
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                day.lnRmssd!.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Text list of resting HR values.
  Widget _buildRestingHrValues(AthleteTrend trend, KineColors colors) {
    final daysWithHr =
        trend.days.where((d) => d.restingHr != null).toList();

    if (daysWithHr.isEmpty) {
      return Text('No resting HR data', style: TextStyle(color: colors.textMuted));
    }

    // Display as arrow-separated chain
    final chain = daysWithHr.map((d) => '${d.restingHr}').join(' → ');
    return Text(
      chain,
      style: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
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

  String _shortDate(DateTime d) =>
      '${d.day}/${d.month.toString().padLeft(2, '0')}';

  String _weekdayShort(DateTime d) =>
      const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][d.weekday - 1];
}
