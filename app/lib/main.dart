import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simurh/router/app_router.dart';
import 'package:simurh/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.init();
  runApp(const ProviderScope(child: SimuRhApp()));
}

class SimuRhApp extends ConsumerWidget {
  const SimuRhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SimuRH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
