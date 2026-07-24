import 'dart:async';
import 'package:flutter/material.dart' hide Simulation;
import 'package:intl/intl.dart';
import 'package:simurh/services/auth_service.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/sync_service.dart';
import 'package:simurh/services/file_service.dart';
import 'package:simurh/models/simulation.dart';
import 'package:simurh/models/group_model.dart';
import 'package:simurh/models/submission.dart';
import 'package:simurh/models/resource.dart';

class SimulationWorkScreen extends StatefulWidget {
  final Simulation simulation;
  final Group? group;
  final Submission? submission;

  const SimulationWorkScreen({
    super.key,
    required this.simulation,
    this.group,
    this.submission,
  });

  @override
  State<SimulationWorkScreen> createState() => _SimulationWorkScreenState();
}

class _SimulationWorkScreenState extends State<SimulationWorkScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final DbService _dbService = DbService();
  final SyncService _syncService = SyncService();
  final FileService _fileService = FileService();

  late TabController _tabController;

  bool _isLoading = true;
  bool _isOnline = true;
  String? _errorMessage;

  // Data
  User? _currentUser;
  Group? _group;
  Submission? _submission;
  List<Resource> _resources = [];
  List<SimFile> _simFiles = [];
  String? _attachedFilePath;
  String? _attachedFileName;

  // Text controller for submission content
  final TextEditingController _contentController = TextEditingController();

  // Leader management
  String? _selectedLeaderId;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await _authService.getCurrentUser();

      // Check online status
      try {
        await _syncService.syncAll();
        _isOnline = true;
      } catch (_) {
        _isOnline = false;
      }

      // Load data
      await _loadData();
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors du chargement : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    final sim = widget.simulation;

    // Load group data
    if (widget.group != null) {
      _group = widget.group;
    } else {
      await _loadGroupFromServer(sim.id);
    }

    // Load submission data
    if (widget.submission != null) {
      _submission = widget.submission;
      _contentController.text = _submission!.content;
    } else if (_group != null) {
      await _loadSubmissionFromCache(sim.id, _group!.id);
    }

    // Load resources
    await _loadResources(sim.id);

    // Set sim files
    _simFiles = sim.files;
  }

  Future<void> _loadGroupFromServer(String simulationId) async {
    try {
      final response = await _apiService.get('simulations/$simulationId/group');
      _group = Group.fromJson(response);
      await _dbService.cacheGroup(response);
    } catch (_) {
      // Try loading from cache
      final cachedGroups = await _dbService.query(
        'groups_table',
        where: 'simulation_id = ?',
        whereArgs: [simulationId],
      );
      if (cachedGroups.isNotEmpty) {
        // Find the user's group by checking members
        final userId = _currentUser?.id;
        if (userId != null) {
          final memberships = await _dbService.query(
            'group_members',
            where: 'user_id = ?',
            whereArgs: [userId],
          );
          if (memberships.isNotEmpty) {
            final groupId = memberships.first['group_id'];
            final groups = await _dbService.query(
              'groups_table',
              where: 'id = ?',
              whereArgs: [groupId],
            );
            if (groups.isNotEmpty) {
              _group = _buildGroupFromDb(groups.first, memberships);
            }
          }
        }
      }
    }
  }

  Future<void> _loadSubmissionFromCache(String simulationId, String groupId) async {
    final userId = _currentUser?.id;
    final cachedSubs = await _dbService.query(
      'submissions',
      where: 'simulation_id = ? AND group_id = ?',
      whereArgs: [simulationId, groupId],
    );
    if (cachedSubs.isNotEmpty) {
      _submission = _buildSubmissionFromDb(cachedSubs.first);
      _contentController.text = _submission!.content;
    }
  }

  Future<void> _loadResources(String simulationId) async {
    try {
      final response = await _apiService.getList('simulations/$simulationId/resources');
      _resources = response.map((e) => Resource.fromJson(e)).toList();
      for (var res in _resources) {
        await _dbService.cacheResource(res.toJson());
      }
    } catch (_) {
      final cached = await _dbService.getCachedResources();
      _resources = cached.map((e) {
        try {
          return Resource.fromJson(e);
        } catch (_) {
          return _buildResourceFromDb(e);
        }
      }).toList();
    }
  }

  // ── Build helpers ──

  Group _buildGroupFromDb(Map<String, dynamic> data, List<Map<String, dynamic>> memberships) {
    final members = memberships.map((m) {
      final isLeader = '${m['role']}' == 'leader';
      return Member(
        id: '${m['user_id']}',
        name: '${m['user_name'] ?? 'Membre'}',
        email: '',
        isLeader: isLeader,
      );
    }).toList();

    return Group(
      id: '${data['id']}',
      simulationId: '${data['simulation_id']}',
      name: '${data['name'] ?? 'Groupe'}',
      leaderId: members.any((m) => m.isLeader) ? members.firstWhere((m) => m.isLeader).id : '',
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

  // ── Online status ──

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      await _syncService.syncAll();
      setState(() => _isOnline = true);
    } catch (_) {
      setState(() => _isOnline = false);
    }
    await _loadData();
    setState(() => _isLoading = false);
  }

  // ── Leader management ──

  bool get _isCurrentUserLeader {
    if (_currentUser == null || _group == null) return false;
    return _group!.members.any(
      (m) => '${_currentUser!.id}' == m.id && m.isLeader,
    );
  }

  Future<void> _transferLeadership(String newLeaderId) async {
    if (_group == null) return;
    setState(() => _isTransferring = true);

    try {
      await _apiService.post(
        'groups/${_group!.id}/transfer-leader',
        {'new_leader_id': newLeaderId},
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chef de file transféré avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du transfert : $e')),
        );
      }
    } finally {
      setState(() => _isTransferring = false);
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (_group == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer un membre'),
        content: const Text('Êtes-vous sûr de vouloir retirer ce membre du groupe ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.post(
        'groups/${_group!.id}/remove-member',
        {'member_id': memberId},
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre retiré du groupe')),
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

  // ── Submission ──

  Future<void> _pickFile() async {
    // TODO: Replace with file_picker package in production
    // For now, show a dialog to demonstrate the feature
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Joindre un fichier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le chemin du fichier ou utilisez la sélection de fichier.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Chemin du fichier',
                border: OutlineInputBorder(),
                hintText: '/chemin/vers/fichier.pdf',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Sélectionner'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _attachedFilePath = result;
        _attachedFileName = result.split('/').last;
      });
    }
  }

  Future<void> _submitWork() async {
    if (_group == null) return;

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez rédiger votre rendu avant de soumettre')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{
        'simulation_id': widget.simulation.id,
        'group_id': _group!.id,
        'content': content,
        'status': 'submitted',
      };
      if (_attachedFilePath != null) {
        body['file_path'] = _attachedFilePath;
      }

      final response = await _apiService.post('submissions', body);
      await _dbService.cacheSubmission(response);

      // Parse and update local state
      _submission = Submission.fromJson(response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendu soumis avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Offline — save locally as pending
      try {
        final localSub = {
          'simulation_id': widget.simulation.id,
          'group_id': _group!.id,
          'user_id': _currentUser?.id,
          'content': content,
          'status': 'pending_sync',
          'file_path': _attachedFilePath,
          'submitted_at': DateTime.now().toIso8601String(),
          'is_pending_sync': 1,
        };
        await _dbService.cacheSubmission(localSub);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendu sauvegardé localement — sera synchronisé plus tard'),
            ),
          );
        }
      } catch (cacheError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── File download ──

  Future<void> _downloadFile(SimFile file) async {
    try {
      final localPath = await _fileService.downloadFile(file.id, file.originalName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier téléchargé : $localPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement : $e')),
        );
      }
    }
  }

  Future<void> _downloadAllFiles() async {
    for (var file in _simFiles) {
      await _downloadFile(file);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les fichiers ont été téléchargés')),
      );
    }
  }

  Future<void> _downloadResource(Resource res) async {
    try {
      final fileId = res.filePath.split('/').last;
      await _fileService.downloadFile(fileId, res.title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res.title} téléchargé')),
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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.simulation.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Code : ${widget.simulation.code}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          // Online/offline indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOnline ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Contexte'),
            Tab(icon: Icon(Icons.people_outline), text: 'Groupe'),
            Tab(icon: Icon(Icons.upload_file), text: 'Rendu'),
            Tab(icon: Icon(Icons.library_books), text: 'Ressources'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _refresh,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContextTab(theme),
                    _buildGroupTab(theme),
                    _buildSubmissionTab(theme),
                    _buildResourcesTab(theme),
                  ],
                ),
    );
  }

  // ── Tab 1 : Contexte ──

  Widget _buildContextTab(ThemeData theme) {
    final sim = widget.simulation;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
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

          // Documents
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documents', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (_simFiles.isNotEmpty)
                TextButton.icon(
                  onPressed: _downloadAllFiles,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Tout télécharger'),
                ),
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
                child: Center(child: Text('Aucun document fourni')),
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
                    trailing: IconButton(
                      icon: Icon(Icons.download, color: theme.colorScheme.primary),
                      onPressed: () => _downloadFile(file),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
        ],
      ),
    );
  }

  // ── Tab 2 : Mon groupe ──

  Widget _buildGroupTab(ThemeData theme) {
    if (_group == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Aucun groupe trouvé', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Rejoignez une simulation depuis l\'accueil',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final group = _group!;
    final isLeader = _isCurrentUserLeader;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Group header
          Card(
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(Icons.group, size: 28, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${group.members.length} membre${group.members.length > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  if (isLeader)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text('Chef', style: TextStyle(fontSize: 12, color: Colors.amber.shade800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Member list
          Text('Membres', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...group.members.map((member) => _buildMemberTile(theme, member, isLeader)),
          const SizedBox(height: 24),

          // Leader actions
          if (isLeader) ...[
            Text('Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTransferLeadershipCard(theme),
            const SizedBox(height: 8),
            _buildRemoveMemberCard(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberTile(ThemeData theme, Member member, bool isCurrentUserLeader) {
    final isLeader = member.isLeader;
    final isSelf = _currentUser != null && '${_currentUser!.id}' == member.id;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isLeader ? Colors.amber.shade300 : theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLeader ? Colors.amber.withOpacity(0.2) : theme.colorScheme.primaryContainer,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLeader ? Colors.amber.shade700 : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(member.name.isNotEmpty ? member.name : 'Membre #${member.id}'),
            if (isLeader) ...[
              const SizedBox(width: 6),
              const Text('👑', style: TextStyle(fontSize: 16)),
            ],
            if (isSelf) ...[
              const SizedBox(width: 6),
              Text('(vous)', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
        subtitle: member.email.isNotEmpty ? Text(member.email) : null,
        trailing: isCurrentUserLeader && !isLeader
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                onSelected: (value) {
                  if (value == 'transfer') {
                    _transferLeadership(member.id);
                  } else if (value == 'remove') {
                    _removeMember(member.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'transfer', child: Text('Transférer le chef')),
                  const PopupMenuItem(value: 'remove', child: Text('Retirer du groupe')),
                ],
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTransferLeadershipCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Transférer le chef', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            // Dropdown to select new leader
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Nouveau chef',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _group!.members
                  .where((m) => !m.isLeader)
                  .map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name.isNotEmpty ? m.name : 'Membre #${m.id}'),
                      ))
                  .toList(),
              onChanged: (val) => _selectedLeaderId = val,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _selectedLeaderId != null && !_isTransferring
                    ? () => _transferLeadership(_selectedLeaderId!)
                    : null,
                child: _isTransferring
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Transférer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveMemberCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.person_remove, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Retirer un membre', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    'Appuyez longuement sur un membre pour le retirer',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3 : Rendu ──

  Widget _buildSubmissionTab(ThemeData theme) {
    final isLeader = _isCurrentUserLeader;
    final submission = _submission;

    // Determine submission status
    String statusText;
    Color statusColor;
    if (submission == null) {
      statusText = 'Brouillon';
      statusColor = theme.colorScheme.secondary;
    } else if (submission.submittedAt != null) {
      // If we have submission data, it means it was submitted
      statusText = 'Soumis';
      statusColor = Colors.green;
    } else {
      statusText = 'En attente';
      statusColor = Colors.orange;
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  submission == null ? Icons.edit_note : Icons.check_circle,
                  color: statusColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'État : $statusText',
                        style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      if (submission != null)
                        Text(
                          'Soumis le ${DateFormat('dd/MM/yyyy à HH:mm').format(submission.submittedAt)}',
                          style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.8)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content editor
          Text('Votre rendu', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: null,
            minLines: 8,
            decoration: InputDecoration(
              hintText: 'Rédigez votre réponse ici...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(16),
              alignLabelWithHint: true,
            ),
            enabled: submission == null || submission.submittedAt == null,
          ),
          const SizedBox(height: 20),

          // File attachment
          Text('Fichiers joints', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (submission == null || submission.submittedAt == null) ? _pickFile : null,
            icon: const Icon(Icons.attach_file),
            label: const Text('Joindre un fichier (PDF, DOC)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_attachedFileName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_attachedFileName!, style: theme.textTheme.bodySmall)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _attachedFilePath = null;
                      _attachedFileName = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Submit button
          if (isLeader)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: (submission == null || submission.submittedAt == null) ? _submitWork : null,
                icon: Icon(submission == null ? Icons.send : Icons.cloud_upload),
                label: Text(submission == null ? 'Soumettre le rendu' : 'Mettre à jour'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seul le chef de file peut soumettre le rendu.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 4 : Ressources ──

  Widget _buildResourcesTab(ThemeData theme) {
    if (_resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Aucune ressource disponible', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ressources supplémentaires',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Documents partagés par votre professeur',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ..._resources.map((res) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: _fileTypeIcon(res.fileType, theme),
                  title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (res.description.isNotEmpty)
                        Text(res.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(
                        DateFormat('dd/MM/yyyy').format(res.uploadedAt),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.download, color: theme.colorScheme.primary),
                    onPressed: () => _downloadResource(res),
                  ),
                  isThreeLine: res.description.isNotEmpty,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
