import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/file_service.dart';
import 'package:simurh/models/simulation.dart';
import 'package:simurh/models/group_model.dart';
import 'package:simurh/models/submission.dart';
import 'package:simurh/models/evaluation.dart';

class EvaluationScreen extends StatefulWidget {
  final String simulationId;
  final Group group;
  final Submission? submission;
  final List<GradingCriterion> gradingCriteria;
  final Evaluation? existingEvaluation;

  const EvaluationScreen({
    super.key,
    required this.simulationId,
    required this.group,
    this.submission,
    required this.gradingCriteria,
    this.existingEvaluation,
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final DbService _db = DbService();
  final FileService _fileService = FileService();
  final _commentController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isEditMode = false;

  // Score per criterion name
  final Map<String, double> _scores = {};

  @override
  void initState() {
    super.initState();
    _initScores();
  }

  void _initScores() {
    final existing = widget.existingEvaluation;
    if (existing != null) {
      _isEditMode = true;
      _commentController.text = existing.comments ?? '';
      for (final criterion in widget.gradingCriteria) {
        _scores[criterion.name] = existing.scores[criterion.name] ?? 0.0;
      }
    } else {
      for (final criterion in widget.gradingCriteria) {
        _scores[criterion.name] = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Score calculation ──

  double get _totalScore {
    double weightedSum = 0;
    double maxWeightedSum = 0;

    for (final criterion in widget.gradingCriteria) {
      final score = _scores[criterion.name] ?? 0.0;
      weightedSum += score * criterion.coefficient;
      maxWeightedSum += criterion.maxScore * criterion.coefficient;
    }

    if (maxWeightedSum == 0) return 0;
    return (weightedSum / maxWeightedSum) * 100;
  }

  // ── Save ──

  Future<void> _saveEvaluation() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final scoresMap = <String, double>{};
      for (final criterion in widget.gradingCriteria) {
        scoresMap[criterion.name] = _scores[criterion.name] ?? 0.0;
      }

      final body = {
        'simulation_id': widget.simulationId,
        'group_id': widget.group.id,
        if (widget.submission != null) 'submission_id': widget.submission!.id,
        'scores': scoresMap,
        'totalScore': _totalScore,
        'comments': _commentController.text.trim(),
      };

      if (_isEditMode && widget.existingEvaluation != null) {
        await _db.update(
          'evaluations',
          body,
          where: 'id = ?',
          whereArgs: [widget.existingEvaluation!.id],
        );
      } else {
        await _db.insert('evaluations', body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Note mise à jour' : 'Évaluation enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur : $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _downloadSubmissionFile() async {
    final submission = widget.submission;
    if (submission?.filePath == null) return;

    try {
      final fileId = submission!.filePath!.split('/').last;
      final filename = 'rendu_${widget.group.name}.pdf';
      await _fileService.downloadFile(fileId, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier téléchargé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement : $e')),
        );
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submission = widget.submission;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Noter : ${widget.group.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              'Simulation #${widget.simulationId}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Submission content ──
                  if (submission != null) ...[
                    _buildSectionTitle(theme, 'Rendu du groupe'),
                    const SizedBox(height: 8),

                    // Submission metadata
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Soumis le ${DateFormat('dd/MM/yyyy à HH:mm').format(submission.submittedAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Submission text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        submission.content.isNotEmpty
                            ? submission.content
                            : 'Aucun contenu texte.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),

                    // Submission file
                    if (submission.filePath != null && submission.filePath!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.insert_drive_file, color: Colors.blue),
                          ),
                          title: const Text('Fichier joint', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(submission.filePath!.split('/').last),
                          trailing: IconButton(
                            icon: Icon(Icons.download, color: theme.colorScheme.primary),
                            onPressed: _downloadSubmissionFile,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildSectionTitle(theme, 'Évaluation sans rendu'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ce groupe n\'a pas encore soumis de rendu. Vous pouvez tout de même évaluer leur travail oral ou leur participation.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Grading criteria ──
                  _buildSectionTitle(theme, 'Grille d\'évaluation'),
                  const SizedBox(height: 12),

                  ...widget.gradingCriteria.map((criterion) {
                    final score = _scores[criterion.name] ?? 0.0;
                    final maxScore = criterion.maxScore;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
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
                                Expanded(
                                  child: Text(
                                    criterion.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Coeff. ${criterion.coefficient.toInt()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Live score display
                            Row(
                              children: [
                                Text(
                                  '${score.toStringAsFixed(1)}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  ' / $maxScore',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                showValueIndicator: ShowValueIndicator.always,
                              ),
                              child: Slider(
                                value: score,
                                min: 0,
                                max: maxScore,
                                divisions: (maxScore * 2).toInt(), // steps of 0.5
                                label: score.toStringAsFixed(1),
                                onChanged: (v) {
                                  setState(() => _scores[criterion.name] = v);
                                },
                              ),
                            ),

                            // Quick score buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [0.0, 0.25, 0.5, 0.75, 1.0].map((fraction) {
                                final val = (maxScore * fraction).roundToDouble();
                                return InkWell(
                                  onTap: () => setState(() => _scores[criterion.name] = val),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: score == val
                                          ? theme.colorScheme.primary.withOpacity(0.15)
                                          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: score == val
                                          ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                                          : null,
                                    ),
                                    child: Text(
                                      '${val.toInt()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: score == val ? FontWeight.bold : FontWeight.normal,
                                        color: score == val
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Total score ──
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.score, size: 28, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Score total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  '${_totalScore.toStringAsFixed(1)}%',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _totalScore >= 80
                                  ? Colors.green.withOpacity(0.2)
                                  : _totalScore >= 60
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _totalScore >= 80
                                    ? 'A'
                                    : _totalScore >= 70
                                        ? 'B'
                                        : _totalScore >= 60
                                            ? 'C'
                                            : _totalScore >= 50
                                                ? 'D'
                                                : 'F',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: _totalScore >= 80
                                      ? Colors.green.shade700
                                      : _totalScore >= 60
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Comment ──
                  _buildSectionTitle(theme, 'Commentaire'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ajoutez un commentaire sur la prestation du groupe...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

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

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveEvaluation,
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_isEditMode ? Icons.update : Icons.save),
                      label: Text(_isSaving
                          ? 'Enregistrement...'
                          : _isEditMode
                              ? 'Mettre à jour la note'
                              : 'Enregistrer l\'évaluation'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
