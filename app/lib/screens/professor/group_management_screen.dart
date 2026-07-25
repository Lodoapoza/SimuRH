import 'package:flutter/material.dart';
import 'package:simurh/models/group_model.dart';
import 'package:simurh/services/group_service.dart';

class GroupManagementScreen extends StatefulWidget {
  final int simulationId;
  const GroupManagementScreen({super.key, required this.simulationId});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final _service = GroupService();
  List<Group> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await _service.getGroups(widget.simulationId);
    if (mounted) setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groupes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroup,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('Aucun groupe. Créez-en un !'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (ctx, i) {
                      final g = _groups[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(g.name),
                          subtitle: Text('${g.members.length} étudiant(s)'),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _editGroup(g),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau groupe'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nom du groupe'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final members = await _editMembers([], title: 'Membres du groupe $name');
    if (members == null) return;

    await _service.createGroup(name, widget.simulationId);
    final created = await _service.getGroups(widget.simulationId);
    final newGroup = created.firstWhere((g) => g.name == name);
    final gid = int.parse(newGroup.id);
    for (final m in members) {
      await _service.addMember(gid, m);
    }
    await _load();
  }

  Future<List<String>?> _editMembers(List<String> current,
      {String title = 'Membres'}) async {
    final members = List<String>.from(current);
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration:
                            const InputDecoration(labelText: "Nom de l'étudiant"),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        final n = ctrl.text.trim();
                        if (n.isNotEmpty) {
                          setDState(() {
                            members.add(n);
                          });
                          ctrl.clear();
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                if (members.isEmpty)
                  const Text("Aucun étudiant. Ajoutez-en un."),
                ...members.map((m) => ListTile(
                      title: Text(m),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setDState(() => members.remove(m)),
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Valider (${members.length})'),
            ),
          ],
        ),
      ),
    );
    if (result == true) return members;
    return null;
  }

  Future<void> _editGroup(Group group) async {
    final gid = int.parse(group.id);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(group.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'rename'),
            child: const ListTile(
                leading: Icon(Icons.edit), title: Text('Renommer')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'members'),
            child: const ListTile(
                leading: Icon(Icons.people), title: Text('Gérer les membres')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer')),
          ),
        ],
      ),
    );
    if (action == null) return;

    if (action == 'rename') {
      final ctrl = TextEditingController(text: group.name);
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Renommer'),
          content: TextField(controller: ctrl, autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('OK')),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        await _service.updateGroupName(gid, name);
        await _load();
      }
    } else if (action == 'members') {
      final currentNames = group.members.map((m) => m.name).toList();
      final newMembers =
          await _editMembers(currentNames, title: 'Membres de ${group.name}');
      if (newMembers != null) {
        for (final m in group.members) {
          if (!newMembers.contains(m.name)) {
            await _service.removeMember(int.parse(m.id));
          }
        }
        for (final name in newMembers) {
          if (!currentNames.contains(name)) {
            await _service.addMember(gid, name);
          }
        }
        await _load();
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer'),
          content: Text('Supprimer le groupe "${group.name}" ?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _service.deleteGroup(gid);
        await _load();
      }
    }
  }
}
