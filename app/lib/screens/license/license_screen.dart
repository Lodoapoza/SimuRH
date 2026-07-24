import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/license_service.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _purchasing = false;
  String _phone = '';
  String? _transactionId;
  String? _paymentUrl;
  String? _message;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await LicenseService().checkStatus();
      if (mounted) setState(() { _status = status; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase() async {
    if (_phone.length < 8) {
      setState(() => _message = '❌ Entrez un numéro de téléphone valide');
      return;
    }

    setState(() { _purchasing = true; _message = null; _paymentUrl = null; });

    try {
      final result = await LicenseService.purchaseLicense(
        establishmentId: _status?['id'] ?? 0,
        phone: _phone,
      );

      if (!mounted) return;

      if (result['success'] == true && result['payment_url'] != null) {
        final url = result['payment_url'] as String;
        final txId = result['transaction_id'] as String;

        setState(() {
          _paymentUrl = url;
          _transactionId = txId;
          _message = '✅ Redirection vers CinetPay...';
        });

        // Ouvrir l'URL de paiement dans le navigateur
        await _openPaymentUrl(url);

        // Démarrer le polling du statut
        _startPolling(txId);
      } else {
        setState(() {
          _message = '❌ Erreur de paiement: réponse invalide';
          _purchasing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _message = '❌ Erreur: $e';
        _purchasing = false;
      });
    }
  }

  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      setState(() => _message = '❌ Impossible d\'ouvrir le lien de paiement');
      _purchasing = false;
    }
  }

  void _startPolling(String transactionId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final status = await LicenseService.checkPaymentStatus(transactionId);
        if (!mounted) { timer.cancel(); return; }

        final paymentStatus = status['payment_status'] as String?;
        final licenseStatus = status['license_status'] as String?;

        if (paymentStatus == 'completed' || licenseStatus == 'active') {
          timer.cancel();
          setState(() {
            _message = '✅ Paiement confirmé ! Licence active. Merci !';
            _purchasing = false;
          });
          await _load();
        } else if (paymentStatus == 'failed') {
          timer.cancel();
          setState(() {
            _message = '❌ Paiement échoué. Veuillez réessayer.';
            _purchasing = false;
          });
        } else {
          // Toujours en attente
          setState(() => _message = '⏳ En attente de confirmation du paiement...');
        }
      } catch (_) {
        // Ignorer les erreurs de polling
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licence SimuRH')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  if (_status?['license_status'] == 'trial') _buildTrialInfo(),
                  if (_status?['license_status'] == 'active') _buildActiveInfo(),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    _buildMessageBanner(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMessageBanner() {
    final isSuccess = _message!.startsWith('✅');
    final isWaiting = _message!.startsWith('⏳');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : isWaiting ? Colors.blue[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isWaiting)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          if (isWaiting) const SizedBox(width: 12),
          Expanded(child: Text(_message!, style: TextStyle(
            color: isSuccess ? Colors.green[800] : isWaiting ? Colors.blue[800] : Colors.red[800],
          ))),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _status?['license_status'] ?? 'trial';
    final color = status == 'active' ? Colors.green : (status == 'trial' ? Colors.orange : Colors.red);
    final label = status == 'active' ? 'ACTIVE' : (status == 'trial' ? 'ESSAI' : 'EXPIRÉE');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.verified, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color,
                  )),
                  if (status == 'active') ...[
                    Text('Expire le ${_status?['expiry_date'] ?? '…'}'),
                    Text('${_status?['days_left'] ?? 0} jours restants',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  if (status == 'trial')
                    const Text('Gratuit — limité à 1 simulation et 1 étudiant',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialInfo() {
    final limits = _status?['trial_limits'] as Map<String, dynamic>? ?? {};
    final maxSims = limits['max_simulations'] as int? ?? 1;
    final maxStudents = limits['max_students'] as int? ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Utilisation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _usageRow('Simulations', _status?['simulation_count'] ?? 0, maxSims),
                _usageRow('Étudiants', _status?['student_count'] ?? 0, maxStudents),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const Text('Passer à la licence complète',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('150 000 FCFA / an — Simulations et étudiants illimités',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Numéro téléphone (Orange Money / MTN)',
            hintText: 'Ex: 76123456',
            prefixText: '+223 ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (v) => _phone = v.trim(),
        ),
        const SizedBox(height: 20),
        if (_paymentUrl != null) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Rouvrir le paiement'),
            onPressed: () => _openPaymentUrl(_paymentUrl!),
          ),
          const SizedBox(height: 8),
          Text('Transaction : $_transactionId',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: _purchasing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payment),
            label: Text(_purchasing ? 'Préparation du paiement...' : 'Payer 150 000 FCFA'),
            onPressed: _purchasing ? null : _purchase,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _usageRow(String label, int current, int max) {
    final ratio = current / max.clamp(1, 999);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio > 1.0 ? 1.0 : ratio,
              backgroundColor: Colors.grey[200],
              color: ratio >= 1.0 ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Text('$current / $max', style: TextStyle(
            fontWeight: FontWeight.w500,
            color: ratio >= 1.0 ? Colors.red : null,
          )),
        ],
      ),
    );
  }

  Widget _buildActiveInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Étudiants : ${_status?['student_count'] ?? 0}'),
            Text('Simulations : ${_status?['simulation_count'] ?? 0}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _purchasing ? null : _purchase,
                child: const Text('Renouveler la licence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
