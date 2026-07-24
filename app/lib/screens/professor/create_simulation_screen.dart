import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:simurh/services/api_service.dart';
import 'package:simurh/services/license_service.dart';
import 'package:simurh/models/simulation.dart';

class CreateSimulationScreen extends StatefulWidget {
  final Simulation? existingSimulation;

  const CreateSimulationScreen({super.key, this.existingSimulation});

  @override
  State<CreateSimulationScreen> createState() => _CreateSimulationScreenState();
}

class _CreateSimulationScreenState extends State<CreateSimulationScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSavingDraft = false;
  bool _isLaunching = false;
  String? _errorMessage;
  bool _isEditMode = false;
  String? _createdCode;

  // Form fields
  final _titleController = TextEditingController();
  final _contextController = TextEditingController();
  final List<TextEditingController> _objectiveControllers = [];
  int _durationDays = 7;
  int _maxGroups = 5;

  // Grading criteria
  final List<_CriterionEntry> _criteria = [];

  // Files
  final List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  void _initForm() {
    final existing = widget.existingSimulation;
    if (existing != null) {
      _isEditMode = true;
      _titleController.text = existing.title;
      _contextController.text = existing.context;
      for (final obj in existing.objectives) {
        final ctrl = TextEditingController(text: obj);
        _objectiveControllers.add(ctrl);
      }
      _durationDays = existing.durationDays;
      _maxGroups = existing.maxGroups;
      for (final crit in existing.gradingCriteria) {
        _criteria.add(_CriterionEntry(
          nameController: TextEditingController(text: crit.name),
          maxScore: crit.maxScore,
          coefficient: crit.coefficient,
        ));
      }
    } else {
      // Default criteria
      _criteria.addAll([
        _CriterionEntry(
          nameController: TextEditingController(text: 'Pertinence analyse'),
          maxScore: 10,
          coefficient: 2,
        ),
        _CriterionEntry(
          nameController: TextEditingController(text: 'Qualité rédaction'),
          maxScore: 10,
          coefficient: 1,
        ),
        _CriterionEntry(
          nameController: TextEditingController(text: 'Respect consignes'),
          maxScore: 5,
          coefficient: 1,
        ),
        _CriterionEntry(
          nameController: TextEditingController(text: 'Présentation'),
          maxScore: 5,
          coefficient: 1,
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    for (final c in _criteria) {
      c.nameController.dispose();
    }
    super.dispose();
  }

  // ── Objectives ──

  void _addObjective() {
    setState(() {
      _objectiveControllers.add(TextEditingController());
    });
  }

  void _removeObjective(int index) {
    setState(() {
      _objectiveControllers[index].dispose();
      _objectiveControllers.removeAt(index);
    });
  }

  // ── Criteria ──

  void _addCriterion() {
    setState(() {
      _criteria.add(_CriterionEntry(
        nameController: TextEditingController(),
        maxScore: 10,
        coefficient: 1,
      ));
    });
  }

  void _removeCriterion(int index) {
    setState(() {
      _criteria[index].nameController.dispose();
      _criteria.removeAt(index);
    });
  }

  // ── Files ──

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  // ── Submission ──

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;

    // Check trial mode
    if (LicenseService.isTrialMode() && await LicenseService.canCreateSimulation() != null) {
      _showLicenseError();
      return;
    }

    setState(() {
      _isSavingDraft = true;
      _errorMessage = null;
    });

    try {
      final body = _buildSimulationBody('draft');
      final response = await _apiService.post('simulations', body);
      await _uploadFiles(response['id'] as String);

      final code = response['code'] as String?;
      if (mounted) {
        setState(() {
          _createdCode = code ?? 'RH-${DateTime.now().year}-?';
          _isSavingDraft = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de l\'enregistrement : $e';
          _isSavingDraft = false;
        });
      }
    }
  }

  Future<void> _launchSimulation() async {
    if (!_formKey.currentState!.validate()) return;

    // Check trial mode
    if (LicenseService.isTrialMode() && await LicenseService.canCreateSimulation() != null) {
      _showLicenseError();
      return;
    }

    setState(() {
      _isLaunching = true;
      _errorMessage = null;
    });

    try {
      // Create simulation
      final body = _buildSimulationBody('active');
      final response = await _apiService.post('simulations', body);
      final simId = response['id'] as String;

      // Upload files
      await _uploadFiles(simId);

      // Launch
      await _apiService.post('simulations/$simId/launch', {});

      final code = response['code'] as String?;
      if (mounted) {
        setState(() {
          _createdCode = code ?? 'RH-${DateTime.now().year}-?';
          _isLaunching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulation lancée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du lancement : $e';
          _isLaunching = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildSimulationBody(String status) {
    return {
      'title': _titleController.text.trim(),
      'context': _contextController.text.trim(),
      'objectives': _objectiveControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      'durationDays': _durationDays,
      'maxGroups': _maxGroups,
      'gradingCriteria': _criteria
          .where((c) => c.nameController.text.trim().isNotEmpty)
          .map((c) => {
                'name': c.nameController.text.trim(),
                'maxScore': c.maxScore,
                'coefficient': c.coefficient,
              })
          .toList(),
      'status': status,
    };
  }

  Future<void> _uploadFiles(String simulationId) async {
    for (final file in _selectedFiles) {
      if (file.path != null) {
        try {
          await _apiService.uploadFile(
            'simulations/$simulationId/files',
            file.path!,
          );
        } catch (e) {
          // Continue with other files even if one fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur upload ${file.name} : $e')),
            );
          }
        }
      }
    }
  }

  void _showLicenseError() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limite d\'essai atteinte'),
        content: const Text(
          'Vous avez atteint la limite de simulations autorisées en mode essai. '
          'Veuillez souscrire à une licence pour créer davantage de simulations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Navigate to license purchase screen
            },
            child: const Text('Voir les offres'),
          ),
        ],
      ),
    );
  }

  void _resetAfterSuccess() {
    setState(() {
      _createdCode = null;
      _titleController.clear();
      _contextController.clear();
      for (final c in _objectiveControllers) {
        c.dispose();
      }
      _objectiveControllers.clear();
      _durationDays = 7;
      _maxGroups = 5;
      _selectedFiles.clear();
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Success state: show generated code
    if (_createdCode != null) {
      return _buildSuccessScreen(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la simulation' : 'Nouvelle simulation'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(theme, 'Informations générales'),
                    const SizedBox(height: 12),
                    _buildTitleField(theme),
                    const SizedBox(height: 16),
                    _buildContextField(theme),
                    const SizedBox(height: 24),

                    _buildSectionTitle(theme, 'Objectifs pédagogiques'),
                    const SizedBox(height: 8),
                    _buildObjectivesSection(theme),
                    const SizedBox(height: 24),

                    _buildSectionTitle(theme, 'Configuration'),
                    const SizedBox(height: 8),
                    _buildDurationSlider(theme),
                    const SizedBox(height: 16),
                    _buildMaxGroupsSlider(theme),
                    const SizedBox(height: 24),

                    _buildSectionTitle(theme, 'Grille d\'évaluation'),
                    const SizedBox(height: 8),
                    _buildCriteriaSection(theme),
                    const SizedBox(height: 24),

                    _buildSectionTitle(theme, 'Documents joints'),
                    const SizedBox(height: 8),
                    _buildFileSection(theme),
                    const SizedBox(height: 32),

                    // Error
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Action buttons
                    _buildActionButtons(theme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation créée'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 48, color: Colors.green),
              ),
              const SizedBox(height: 24),
              Text(
                'Simulation prête !',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Partagez ce code avec vos étudiants :',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _createdCode!,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code unique de la simulation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _createdCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copié dans le presse-papier')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copier le code'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetAfterSuccess,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Créer une autre'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terminer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form sections ──

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Titre de la simulation *',
        hintText: 'Ex: Cas pratique - Recrutement',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le titre est requis';
        }
        return null;
      },
    );
  }

  Widget _buildContextField(ThemeData theme) {
    return TextFormField(
      controller: _contextController,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: 'Contexte *',
        hintText: 'Décrivez le contexte de la simulation RH...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 100),
          child: Icon(Icons.description),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le contexte est requis';
        }
        return null;
      },
    );
  }

  // ── Objectives ──

  Widget _buildObjectivesSection(ThemeData theme) {
    return Column(
      children: [
        ..._objectiveControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Objectif ${index + 1}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                  onPressed: () => _removeObjective(index),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _addObjective,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter un objectif'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ── Sliders ──

  Widget _buildDurationSlider(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Durée', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_durationDays jour${_durationDays > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _durationDays.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_durationDays jours',
              onChanged: (v) => setState(() => _durationDays = v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 jour', style: theme.textTheme.bodySmall),
                Text('60 jours', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxGroupsSlider(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Nombre max de groupes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_maxGroups',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _maxGroups.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '$_maxGroups groupes',
              onChanged: (v) => setState(() => _maxGroups = v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 groupe', style: theme.textTheme.bodySmall),
                Text('20 groupes', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Criteria ──

  Widget _buildCriteriaSection(ThemeData theme) {
    return Column(
      children: [
        ..._criteria.asMap().entries.map((entry) {
          final index = entry.key;
          final criterion = entry.value;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: criterion.nameController,
                          decoration: InputDecoration(
                            labelText: 'Critère ${index + 1}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requis';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        onPressed: _criteria.length > 1 ? () => _removeCriterion(index) : null,
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Note max: ${criterion.maxScore.toInt()}', style: theme.textTheme.bodySmall),
                            Slider(
                              value: criterion.maxScore,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: '${criterion.maxScore.toInt()}',
                              onChanged: (v) => setState(() => criterion.maxScore = v.round().toDouble()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coefficient: ${criterion.coefficient.toInt()}', style: theme.textTheme.bodySmall),
                            Slider(
                              value: criterion.coefficient,
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: '${criterion.coefficient.toInt()}',
                              onChanged: (v) => setState(() => criterion.coefficient = v.round().toDouble()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _addCriterion,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter un critère'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ── Files ──

  Widget _buildFileSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                const SizedBox(height: 8),
                Text(
                  'Aucun fichier sélectionné',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ..._selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.insert_drive_file, color: theme.colorScheme.primary),
                title: Text(file.name, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_formatFileSize(file.size), style: theme.textTheme.bodySmall),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                  onPressed: () => _removeFile(index),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.attach_file, size: 18),
          label: const Text('Ajouter des fichiers'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Formats acceptés : PDF, DOC, XLS, PPT, images...',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // ── Action Buttons ──

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isSavingDraft || _isLaunching ? null : _saveDraft,
            icon: _isSavingDraft
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_isSavingDraft ? 'Enregistrement...' : 'Enregistrer le brouillon'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isSavingDraft || _isLaunching ? null : _launchSimulation,
            icon: _isLaunching
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rocket_launch),
            label: Text(_isLaunching ? 'Lancement...' : 'Lancer la simulation'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper class for criteria form state ──

class _CriterionEntry {
  final TextEditingController nameController;
  double maxScore;
  double coefficient;

  _CriterionEntry({
    required this.nameController,
    this.maxScore = 10,
    this.coefficient = 1,
  });
}
