import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/decision_engine.dart';
import 'package:simurh/services/hr_template_service.dart';
import 'package:simurh/models/hr_template.dart';
import 'package:simurh/models/simulation_round.dart';

class SimulationGameScreen extends StatefulWidget {
  const SimulationGameScreen({super.key});

  @override
  State<SimulationGameScreen> createState() => _SimulationGameScreenState();
}

class _SimulationGameScreenState extends State<SimulationGameScreen>
    with SingleTickerProviderStateMixin {
  final DbService _db = DbService();
  final DecisionEngine _engine = DecisionEngine();
  final HrTemplateService _templateService = HrTemplateService();

  // Arguments
  int _simulationId = 0;
  int _groupId = 0;
  String _templateId = '';

  // Loading / Error
  bool _isLoading = true;
  String? _errorMessage;

  // Data
  Map<String, dynamic>? _simulationData;
  HrTemplate? _template;
  List<SimulationRound> _rounds = [];

  // Game state
  int _currentPeriod = 1;
  int _totalPeriods = 4;
  bool _allPeriodsDone = false;
  bool _isValidating = false;

  // Decisions — current slider values
  Map<String, double> _decisionValues = {};

  // Metrics from last completed round (displayed as dashboard)
  Map<String, double> _currentMetrics = {};
  Map<String, double> _previousMetrics = {};

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Metric colors
  Color _metricColor(double value) {
    if (value >= 70) return Colors.green;
    if (value >= 40) return Colors.orange;
    return Colors.red;
  }

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Data Loading ──

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Read route arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _simulationId = (args['simulationId'] as num?)?.toInt() ?? 0;
        _groupId = (args['groupId'] as num?)?.toInt() ?? 0;
        _templateId = (args['templateId'] as String?) ?? '';
      }

      if (_simulationId == 0 || _templateId.isEmpty) {
        setState(() {
          _errorMessage = 'Paramètres de simulation invalides.';
          _isLoading = false;
        });
        return;
      }

      // Load simulation from DB
      final sims = await _db.query(
        'simulations',
        where: 'id = ?',
        whereArgs: [_simulationId],
      );
      if (sims.isEmpty) {
        setState(() {
          _errorMessage = 'Simulation introuvable.';
          _isLoading = false;
        });
        return;
      }
      _simulationData = sims.first;

      // Load template
      final template = _templateService.getById(_templateId);
      if (template == null) {
        setState(() {
          _errorMessage = 'Template de simulation introuvable.';
          _isLoading = false;
        });
        return;
      }
      _template = template;
      _totalPeriods = template.decisionPeriods;

      // Load existing rounds
      final roundRows = await _db.query(
        'simulation_rounds',
        where: 'simulation_id = ? AND group_id = ?',
        whereArgs: [_simulationId, _groupId],
      );
      _rounds = roundRows.map((r) => SimulationRound.fromMap(r)).toList();
      _rounds.sort((a, b) => a.period.compareTo(b.period));

      // Determine current period
      await _initRound();
    } catch (e) {
      setState(() => _errorMessage = 'Erreur de chargement : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initRound() async {
    final completedRounds =
        _rounds.where((r) => r.status == 'completed').toList();
    completedRounds.sort((a, b) => b.period.compareTo(a.period));

    if (completedRounds.isNotEmpty) {
      final lastCompleted = completedRounds.first;
      _currentPeriod = lastCompleted.period + 1;
      _previousMetrics = Map.from(lastCompleted.metrics);
      _currentMetrics = Map.from(lastCompleted.metrics);
    } else {
      _currentPeriod = 1;
      _previousMetrics = {};
      _currentMetrics = {};
    }

    if (_currentPeriod > _totalPeriods) {
      _allPeriodsDone = true;
    } else {
      _allPeriodsDone = false;
      _initDefaultDecisions();
    }

    _animController.reset();
    _animController.forward();
    setState(() {});
  }

  void _initDefaultDecisions() {
    final template = _template;
    if (template == null) return;

    _decisionValues = {};
    // Start with defaults from template
    for (final param in template.decisionParams) {
      _decisionValues[param.id] = param.defaultValue;
    }

    // Override with decisions from the most recent pending round (if any)
    final pendingRounds = _rounds
        .where((r) => r.status == 'pending' && r.period == _currentPeriod)
        .toList();
    if (pendingRounds.isNotEmpty) {
      final pending = pendingRounds.first;
      for (final entry in pending.decisions.entries) {
        _decisionValues[entry.key] = entry.value;
      }
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ── Validation ──

  Future<void> _validateDecisions() async {
    if (_isValidating) return;
    setState(() => _isValidating = true);

    try {
      final decisions = Map<String, double>.from(_decisionValues);

      // Compute new metrics
      final newMetrics = await _engine.computeMetrics(
        simulationId: _simulationId,
        period: _currentPeriod,
        decisions: decisions,
        previousMetrics:
            _previousMetrics.isNotEmpty ? _previousMetrics : null,
      );

      // Save the round
      await _engine.saveRound(
        simulationId: _simulationId,
        period: _currentPeriod,
        decisions: decisions,
        metrics: newMetrics,
        groupId: _groupId,
      );

      // Reload rounds
      final roundRows = await _db.query(
        'simulation_rounds',
        where: 'simulation_id = ? AND group_id = ?',
        whereArgs: [_simulationId, _groupId],
      );
      _rounds = roundRows.map((r) => SimulationRound.fromMap(r)).toList();
      _rounds.sort((a, b) => a.period.compareTo(b.period));

      // Show transition dialog with results
      if (mounted) {
        await _showTransitionDialog(
          oldMetrics: _previousMetrics,
          newMetrics: newMetrics,
          period: _currentPeriod,
        );
      }

      // Move to next period
      await _initRound();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la validation : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ── Transition Dialog ──

  Future<void> _showTransitionDialog({
    required Map<String, double> oldMetrics,
    required Map<String, double> newMetrics,
    required int period,
  }) async {
    final template = _template;
    if (template == null) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isLastPeriod = period >= _totalPeriods;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                isLastPeriod ? Icons.flag : Icons.check_circle,
                size: 48,
                color: isLastPeriod
                    ? Colors.amber.shade600
                    : Colors.green.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                isLastPeriod
                    ? 'Simulation terminée !'
                    : 'Période $period validée',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Évolution des indicateurs',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...template.successMetrics.map((metric) {
                    final newVal = newMetrics[metric.id];
                    final oldVal = oldMetrics[metric.id];
                    if (newVal == null) return const SizedBox.shrink();

                    final diff = oldVal != null ? newVal - oldVal : 0.0;
                    final isGood = _isHigherBetter(metric.id) ? diff >= 0 : diff <= 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  metric.label,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (oldVal != null)
                                Text(
                                  '${_formatMetricValue(oldVal, metric)} → ',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              Text(
                                _formatMetricValue(newVal, metric),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (oldVal != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isGood ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 14,
                                  color: isGood ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isGood ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isLastPeriod ? 'Voir le résumé final' : 'Continuer',
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isHigherBetter(String metricId) {
    const lowerBetter = {
      'time_to_hire',
      'cost_per_hire',
      'cout_total',
      'cout_recrutement',
      'cout_formation',
      'masse_salariale',
      'turnover',
      'delai_moyen_dpae',
      'taux_erreur_admin',
      'taux_mobilite',
    };
    return !lowerBetter.contains(metricId);
  }

  // ── Formatting ──

  String _formatMetricValue(double value, SuccessMetric metric) {
    if (value.isNaN || value.isInfinite) return '—';

    final unit = metric.unit.toLowerCase();

    if (unit == 'fcfa' || unit.contains('fcfa')) {
      return '${NumberFormat('#,###', 'fr_FR').format(value)} FCFA';
    }
    if (unit == '%' || metric.id.contains('taux') || metric.id.contains('pourcentage')) {
      return '${value.toStringAsFixed(1)} %';
    }
    if (unit == '/10') {
      return value.toStringAsFixed(1);
    }
    if (unit == 'jours' || unit == 'jour') {
      return '${value.toStringAsFixed(0)} j';
    }
    if (value >= 10000) {
      return '${NumberFormat('#,###', 'fr_FR').format(value)} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  String _formatDecisionValue(double value, DecisionParam param) {
    if (value.isNaN || value.isInfinite) return '—';

    switch (param.type) {
      case DecisionType.currency:
        return '${NumberFormat('#,###', 'fr_FR').format(value)} FCFA';
      case DecisionType.percentage:
        return '${value.toStringAsFixed(0)} %';
      case DecisionType.integer:
        return value.toStringAsFixed(0);
      case DecisionType.choice:
        return value.toStringAsFixed(0);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final simTitle = _simulationData?['title'] as String? ?? 'Simulation';
    final color = theme.colorScheme;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            simTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_template != null && !_allPeriodsDone)
            Text(
              'Période $_currentPeriod / $_totalPeriods',
              style: TextStyle(
                fontSize: 12,
                color: color.onPrimary.withOpacity(0.7),
              ),
            ),
        ],
      ),
      actions: [
        if (!_allPeriodsDone && _template != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _allPeriodsDone
                      ? Colors.green.withOpacity(0.2)
                      : color.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _allPeriodsDone
                      ? 'Terminé'
                      : 'Période $_currentPeriod/$_totalPeriods',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _allPeriodsDone ? Colors.green.shade700 : color.primary,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _refresh,
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Une erreur est survenue',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_template == null) {
      return Center(
        child: Text(
          'Aucun template trouvé.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    if (_template!.decisionParams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun paramètre de décision',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ce template ne comporte pas de paramètres ajustables.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_allPeriodsDone) {
      return _buildFinalState(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            _buildHeader(theme),
            const SizedBox(height: 20),

            // Metrics dashboard
            if (_currentMetrics.isNotEmpty) ...[
              _buildMetricsDashboard(theme),
              const SizedBox(height: 20),
            ],

            // Decisions form
            _buildDecisionsForm(theme),
            const SizedBox(height: 24),

            // Validate button
            _buildActionButton(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Header Section ──

  Widget _buildHeader(ThemeData theme) {
    final template = _template!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_turned_in,
                color: theme.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Période $_currentPeriod / $_totalPeriods',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _currentPeriod / _totalPeriods,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metrics Dashboard ──

  Widget _buildMetricsDashboard(ThemeData theme) {
    final template = _template!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs de performance',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Résultats de la période précédente',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...template.successMetrics.map((metric) {
          final value = _currentMetrics[metric.id];
          if (value == null) return const SizedBox.shrink();

          // Determine display value and color
          final color = _metricColor(value);
          final displayValue = _isHigherBetter(metric.id) ? value : 100 - value;
          final gaugeValue = displayValue.clamp(0.0, 100.0) / 100.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.label,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (metric.description.isNotEmpty)
                                Text(
                                  metric.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatMetricValue(value, metric),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: gaugeValue,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Decisions Form ──

  Widget _buildDecisionsForm(ThemeData theme) {
    final template = _template!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Décisions — Période $_currentPeriod',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ajustez les paramètres de votre stratégie RH',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...template.decisionParams.map((param) {
          final value = _decisionValues[param.id] ?? param.defaultValue;
          final formatted = _formatDecisionValue(value, param);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                param.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatted,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor:
                            theme.colorScheme.surfaceVariant,
                        thumbColor: theme.colorScheme.primary,
                        overlayColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        valueIndicatorColor: theme.colorScheme.primary,
                        valueIndicatorTextStyle: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                      child: Slider(
                        value: value.clamp(param.min, param.max),
                        min: param.min,
                        max: param.max,
                        divisions:
                            ((param.max - param.min) / param.step).round().clamp(1, 1000),
                        label: formatted,
                        onChanged: (v) {
                          // Snap to step
                          final stepped =
                              (v / param.step).round() * param.step;
                          setState(() {
                            _decisionValues[param.id] =
                                stepped.clamp(param.min, param.max);
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDecisionValue(param.min, param),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _formatDecisionValue(param.max, param),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Action Button ──

  Widget _buildActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isValidating ? null : _validateDecisions,
        icon: _isValidating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isValidating
              ? 'Calcul en cours…'
              : 'Valider les décisions — Période $_currentPeriod',
          style: const TextStyle(fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Final State ──

  Widget _buildFinalState(ThemeData theme) {
    // Gather all completed rounds for the summary
    final completed =
        _rounds.where((r) => r.status == 'completed').toList();
    completed.sort((a, b) => a.period.compareTo(b.period));

    // Use metrics from the last completed round
    final finalMetrics =
        completed.isNotEmpty ? completed.last.metrics : <String, double>{};
    final template = _template!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Congrats header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade700,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.flag, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Simulation terminée !',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous avez complété les $_totalPeriods périodes.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${completed.length} période${completed.length > 1 ? 's' : ''} validée${completed.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Final metrics
            if (finalMetrics.isNotEmpty) ...[
              Text(
                'Résultats finaux',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...template.successMetrics.map((metric) {
                final value = finalMetrics[metric.id];
                if (value == null) return const SizedBox.shrink();

                final color = _metricColor(value);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              metric.label,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatMetricValue(value, metric),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Period-by-period summary
            if (completed.length >= 2) ...[
              Text(
                'Historique des périodes',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...completed.map((round) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'P${round.period}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    title: Text('Période ${round.period}'),
                    subtitle: Text(
                      '${round.decisions.length} décisions • ${round.metrics.length} indicateurs',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Back button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour à l\'accueil'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
