import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/models/resource.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final DbService _db = DbService();

  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  List<Resource> _resources = [];
  Set<String> _downloadingIds = {};
  Set<String> _deletingIds = {};
  String _etablissement = '';

  @override
  void initState() {
    super.initState();
    _loadResources();
    _loadEtablissement();
  }

  Future<void> _loadEtablissement() async {
    _etablissement = (await LicenseService.getLicense())?.etablissement ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _db.query('resources');
      setState(() {
        _resources = response.map((e) => Resource.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement : $e';
        _isLoading = false;
      });
    }
  }

  // ── Upload ──

  Future<void> _showUploadDialog() async {
    final titleController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une ressource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Cours recrutement SEM1',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            // File picker button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final file = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                  );
                  if (file != null && file.files.isNotEmpty) {
                    // We handle file selection differently - close dialog with data
                    Navigator.of(ctx).pop({
                      'title': titleController.text.trim(),
                      'file_path': file.files.first.path ?? '',
                      'file_name': file.files.first.name,
                    });
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Sélectionner un fichier'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir un titre')),
                );
                return;
              }
              Navigator.of(ctx).pop({
                'title': title,
                'file_path': '',
                'file_name': '',
              });
            },
            child: const Text('Ajouter sans fichier'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final title = result['title'] ?? '';
    final filePath = result['file_path'] ?? '';

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est requis')),
      );
      return;
    }

    await _uploadResource(title, filePath, result['file_name'] ?? '');
  }

  Future<void> _uploadResource(String title, String filePath, String fileName) async {
    setState(() => _isUploading = true);

    try {
      String? localPath;
      if (filePath.isNotEmpty) {
        final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/resources');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final destFile = File('${dir.path}/$fileName');
        await File(filePath).copy(destFile.path);
        localPath = destFile.path;
      }

      await _db.insert('resources', {
        'title': title,
        'description': '',
        'url': localPath ?? '',
        'file_type': fileName.split('.').last,
      });

      await _loadResources();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ressource "${title}" ajoutée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // ── Download ──

  Future<void> _downloadResource(Resource res) async {
    setState(() => _downloadingIds.add(res.id));

    try {
      if (res.filePath.isNotEmpty) {
        final localFile = File(res.filePath);
        if (await localFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${res.title} disponible localement')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fichier introuvable')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aucun fichier associé')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(res.id));
      }
    }
  }

  // ── Delete ──

  Future<void> _confirmDelete(Resource res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la ressource'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${res.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _deleteResource(res);
  }

  Future<void> _deleteResource(Resource res) async {
    setState(() => _deletingIds.add(res.id));

    try {
      await _db.delete('resources', where: 'id = ?', whereArgs: [res.id]);
      setState(() {
        _resources.removeWhere((r) => r.id == res.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res.title} supprimé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(res.id));
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ressources pédagogiques'),
            if (_etablissement.isNotEmpty)
              Text(_etablissement,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showUploadDialog,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isUploading ? 'En cours...' : 'Ajouter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _loadResources,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _resources.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 80,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune ressource partagée',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyez sur + pour ajouter.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadResources,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _resources.length,
                        itemBuilder: (context, index) {
                          final res = _resources[index];
                          final isDownloading = _downloadingIds.contains(res.id);
                          final isDeleting = _deletingIds.contains(res.id);
                          return _buildResourceCard(theme, res, isDownloading, isDeleting);
                        },
                      ),
                    ),
    );
  }

  Widget _buildResourceCard(
      ThemeData theme, Resource res, bool isDownloading, bool isDeleting) {
    return Dismissible(
      key: ValueKey(res.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer'),
            content: Text('Supprimer "${res.title}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (_) => _deleteResource(res),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Opacity(
          opacity: isDeleting ? 0.5 : 1.0,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isDownloading ? null : () => _downloadResource(res),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File type icon
                  _fileTypeIcon(res.fileType, theme),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (res.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            res.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(res.uploadedAt),
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            if (res.fileType.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  res.fileType.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Download / Delete actions
                  const SizedBox(width: 8),
                  if (isDownloading || isDeleting)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.download,
                                color: theme.colorScheme.onPrimaryContainer, size: 20),
                            onPressed: () => _downloadResource(res),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: theme.colorScheme.onErrorContainer, size: 20),
                            onPressed: () => _confirmDelete(res),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fileTypeIcon(String fileType, ThemeData theme) {
    IconData icon;
    Color color;
    switch (fileType.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        icon = Icons.table_chart;
        color = Colors.green.shade700;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'mp4':
      case 'avi':
      case 'mov':
        icon = Icons.videocam;
        color = Colors.purple;
        break;
      case 'mp3':
      case 'wav':
      case 'aac':
        icon = Icons.audiotrack;
        color = Colors.teal;
        break;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
        icon = Icons.folder_zip;
        color = Colors.brown;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
