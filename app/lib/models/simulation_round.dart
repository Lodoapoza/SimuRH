class SimulationRound {
  final int id;
  final int simulationId;
  final int period;
  final Map<String, double> decisions;
  final Map<String, double> metrics;
  final String status; // pending, active, completed
  final DateTime createdAt;

  SimulationRound({
    required this.id,
    required this.simulationId,
    required this.period,
    required this.decisions,
    required this.metrics,
    required this.status,
    required this.createdAt,
  });

  factory SimulationRound.fromMap(Map<String, dynamic> map) {
    return SimulationRound(
      id: map['id'] as int,
      simulationId: map['simulation_id'] as int,
      period: map['period'] as int,
      decisions: _parseMap(map['decisions']),
      metrics: _parseMap(map['metrics']),
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'simulation_id': simulationId,
    'period': period,
    'decisions': decisions.toString(),
    'metrics': metrics.toString(),
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  static Map<String, double> _parseMap(dynamic v) {
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    return {};
  }
}
