import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'simurh_offline.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        name TEXT,
        phone TEXT UNIQUE,
        role TEXT,
        establishment_name TEXT,
        city TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE simulations(
        id INTEGER PRIMARY KEY,
        code TEXT UNIQUE,
        title TEXT,
        description TEXT,
        establishment_id INTEGER,
        creator_id INTEGER,
        status TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE simulation_files(
        id INTEGER PRIMARY KEY,
        simulation_id INTEGER,
        file_id TEXT,
        filename TEXT,
        file_type TEXT,
        url TEXT,
        local_path TEXT,
        FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE groups_table(
        id INTEGER PRIMARY KEY,
        simulation_id INTEGER,
        name TEXT,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER,
        student_name TEXT NOT NULL,
        joined_at TEXT,
        FOREIGN KEY (group_id) REFERENCES groups_table(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE submissions(
        id INTEGER PRIMARY KEY,
        simulation_id INTEGER,
        user_id INTEGER,
        group_id INTEGER,
        content TEXT,
        status TEXT,
        submitted_at TEXT,
        is_pending_sync INTEGER DEFAULT 1, -- 1 for true, 0 for false
        FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups_table(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE evaluations(
        id INTEGER PRIMARY KEY,
        submission_id INTEGER,
        evaluator_id INTEGER,
        score REAL,
        feedback TEXT,
        evaluated_at TEXT,
        FOREIGN KEY (submission_id) REFERENCES submissions(id) ON DELETE CASCADE,
        FOREIGN KEY (evaluator_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE resources(
        id INTEGER PRIMARY KEY,
        simulation_id INTEGER,
        title TEXT,
        description TEXT,
        url TEXT,
        file_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        group_id INTEGER,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS profiles(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          role TEXT NOT NULL,
          group_id INTEGER,
          is_active INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS group_members');
      await db.execute('''
        CREATE TABLE group_members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER,
          student_name TEXT NOT NULL,
          joined_at TEXT,
          FOREIGN KEY (group_id) REFERENCES groups_table(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE simulations ADD COLUMN context TEXT');
      await db.execute('ALTER TABLE simulations ADD COLUMN objectives TEXT');
      await db.execute('ALTER TABLE simulations ADD COLUMN duration_days INTEGER DEFAULT 7');
      await db.execute('ALTER TABLE simulations ADD COLUMN max_groups INTEGER DEFAULT 5');
      await db.execute('ALTER TABLE simulations ADD COLUMN grading_criteria TEXT');
      await db.execute('ALTER TABLE simulations ADD COLUMN professor_name TEXT');
      await db.execute('ALTER TABLE simulations ADD COLUMN group_count INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE simulations ADD COLUMN submission_count INTEGER DEFAULT 0');
    }
  }

  // --- Generic CRUD Operations ---
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // --- Specific Caching Methods ---

  /// Simulations
  Future<void> cacheSimulation(Map<String, dynamic> sim) async {
    final db = await database;
    await db.insert('simulations', sim);
  }

  Future<List<Map<String, dynamic>>> getCachedSimulations() async {
    final db = await database;
    return await db.query('simulations');
  }

  Future<Map<String, dynamic>?> getCachedSimulation(String code) async {
    final db = await database;
    final results = await db.query('simulations', where: 'code = ?', whereArgs: [code]);
    return results.isNotEmpty ? results.first : null;
  }

  /// Submissions
  Future<void> cacheSubmission(Map<String, dynamic> sub) async {
    final db = await database;
    await db.insert('submissions', sub);
  }

  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    final db = await database;
    return await db.query('submissions', where: 'is_pending_sync = ?', whereArgs: [1]);
  }

  Future<void> markSubmissionAsSynced(int submissionId) async {
    final db = await database;
    await db.update(
      'submissions',
      {'is_pending_sync': 0},
      where: 'id = ?',
      whereArgs: [submissionId],
    );
  }

  /// Resources
  Future<void> cacheResource(Map<String, dynamic> resource) async {
    final db = await database;
    await db.insert('resources', resource);
  }

  Future<List<Map<String, dynamic>>> getCachedResources() async {
    final db = await database;
    return await db.query('resources');
  }

  /// Evaluations
  Future<void> cacheEvaluation(Map<String, dynamic> evaluation) async {
    final db = await database;
    await db.insert('evaluations', evaluation);
  }

  Future<List<Map<String, dynamic>>> getCachedEvaluations() async {
    final db = await database;
    return await db.query('evaluations');
  }

  // --- Additional utility methods if needed ---

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final db = await database;
    final results = await db.query('users', where: 'phone = ?', whereArgs: [phone]);
    return results.isNotEmpty ? results.first : null;
  }
}