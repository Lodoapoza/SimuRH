import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simurh/models/hr_template.dart';
import 'package:simurh/services/hr_template_service.dart';
import 'package:simurh/services/db_service.dart';

class SimulationSetupScreen extends StatefulWidget {
  const SimulationSetupScreen({super.key});

  @override
  State<SimulationSetupScreen> createState() => _SimulationSetupScreenState();
}

class _SimulationSetupScreenState extends State<SimulationSetupScreen> {
  final HrTemplateService _templateService = HrTemplateService();
  final DbService _db = DbService();

  bool _isLoading = true;
  bool _isSavingDraft = false;
  bool _isLaunching = false;
  String? _errorMessage;

  HrTemplate? _template;

  // Form fields
  final _titleController = TextEditingController();
  final _contextController = TextEditingController();
  final _objectivesController = TextEditingController();
  int _durationDays = 7;
  int _maxGroups = 5;
  int _decisionPeriods = 3;

  // Decision param values (id -> value)
  final Map<String, double> _decisionParamValues = {};

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);

    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args.containsKey('templateId')) {
        final templateId = args['templateId'] as String;
        final template = _templateService.getById(templateId);

        if (template == null) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Template introuvable.';
              _isLoading = false;
            });
          }
          return;
        }

        // Pre-fill form with template values
        _titleController.text = template.title;
        _contextController.text = template.context;
        _objectivesController.text = template.objectives.join('\n');
        _durationDays = template.defaultDurationDays;
        _maxGroups = template.defaultMaxGroups;
        _decisionPeriods = template.decisionPeriods;

        // Init decision param values with defaults
        for (final param in template.decisionParams) {
          _decisionParamValues[param.id] = param.defaultValue;
        }

        if (mounted) {
          setState(() {
            _template = template;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Aucun template spécifié.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement du template : $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    _objectivesController.dispose();
    super.dispose();
  }

  // ── Code generation ──

  String _generateLocalCode() {
    final now = DateTime.now();
    final rand = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return 'RH-${now.year}-${rand.substring(0, 4)}';
  }

  // ── Save actions ──

  Map<String, dynamic> _buildSimulationBody(String status) {
    final t = _template!;
    return {
      'title': _titleController.text.trim(),
      'code': _generateLocalCode(),
      'context': _contextController.text.trim(),
      'objectives': jsonEncode(
        _objectivesController.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
      ),
      'duration_days': _durationDays,
      'max_groups': _maxGroups,
      'grading_criteria': jsonEncode(
        t.gradingCriteria.map((c) => {
          'name': c.name,
          'maxScore': c.maxScore,
          'coefficient': c.coefficient,
        }).toList(),
      ),
      'decision_periods': _decisionPeriods,
      'decision_params': jsonEncode(
        t.decisionParams.map((p) => {
          'id': p.id,
          'label': p.label,
          'type': p.type.name,
          'value': _decisionParamValues[p.id] ?? p.defaultValue,
        }).toList(),
      ),
      'regles': jsonEncode(t.rules),
      'contraintes': jsonEncode(t.constraints),
      'success_metrics': jsonEncode(
        t.successMetrics.map((m) => {
          'id': m.id,
          'label': m.label,
          'unit': m.unit,
          'description': m.description,
        }).toList(),
      ),
      'template_id': t.id,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un nom de simulation')),
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
      _errorMessage = null;
    });

    try {
      final body = _buildSimulationBody('draft');
      await _db.insert('simulations', body);

      if (mounted) {
        setState(() => _isSavingDraft = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brouillon enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un nom de simulation')),
      );
      return;
    }

    setState(() {
      _isLaunching = true;
      _errorMessage = null;
    });

    try {
      final body = _buildSimulationBody('active');
      await _db.insert('simulations', body);

      if (mounted) {
        setState(() => _isLaunching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulation lancée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Redirige vers le dashboard
        Navigator.of(context).pushNamedAndRemoveUntil('/professor/dashboard', (route) => false);
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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuration simulation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuration simulation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final template = _template!;

    return Scaffold(
      appBar: AppBar(
        title: Text(template.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Template header ──
          _buildTemplateHeader(theme, template),
          const SizedBox(height: 20),

          // ── Scenario ──
          _buildEditableScenarioCard(theme),
          const SizedBox(height: 20),

          // ── Objectives ──
          _buildObjectivesSection(theme),
          const SizedBox(height: 20),

          // ── Configuration form ──
          _buildConfigForm(theme, template),
          const SizedBox(height: 20),

          // ── Decision parameters ──
          if (template.decisionParams.isNotEmpty) ...[
            _buildDecisionParamsSection(theme, template),
            const SizedBox(height: 20),
          ],

          // ── Rules ──
          if (template.rules.isNotEmpty) ...[
            _buildRulesSection(theme, template),
            const SizedBox(height: 20),
          ],

          // ── Constraints ──
          if (template.constraints.isNotEmpty) ...[
            _buildConstraintsSection(theme, template),
            const SizedBox(height: 20),
          ],

          // ── Grading criteria ──
          if (template.gradingCriteria.isNotEmpty) ...[
            _buildGradingCriteriaSection(theme, template),
            const SizedBox(height: 20),
          ],

          // ── Success metrics ──
          if (template.successMetrics.isNotEmpty) ...[
            _buildSuccessMetricsSection(theme, template),
            const SizedBox(height: 20),
          ],

          // ── Error ──
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

          // ── Action buttons ──
          _buildActionButtons(theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Template header ──

  Widget _buildTemplateHeader(ThemeData theme, HrTemplate template) {
    final Color levelColor = template.level == 'master'
        ? Colors.purple
        : Colors.blue;
    final String levelLabel = template.level == 'master' ? 'Master' : 'Licence';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _iconDataFromString(template.icon),
                size: 32,
                color: levelColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              template.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    template.level == 'master' ? Icons.school : Icons.auto_stories,
                    size: 16,
                    color: levelColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    levelLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconDataFromString(String iconName) {
    switch (iconName) {
      case 'recruitment':
        return Icons.person_search;
      case 'evaluation':
        return Icons.assessment;
      case 'training':
        return Icons.school;
      case 'payroll':
        return Icons.account_balance;
      case 'conflict':
        return Icons.gpp_maybe;
      case 'strategy':
        return Icons.insights;
      default:
        return Icons.business;
    }
  }

  // ── Scenario ──

  Widget _buildEditableScenarioCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Scénario',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contextController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Décrivez le scénario de la simulation…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Objectives ──

  Widget _buildObjectivesSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Objectifs pédagogiques (un par ligne)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _objectivesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Saisissez les objectifs, un par ligne…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Configuration form ──

  Widget _buildConfigForm(ThemeData theme, HrTemplate template) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nom de la simulation
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Nom de la simulation *',
                hintText: 'Ex: ${template.title}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20),

            // Durée
            _buildSliderField(
              theme: theme,
              icon: Icons.calendar_today,
              label: 'Durée (jours)',
              value: _durationDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              displayValue: '$_durationDays jour${_durationDays > 1 ? 's' : ''}',
              onChanged: (v) => setState(() => _durationDays = v.round()),
            ),
            const SizedBox(height: 16),

            // Nombre de groupes
            _buildSliderField(
              theme: theme,
              icon: Icons.group,
              label: 'Nombre de groupes',
              value: _maxGroups.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              displayValue: '$_maxGroups',
              onChanged: (v) => setState(() => _maxGroups = v.round()),
            ),
            const SizedBox(height: 16),

            // Périodes de décision
            _buildSliderField(
              theme: theme,
              icon: Icons.timeline,
              label: 'Périodes de décision',
              value: _decisionPeriods.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              displayValue: '$_decisionPeriods',
              onChanged: (v) => setState(() => _decisionPeriods = v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderField({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: displayValue,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toInt()}', style: theme.textTheme.bodySmall),
              Text('${max.toInt()}', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  // ── Decision parameters ──

  Widget _buildDecisionParamsSection(ThemeData theme, HrTemplate template) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.toggle_off_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Paramètres de décision',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...template.decisionParams.map((param) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDecisionParamField(theme, param),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionParamField(ThemeData theme, DecisionParam param) {
    final currentValue = _decisionParamValues[param.id] ?? param.defaultValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and description
        Text(
          param.label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (param.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              param.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Input based on type
        _buildDecisionParamInput(theme, param, currentValue),
      ],
    );
  }

  Widget _buildDecisionParamInput(ThemeData theme, DecisionParam param, double currentValue) {
    switch (param.type) {
      case DecisionType.choice:
        return _buildChoiceField(theme, param, currentValue);
      case DecisionType.percentage:
        return _buildPercentageSlider(theme, param, currentValue);
      case DecisionType.currency:
        return _buildCurrencySlider(theme, param, currentValue);
      case DecisionType.integer:
        return _buildIntegerSlider(theme, param, currentValue);
    }
  }

  Widget _buildIntegerSlider(ThemeData theme, DecisionParam param, double currentValue) {
    final divisions = ((param.max - param.min) / param.step).round().clamp(1, 100);
    return Column(
      children: [
        Slider(
          value: currentValue,
          min: param.min,
          max: param.max,
          divisions: divisions,
          label: currentValue.toInt().toString(),
          onChanged: (v) {
            setState(() {
              _decisionParamValues[param.id] = v;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${param.min.toInt()}', style: theme.textTheme.bodySmall),
              Text('${currentValue.toInt()}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('${param.max.toInt()}', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageSlider(ThemeData theme, DecisionParam param, double currentValue) {
    return Column(
      children: [
        Slider(
          value: currentValue,
          min: 0,
          max: 100,
          divisions: 20,
          label: '${currentValue.toInt()}%',
          onChanged: (v) {
            setState(() {
              _decisionParamValues[param.id] = v;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: theme.textTheme.bodySmall),
              Text('${currentValue.toInt()}%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('100%', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySlider(ThemeData theme, DecisionParam param, double currentValue) {
    final divisions = ((param.max - param.min) / param.step).round().clamp(1, 100);
    return Column(
      children: [
        Slider(
          value: currentValue,
          min: param.min,
          max: param.max,
          divisions: divisions,
          label: '${_formatFcfa(currentValue)} FCFA',
          onChanged: (v) {
            setState(() {
              _decisionParamValues[param.id] = v;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_formatFcfa(param.min)} FCFA', style: theme.textTheme.bodySmall),
              Text('${_formatFcfa(currentValue)} FCFA', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('${_formatFcfa(param.max)} FCFA', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceField(ThemeData theme, DecisionParam param, double currentValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sélecteur de choix à implémenter',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFcfa(double value) {
    final intVal = value.round();
    final formatted = NumberFormat('#,##0', 'fr_FR').format(intVal);
    return formatted;
  }

  // ── Rules ──

  Widget _buildRulesSection(ThemeData theme, HrTemplate template) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Règles du jeu',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...template.rules.map((rule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rule,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Constraints ──

  Widget _buildConstraintsSection(ThemeData theme, HrTemplate template) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Contraintes',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...template.constraints.map((constraint) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        constraint,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Grading criteria ──

  Widget _buildGradingCriteriaSection(ThemeData theme, HrTemplate template) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grading, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Critères d\'évaluation',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...template.gradingCriteria.map((criteria) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        criteria.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${criteria.maxScore.toInt()} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${criteria.coefficient}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Success metrics ──

  Widget _buildSuccessMetricsSection(ThemeData theme, HrTemplate template) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Métriques de succès',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...template.successMetrics.map((metric) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${metric.label} (${metric.unit})',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (metric.description.isNotEmpty)
                            Text(
                              metric.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ──

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isSavingDraft || _isLaunching ? null : _saveDraft,
            icon: _isSavingDraft
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_isSavingDraft ? 'Enregistrement...' : 'Enregistrer comme brouillon'),
            style: OutlinedButton.styleFrom(
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
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: TextButton.icon(
            onPressed: _isSavingDraft || _isLaunching ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Annuler'),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
