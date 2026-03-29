import 'package:flutter/material.dart';
import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/readiness_indicator.dart';

/// PRD 8.4 + 8.5 — Team load summary with alerts banner.
class TeamSummaryScreen extends StatefulWidget {
  const TeamSummaryScreen({super.key});

  @override
  State<TeamSummaryScreen> createState() => _TeamSummaryScreenState();
}

class _TeamSummaryScreenState extends State<TeamSummaryScreen> {
  final _service = CoachDataService.instance;

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

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _service.loading ? null : _loadData,
          ),
        ],
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
          ...alerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, right: KineSpacing.sm),
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
              )),
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

    return Text(
      'Team Load — $dateStr',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );
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
            child: Text(row.name, style: nameStyle, overflow: TextOverflow.ellipsis),
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
          SizedBox(
            width: 68,
            child: _buildRiskBadge(row.riskLevel, colors),
          ),
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
                color: row.redDays >= 3 ? KineColors.red3 : colors.textSecondary,
                fontWeight:
                    row.redDays >= 3 ? FontWeight.w600 : FontWeight.w400,
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
      _ => (
          colors.surfaceCard,
          colors.textMuted,
          Icons.remove,
        ),
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
          '$highCount athlete${highCount == 1 ? '' : 's'} in HIGH ACWR zone');
    }
    if (elevatedCount > 0) {
      lines.add(
          '$elevatedCount athlete${elevatedCount == 1 ? '' : 's'} in ELEVATED ACWR zone');
    }
    if (lowCount > 0) {
      lines.add(
          '$lowCount athlete${lowCount == 1 ? '' : 's'} in LOW ACWR zone (undertraining)');
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups, size: 48, color: colors.textMuted),
            const SizedBox(height: KineSpacing.md),
            Text(
              'No weekly data available yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            Text(
              'Team data will appear after athletes start syncing sessions.',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];
}
