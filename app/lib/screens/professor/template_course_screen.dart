import 'package:flutter/material.dart';
import 'package:simurh/models/hr_template.dart';
import 'package:simurh/services/hr_template_service.dart';

/// Écran affichant le mini-cours embarqué d'un template RH.
///
/// Reçoit un [templateId] dans les arguments de route. Charge le template
/// via [HrTemplateService] et présente son [ResourceContent] dans un
/// format lisible, structuré en sections avec résumé, concepts clés et
/// contenu pédagogique.
class TemplateCourseScreen extends StatefulWidget {
  const TemplateCourseScreen({super.key});

  @override
  State<TemplateCourseScreen> createState() => _TemplateCourseScreenState();
}

class _TemplateCourseScreenState extends State<TemplateCourseScreen> {
  final HrTemplateService _templateService = HrTemplateService();

  bool _isLoading = true;
  HrTemplate? _template;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  void _loadTemplate() {
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?;
    final templateId = args?['templateId'] as String?;

    if (templateId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final template = _templateService.getById(templateId);
    setState(() {
      _template = template;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _template != null ? '${_template!.title} — Cours' : 'Cours',
        ),
      ),
      body: _buildBody(context),
      bottomNavigationBar: _template != null ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_template == null) {
      return _buildUnavailableView(context);
    }

    return _buildCourseView(context, _template!);
  }

  /// Affiche un message "Cours non disponible" avec bouton retour.
  Widget _buildUnavailableView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Cours non disponible',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le cours demandé est introuvable. Veuillez réessayer.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la vue complète du cours.
  Widget _buildCourseView(BuildContext context, HrTemplate template) {
    final theme = Theme.of(context);
    final rc = template.resourceContent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // --- Résumé ---
        _buildSummaryCard(context, rc.summary),
        const SizedBox(height: 24),

        // --- Concepts clés ---
        if (rc.keyConcepts.isNotEmpty) ...[
          _buildSectionTitle(context, 'Concepts clés'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rc.keyConcepts
                .map((concept) => Chip(
                      label: Text(
                        concept,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withOpacity(0.5),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // --- Sections de cours ---
        for (int i = 0; i < rc.sections.length; i++) ...[
          _buildSectionCard(context, rc.sections[i]),
          if (i < rc.sections.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Titre de section dans le cours.
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Carte colorée pour le résumé.
  Widget _buildSummaryCard(BuildContext context, String summary) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.primaryContainer.withOpacity(0.2);

    return Card(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Résumé',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barre inférieure avec le bouton de téléchargement (placeholder).
  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Le téléchargement PDF sera bientôt disponible.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Télécharger le cours en PDF'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  /// Carte pour une section de cours (titre + contenu).
  Widget _buildSectionCard(BuildContext context, ResourceSection section) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              section.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
