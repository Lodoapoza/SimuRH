import 'package:flutter/material.dart';
import 'package:simurh/services/local_server_service.dart';
import 'package:simurh/services/local_server_routes.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});
  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final _server = LocalServerService();
  bool _loading = true;
  String? _ip;
  bool _running = false;
  int _port = 8080;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _running = _server.isRunning;
    _ip = await _server.getLocalIp();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleServer() async {
    if (_running) {
      await _server.stop();
    } else {
      final routes = LocalServerRoutes();
      _server.setRouter(routes.router);
      final ok = await _server.start(port: _port);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de démarrer le serveur'),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) {
      setState(() {
        _running = _server.isRunning;
        _ip = _server.isRunning ? _ip : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Connectivité')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _running ? Icons.wifi : Icons.wifi_off,
              size: 64,
              color: _running ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _running ? 'Serveur actif' : 'Serveur arrêté',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (_running && _ip != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Adresse de connexion',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(
                        'http://$_ip:$_port',
                        style: const TextStyle(fontSize: 20, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Text('Token: ${_server.token.substring(0, 8)}...',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir IP'),
                onPressed: () async {
                  final ip = await _server.getLocalIp();
                  setState(() => _ip = ip);
                },
              ),
            ],
            const Spacer(),
            ElevatedButton.icon(
              icon: Icon(_running ? Icons.stop : Icons.play_arrow),
              label: Text(_running ? 'Arrêter le serveur' : 'Démarrer le serveur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _running ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _toggleServer,
            ),
          ],
        ),
      ),
    );
  }
}
