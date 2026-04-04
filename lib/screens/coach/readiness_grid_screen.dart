import 'package:flutter/material.dart';
import 'package:kine_charts/kine_charts.dart';
import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_kine_chart_theme.dart';
import '../../widgets/readiness_indicator.dart';

/// PRD 8.1 — Morning readiness grid showing all athletes' status.
class ReadinessGridScreen extends StatefulWidget {
  const ReadinessGridScreen({super.key});

  @override
  State<ReadinessGridScreen> createState() => _ReadinessGridScreenState();
}

class _ReadinessGridScreenState extends State<ReadinessGridScreen> {
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

  Future<void> _loadData() => _service.loadTodayReadiness();

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Readiness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _service.loading ? null : _loadData,
          ),
        ],
      ),
      body: _service.loading && _service.todayReadiness.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(colors, dateStr),
            ),
    );
  }

  Widget _buildContent(KineColors colors, String dateStr) {
    final readiness = _service.todayReadiness;

    if (readiness.isEmpty) {
      return _emptyState(colors);
    }

    final checkedIn = readiness.where((r) => r.hasData).length;
    final total = readiness.length;

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KineSpacing.md,
              KineSpacing.md,
              KineSpacing.md,
              KineSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Readiness — $dateStr',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: KineSpacing.xs),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checkedIn == total
                            ? KineColors.green2
                            : KineColors.yellow0,
                      ),
                    ),
                    const SizedBox(width: KineSpacing.sm),
                    Text(
                      '$checkedIn/$total checked in',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (_service.error.isNotEmpty) ...[
                  const SizedBox(height: KineSpacing.sm),
                  Text(
                    'Using sample data — ${_service.error}',
                    style: TextStyle(fontSize: 12, color: colors.warning),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KineSpacing.md),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: KineSpacing.gap,
              crossAxisSpacing: KineSpacing.gap,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _AthleteReadinessCard(data: readiness[index]),
              childCount: readiness.length,
            ),
          ),
        ),

        // Footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(KineSpacing.md),
            child: Text(
              'Sorted by readiness (worst first)',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(KineColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KineSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view, size: 48, color: colors.textMuted),
            const SizedBox(height: KineSpacing.md),
            Text(
              'No readiness data for today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: KineSpacing.sm),
            Text(
              'Athletes need to complete their morning check.',
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
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Individual athlete card in the readiness grid.
class _AthleteReadinessCard extends StatelessWidget {
  final AthleteReadiness data;

  const _AthleteReadinessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);

    return Card(
      color: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KineRadius.card),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(KineRadius.card),
        onTap: () {
          // Stub for V1: show a snackbar with details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data.name} — detail view coming soon'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(KineSpacing.inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                data.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              const SizedBox(height: KineSpacing.sm),

              // Readiness dot
              Align(
                alignment: Alignment.center,
                child: ReadinessDot(
                  readiness: data.hasData ? data.readiness : null,
                  size: 28,
                ),
              ),

              const SizedBox(height: KineSpacing.sm),

              if (data.hasData) ...[
                Text(
                  'HR ${data.restingHr} bpm',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'lnRMSSD ${data.lnRmssd.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ] else
                Text(
                  'No data today',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              const Spacer(),
              Text(
                '7d lnRMSSD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: KineSpacing.xs),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: _buildSparkline(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline(KineColors colors) {
    if (data.last7LnRmssd.isEmpty) {
      return Center(
        child: Text(
          'No trend yet',
          style: TextStyle(fontSize: 10, color: colors.textMuted),
        ),
      );
    }

    return AppKineChartTheme(
      child: SparklineChart(
        data: SparklineData(
          values: data.last7LnRmssd,
          color: _sparklineColor(colors),
          lineWidth: 2.0,
          showArea: true,
          areaAlpha: 24,
          showEndDot: true,
          dotRadius: 2.3,
        ),
      ),
    );
  }

  Color _sparklineColor(KineColors colors) {
    return switch (data.readiness.toLowerCase()) {
      'green' => KineColors.green2,
      'amber' => KineColors.yellow0,
      'red' => KineColors.red3,
      _ => colors.textMuted,
    };
  }
}
