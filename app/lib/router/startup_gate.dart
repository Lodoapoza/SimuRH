import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simurh/providers/auth_provider.dart';
import 'package:simurh/screens/home_gate.dart';
import 'package:simurh/services/license_service.dart';

class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  bool? _activated;
  LicenseInfo? _license;
  String _profName = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await LicenseService.isValid();
    final license = await LicenseService.getLicense();
    final prefs = await SharedPreferences.getInstance();
    final profName = prefs.getString('prof_name') ?? '';
    if (mounted) setState(() {
      _activated = ok;
      _license = license;
      _profName = profName;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activated == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_activated!) {
      return const HomeGate();
    }
    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('SimuRH', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Application de simulation RH', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
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
                          dense: true, contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('Établissement'),
                          subtitle: Text(_license!.etablissement),
                          dense: true, contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          leading: Icon(Icons.event, color: _license!.isExpired ? Colors.red : Colors.green),
                          title: const Text('Licence'),
                          subtitle: Text(_license!.isExpired
                              ? 'Expirée depuis ${_license!.expiryYear}'
                              : 'Valide jusqu\'en ${_license!.expiryYear}'),
                          dense: true, contentPadding: EdgeInsets.zero,
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
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontSize: 18)),
                  onPressed: () => context.go('/activation'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('Je suis étudiant'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontSize: 18)),
                  onPressed: () => context.go('/student/connect'),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.go('/home-gate'),
                child: const Text('Déjà activé ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
