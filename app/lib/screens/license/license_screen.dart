import 'package:flutter/material.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/license_service.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _service = LicenseService();
  final _api = ApiService();
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _purchasing = false;
  String _paymentMethod = 'orange_money';
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await _service.checkStatus();
      if (mounted) setState(() { _status = status; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase() async {
    setState(() { _purchasing = true; _message = null; });
    try {
      final result = await _service.purchaseLicense(_paymentMethod);
      if (mounted) {
        setState(() {
          _message = '✅ Licence activée avec succès !';
          _purchasing = false;
        });
        _load();
      }
    } catch (e) {
      if (mounted) setState(() {
        _message = '❌ Erreur de paiement: $e';
        _purchasing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licence SimuRH')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  if (_status?['status'] == 'trial') _buildTrialInfo(),
                  if (_status?['status'] == 'active') _buildActiveInfo(),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _message!.startsWith('✅') ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_message!, style: TextStyle(
                        color: _message!.startsWith('✅') ? Colors.green[800] : Colors.red[800],
                      )),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final status = _status?['status'] ?? 'trial';
    final color = status == 'active' ? Colors.green : (status == 'trial' ? Colors.orange : Colors.red);
    final label = status == 'active' ? 'ACTIVE' : (status == 'trial' ? 'ESSAI' : 'EXPIRÉE');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.verified, size: 48, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color,
                )),
                if (status == 'active')
                  Text('Expire le ${_status?['expires_at'] ?? '…'} · ${_status?['days_left'] ?? 0} jours restants'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode Essai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Étudiants : ${_status?['student_count'] ?? 0} / ${_status?['trial_limits']?['max_students'] ?? 1}'),
                Text('Simulations : ${_status?['simulation_count'] ?? 0} / ${_status?['trial_limits']?['max_simulations'] ?? 1}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Passer à la licence complète', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('150 000 FCFA / an — Illimité'),
        const SizedBox(height: 16),
        const Text('Moyen de paiement :'),
        ...['orange_money', 'mtn_money', 'card'].map((m) => RadioListTile<String>(
          title: Text(_methodLabel(m)),
          value: m,
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        )),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: _purchasing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payment),
            label: Text(_purchasing ? 'Traitement...' : 'Payer 150 000 FCFA'),
            onPressed: _purchasing ? null : _purchase,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Étudiants inscrits : ${_status?['student_count'] ?? 0}'),
            Text('Simulations créées : ${_status?['simulation_count'] ?? 0}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _purchase,
                child: const Text('Renouveler la licence'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'orange_money': return 'Orange Money';
      case 'mtn_money': return 'MTN Mobile Money';
      case 'card': return 'Carte bancaire';
      default: return m;
    }
  }
}
