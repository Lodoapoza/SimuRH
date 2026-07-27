import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simurh/services/db_service.dart';

class Simulation {
  final int id;
  final String code;
  final String title;
  final String context;
  final String objectives;
  final String status;
  final String createdAt;

  Simulation({
    required this.id,
    required this.code,
    required this.title,
    required this.context,
    required this.objectives,
    required this.status,
    required this.createdAt,
  });

  factory Simulation.fromMap(Map<String, dynamic> map) {
    return Simulation(
      id: map['id'] as int,
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? '',
      context: map['context'] as String? ?? '',
      objectives: map['objectives'] as String? ?? '[]',
      status: map['status'] as String? ?? 'draft',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

class SimulationNotifier extends StateNotifier<List<Simulation>> {
  final DbService _db = DbService();

  SimulationNotifier() : super([]);

  Future<void> loadSimulations() async {
    final rows = await _db.query('simulations');
    rows.sort((a, b) => (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''));
    state = rows.map((r) => Simulation.fromMap(r)).toList();
  }

  Future<void> createSimulation(Map<String, dynamic> data) async {
    final id = await _db.insert('simulations', data);
    await loadSimulations();
  }

  Future<void> deleteSimulation(int id) async {
    await _db.delete('simulations', where: 'id = ?', whereArgs: [id]);
    await loadSimulations();
  }
}

final simulationProvider = StateNotifierProvider<SimulationNotifier, List<Simulation>>((ref) {
  return SimulationNotifier();
});
