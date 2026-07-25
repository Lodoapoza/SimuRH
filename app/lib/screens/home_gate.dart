import 'package:flutter/material.dart';
import 'package:simurh/models/local_profile.dart';
import 'package:simurh/services/local_auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _auth.getActiveProfile();
    final professors = await _auth.getAllProfessors();
    if (mounted) setState(() {
      _activeProfile = profile;
      _professors = professors;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Si un profil actif existe, aller directement à la vue correspondante
    if (_activeProfile != null) {
      if (_activeProfile!.role == 'professor') {
        return const DashboardScreen();
      } else {
        return const StudentHomeScreen();
      }
    }
    // Sinon, écran de bienvenue
    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('SimuRH')),
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
              if (_professors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Reprendre un profil existant :'),
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
}
