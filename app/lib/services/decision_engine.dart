import 'dart:math';
import 'dart:convert';
import 'package:simurh/services/db_service.dart';

class DecisionEngine {
  static final DecisionEngine _instance = DecisionEngine._internal();
  factory DecisionEngine() => _instance;
  DecisionEngine._internal();
  final DbService _db = DbService();
  final Random _rand = Random();

  /// Calcule les métriques du round suivant à partir des décisions du round actuel.
  Future<Map<String, double>> computeMetrics({
    required int simulationId,
    required int period,
    required Map<String, double> decisions,
    Map<String, double>? previousMetrics,
  }) async {
    final sim = await _getSimulation(simulationId);
    final templateParams = sim['decision_params'] as String? ?? '[]';
    final params = jsonDecode(templateParams) as List;

    final metrics = <String, double>{};

    for (final p in params) {
      final id = p['id'] as String;
      final value = decisions[id] ?? (p['value'] as num).toDouble();

      switch (id) {
        case 'budget':
          metrics['cout_total'] = value;
          metrics['efficacite'] = _clamp(_linear(value, 500000, 5000000, 30, 80) + _noise(5), 0, 100);
          break;
        case 'budget_formation':
          metrics['taux_formation'] = _clamp(value / 100000, 0, 100);
          metrics['satisfaction'] = _clamp(_linear(value, 0, 2000000, 40, 85) + _noise(3), 0, 100);
          break;
        case 'effectifs_cibles':
          metrics['taux_adequation'] = _clamp(_linear(value, 50, 250, 100, 60) * _noiseFactor(0.05), 0, 100);
          break;
        case 'duree_pub':
          metrics['time_to_hire'] = value + _noise(3);
          break;
        case 'nb_candidats':
          metrics['qualite_candidat'] = _clamp(_linear(value, 3, 10, 40, 85), 0, 100);
          metrics['cost_per_hire'] = (decisions['budget'] ?? 2000000) / _max(1, value);
          break;
        case 'recrutement_externe':
          final ratio = value / 100;
          metrics['taux_mobilite'] = _clamp(100 - value + _noise(5), 0, 100);
          metrics['cout_recrutement'] = _clamp(ratio * 3000000, 0, 5000000);
          break;
        case 'mobilite_interne':
          metrics['taux_mobilite'] = _clamp(value + _noise(5), 0, 100);
          metrics['cout_formation'] = _clamp((100 - value) * 50000 + _noise(10000), 0, 5000000);
          break;
        case 'budget_remuneration':
          metrics['attractivite'] = _clamp(_linear(value, 5000000, 50000000, 40, 95) + _noise(3), 0, 100);
          metrics['masse_salariale'] = value;
          break;
        case 'nb_recrutements':
          metrics['taux_activite'] = _clamp(_linear(value, 1, 20, 60, 95) + _noise(3), 0, 100);
          metrics['cout_total'] = value * 2000000;
          break;
        default:
          if (id.contains('salaire') || id.contains('remuneration')) {
            metrics['attractivite'] = _clamp(_linear(value, 100000, 500000, 30, 90) + _noise(3), 0, 100);
            metrics['motivation'] = _clamp(_linear(value, 100000, 500000, 40, 85) + _noise(3), 0, 100);
          } else if (id.contains('formation') || id.contains('budget_form')) {
            metrics['taux_formation'] = _clamp(value / 10000, 0, 100);
            metrics['competences'] = _clamp(_linear(value, 0, 1000000, 30, 90) + _noise(3), 0, 100);
          } else {
            metrics[id] = value;
          }
      }
    }

    if (previousMetrics != null && previousMetrics.isNotEmpty) {
      for (final key in previousMetrics.keys) {
        if (!metrics.containsKey(key)) {
          metrics[key] = previousMetrics[key]!;
        }
      }
    }

    metrics['turnover'] = _clamp(30 - (decisions['satisfaction'] ?? 60) / 3 + _noise(5), 0, 100);
    metrics['productivite'] = _clamp(50 + (decisions['budget'] ?? 2000000) / 200000 + _noise(5), 0, 100);

    return metrics;
  }

  Future<void> saveRound({
    required int simulationId,
    required int period,
    required Map<String, double> decisions,
    required Map<String, double> metrics,
    required int groupId,
  }) async {
    await _db.insert('simulation_rounds', {
      'simulation_id': simulationId,
      'group_id': groupId,
      'period': period,
      'decisions': jsonEncode(decisions),
      'metrics': jsonEncode(metrics),
      'status': 'completed',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  double _clamp(double v, double min, double max) => v.clamp(min, max);
  double _max(double a, double b) => a > b ? a : b;
  double _noise(double max) => (_rand.nextDouble() - 0.5) * 2 * max;
  double _noiseFactor(double pct) => 1 + (_rand.nextDouble() - 0.5) * 2 * pct;
  double _linear(double x, double x1, double x2, double y1, double y2) {
    if (x <= x1) return y1;
    if (x >= x2) return y2;
    return y1 + (x - x1) / (x2 - x1) * (y2 - y1);
  }

  Future<Map<String, dynamic>> _getSimulation(int id) async {
    final results = await _db.query('simulations', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : {};
  }
}
