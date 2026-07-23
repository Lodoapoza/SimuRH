import 'package:flutter/material.dart';
import 'package:simurh/screens/auth/login_screen.dart';
import 'package:simurh/screens/professor/dashboard_screen.dart';
import 'package:simurh/screens/professor/create_simulation_screen.dart';
import 'package:simurh/screens/student/student_home_screen.dart';
import 'package:simurh/services/auth_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LicenseService.init();
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
      home: const LoginScreen(),
      routes: {
        '/professor/dashboard': (context) => const DashboardScreen(),
        '/student/home': (context) => const StudentHomeScreen(),
        '/professor/create-simulation': (context) => const CreateSimulationScreen(),
      },
    );
  }
}
