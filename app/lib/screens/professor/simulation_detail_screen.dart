import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:simurh/services/group_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/models/simulation.dart';
import 'package:simurh/models/group_model.dart';
import 'package:simurh/models/submission.dart';
import 'package:simurh/models/evaluation.dart';
import 'package:simurh/screens/professor/evaluation_screen.dart';

class SimulationDetailScreen extends StatefulWidget {
  final String simulationId;

  const SimulationDetailScreen({super.key, required this.simulationId});

  @override
  State<SimulationDetailScreen> createState() => _SimulationDetailScreenState();
}

class _SimulationDetailScreenState extends State<SimulationDetailScreen>
    with SingleTickerProviderStateMixin {
  final DbService _db = DbService();

  late TabController _tabController;

  bool _isLoading = true;
  bool _isOnline = true;
  String? _errorMessage;

  Simulation? _simulation;
  List<Group> _groups = [];
  List<Evaluation> _evaluations = [];
  Map<String, Submission> _submissionsByGroup = {};
  List<SimFile> _simFiles = [];
  Set<String> _downloadingFileIds = {};
  String _etablissement = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    _etablissement = (await LicenseService.getLicense())?.etablissement ?? '';

    try {
      await Future.wait([
        _loadSimulation(),
        _loadGroups(),
        _loadEvaluations(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur : $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSimulation() async {
    try {
      final results = await _db.query('simulations',
          where: 'id = ?',
          whereArgs: [int.tryParse(widget.simulationId)]);
      if (results.isNotEmpty) {
        _simulation = Simulation.fromJson(results.first);
        _simFiles = _simulation!.files;
      }
      setState(() => _isOnline = true);
    } catch (_) {
      setState(() => _isOnline = false);
    }
  }

  Future<void> _loadGroups() async {
    try {
      _groups = await GroupService().getGroups(int.parse(widget.simulationId));

      // Load submissions for each group
      for (final group in _groups) {
        try {
          final subResults = await _db.query('submissions',
              where: 'group_id = ? AND simulation_id = ?',
              whereArgs: [int.tryParse(group.id), int.tryParse(widget.simulationId)]);
          if (subResults.isNotEmpty) {
            final submission = Submission.fromJson(subResults.first);
            _submissionsByGroup[group.id] = submission;
          }
        } catch (_) {
          // No submission yet for this group
        }
      }
    } catch (_) {}
  }

  Future<void> _loadEvaluations() async {
    try {
      final results = await _db.query('evaluations',
          where: 'submission_id IN (SELECT id FROM submissions WHERE simulation_id = ?)',
          whereArgs: [int.tryParse(widget.simulationId)]);
      _evaluations = results.map((e) => Evaluation.fromJson(e)).toList();
    } catch (_) {}
  }

  Group _buildGroupFromDb(Map<String, dynamic> data) {
    return Group(
      id: '${data['id']}',
      simulationId: '${data['simulation_id']}',
      name: '${data['name'] ?? 'Groupe'}',
      leaderId: '',
      leaderName: '',
      createdAt: DateTime.tryParse('${data['created_at'] ?? ''}') ?? DateTime.now(),
      members: [],
    );
  }

  Future<void> _refresh() async {
    await _initialize();
  }

  // ── Actions ──

  Future<void> _launchSimulation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lancer la simulation'),
        content: const Text(
          'Les étudiants pourront rejoindre et commencer à travailler. '
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lancer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.update('simulations', {'status': 'active'},
          where: 'id = ?',
          whereArgs: [int.tryParse(widget.simulationId)]);
      await _loadSimulation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulation lancée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _closeSimulation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer la simulation'),
        content: const Text(
          'Les étudiants ne pourront plus soumettre de rendus. '
          'Êtes-vous sûr de vouloir clôturer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.update('simulations', {'status': 'closed'},
          where: 'id = ?',
          whereArgs: [int.tryParse(widget.simulationId)]);
      await _loadSimulation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulation clôturée.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(SimFile file) async {
    setState(() => _downloadingFileIds.add(file.id));

    try {
      // fichiers stockés localement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.originalName} téléchargé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingFileIds.remove(file.id));
      }
    }
  }

  void _navigateToEvaluation(Group group, Submission? submission) {
    // Find existing evaluation for this submission using simple for-loop (Dart 2.19 compatible)
    Evaluation? existingEvaluation;
    if (submission != null) {
      for (final e in _evaluations) {
        if (e.submissionId == submission.id) {
          existingEvaluation = e;
          break;
        }
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvaluationScreen(
          simulationId: widget.simulationId,
          group: group,
          submission: submission,
          gradingCriteria: _simulation?.gradingCriteria ?? [],
          existingEvaluation: existingEvaluation,
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_simulation?.title ?? 'Détails simulation'),
            if (_etablissement.isNotEmpty)
              Text(_etablissement,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
        actions: [
          if (!_isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'Hors ligne',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
        ],
        bottom: _simulation != null
            ? TabBar(
                controller: _tabController,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'Infos'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Groupes'),
                  Tab(icon: Icon(Icons.grading_outlined), text: 'Évaluations'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _simulation == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text('Simulation introuvable', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: Column(
                        children: [
                          _buildHeader(theme),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildInfoTab(theme),
                                _buildGroupsTab(theme),
                                _buildEvaluationsTab(theme),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final sim = _simulation!;

    // Status config
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (sim.status) {
      case 'draft':
        statusColor = Colors.orange;
        statusLabel = 'Brouillon';
        statusIcon = Icons.edit_note;
        break;
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
        statusIcon = Icons.play_circle;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusLabel = 'Clôturée';
        statusIcon = Icons.lock;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusLabel = sim.status;
        statusIcon = Icons.help_outline;
    }

    // Progress
    final submittedCount = _submissionsByGroup.length;
    final totalGroups = _groups.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Action button
              if (sim.status == 'draft')
                _buildActionChip(theme, 'Lancer', Icons.rocket_launch, Colors.green, _launchSimulation)
              else if (sim.status == 'active')
                _buildActionChip(theme, 'Clôturer', Icons.lock, Colors.grey, _closeSimulation),
            ],
          ),
          const SizedBox(height: 10),

          // Code
          Row(
            children: [
              Text(
                sim.code,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: sim.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copié')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.copy, size: 16, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Créée le ${DateFormat('dd/MM/yyyy').format(sim.createdAt)} par ${sim.professorName}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),

          // Progress bar
          if (totalGroups > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalGroups > 0 ? submittedCount / totalGroups : 0,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        submittedCount == totalGroups ? Colors.green : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$submittedCount/$totalGroups',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              '$submittedCount groupe${submittedCount > 1 ? 's' : ''} sur $totalGroups ont rendu',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(
      ThemeData theme, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1 : Infos ──

  Widget _buildInfoTab(ThemeData theme) {
    final sim = _simulation!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Contexte
        Text('Contexte', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            sim.context.isNotEmpty ? sim.context : 'Aucun contexte fourni.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: 24),

        // Objectifs
        Text('Objectifs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (sim.objectives.isEmpty)
          Text('Aucun objectif défini.', style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ))
        else
          ...sim.objectives.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2.5),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.value, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),

        // Configuration
        Text('Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(theme, Icons.calendar_today, 'Durée', '${sim.durationDays} jours'),
                const Divider(height: 20),
                _buildInfoRow(theme, Icons.group, 'Groupes max', '${sim.maxGroups}'),
                if (sim.gradingCriteria.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    theme,
                    Icons.assignment_turned_in,
                    'Critères d\'évaluation',
                    '${sim.gradingCriteria.length} critères',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Documents
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Documents', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (_simFiles.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucun document joint')),
            ),
          )
        else
          ..._simFiles.map((file) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: _fileTypeIcon(file.fileType, theme),
                  title: Text(file.originalName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(_formatFileSize(file.fileSize)),
                  trailing: _downloadingFileIds.contains(file.id)
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: Icon(Icons.download, color: theme.colorScheme.primary),
                          onPressed: () => _downloadFile(file),
                        ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
        const SizedBox(height: 24),

        // Grille d'évaluation
        Text('Grille d\'évaluation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...sim.gradingCriteria.map((criterion) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(criterion.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            'Max: ${criterion.maxScore.toInt()}  •  Coeff: ${criterion.coefficient.toInt()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(criterion.maxScore * criterion.coefficient).toInt()} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Tab 2 : Groupes ──

  Widget _buildGroupsTab(ThemeData theme) {
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Aucun groupe inscrit', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Les étudiants rejoindront via le code de la simulation',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final submission = _submissionsByGroup[group.id];
          final hasSubmitted = submission != null;
          final hasEvaluation = submission != null &&
              _evaluations.any((e) => e.submissionId == submission.id);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: hasSubmitted ? Colors.green.withOpacity(0.4) : theme.colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _navigateToEvaluation(group, submission),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.members.length} membre${group.members.length > 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasSubmitted
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasSubmitted ? '🟢' : '🔴',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasSubmitted ? 'Rendu' : 'Pas rendu',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasSubmitted ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (group.members.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: group.members.map((member) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: member.isLeader
                                  ? Colors.amber.withOpacity(0.12)
                                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${member.isLeader ? '👑 ' : ''}${member.name}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: member.isLeader ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (hasEvaluation) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Noté',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ] else if (hasSubmitted) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.rate_review_outlined, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'À noter',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 3 : Évaluations ──

  Widget _buildEvaluationsTab(ThemeData theme) {
    if (_evaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grading_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Aucune évaluation', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Les évaluations apparaîtront ici après notation',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Build ranking sorted by totalScore descending
    final rankedEvaluations = List<Evaluation>.from(_evaluations);
    rankedEvaluations.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Classement header
          Card(
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.leaderboard, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Classement provisoire',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...rankedEvaluations.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final evaluation = entry.value;
            final group = _groups.firstWhere(
              (g) {
                final sub = _submissionsByGroup[g.id];
                return sub?.id == evaluation.submissionId;
              },
              orElse: () => Group(
                id: '',
                simulationId: '',
                name: 'Groupe inconnu',
                leaderId: '',
                leaderName: '',
                createdAt: DateTime.now(),
                members: [],
              ),
            );

            Color rankColor;
            IconData rankIcon;
            if (rank == 1) {
              rankColor = Colors.amber;
              rankIcon = Icons.emoji_events;
            } else if (rank == 2) {
              rankColor = Colors.grey;
              rankIcon = Icons.emoji_events;
            } else if (rank == 3) {
              rankColor = Colors.brown;
              rankIcon = Icons.emoji_events;
            } else {
              rankColor = theme.colorScheme.onSurfaceVariant;
              rankIcon = Icons.circle;
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: rank <= 3 ? rankColor.withOpacity(0.3) : theme.colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final sub = _evaluations.isNotEmpty
                      ? _submissionsByGroup.values.firstWhere(
                          (s) => s.id == evaluation.submissionId,
                          orElse: () => Submission(
                            id: evaluation.submissionId,
                            groupId: group.id,
                            simulationId: widget.simulationId,
                            content: '',
                            submittedAt: DateTime.now(),
                            groupName: group.name,
                            leaderName: group.leaderName,
                            totalScore: 0,
                            scores: evaluation.scores,
                            comments: evaluation.comments,
                          ),
                        )
                      : null;
                  _navigateToEvaluation(group, sub);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? rankColor.withOpacity(0.15) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: rank > 3
                              ? Border.all(color: theme.colorScheme.outlineVariant)
                              : null,
                        ),
                        child: Center(
                          child: rank <= 3
                              ? Icon(rankIcon, color: rankColor, size: 18)
                              : Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Noté le ${DateFormat('dd/MM/yyyy').format(evaluation.evaluatedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: evaluation.totalScore >= 80
                              ? Colors.green.withOpacity(0.1)
                              : evaluation.totalScore >= 60
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${evaluation.totalScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: evaluation.totalScore >= 80
                                ? Colors.green.shade700
                                : evaluation.totalScore >= 60
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _fileTypeIcon(String fileType, ThemeData theme) {
    IconData icon;
    Color color;
    switch (fileType.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        icon = Icons.table_chart;
        color = Colors.green.shade700;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = theme.colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
