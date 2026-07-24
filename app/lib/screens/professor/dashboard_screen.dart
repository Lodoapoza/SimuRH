import 'package:flutter/material.dart' hide Simulation;
import 'package:simurh/services/auth_service.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/screens/professor/create_simulation_screen.dart';
import 'package:simurh/screens/professor/simulation_detail_screen.dart';
import 'package:simurh/screens/professor/resources_screen.dart';

import 'package:simurh/screens/license/license_screen.dart';
import 'package:simurh/models/simulation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = true;
  bool _isOnline = true;
  int _simulationCount = 0;
  int _studentCount = 0;
  List<Simulation> _recentSimulations = [];
  Map<String, dynamic>? _licenseStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _user = await _authService.getCurrentUser();
    } catch (_) {}

    // Charger les stats depuis l'API (avec fallback offline)
    try {
      final statusData = await LicenseService().checkStatus();
      _licenseStatus = statusData;
      _studentCount = statusData['student_count'] as int? ?? 0;

      // Charger les simulations
      final simsData = await _apiService.getList('/simulations');
      _simulationCount = simsData.length;
      _recentSimulations = simsData
          .map((j) => Simulation.fromJson(j))
          .take(5)
          .toList();

      _isOnline = true;
    } catch (_) {
      _isOnline = false;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _user?.establishmentName ?? 'SimuRH',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          // Statut en ligne/hors ligne
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline
                  ? colorScheme.onPrimary.withOpacity(0.8)
                  : Colors.orange[300],
              size: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
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
                    _user?.name ?? 'Professeur',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _user?.establishmentName ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
    final isTrial = LicenseService.isTrialMode();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTrial
            ? Colors.orange.withOpacity(0.15)
            : Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTrial ? Icons.info_outline : Icons.verified,
            size: 14,
            color: isTrial ? Colors.orange[800] : Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            isTrial ? 'Mode essai' : 'Licence active',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isTrial ? Colors.orange[800] : Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Simulations', '$_simulationCount', Icons.assignment, colorScheme.primary, colorScheme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Étudiants', '$_studentCount', Icons.people, colorScheme.tertiary, colorScheme)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Statut',
            _isOnline ? 'En ligne' : 'Hors ligne',
            _isOnline ? Icons.wifi : Icons.wifi_off,
            _isOnline ? Colors.green : Colors.orange.shade700,
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
        Navigator.pushNamed(context, '/professor/create-simulation');
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
      _NavItem('Étudiants', Icons.people_outline, Colors.indigo, () {
        // Navigation vers la gestion des groupes
      }),
      _NavItem('Licence', Icons.credit_card_outlined, Colors.purple, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LicenseScreen()),
        );
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

// Écran simple de liste des simulations (utilisé par le dashboard)
class SimulationListScreen extends StatefulWidget {
  const SimulationListScreen({super.key});

  @override
  State<SimulationListScreen> createState() => _SimulationListScreenState();
}

class _SimulationListScreenState extends State<SimulationListScreen> {
  final ApiService _apiService = ApiService();
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
      final data = await _apiService.getList('/simulations');
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
      appBar: AppBar(title: const Text('Mes simulations')),
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
