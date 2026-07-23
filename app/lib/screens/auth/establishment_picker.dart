import 'package:flutter/material.dart';
import 'package:simurh/services/api_service.dart';

class EstablishmentPicker extends StatefulWidget {
  const EstablishmentPicker({super.key});

  @override
  State<EstablishmentPicker> createState() => _EstablishmentPickerState();
}

class _EstablishmentPickerState extends State<EstablishmentPicker> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  List<Map<String, dynamic>> _establishments = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.getList('establishments');
      if (mounted) setState(() {
        _establishments = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      _filtered = _establishments.where((e) =>
        e['name'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  Future<void> _addEstablishment() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      final result = await _api.post('establishments', {
        'name': _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      });
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un établissement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filter,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Aucun établissement trouvé'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter mon établissement'),
                                onPressed: () => setState(() => _showAddForm = true),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final e = _filtered[i];
                            return ListTile(
                              leading: const Icon(Icons.business),
                              title: Text(e['name'] ?? ''),
                              subtitle: Text(e['city'] ?? ''),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(context, e),
                            );
                          },
                        ),
                ),
                if (_showAddForm)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom de l\'établissement',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ville',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _addEstablishment,
                          child: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
