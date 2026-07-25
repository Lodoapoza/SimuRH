import 'package:flutter/material.dart' hide Simulation;
import 'package:intl/intl.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/models/simulation.dart';
import 'package:simurh/models/submission.dart';
import 'package:simurh/models/evaluation.dart';
import 'package:simurh/models/ranking.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultScreen extends StatefulWidget {
  final Simulation simulation;
  final Evaluation? evaluation;
  final Submission? submission;
  final List<RankingEntry> rankings;

  const ResultScreen({
    super.key,
    required this.simulation,
    this.evaluation,
    this.submission,
    this.rankings = const [],
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final DbService _dbService = DbService();

  bool _isLoading = false;
  String? _errorMessage;
  Evaluation? _evaluation;
  List<RankingEntry> _rankings = [];
  String _etablissement = '';

  @override
  void initState() {
    super.initState();
    _evaluation = widget.evaluation;
    _rankings = List.from(widget.rankings);
    _loadEtablissement();
    _loadFullData();
  }

  Future<void> _loadEtablissement() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['etablissement'] != null) {
      setState(() => _etablissement = args['etablissement'] as String);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _etablissement = prefs.getString('simurh_etablissement') ?? '';
    });
  }

  Future<void> _loadFullData() async {
    setState(() => _isLoading = true);

    try {
      // Load evaluation from local DB
      if (_evaluation == null && widget.submission != null) {
        final evalData = await _dbService.query(
          'evaluations',
          where: 'submission_id = ?',
          whereArgs: [widget.submission!.id],
        );
        if (evalData.isNotEmpty) {
          _evaluation = Evaluation.fromJson(evalData.first);
        }
      }

      // Load rankings from local DB
      final allEvals = await _dbService.query('evaluations');
      if (allEvals.isNotEmpty && widget.simulation.id.isNotEmpty) {
        final allRankings = allEvals.map((e) {
          return RankingEntry(
            groupName: '${e['group_name'] ?? 'Groupe'}',
            totalScore: (e['score'] as num?)?.toDouble() ?? 0,
            evaluatedAt: DateTime.now(),
            memberCount: 0,
            rank: 0,
          );
        }).toList();
        allRankings.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        for (int i = 0; i < allRankings.length; i++) {
          allRankings[i] = RankingEntry(
            groupName: allRankings[i].groupName,
            totalScore: allRankings[i].totalScore,
            evaluatedAt: allRankings[i].evaluatedAt,
            memberCount: allRankings[i].memberCount,
            rank: i + 1,
          );
        }
        _rankings = allRankings;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Résultats'),
            if (_etablissement.isNotEmpty)
              Text(_etablissement,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFullData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildScoreHeader(theme),
                  const SizedBox(height: 24),
                  if (_evaluation != null) ...[
                    _buildCriteriaDetail(theme),
                    const SizedBox(height: 24),
                    if (_evaluation!.comments != null && _evaluation!.comments!.isNotEmpty)
                      _buildComments(theme),
                    const SizedBox(height: 24),
                  ],
                  if (_evaluation == null)
                    _buildNoEvaluationCard(theme),
                  _buildRankingSection(theme),
                ],
              ),
            ),
    );
  }

  // ── Score Header ──

  Widget _buildScoreHeader(ThemeData theme) {
    final score = _evaluation?.totalScore;
    final hasScore = score != null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasScore
                ? (score! >= 14
                    ? [Colors.green.shade400, Colors.green.shade700]
                    : score >= 10
                        ? [Colors.blue.shade400, Colors.blue.shade700]
                        : [Colors.orange.shade400, Colors.red.shade600])
                : [theme.colorScheme.surfaceVariant, theme.colorScheme.surfaceVariant],
          ),
        ),
        child: Column(
          children: [
            Text(
              hasScore ? 'Note du groupe' : 'En attente',
              style: TextStyle(
                color: hasScore ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (hasScore)
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              )
            else
              Icon(
                Icons.hourglass_empty,
                size: 72,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            if (hasScore) ...[
              const SizedBox(height: 4),
              Text(
                '/ 20',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              widget.simulation.title,
              style: TextStyle(
                color: hasScore ? Colors.white.withOpacity(0.9) : theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            if (widget.submission != null) ...[
              const SizedBox(height: 4),
              Text(
                'Soumis le ${DateFormat('dd/MM/yyyy').format(widget.submission!.submittedAt)}',
                style: TextStyle(
                  color: hasScore ? Colors.white.withOpacity(0.6) : theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Criteria Detail ──

  Widget _buildCriteriaDetail(ThemeData theme) {
    final evaluation = _evaluation!;
    final criteria = widget.simulation.gradingCriteria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détail des notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...criteria.map((criterion) {
          final score = evaluation.scores[criterion.name] ?? 0.0;
          final percentage = criterion.maxScore > 0 ? score / criterion.maxScore : 0.0;
          final barColor = percentage >= 0.7
              ? Colors.green
              : percentage >= 0.5
                  ? Colors.orange
                  : Colors.red;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        criterion.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)} / ${criterion.maxScore.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: barColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Comments ──

  Widget _buildComments(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.comment, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Commentaires du professeur', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primaryContainer),
          ),
          child: Text(
            _evaluation!.comments!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  // ── No Evaluation ──

  Widget _buildNoEvaluationCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'En attente d\'évaluation',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre professeur n\'a pas encore évalué votre travail. Revenez plus tard.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ranking ──

  Widget _buildRankingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.leaderboard, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Classement général', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (_rankings.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Classement non disponible')),
            ),
          )
        else
          ..._rankings.asMap().entries.map((entry) {
            final rank = entry.value.rank;
            final isMyGroup = widget.submission != null &&
                widget.submission!.groupName == entry.value.groupName;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: isMyGroup ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isMyGroup
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: _buildRankBadge(rank),
                title: Row(
                  children: [
                    Text(
                      entry.value.groupName,
                      style: TextStyle(
                        fontWeight: isMyGroup ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isMyGroup) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'VOUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  entry.value.totalScore.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMyGroup ? theme.colorScheme.primary : null,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🥇', style: TextStyle(fontSize: 22))),
      );
    } else if (rank == 2) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🥈', style: TextStyle(fontSize: 22))),
      );
    } else if (rank == 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.brown.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🥉', style: TextStyle(fontSize: 22))),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
