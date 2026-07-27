import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simurh/router/startup_gate.dart';
import 'package:simurh/screens/activation_screen.dart';
import 'package:simurh/screens/home_gate.dart';
import 'package:simurh/screens/professor/dashboard_screen.dart';
import 'package:simurh/screens/professor/create_simulation_screen.dart';
import 'package:simurh/screens/professor/connectivity_screen.dart';
import 'package:simurh/screens/professor/domain_selection_screen.dart';
import 'package:simurh/screens/professor/simulation_setup_screen.dart';
import 'package:simurh/screens/professor/template_course_screen.dart';
import 'package:simurh/screens/student/student_home_screen.dart';
import 'package:simurh/screens/student/connect_screen.dart';
import 'package:simurh/screens/student/simulation_game_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartupGate()),
    GoRoute(path: '/activation', builder: (context, state) => const ActivationScreen()),
    GoRoute(path: '/home-gate', builder: (context, state) => const HomeGate()),
    GoRoute(path: '/professor/dashboard', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/professor/create-simulation', builder: (context, state) => const CreateSimulationScreen()),
    GoRoute(path: '/professor/connectivity', builder: (context, state) => const ConnectivityScreen()),
    GoRoute(path: '/professor/domain-selection', builder: (context, state) => const DomainSelectionScreen()),
    GoRoute(path: '/professor/simulation-setup', builder: (context, state) => const SimulationSetupScreen()),
    GoRoute(path: '/professor/template-course', builder: (context, state) => const TemplateCourseScreen()),
    GoRoute(path: '/student/home', builder: (context, state) => const StudentHomeScreen()),
    GoRoute(path: '/student/connect', builder: (context, state) => const ConnectScreen()),
    GoRoute(path: '/student/simulation-game', builder: (context, state) => const SimulationGameScreen()),
  ],
);
