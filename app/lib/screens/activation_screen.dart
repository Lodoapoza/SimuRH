import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simurh/services/license_service.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _nameCtrl = TextEditingController();
  final _etabCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _attempts = 0;
  DateTime? _lockUntil;
  static const int _maxAttempts = 5;
  static const Duration _lockDuration = Duration(seconds: 30);

  bool get _isLocked => _lockUntil != null && DateTime.now().isBefore(_lockUntil!);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _etabCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final name = _nameCtrl.text.trim();
    final etab = _etabCtrl.text.trim();
    final key = _keyCtrl.text.trim().toUpperCase();

    if (name.isEmpty || etab.isEmpty || key.isEmpty) {
      setState(() => _error = 'Tous les champs sont requis');
      return;
    }

    if (_isLocked) {
      final remaining = _lockUntil!.difference(DateTime.now()).inSeconds + 1;
      setState(() => _error = 'Trop de tentatives. Réessayez dans $remaining s');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final valid = await LicenseService.validate(etab, key);
    if (!valid) {
      _attempts++;
      if (_attempts >= _maxAttempts) {
        _lockUntil = DateTime.now().add(_lockDuration);
        _attempts = 0;
        Future.delayed(_lockDuration, () {
          if (mounted) setState(() => _lockUntil = null);
        });
      }
      setState(() { _loading = false; _error = 'Clé invalide ou erronée'; });
      return;
    }

    final ok = await LicenseService.activate(etab, key);
    if (!ok) {
      setState(() { _loading = false; _error = 'Erreur lors de l\'activation'; });
      return;
    }

    // Sauvegarder aussi le nom du professeur
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prof_name', name);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _formatKey(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length && i < 12; i++) {
      if (buffer.length == 4 || buffer.length == 9) buffer.write('-');
      buffer.write(cleaned[i]);
    }
    _keyCtrl.value = TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'SimuRH',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Activation de la licence',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Votre nom',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _etabCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom de l\'établissement',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _keyCtrl,
                        onChanged: _formatKey,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(14),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Clé d\'activation',
                          hintText: 'XXXX-XXXX-XXXX',
                          prefixIcon: const Icon(Icons.vpn_key),
                          border: const OutlineInputBorder(),
                          suffixIcon: _keyCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.paste),
                                  onPressed: () async {
                                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                                    if (data?.text != null) _formatKey(data!.text!);
                                  },
                                )
                              : null,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                      if (!_isLocked && _attempts > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tentatives : ${_maxAttempts - _attempts} restante(s)',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                      if (_isLocked) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Verrouillé ${_lockUntil!.difference(DateTime.now()).inSeconds + 1}s',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: (_loading || _isLocked) ? null : _activate,
                          icon: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check),
                          label: Text(_loading ? 'Vérification...' : 'Activer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
