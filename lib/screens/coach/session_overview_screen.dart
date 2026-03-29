import 'package:flutter/material.dart';
import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/zone_bar.dart';

/// PRD 8.2 — Post-training session overview for all athletes.
class SessionOverviewScreen extends StatefulWidget {
  const SessionOverviewScreen({super.key});

  @override
  State<SessionOverviewScreen> createState() => _SessionOverviewScreenState();
}

class _SessionOverviewScreenState extends State<SessionOverviewScreen> {
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

  Future<void> _loadData() => _service.loadTodaySessions();

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _service.loading ? null : _loadData,
          ),
        ],
      ),
      body: _service.loading && _service.todaySessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(colors, dateStr),
            ),
    );
  }

  Widget _buildContent(KineColors colors, String dateStr) {
    final sessions = _service.todaySessions;

    if (sessions.isEmpty) {
      return _emptyState(colors);
    }

    // Compute team averages
    final avgTrimp =
        sessions.fold(0.0, (s, e) => s + e.trimp) / sessions.length;
    final avgHr =
        (sessions.fold(0, (s, e) => s + e.hrAvg) / sessions.length).round();
    final avgMaxHr =
        (sessions.fold(0, (s, e) => s + e.hrMax) / sessions.length).round();
    final avgDuration =
        (sessions.fold(0, (s, e) => s + e.durationMin) / sessions.length)
            .round();

    return ListView(
      padding: const EdgeInsets.all(KineSpacing.md),
      children: [
        // Header
        Text(
          'Session — $dateStr',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: KineSpacing.xs),
        Text(
          '${sessions.length} athlete${sessions.length == 1 ? '' : 's'} synced',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        if (_service.error.isNotEmpty) ...[
          const SizedBox(height: KineSpacing.sm),
          Text(
            'Using sample data — ${_service.error}',
            style: TextStyle(fontSize: 12, color: colors.warning),
          ),
        ],
        const SizedBox(height: KineSpacing.md),

        // Column headers
        _buildHeaderRow(colors),
        const Divider(height: 1),

        // Athlete rows
        ...sessions.map((s) => _buildSessionRow(s, colors)),

        // Team averages footer
        const Divider(height: 1, thickness: 2),
        _buildAverageRow(avgTrimp, avgHr, avgMaxHr, avgDuration, colors),

        const SizedBox(height: KineSpacing.md),
        Text(
          'Sorted by TRIMP (highest first)',
          style: TextStyle(fontSize: 12, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(KineColors colors) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: colors.textMuted,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KineSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('NAME', style: style)),
          SizedBox(width: 56, child: Text('TRIMP', style: style)),
          SizedBox(width: 52, child: Text('AVG', style: style)),
          SizedBox(width: 52, child: Text('MAX', style: style)),
          SizedBox(width: 48, child: Text('MIN', style: style)),
          Expanded(child: Text('ZONES', style: style)),
        ],
      ),
    );
  }

  Widget _buildSessionRow(AthleteSession s, KineColors colors) {
    final nameStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      color: colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.name} session detail — coming soon'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KineSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                s.name,
                style: nameStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(s.trimp.round().toString(), style: valueStyle),
            ),
            SizedBox(
              width: 52,
              child: Text('${s.hrAvg}', style: valueStyle),
            ),
            SizedBox(
              width: 52,
              child: Text('${s.hrMax}', style: valueStyle),
            ),
            SizedBox(
              width: 48,
              child: Text('${s.durationMin}m', style: valueStyle),
            ),
            Expanded(
              child: ZoneBar(
                zonePercent: s.zonePercent,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageRow(
      double trimp, int avgHr, int maxHr, int duration, KineColors colors) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KineSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('Team avg', style: style)),
          SizedBox(
            width: 56,
            child: Text(trimp.round().toString(), style: style),
          ),
          SizedBox(width: 52, child: Text('$avgHr', style: style)),
          SizedBox(width: 52, child: Text('$maxHr', style: style)),
          SizedBox(width: 48, child: Text('${duration}m', style: style)),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _emptyState(KineColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 48, color: colors.textMuted),
            const SizedBox(height: KineSpacing.md),
            Text(
              'No sessions synced for today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            Text(
              'Sessions will appear here after athletes sync their training data.',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
