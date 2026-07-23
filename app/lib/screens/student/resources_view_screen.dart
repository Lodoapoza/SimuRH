import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/file_service.dart';
import 'package:simurh/models/resource.dart';

class ResourcesViewScreen extends StatefulWidget {
  final List<Resource>? resources;

  const ResourcesViewScreen({super.key, this.resources});

  @override
  State<ResourcesViewScreen> createState() => _ResourcesViewScreenState();
}

class _ResourcesViewScreenState extends State<ResourcesViewScreen> {
  final ApiService _apiService = ApiService();
  final DbService _dbService = DbService();
  final FileService _fileService = FileService();

  bool _isLoading = true;
  bool _isOnline = true;
  String? _errorMessage;
  List<Resource> _resources = [];
  Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      if (widget.resources != null && widget.resources!.isNotEmpty) {
        _resources = widget.resources!;
      }

      // Try to fetch latest from API
      try {
        final response = await _apiService.getList('resources');
        final apiResources = response.map((e) => Resource.fromJson(e)).toList();

        // Cache them
        for (var res in apiResources) {
          await _dbService.cacheResource(res.toJson());
        }

        // Cache the resource file data for offline
        for (var res in apiResources) {
          await _dbService.insert('resources', {
            'id': res.id,
            'title': res.title,
            'description': res.description,
            'url': res.filePath,
            'file_type': res.fileType,
            'created_at': res.uploadedAt.toIso8601String(),
          });
        }

        setState(() {
          _resources = apiResources;
          _isOnline = true;
        });
      } catch (_) {
        setState(() => _isOnline = false);

        // Load from cache if we don't have data yet
        if (_resources.isEmpty) {
          final cached = await _dbService.getCachedResources();
          _resources = cached.map((e) {
            try {
              return Resource.fromJson(e);
            } catch (_) {
              return _buildResourceFromDb(e);
            }
          }).toList();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Resource _buildResourceFromDb(Map<String, dynamic> data) {
    return Resource(
      id: '${data['id']}',
      professorId: '',
      establishmentId: '',
      title: '${data['title'] ?? ''}',
      description: '${data['description'] ?? ''}',
      filePath: '${data['url'] ?? ''}',
      fileType: '${data['file_type'] ?? ''}',
      uploadedAt: DateTime.tryParse('${data['created_at'] ?? ''}') ?? DateTime.now(),
      professorName: '',
    );
  }

  Future<void> _onRefresh() async {
    await _initialize();
  }

  Future<void> _openResource(Resource res) async {
    // Check if the file is already cached
    final fileId = res.filePath.split('/').last;
    final cachedPath = await _fileService.getCachedFilePath(fileId);

    if (cachedPath != null) {
      // File is already cached — show info
      if (mounted) {
        _showFileInfo(res, cachedPath);
      }
      return;
    }

    // Need to download
    await _downloadResource(res);
  }

  Future<void> _downloadResource(Resource res) async {
    setState(() => _downloadingIds.add(res.id));

    try {
      final fileId = res.filePath.split('/').last;
      final localPath = await _fileService.downloadFile(fileId, res.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${res.title} téléchargé avec succès'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ouvrir',
              textColor: Colors.white,
              onPressed: () => _showFileInfo(res, localPath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Check if already cached (download might have failed but file exists)
        final fileId = res.filePath.split('/').last;
        final cachedPath = await _fileService.getCachedFilePath(fileId);
        if (cachedPath != null) {
          _showFileInfo(res, cachedPath);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(res.id));
      }
    }
  }

  void _showFileInfo(Resource res, String localPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(res.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fileTypeIcon(res.fileType, Theme.of(context), large: true),
            const SizedBox(height: 12),
            Text('Type : ${res.fileType.toUpperCase()}'),
            const SizedBox(height: 4),
            Text('Chemin local : $localPath'),
            if (res.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(res.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Open file — would use open_file package or similar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ouverture du fichier...')),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ressources'),
        actions: [
          if (!_isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'Hors ligne',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
        ],
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
                          onPressed: _onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _resources.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
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
                                      'Aucune ressource disponible',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Le professeur n\'a pas encore partagé de ressources.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _resources.length,
                          itemBuilder: (context, index) {
                            final res = _resources[index];
                            final isDownloading = _downloadingIds.contains(res.id);
                            return _buildResourceCard(theme, res, isDownloading);
                          },
                        ),
                ),
    );
  }

  Widget _buildResourceCard(ThemeData theme, Resource res, bool isDownloading) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isDownloading ? null : () => _openResource(res),
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
                        Icon(Icons.person, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          res.professorName.isNotEmpty ? res.professorName : 'Professeur',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(res.uploadedAt),
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Download button
              const SizedBox(width: 8),
              if (isDownloading)
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
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.download, color: theme.colorScheme.onPrimaryContainer, size: 20),
                    onPressed: () => _downloadResource(res),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileTypeIcon(String fileType, ThemeData theme, {bool large = false}) {
    IconData icon;
    Color color;
    final double size = large ? 48 : 40;

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
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(large ? 12 : 10),
      ),
      child: Icon(icon, color: color, size: large ? 28 : 22),
    );
  }
}
