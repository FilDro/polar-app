import 'package:flutter/material.dart';
import '../../models/coach_models.dart';
import '../../services/coach_data_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _service = CoachDataService.instance;
  final _athleteIdController = TextEditingController();

  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _athleteIdController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    setState(() => _initialLoad = true);

    try {
      await _service.getTeamInfo();
      await _service.getRoster();
    } catch (e) {
      _showMessage(_displayError(e));
    } finally {
      if (mounted) {
        setState(() => _initialLoad = false);
      }
    }
  }

  Future<void> _addAthlete() async {
    FocusScope.of(context).unfocus();

    final athleteId = _athleteIdController.text.trim();
    if (athleteId.isEmpty) {
      _showMessage('Enter an athlete ID to add.');
      return;
    }

    try {
      await _service.assignAthleteToTeam(athleteId);
      _athleteIdController.clear();
      _showMessage('Athlete added to the roster.');
    } catch (e) {
      _showMessage(_displayError(e));
    }
  }

  Future<void> _editTeamName() async {
    final team = _service.teamInfo;
    if (team == null) {
      _showMessage('No team is linked to this coach yet.');
      return;
    }

    final controller = TextEditingController(text: team.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Team Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Team Name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName == null) return;

    try {
      await _service.updateTeamName(newName);
      _showMessage('Team name updated.');
    } catch (e) {
      _showMessage(_displayError(e));
    }
  }

  Future<void> _removeAthlete(({String id, String name}) athlete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Athlete'),
          content: Text(
            'Remove ${athlete.name} from this team? Their team assignment will be cleared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.removeAthleteFromTeam(athlete.id);
      _showMessage('${athlete.name} removed from the roster.');
    } catch (e) {
      _showMessage(_displayError(e));
    }
  }

  void _showMessage(String message) {
    if (!mounted || message.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayError(Object error) {
    final serviceError = _service.error.trim();
    if (serviceError.isNotEmpty) {
      return serviceError;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final team = _service.teamInfo;
    final roster = _service.roster;
    final busy = _initialLoad || _service.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: busy ? null : _refresh,
          ),
        ],
      ),
      body: busy && team == null && roster.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(KineSpacing.md),
                children: [
                  _buildTeamCard(colors, team),
                  const SizedBox(height: KineSpacing.md),
                  _buildAddAthleteCard(colors, busy),
                  const SizedBox(height: KineSpacing.md),
                  _buildRosterCard(colors, roster, busy),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamCard(KineColors colors, TeamInfo? team) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: team == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No team linked',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: KineSpacing.sm),
                Text(
                  'A coach profile exists, but no team is assigned yet.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _service.loading ? null : _editTeamName,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Rename'),
                    ),
                  ],
                ),
                const SizedBox(height: KineSpacing.sm),
                Text(
                  'Team ID',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: KineSpacing.xs),
                SelectableText(
                  team.id,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
    );
  }

  Widget _buildAddAthleteCard(KineColors colors, bool busy) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Athlete',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: KineSpacing.sm),
          Text(
            'Paste the athlete UUID to add them to this team. Email lookup is not available in the current schema.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: KineSpacing.md),
          TextField(
            controller: _athleteIdController,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Athlete ID (UUID)',
              hintText: '00000000-0000-0000-0000-000000000000',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addAthlete(),
          ),
          const SizedBox(height: KineSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy ? null : _addAthlete,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Athlete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterCard(
    KineColors colors,
    List<({String id, String name})> roster,
    bool busy,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(KineRadius.card),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KineSpacing.md,
              KineSpacing.md,
              KineSpacing.md,
              KineSpacing.sm,
            ),
            child: Text(
              'Roster (${roster.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (roster.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KineSpacing.md,
                0,
                KineSpacing.md,
                KineSpacing.md,
              ),
              child: Text(
                'No athletes are assigned to this team yet.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            )
          else
            ...roster.map((athlete) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      athlete.name,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      athlete.id,
                      style: TextStyle(color: colors.textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      tooltip: 'Remove Athlete',
                      onPressed: busy ? null : () => _removeAthlete(athlete),
                    ),
                  ),
                  Divider(height: 1, color: colors.surfaceBorder),
                ],
              );
            }),
        ],
      ),
    );
  }
}
