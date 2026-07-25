import 'package:flutter/material.dart';
import 'package:simurh/screens/activation_screen.dart';
import 'package:simurh/screens/home_gate.dart';
import 'package:simurh/screens/professor/dashboard_screen.dart';
import 'package:simurh/screens/professor/create_simulation_screen.dart';
import 'package:simurh/screens/student/student_home_screen.dart';
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
    if (!_activated!) {
      return const ActivationScreen();
    }
    return const HomeGate();
  }
}
