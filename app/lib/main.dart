import 'package:flutter/material.dart';
import 'package:simurh/screens/activation_screen.dart';
import 'package:simurh/screens/home_gate.dart';
import 'package:simurh/screens/professor/dashboard_screen.dart';
import 'package:simurh/screens/professor/create_simulation_screen.dart';
import 'package:simurh/screens/professor/connectivity_screen.dart';
import 'package:simurh/screens/student/student_home_screen.dart';
import 'package:simurh/screens/student/connect_screen.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.init();
  runApp(const SimuRhApp());
}

class SimuRhApp extends StatelessWidget {
  const SimuRhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimuRH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _StartupGate(),
      routes: {
        '/activation': (context) => const ActivationScreen(),
        '/home-gate': (context) => const HomeGate(),
        '/professor/dashboard': (context) => const DashboardScreen(),
        '/student/home': (context) => const StudentHomeScreen(),
        '/professor/create-simulation': (context) => const CreateSimulationScreen(),
        '/professor/connectivity': (context) => const ConnectivityScreen(),
        '/student/connect': (context) => const ConnectScreen(),
      },
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();
  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool? _activated;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await LicenseService.isValid();
    if (mounted) setState(() => _activated = ok);
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
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('Je suis professeur'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontSize: 18)),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/activation'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('Je suis étudiant'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontSize: 18)),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/student/connect'),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home-gate');
                },
                child: const Text('Déjà activé ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
