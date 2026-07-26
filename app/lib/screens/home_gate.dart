import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simurh/models/local_profile.dart';
import 'package:simurh/services/local_auth_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/group_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/screens/professor/dashboard_screen.dart';
import 'package:simurh/screens/student/student_home_screen.dart';

class HomeGate extends StatefulWidget {
  const HomeGate({super.key});
  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  final _auth = LocalAuthService();
  bool _loading = true;
  LocalProfile? _activeProfile;
  List<LocalProfile> _professors = [];
  LicenseInfo? _license;
  String _profName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _auth.getActiveProfile();
    final professors = await _auth.getAllProfessors();
    final license = await LicenseService.getLicense();
    final prefs = await SharedPreferences.getInstance();
    final profName = prefs.getString('prof_name') ?? '';
    if (mounted) setState(() {
      _activeProfile = profile;
      _professors = professors;
      _license = license;
      _profName = profName;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_activeProfile != null) {
      if (_activeProfile!.role == 'professor') {
        return const DashboardScreen();
      } else {
        return const StudentHomeScreen();
      }
    }
    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SimuRH'),
            if (_license != null && _license!.etablissement.isNotEmpty)
              Text(_license!.etablissement,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Bienvenue sur SimuRH',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Application de simulation RH pour les écoles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              if (_license != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_profName.isNotEmpty) ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Professeur'),
                          subtitle: Text(_profName),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('Établissement'),
                          subtitle: Text(_license!.etablissement),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          leading: Icon(Icons.event, color: _license!.isExpired ? Colors.red : Colors.green),
                          title: const Text('Licence'),
                          subtitle: Text(_license!.isExpired
                              ? 'Expirée depuis ${_license!.expiryYear}'
                              : 'Valide jusqu\'en ${_license!.expiryYear}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('Je suis professeur'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () => _createProfessor(context),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('Je suis étudiant'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () => _joinAsStudent(context),
                ),
              ),
              if (_professors.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const Text('Profils existants :'),
                const SizedBox(height: 8),
                ..._professors.map((p) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(p.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    await _auth.switchToProfile(p.id);
                    if (mounted) _load();
                  },
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createProfessor(BuildContext context) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer votre profil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Votre nom',
            hintText: 'Dr. Kouamé',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _auth.createProfessor(result);
      if (mounted) _load();
    }
  }

  Future<void> _joinAsStudent(BuildContext context) async {
    // Étape 1: sélectionner une simulation
    final db = DbService();
    final sims = await db.getCachedSimulations();
    if (sims.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune simulation disponible')),
        );
      }
      return;
    }

    final simId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choisissez une simulation'),
        children: sims.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, s['id'] as int),
          child: ListTile(
            title: Text(s['title'] as String? ?? 'Simulation'),
            subtitle: Text(s['description'] as String? ?? ''),
          ),
        )).toList(),
      ),
    );
    if (simId == null) return;

    // Étape 2: sélectionner un groupe
    final groupService = GroupService();
    final groups = await groupService.getGroups(simId);
    if (groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun groupe disponible dans cette simulation')),
        );
      }
      return;
    }

    final selectedGroup = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choisissez votre groupe'),
        children: groups.map((g) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, g),
          child: ListTile(
            title: Text(g.name),
            subtitle: Text('${g.members.length} membres'),
          ),
        )).toList(),
      ),
    );
    if (selectedGroup == null) return;

    // Étape 3: choisir son nom
    String? memberName;
    final members = selectedGroup.members;
    if (members.isEmpty) {
      // Groupe vide → entrer son nom
      final ctrl = TextEditingController();
      memberName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Entrez votre nom'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Votre prénom et nom'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Rejoindre')),
          ],
        ),
      );
      ctrl.dispose();
    } else {
      memberName = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Sélectionnez votre nom'),
          children: members.map((m) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, m.name),
            child: ListTile(title: Text(m.name)),
          )).toList(),
        ),
      );
    }
    if (memberName == null || memberName.isEmpty) return;

    // Ajouter l'étudiant au groupe si pas déjà membre
    if (members.every((m) => m.name != memberName)) {
      await groupService.addMember(selectedGroup.id, memberName);
    }

    // Créer le profil étudiant et basculer dessus
    final studentProfile = await _auth.createStudent(memberName, int.parse(selectedGroup.id));
    await _auth.switchToProfile(studentProfile.id);
    if (mounted) _load();
  }
}
