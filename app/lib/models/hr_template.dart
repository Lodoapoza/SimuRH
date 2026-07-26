class HrTemplate {
  final String id;
  final String title;
  final String description;
  final String level; // 'licence' | 'master'
  final String icon;
  final String role;
  final String context;
  final List<String> objectives;
  final int defaultDurationDays;
  final int defaultMaxGroups;
  final List<CriteriaDef> gradingCriteria;
  final List<DecisionParam> decisionParams;
  final List<SuccessMetric> successMetrics;
  final int decisionPeriods;
  final List<String> rules;
  final List<String> constraints;
  final ResourceContent resourceContent;

  HrTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
    required this.role,
    required this.context,
    required this.objectives,
    required this.defaultDurationDays,
    required this.defaultMaxGroups,
    required this.gradingCriteria,
    required this.decisionParams,
    required this.successMetrics,
    required this.decisionPeriods,
    required this.rules,
    required this.constraints,
    required this.resourceContent,
  });
}

class CriteriaDef {
  final String name;
  final double maxScore;
  final double coefficient;
  CriteriaDef({required this.name, required this.maxScore, required this.coefficient});
}

class DecisionParam {
  final String id;
  final String label;
  final String description;
  final DecisionType type;
  final double min;
  final double max;
  final double defaultValue;
  final double step;

  DecisionParam({
    required this.id,
    required this.label,
    required this.description,
    required this.type,
    required this.min,
    required this.max,
    required this.defaultValue,
    this.step = 1,
  });
}

enum DecisionType { integer, percentage, currency, choice }

class SuccessMetric {
  final String id;
  final String label;
  final String unit;
  final String description;

  SuccessMetric({required this.id, required this.label, required this.unit, required this.description});
}

class ResourceContent {
  final String summary;
  final List<String> keyConcepts;
  final List<ResourceSection> sections;

  ResourceContent({required this.summary, required this.keyConcepts, required this.sections});
}

class ResourceSection {
  final String title;
  final String content;
  ResourceSection({required this.title, required this.content});
}
