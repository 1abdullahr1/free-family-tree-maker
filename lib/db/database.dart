import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/person.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('family.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE persons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      birthYear TEXT,
      parentId INTEGER
    )
    ''');
  }

  Future<Person> createPerson(Person p) async {
    final db = await instance.database;
    final id = await db.insert('persons', p.toMap());
    return p.copyWith(id: id);
  }

  Future<List<Person>> getAllPersons() async {
    final db = await instance.database;
    final res = await db.query('persons', orderBy: 'name COLLATE NOCASE');
    return res.map((m) => Person.fromMap(m)).toList();
  }

  Future<Person?> getPerson(int id) async {
    final db = await instance.database;
    final res = await db.query('persons', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Person.fromMap(res.first);
    return null;
  }

  Future<int> updatePerson(Person p) async {
    final db = await instance.database;
    return db.update('persons', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePerson(int id) async {
    final db = await instance.database;
    return db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
