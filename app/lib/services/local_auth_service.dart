import 'package:simurh/models/local_profile.dart';
import 'package:simurh/services/db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  static const String _activeProfileIdKey = 'active_profile_id';

  /// Crée un profil professeur et le définit comme actif
  Future<LocalProfile> createProfessor(String name) async {
    final db = await DbService().database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('profiles', {
      'name': name,
      'role': 'professor',
      'created_at': now,
    });
    // Désactiver tous les autres profils
    await db.update('profiles', {'is_active': 0});
    // Activer celui-ci
    await db.update('profiles', {'is_active': 1}, where: 'id = ?', whereArgs: [id]);
    // Sauvegarder dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeProfileIdKey, id);

    return LocalProfile(id: id, name: name, role: 'professor', isActive: true);
  }

  /// Crée un étudiant dans un groupe
  Future<LocalProfile> createStudent(String name, int groupId) async {
    final db = await DbService().database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('profiles', {
      'name': name,
      'role': 'student',
      'group_id': groupId,
      'created_at': now,
    });
    return LocalProfile(id: id, name: name, role: 'student', groupId: groupId);
  }

  /// Active un profil existant
  Future<void> switchToProfile(int profileId) async {
    final db = await DbService().database;
    await db.update('profiles', {'is_active': 0});
    await db.update('profiles', {'is_active': 1}, where: 'id = ?', whereArgs: [profileId]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeProfileIdKey, profileId);
  }

  /// Retourne le profil actif ou null
  Future<LocalProfile?> getActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt(_activeProfileIdKey);
    if (activeId == null) return null;
    final db = await DbService().database;
    final results = await db.query('profiles', where: 'id = ?', whereArgs: [activeId]);
    if (results.isEmpty) return null;
    return LocalProfile.fromMap(results.first);
  }

  /// Retourne tous les profils professeur
  Future<List<LocalProfile>> getAllProfessors() async {
    final db = await DbService().database;
    final results = await db.query('profiles', where: 'role = ?', whereArgs: ['professor']);
    return results.map((m) => LocalProfile.fromMap(m)).toList();
  }

  /// Retourne les étudiants d'un groupe
  Future<List<LocalProfile>> getStudentsInGroup(int groupId) async {
    final db = await DbService().database;
    final results = await db.query('profiles',
      where: 'role = ? AND group_id = ?',
      whereArgs: ['student', groupId],
    );
    return results.map((m) => LocalProfile.fromMap(m)).toList();
  }

  /// Vérifie si le profil actif est professeur
  Future<bool> isProfessor() async {
    final profile = await getActiveProfile();
    return profile?.role == 'professor';
  }

  /// Supprime un profil
  Future<void> deleteProfile(int profileId) async {
    final db = await DbService().database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
  }

  /// Déconnecte (aucun profil actif)
  Future<void> logout() async {
    final db = await DbService().database;
    await db.update('profiles', {'is_active': 0});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeProfileIdKey);
  }
}
