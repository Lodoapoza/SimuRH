import 'package:simurh/models/hr_template.dart';
import 'package:simurh/data/hr_templates_licence.dart';
import 'package:simurh/data/hr_templates_master.dart';

class HrTemplateService {
  static final HrTemplateService _instance = HrTemplateService._internal();
  factory HrTemplateService() => _instance;
  HrTemplateService._internal();

  final List<HrTemplate> _all = [...licenceTemplates, ...masterTemplates];

  List<HrTemplate> getAll() => _all;

  List<HrTemplate> getByLevel(String level) =>
      _all.where((t) => t.level == level).toList();

  HrTemplate? getById(String id) {
    try {
      return _all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
