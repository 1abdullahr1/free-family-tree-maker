import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

class AppDatabase {
  AppDatabase({
    sqflite.DatabaseFactory? databaseFactory,
    Future<String> Function()? databasePathProvider,
  })  : _databaseFactory = databaseFactory ?? databaseFactoryDefault,
        _databasePathProvider = databasePathProvider ?? sqflite.getDatabasesPath;

  final sqflite.DatabaseFactory _databaseFactory;
  final Future<String> Function() _databasePathProvider;
  sqflite.Database? _database;

  Future<sqflite.Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final path = p.join(await _databasePathProvider(), 'family_tree_maker.db');
    final db = await _databaseFactory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: 2,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    _database = db;
    return db;
  }

  Future<void> _onConfigure(sqflite.Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE family_trees (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
        tree_id TEXT NOT NULL,
        given_name TEXT,
        middle_name TEXT,
        surname TEXT,
        nickname TEXT,
        gender TEXT,
        life_status TEXT NOT NULL DEFAULT 'unknown',
        birth_year INTEGER,
        birth_month INTEGER,
        birth_day INTEGER,
        birth_approximate INTEGER NOT NULL DEFAULT 0,
        birth_place TEXT,
        death_year INTEGER,
        death_month INTEGER,
        death_day INTEGER,
        death_approximate INTEGER NOT NULL DEFAULT 0,
        death_place TEXT,
        biography TEXT,
        notes TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(tree_id) REFERENCES family_trees(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE parent_child_relations (
        id TEXT PRIMARY KEY,
        tree_id TEXT NOT NULL,
        parent_person_id TEXT NOT NULL,
        child_person_id TEXT NOT NULL,
        parentage_type TEXT NOT NULL DEFAULT 'unknown',
        created_at TEXT NOT NULL,
        FOREIGN KEY(tree_id) REFERENCES family_trees(id) ON DELETE CASCADE,
        FOREIGN KEY(parent_person_id) REFERENCES persons(id) ON DELETE CASCADE,
        FOREIGN KEY(child_person_id) REFERENCES persons(id) ON DELETE CASCADE,
        UNIQUE(tree_id, parent_person_id, child_person_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_relations (
        id TEXT PRIMARY KEY,
        tree_id TEXT NOT NULL,
        person_a_id TEXT NOT NULL,
        person_b_id TEXT NOT NULL,
        partnership_type TEXT NOT NULL DEFAULT 'partner',
        status TEXT NOT NULL DEFAULT 'unknown',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(tree_id) REFERENCES family_trees(id) ON DELETE CASCADE,
        FOREIGN KEY(person_a_id) REFERENCES persons(id) ON DELETE CASCADE,
        FOREIGN KEY(person_b_id) REFERENCES persons(id) ON DELETE CASCADE,
        UNIQUE(tree_id, person_a_id, person_b_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_persons_tree_id ON persons(tree_id)');
    await db.execute('CREATE INDEX idx_family_trees_updated_at ON family_trees(updated_at)');
  }

  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE persons ADD COLUMN biography TEXT');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

final sqflite.DatabaseFactory databaseFactoryDefault = sqflite.databaseFactory;
