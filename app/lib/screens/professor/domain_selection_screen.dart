import 'package:flutter/material.dart';
import 'package:simurh/models/hr_template.dart';
import 'package:simurh/services/hr_template_service.dart';

/// Écran affichant la grille des 28 templates RH disponibles,
/// répartis en deux catégories : Licence (opérationnel) et Master (stratégique).
class DomainSelectionScreen extends StatefulWidget {
  const DomainSelectionScreen({super.key});

  @override
  State<DomainSelectionScreen> createState() => _DomainSelectionScreenState();
}

class _DomainSelectionScreenState extends State<DomainSelectionScreen> {
  final HrTemplateService _templateService = HrTemplateService();

  List<HrTemplate> _licenceTemplates = [];
  List<HrTemplate> _masterTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  /// Charge les templates depuis le service et les filtre par niveau.
  void _loadTemplates() {
    final licence = _templateService.getByLevel('licence');
    final master = _templateService.getByLevel('master');
    setState(() {
      _licenceTemplates = licence;
      _masterTemplates = master;
      _isLoading = false;
    });
  }

  /// Mappe un nom d'icône (string) vers une [IconData] Material Design.
  /// Retourne [Icons.work_outline] pour les noms inconnus.
  IconData _iconFromString(String name) {
    switch (name) {
      case 'person_search':
        return Icons.person_search;
      case 'trending_up':
        return Icons.trending_up;
      case 'groups':
        return Icons.groups;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'business':
        return Icons.business;
      case 'assignment':
        return Icons.assignment;
      case 'assessment':
        return Icons.assessment;
      case 'people':
        return Icons.people;
      case 'handshake':
        return Icons.handshake;
      case 'account_balance':
        return Icons.account_balance;
      case 'description':
        return Icons.description;
      case 'fact_check':
        return Icons.fact_check;
      case 'psychology':
        return Icons.psychology;
      case 'diversity':
        return Icons.diversity_3;
      case 'gavel':
        return Icons.gavel;
      case 'payments':
        return Icons.payments;
      case 'analytics':
        return Icons.analytics;
      case 'forum':
        return Icons.forum;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'group_work':
        return Icons.group_work;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'insights':
        return Icons.insights;
      case 'summarize':
        return Icons.summarize;
      case 'policy':
        return Icons.policy;
      case 'balance':
        return Icons.balance;
      default:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un domaine RH'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        _buildSection(
          context,
          title: 'Licence \u2014 Niveau op\u00e9rationnel',
          templates: _licenceTemplates,
          accentColor: Colors.indigo,
          badgeLabel: 'Licence',
        ),
        const SizedBox(height: 8),
        _buildSection(
          context,
          title: 'Master \u2014 Niveau strat\u00e9gique',
          templates: _masterTemplates,
          accentColor: theme.colorScheme.tertiary,
          badgeLabel: 'Master',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<HrTemplate> templates,
    required Color accentColor,
    required String badgeLabel,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun template disponible',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.80,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return _buildTemplateCard(
                context,
                templates[index],
                accentColor,
                badgeLabel,
              );
            },
          ),
      ],
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    HrTemplate template,
    Color accentColor,
    String badgeLabel,
  ) {
    final theme = Theme.of(context);
    final icon = _iconFromString(template.icon);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: theme.shadowColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/professor/simulation-setup',
            arguments: {'templateId': template.id},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: icon + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 22, color: accentColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Titre
              Text(
                template.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Expanded(
                child: Text(
                  template.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
