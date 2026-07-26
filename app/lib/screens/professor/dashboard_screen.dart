import 'dart:async';
import 'package:flutter/material.dart' hide Simulation;
import 'package:url_launcher/url_launcher.dart';
import 'package:simurh/services/local_auth_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/services/group_service.dart';
import 'package:simurh/services/local_server_service.dart';
import 'package:simurh/services/update_service.dart';
import 'package:simurh/screens/professor/create_simulation_screen.dart';
import 'package:simurh/screens/professor/simulation_detail_screen.dart';
import 'package:simurh/screens/professor/resources_screen.dart';
import 'package:simurh/screens/professor/group_management_screen.dart';
import 'package:simurh/screens/professor/connectivity_screen.dart';
import 'package:simurh/models/simulation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalAuthService _auth = LocalAuthService();
  final DbService _db = DbService();
  final LocalServerService _server = LocalServerService();

  String _userName = '';
  String _etablissement = '';
  LicenseInfo? _license;
  bool _isLoading = true;
  bool _isOnline = true;
  int _simulationCount = 0;
  List<Simulation> _recentSimulations = [];
  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      if (!mounted) return;
      final profile = await _auth.getActiveProfile();
      final sims = await _db.getCachedSimulations();
      if (mounted) setState(() {
        _userName = profile?.name ?? 'Professeur';
        _simulationCount = sims.length;
        _recentSimulations = sims.take(5).map((j) => Simulation.fromJson(j)).toList();
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _auth.getActiveProfile();
      _userName = profile?.name ?? 'Professeur';

      final license = await LicenseService.getLicense();
      _license = license;
      _etablissement = license?.etablissement ?? '';

      final sims = await _db.getCachedSimulations();
      _simulationCount = sims.length;
      _recentSimulations = sims.take(5).map((j) => Simulation.fromJson(j)).toList();

      _isOnline = true;
    } catch (_) {
      _isOnline = true;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _switchProfile() async {
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home-gate', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SimuRH', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
            Text(
              [_etablissement, _userName, if (_license != null) 'Exp. ${_license!.expiryYear}']
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: TextStyle(fontSize: 12, color: colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          if (_server.isRunning)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _LiveIndicator(interval: _refreshInterval),
            ),
          _buildUpdateButton(),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Changer de profil',
            onPressed: () => Navigator.pushReplacementNamed(context, '/home-gate'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Changer de profil',
            onPressed: _switchProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(theme, colorScheme),
                  const SizedBox(height: 20),
                  _buildStatsRow(theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Fonctionnalités', theme),
                  const SizedBox(height: 12),
                  _buildNavigationGrid(theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Simulations récentes', theme),
                  const SizedBox(height: 12),
                  _buildRecentSimulations(theme, colorScheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildUpdateButton() {
    return IconButton(
      icon: const Icon(Icons.system_update_outlined),
      tooltip: 'Vérifier les mises à jour',
      onPressed: () async {
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(const SnackBar(content: Text('Vérification...')));
        final update = await UpdateService().checkForUpdate();
        if (!mounted) return;
        if (update == null) {
          scaffold.showSnackBar(const SnackBar(
            content: Text('Aucune mise à jour disponible'),
            backgroundColor: Colors.green,
          ));
          return;
        }
        final currentBuild = await UpdateService().getCurrentBuildNumber();
        if (!mounted) return;
        if (update.buildNumber <= currentBuild) {
          scaffold.showSnackBar(const SnackBar(
            content: Text('Vous avez la dernière version'),
            backgroundColor: Colors.green,
          ));
          return;
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mise à jour disponible'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Build #${update.buildNumber} disponible'),
                const SizedBox(height: 8),
                Text(update.releaseNotes, style: const TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Plus tard'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Télécharger'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Open GitHub release page in browser
                  final url = Uri.parse(update.downloadUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    scaffold.showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le lien')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.school,
                size: 28,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLicenseBadge(theme, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseBadge(ThemeData theme, ColorScheme colorScheme) {
    final license = _license;
    final expired = license != null && license.isExpired;
    final label = expired ? 'Licence expirée' : 'Licence active';
    final icn = expired ? Icons.warning : Icons.verified;
    final clr = expired ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: clr.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icn, size: 14, color: clr[700]),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(
            color: clr[700], fontWeight: FontWeight.w500,
          )),
          if (license != null) ...[
            const SizedBox(width: 4),
            Text('· ${license.expiryYear}', style: theme.textTheme.labelSmall?.copyWith(
              color: clr[700],
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Simulations', '$_simulationCount', Icons.assignment, colorScheme.primary, colorScheme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Groupes', '...', Icons.people, colorScheme.tertiary, colorScheme)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Statut',
            'Local',
            Icons.phone_android,
            Colors.green,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNavigationGrid(ThemeData theme, ColorScheme colorScheme) {
    final items = [
      _NavItem('Créer une simulation', Icons.add_circle_outline, colorScheme.primary, () {
        Navigator.pushNamed(context, '/professor/domain-selection');
      }),
      _NavItem('Mes simulations', Icons.assignment, colorScheme.tertiary, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SimulationListScreen(),
          ),
        );
      }),
      _NavItem('Ressources', Icons.folder_outlined, Colors.orange.shade700, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResourcesScreen()),
        );
      }),
      _NavItem('Évaluations', Icons.grading, Colors.teal, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SimulationListScreen(),
          ),
        );
      }),
      _NavItem('Groupes', Icons.people_outline, Colors.indigo, () async {
        final db = DbService();
        final sims = await db.getCachedSimulations();
        if (!mounted) return;
        if (sims.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune simulation. Créez-en une d\'abord.')),
          );
          return;
        }
        final simId = await showDialog<int>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Choisir une simulation'),
            children: [
              for (final s in sims)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s['id'] as int),
                  child: ListTile(
                    title: Text(s['title'] as String? ?? 'Sans titre'),
                    subtitle: Text(s['code'] as String? ?? ''),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        );
        if (simId == null || !mounted) return;
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => GroupManagementScreen(simulationId: simId)));
      }),
      _NavItem('Connectivité', Icons.cast, Colors.blue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectivityScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: item.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSimulations(ThemeData theme, ColorScheme colorScheme) {
    if (_recentSimulations.isEmpty && _isOnline) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(
                  'Aucune simulation pour le moment',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créez votre première simulation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isOnline && _recentSimulations.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Mode hors ligne — connectez-vous pour voir vos simulations'),
          ),
        ),
      );
    }

    return Column(
      children: _recentSimulations.map((sim) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.assignment, color: colorScheme.onPrimaryContainer),
            ),
            title: Text(sim.title, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('${sim.status} — ${sim.groupCount ?? 0} groupes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SimulationDetailScreen(simulationId: sim.id),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _NavItem(this.label, this.icon, this.color, this.onTap);
}

class _LiveIndicator extends StatelessWidget {
  final Duration interval;
  const _LiveIndicator({required this.interval});

  @override
  Widget build(BuildContext context) {
    return _LiveIndicatorWidget(interval: interval);
  }
}

class _LiveIndicatorWidget extends StatefulWidget {
  final Duration interval;
  const _LiveIndicatorWidget({required this.interval});
  @override
  State<_LiveIndicatorWidget> createState() => _LiveIndicatorWidgetState();
}

class _LiveIndicatorWidgetState extends State<_LiveIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Écran simple de liste des simulations (utilisé par le dashboard)
class SimulationListScreen extends StatefulWidget {
  const SimulationListScreen({super.key});

  @override
  State<SimulationListScreen> createState() => _SimulationListScreenState();
}

class _SimulationListScreenState extends State<SimulationListScreen> {
  final DbService _db = DbService();
  String _etablissement = '';
  List<Simulation> _simulations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSimulations();
  }

  Future<void> _loadSimulations() async {
    setState(() => _isLoading = true);
    try {
      final license = await LicenseService.getLicense();
      _license = license;
      _etablissement = license?.etablissement ?? '';
      final data = await _db.getCachedSimulations();
      if (mounted) {
        setState(() {
          _simulations = data.map((j) => Simulation.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes simulations'),
            if (_etablissement.isNotEmpty)
              Text(_etablissement,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _simulations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('Aucune simulation', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSimulations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _simulations.length,
                    itemBuilder: (context, index) {
                      final sim = _simulations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(sim.title),
                          subtitle: Text(sim.status ?? ''),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SimulationDetailScreen(simulationId: sim.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/professor/create-simulation');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
