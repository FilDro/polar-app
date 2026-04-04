import 'package:flutter/material.dart';
import 'package:kine_charts/kine_charts.dart';
import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_kine_chart_theme.dart';
import '../../widgets/readiness_indicator.dart';
import 'roster_screen.dart';

/// PRD 8.4 + 8.5 — Team load summary with alerts banner.
class TeamSummaryScreen extends StatefulWidget {
  const TeamSummaryScreen({super.key});

  @override
  State<TeamSummaryScreen> createState() => _TeamSummaryScreenState();
}

class _TeamSummaryScreenState extends State<TeamSummaryScreen> {
  final _service = CoachDataService.instance;
  final GlobalKey<BarChartState> _riskChartKey = GlobalKey<BarChartState>();

  Object? _riskChartToken;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _loadData();
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() => _service.loadTeamSummary();

  Future<void> _openRosterManager() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const RosterScreen()));

    if (mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Manage Team',
            onPressed: _openRosterManager,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _service.loading ? null : _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRosterManager,
        icon: const Icon(Icons.groups_2_outlined),
        label: const Text('Manage Team'),
      ),
      body: _service.loading && _service.teamRows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(colors),
            ),
    );
  }

  Widget _buildContent(KineColors colors) {
    final rows = _service.teamRows;
    final alerts = _service.alerts;

    if (rows.isEmpty) {
      return _emptyState(colors);
    }

    return ListView(
      padding: const EdgeInsets.all(KineSpacing.md),
      children: [
        // Alert banner
        if (alerts.isNotEmpty) ...[
          _buildAlertBanner(alerts, colors),
          const SizedBox(height: KineSpacing.md),
        ],

        // Header
        _buildHeader(colors),
        const SizedBox(height: KineSpacing.md),

        if (_service.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: KineSpacing.sm),
            child: Text(
              'Using sample data — ${_service.error}',
              style: TextStyle(fontSize: 12, color: colors.warning),
            ),
          ),
        _buildRiskDistribution(rows, colors),
        const SizedBox(height: KineSpacing.md),

        // Column headers
        _buildColumnHeaders(colors),
        const Divider(height: 1),

        // Athlete rows
        ...rows.map((r) => _buildAthleteRow(r, colors)),

        const SizedBox(height: KineSpacing.md),

        // Summary footer
        _buildSummaryFooter(rows, colors),
      ],
    );
  }

  Widget _buildAlertBanner(List<TeamAlert> alerts, KineColors colors) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.inset),
      decoration: BoxDecoration(
        color: _alertBannerColor(alerts.first.priority, colors),
        borderRadius: BorderRadius.circular(KineRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: _alertIconColor(alerts.first.priority),
              ),
              const SizedBox(width: KineSpacing.sm),
              Text(
                'Alerts (${alerts.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _alertTextColor(alerts.first.priority),
                ),
              ),
            ],
          ),
          const SizedBox(height: KineSpacing.sm),
          ...alerts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(
                      top: 4,
                      right: KineSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _priorityDotColor(a.priority),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      a.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: _alertTextColor(alerts.first.priority),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _alertBannerColor(String priority, KineColors colors) {
    return switch (priority) {
      'high' => KineColors.red3.withValues(alpha: 0.12),
      'medium' => KineColors.orange1.withValues(alpha: 0.12),
      _ => colors.surfaceCard,
    };
  }

  Color _alertIconColor(String priority) {
    return switch (priority) {
      'high' => KineColors.red3,
      'medium' => KineColors.orange1,
      _ => KineColors.gray3,
    };
  }

  Color _alertTextColor(String priority) {
    return switch (priority) {
      'high' => KineColors.red3,
      'medium' => KineColors.orange1,
      _ => KineColors.gray4,
    };
  }

  Color _priorityDotColor(String priority) {
    return switch (priority) {
      'high' => KineColors.red3,
      'medium' => KineColors.orange1,
      'low' => KineColors.yellow0,
      _ => KineColors.gray3,
    };
  }

  Widget _buildHeader(KineColors colors) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final dateStr =
        'Week of ${weekStart.day} ${_monthShort(weekStart.month)} ${weekStart.year}';
    final teamName = _service.teamInfo?.name ?? 'Your Team';
    final rosterCount = _service.roster.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Team Load — $dateStr',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$rosterCount athlete${rosterCount == 1 ? '' : 's'} on roster',
          style: TextStyle(fontSize: 12, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildRiskDistribution(List<TeamAthleteRow> rows, KineColors colors) {
    final buckets =
        <({String label, String axisLabel, int count, Color color})>[
          (
            label: 'LOW',
            axisLabel: 'LOW',
            count: rows.where((row) => row.riskLevel == 'LOW').length,
            color: KineColors.blue3,
          ),
          (
            label: 'OPTIMAL',
            axisLabel: 'OPT',
            count: rows.where((row) => row.riskLevel == 'OPTIMAL').length,
            color: KineColors.green2,
          ),
          (
            label: 'ELEVATED',
            axisLabel: 'ELEV',
            count: rows.where((row) => row.riskLevel == 'ELEVATED').length,
            color: KineColors.orange1,
          ),
          (
            label: 'HIGH',
            axisLabel: 'HIGH',
            count: rows.where((row) => row.riskLevel == 'HIGH').length,
            color: KineColors.red3,
          ),
        ];
    final avgAcwrValues = rows
        .where((row) => row.acwr != null)
        .map((row) => row.acwr!)
        .toList();
    final avgAcwr = avgAcwrValues.isEmpty
        ? null
        : avgAcwrValues.fold<double>(0.0, (sum, value) => sum + value) /
              avgAcwrValues.length;
    final entries = <BarChartDataEntry>[];
    final barColors = <Color>[];

    for (var index = 0; index < buckets.length; index++) {
      entries.add(
        BarChartDataEntry(
          x: index.toDouble(),
          y: buckets[index].count.toDouble(),
        ),
      );
      barColors.add(buckets[index].color);
    }

    final dataSet = BarDataSet(entries, label: 'Athletes')
      ..colors = barColors
      ..cornerRadius = 6;
    final data = BarData([dataSet])..barWidth = 0.62;

    _configureRiskChart(buckets);

    return Container(
      padding: const EdgeInsets.all(KineSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ACWR distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (avgAcwr != null)
                Text(
                  'Avg ${avgAcwr.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _acwrColor(avgAcwr) ?? colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Athletes per risk band this week',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: KineSpacing.sm),
          SizedBox(
            height: 128,
            child: AppKineChartTheme(
              child: BarChart(
                key: _riskChartKey,
                data: data,
                touchEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _configureRiskChart(
    List<({String label, String axisLabel, int count, Color color})> buckets,
  ) {
    final token = Object.hashAll([
      Theme.of(context).brightness,
      for (final bucket in buckets) bucket.count,
    ]);
    if (_riskChartToken == token) return;
    _riskChartToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _riskChartKey.currentState;
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
      state.leftAxis.spaceBottom = 0;
      state.leftAxis.spaceTop = 0.18;
      state.leftAxis.drawAxisLineEnabled = false;
      state.leftAxis.setLabelCount(4, true);
      state.xAxis.drawGridLinesEnabled = false;
      state.xAxis.drawAxisLineEnabled = false;
      state.xAxis.labelPosition = XAxisLabelPosition.bottom;
      state.xAxis.granularityEnabled = true;
      state.xAxis.granularity = 1;
      state.xAxis.setLabelCount(buckets.length, true);
      state.xAxisRenderer.formatter = FuncAxisValueFormatter((value) {
        final index = value.round().clamp(0, buckets.length - 1);
        return buckets[index].axisLabel;
      });
      state.yAxisRendererLeft.formatter = const FuncAxisValueFormatter(
        _wholeNumberLabel,
      );
      state.notifyDataSetChanged();
    });
  }

  Widget _buildColumnHeaders(KineColors colors) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: colors.textMuted,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KineSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('NAME', style: style)),
          SizedBox(width: 55, child: Text('TRIMP', style: style)),
          SizedBox(width: 50, child: Text('ACWR', style: style)),
          SizedBox(width: 68, child: Text('RISK', style: style)),
          SizedBox(width: 36, child: Text('RDY', style: style)),
          Expanded(child: Text('RED', style: style)),
        ],
      ),
    );
  }

  Widget _buildAthleteRow(TeamAthleteRow row, KineColors colors) {
    final nameStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
    );
    final valueStyle = TextStyle(
      fontSize: 12,
      color: colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KineSpacing.xs + 1),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              row.name,
              style: nameStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(row.weekTrimp.round().toString(), style: valueStyle),
          ),
          SizedBox(
            width: 50,
            child: Text(
              row.acwr?.toStringAsFixed(2) ?? '—',
              style: valueStyle.copyWith(
                color: _acwrColor(row.acwr),
                fontWeight: (row.acwr ?? 0) > 1.3
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 68, child: _buildRiskBadge(row.riskLevel, colors)),
          SizedBox(
            width: 36,
            child: ReadinessDot(
              readiness: row.readiness.isEmpty ? null : row.readiness,
              size: 14,
            ),
          ),
          Expanded(
            child: Text(
              row.redDays > 0 ? '${row.redDays}' : '',
              style: valueStyle.copyWith(
                color: row.redDays >= 3
                    ? KineColors.red3
                    : colors.textSecondary,
                fontWeight: row.redDays >= 3
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String level, KineColors colors) {
    if (level.isEmpty) {
      return Text('—', style: TextStyle(fontSize: 11, color: colors.textMuted));
    }

    final (bgColor, textColor, icon) = switch (level) {
      'HIGH' => (
        KineColors.red3.withValues(alpha: 0.15),
        KineColors.red3,
        Icons.warning_amber,
      ),
      'ELEVATED' => (
        KineColors.orange1.withValues(alpha: 0.15),
        KineColors.orange1,
        Icons.trending_up,
      ),
      'OPTIMAL' => (
        KineColors.green2.withValues(alpha: 0.15),
        KineColors.green2,
        Icons.check,
      ),
      'LOW' => (
        KineColors.blue3.withValues(alpha: 0.15),
        KineColors.blue3,
        Icons.trending_down,
      ),
      _ => (colors.surfaceCard, colors.textMuted, Icons.remove),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KineSpacing.xs + 1,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(KineRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 2),
          Text(
            level,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color? _acwrColor(double? acwr) {
    if (acwr == null) return null;
    if (acwr > 1.5) return KineColors.red3;
    if (acwr > 1.3) return KineColors.orange1;
    if (acwr >= 0.8) return KineColors.green2;
    return KineColors.blue3;
  }

  Widget _buildSummaryFooter(List<TeamAthleteRow> rows, KineColors colors) {
    final highCount = rows.where((r) => r.riskLevel == 'HIGH').length;
    final elevatedCount = rows.where((r) => r.riskLevel == 'ELEVATED').length;
    final lowCount = rows.where((r) => r.riskLevel == 'LOW').length;

    final lines = <String>[];
    if (highCount > 0) {
      lines.add(
        '$highCount athlete${highCount == 1 ? '' : 's'} in HIGH ACWR zone',
      );
    }
    if (elevatedCount > 0) {
      lines.add(
        '$elevatedCount athlete${elevatedCount == 1 ? '' : 's'} in ELEVATED ACWR zone',
      );
    }
    if (lowCount > 0) {
      lines.add(
        '$lowCount athlete${lowCount == 1 ? '' : 's'} in LOW ACWR zone (undertraining)',
      );
    }

    if (lines.isEmpty) {
      return Text(
        'All athletes in OPTIMAL ACWR zone',
        style: TextStyle(fontSize: 13, color: KineColors.green2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isHigh = line.contains('HIGH');
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 13,
              color: isHigh ? KineColors.red3 : colors.textSecondary,
              fontWeight: isHigh ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(KineColors colors) {
    final teamName = _service.teamInfo?.name;
    final hasRoster = _service.roster.isNotEmpty;
    final title = teamName == null
        ? 'No team assigned yet'
        : hasRoster
        ? 'No weekly data available yet'
        : 'No athletes on $teamName yet';
    final description = teamName == null
        ? 'Once a team is linked to this coach, you can manage the roster here.'
        : hasRoster
        ? 'Team data will appear after athletes start syncing sessions.'
        : 'Use Manage Team to add athletes by UUID and start building the roster.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups, size: 48, color: colors.textMuted),
            const SizedBox(height: KineSpacing.md),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  static String _wholeNumberLabel(double value) => value.toStringAsFixed(0);
}
