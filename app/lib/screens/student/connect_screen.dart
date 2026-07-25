import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  bool _connecting = false;
  String? _message;

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    if (ip.isEmpty) {
      setState(() => _message = 'Entrez une adresse IP');
      return;
    }

    setState(() { _connecting = true; _message = null; });

    try {
      final url = Uri.parse('http://$ip:$port/api/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Connecté !'),
                content: Text('Connecté au professeur sur $ip:$port'),
                actions: [
                  ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                    child: const Text('Terminé'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
      setState(() { _message = 'Réponse inattendue du serveur'; _connecting = false; });
    } catch (e) {
      setState(() { _message = 'Connexion impossible: $e'; _connecting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion au professeur')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cast, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Adresse IP du professeur',
                hintText: '192.168.1.42',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '8080',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_message!, textAlign: TextAlign.center,
                    style: TextStyle(color: _message!.contains('impossible') || _message!.contains('Entrez')
                        ? Colors.red : Colors.black)),
              ),
            ElevatedButton.icon(
              icon: _connecting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(_connecting ? 'Connexion...' : 'Se connecter'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: _connecting ? null : _connect,
            ),
            const SizedBox(height: 12),
            Text(
              'Assurez-vous d\'être sur le même réseau WiFi que le professeur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
