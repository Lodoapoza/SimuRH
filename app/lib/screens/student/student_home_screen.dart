import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simurh/services/auth_service.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/sync_service.dart';
import 'package:simurh/services/file_service.dart';
import 'package:simurh/models/simulation.dart';
import 'package:simurh/models/group_model.dart';
import 'package:simurh/models/submission.dart';
import 'package:simurh/models/evaluation.dart';
import 'package:simurh/models/resource.dart';
import 'package:simurh/screens/student/simulation_work_screen.dart';
import 'package:simurh/screens/student/result_screen.dart';
import 'package:simurh/screens/student/resources_view_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final DbService _dbService = DbService();
  final SyncService _syncService = SyncService();
  final FileService _fileService = FileService();

  User? _currentUser;
  bool _isLoading = true;
  bool _isOnline = true;
  String? _errorMessage;

  // Simulation state
  Simulation? _simulation;
  Group? _userGroup;
  Submission? _submission;
  Evaluation? _evaluation;
  List<Resource> _resources = [];
  List<RankingEntry> _rankings = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUser = await _authService.getCurrentUser();

      // Try to sync from server first
      await _syncAndReload();
    } catch (e) {
      // Offline or error — fall back to cache
      await _loadFromCache();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _syncAndReload() async {
    try {
      await _syncService.syncAll();
      setState(() => _isOnline = true);
    } catch (_) {
      setState(() => _isOnline = false);
    }

    await _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final userId = _currentUser?.id;
    if (userId == null) return;

    // Find user's group memberships
    final memberships = await _dbService.query(
      'group_members',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (memberships.isEmpty) {
      // No active simulation — try fetching available resources
      await _loadResources();
      return;
    }

    // Get the first group's simulation
    final groupId = memberships.first['group_id'];
    final groups = await _dbService.query(
      'groups_table',
      where: 'id = ?',
      whereArgs: [groupId],
    );
    if (groups.isEmpty) return;
    final groupData = groups.first;
    final simulationId = groupData['simulation_id'];

    // Build Group model
    _userGroup = _buildGroupFromDb(groupData, memberships);

    // Build Simulation model
    final sims = await _dbService.query(
      'simulations',
      where: 'id = ?',
      whereArgs: [simulationId],
    );
    if (sims.isNotEmpty) {
      _simulation = _buildSimulationFromDb(sims.first);
    }

    // Build Submission model
    final subs = await _dbService.query(
      'submissions',
      where: 'simulation_id = ? AND group_id = ?',
      whereArgs: [simulationId, groupId],
    );
    if (subs.isNotEmpty) {
      _submission = _buildSubmissionFromDb(subs.first);

      // Build Evaluation model
      final evals = await _dbService.query(
        'evaluations',
        where: 'submission_id = ?',
        whereArgs: [_submission!.id],
      );
      if (evals.isNotEmpty) {
        _evaluation = _buildEvaluationFromDb(evals.first);
      }
    }

    // Load resources
    await _loadResources();

    // Load ranking from cache
    final rankingsData = await _dbService.getCachedEvaluations();
    if (rankingsData.isNotEmpty && _simulation != null) {
      // In a full implementation, ranking data would be stored separately
    }
  }

  Future<void> _loadResources() async {
    final resourcesData = await _dbService.getCachedResources();
    _resources = resourcesData.map((e) {
      try {
        return Resource.fromJson(e);
      } catch (_) {
        return _buildResourceFromDb(e);
      }
    }).toList();
  }

  // ── Build helpers for cached data ──

  Simulation _buildSimulationFromDb(Map<String, dynamic> data) {
    return Simulation(
      id: '${data['id']}',
      professorId: '${data['creator_id'] ?? ''}',
      establishmentId: '',
      code: '${data['code'] ?? ''}',
      title: '${data['title'] ?? ''}',
      context: '${data['description'] ?? ''}',
      objectives: [],
      durationDays: 0,
      maxGroups: 0,
      gradingCriteria: [],
      status: '${data['status'] ?? 'active'}',
      createdAt: DateTime.tryParse('${data['created_at'] ?? ''}') ?? DateTime.now(),
      professorName: '',
      groupCount: 0,
      submissionCount: 0,
      files: [],
    );
  }

  Group _buildGroupFromDb(Map<String, dynamic> data, List<Map<String, dynamic>> memberships) {
    final members = memberships.map((m) {
      final isLeader = '${m['role']}' == 'leader';
      return Member(
        id: '${m['user_id']}',
        name: '',
        email: '',
        isLeader: isLeader,
      );
    }).toList();

    return Group(
      id: '${data['id']}',
      simulationId: '${data['simulation_id']}',
      name: '${data['name'] ?? ''}',
      leaderId: '',
      leaderName: '',
      createdAt: DateTime.tryParse('${data['created_at'] ?? ''}') ?? DateTime.now(),
      members: members,
    );
  }

  Submission _buildSubmissionFromDb(Map<String, dynamic> data) {
    return Submission(
      id: '${data['id']}',
      groupId: '${data['group_id']}',
      simulationId: '${data['simulation_id']}',
      content: '${data['content'] ?? ''}',
      filePath: '${data['file_path'] ?? ''}',
      submittedAt: DateTime.tryParse('${data['submitted_at'] ?? ''}') ?? DateTime.now(),
      syncedAt: null,
      groupName: '',
      leaderName: '',
      totalScore: 0,
      comments: null,
      scores: {},
    );
  }

  Evaluation _buildEvaluationFromDb(Map<String, dynamic> data) {
    return Evaluation(
      id: '${data['id']}',
      submissionId: '${data['submission_id']}',
      professorId: '${data['evaluator_id']}',
      scores: {},
      totalScore: (data['score'] as num?)?.toDouble() ?? 0,
      comments: '${data['feedback'] ?? ''}',
      evaluatedAt: DateTime.tryParse('${data['evaluated_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  Resource _buildResourceFromDb(Map<String, dynamic> data) {
    return Resource(
      id: '${data['id']}',
      professorId: '',
      establishmentId: '',
      title: '${data['title'] ?? ''}',
      description: '${data['description'] ?? ''}',
      filePath: '${data['url'] ?? ''}',
      fileType: '${data['file_type'] ?? ''}',
      uploadedAt: DateTime.tryParse('${data['created_at'] ?? ''}') ?? DateTime.now(),
      professorName: '',
    );
  }

  // ── Join Simulation ──

  Future<void> _showJoinDialog() async {
    final codeController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejoindre une simulation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez le code à 10 caractères fourni par votre professeur.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code de la simulation',
                hintText: 'XXXXXXXXXX',
                counterText: '',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 18, letterSpacing: 4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final code = codeController.text.trim().toUpperCase();
              if (code.length == 10) {
                Navigator.of(ctx).pop();
                _joinSimulation(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le code doit contenir exactement 10 caractères')),
                );
              }
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinSimulation(String code) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('simulations/join/$code');
      // Cache the joined simulation data
      await _dbService.cacheSimulation(response);
      // Reload everything
      await _loadFromCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez rejoint la simulation !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : impossible de rejoindre la simulation. $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Refresh ──

  Future<void> _onRefresh() async {
    await _loadData();
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
            const Text('SimuRH', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_currentUser != null)
              Text(
                _currentUser!.name,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
              ),
          ],
        ),
        actions: [
          if (!_isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text('Hors ligne', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _simulation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Une erreur est survenue', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Online Status Banner ──
        if (!_isOnline)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 20, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  'Mode hors ligne — les données affichées peuvent ne pas être à jour',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                ),
              ],
            ),
          ),

        // ── No Simulation ──
        if (_simulation == null) _buildJoinSection(theme),

        // ── Active Simulation ──
        if (_simulation != null && _simulation!.status != 'closed')
          _buildActiveSimulationCard(theme),

        // ── Finished Simulation (Results) ──
        if (_simulation != null && _simulation!.status == 'closed')
          _buildResultsSection(theme),

        // ── Resources ──
        if (_resources.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildResourcesSection(theme),
        ],
      ],
    );
  }

  // ── Join Section ──

  Widget _buildJoinSection(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text(
              'Bienvenue sur SimuRH',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de simulation active.\nRejoignez une simulation avec le code fourni par votre professeur.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 260,
              height: 56,
              child: FilledButton.icon(
                onPressed: _showJoinDialog,
                icon: const Icon(Icons.group_add, size: 24),
                label: const Text('Rejoindre une simulation', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Simulation Card ──

  Widget _buildActiveSimulationCard(ThemeData theme) {
    final sim = _simulation!;
    final submission = _submission;
    final group = _userGroup;

    // Determine progress
    String progressText;
    Color progressColor;
    if (submission != null) {
      progressText = submission.status == 'submitted' ? 'Soumis' : 'En cours de rédaction';
      progressColor = submission.status == 'submitted'
          ? Colors.green
          : theme.colorScheme.tertiary;
    } else {
      progressText = 'En cours';
      progressColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSimulationWork(sim),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sim.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code : ${sim.code}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      progressText,
                      style: TextStyle(fontSize: 12, color: progressColor),
                    ),
                    backgroundColor: progressColor.withOpacity(0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _infoChip(theme, Icons.people_outline, group?.name ?? 'Groupe'),
                  const SizedBox(width: 12),
                  _infoChip(theme, Icons.calendar_today, 'Créée le ${DateFormat('dd/MM/yyyy').format(sim.createdAt)}'),
                ],
              ),
              if (sim.context.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  sim.context,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Appuyez pour travailler →',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  // ── Results Section ──

  Widget _buildResultsSection(ThemeData theme) {
    final sim = _simulation!;
    final evaluation = _evaluation;
    final submission = _submission;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Résultats', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openResults(sim, evaluation, submission),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: evaluation != null
                          ? (evaluation.totalScore >= 10 ? Colors.green : Colors.orange)
                              .withOpacity(0.1)
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        evaluation != null
                            ? '${evaluation.totalScore.toStringAsFixed(1)}'
                            : '—',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: evaluation != null
                              ? (evaluation.totalScore >= 10 ? Colors.green : Colors.orange)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sim.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (evaluation != null && evaluation.comments != null && evaluation.comments!.isNotEmpty)
                          Text(
                            evaluation.comments!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (evaluation == null)
                          Text(
                            'En attente d\'évaluation',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.assignment_turned_in, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              submission != null
                                  ? 'Soumis le ${DateFormat('dd/MM/yyyy').format(submission.submittedAt)}'
                                  : 'Pas de soumission',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Resources Section ──

  Widget _buildResourcesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ressources disponibles', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => _openAllResources(),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_resources.take(3).map((res) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildResourceTile(theme, res),
        ))),
        if (_resources.length > 3)
          Center(
            child: TextButton(
              onPressed: () => _openAllResources(),
              child: Text('+ ${_resources.length - 3} autres ressources'),
            ),
          ),
      ],
    );
  }

  Widget _buildResourceTile(ThemeData theme, Resource res) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: _fileTypeIcon(res.fileType, theme),
        title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(res.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.download, color: theme.colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
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

  // ── Navigation ──

  void _openSimulationWork(Simulation sim) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimulationWorkScreen(
          simulation: sim,
          group: _userGroup,
          submission: _submission,
        ),
      ),
    );
  }

  void _openResults(Simulation sim, Evaluation? evaluation, Submission? submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          simulation: sim,
          evaluation: evaluation,
          submission: submission,
          rankings: _rankings,
        ),
      ),
    );
  }

  void _openAllResources() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResourcesViewScreen(resources: _resources),
      ),
    );
  }
}
