import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'lab04_app.db';
  static const int _version = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        published INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // No-op for now. Add migration logic if needed in future.
  }

  // User CRUD operations

  static Future<User> createUser(CreateUserRequest request) async {
    final db = await database;
    final now = DateTime.now();
    final id = await db.insert(
      'users',
      {
        'name': request.name,
        'email': request.email,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
    );
    return User(
      id: id,
      name: request.name,
      email: request.email,
      createdAt: now,
      updatedAt: now,
    );
  }

  static Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  static Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at ASC');
    return maps.map((e) => User.fromJson(e)).toList();
  }

  static Future<User> updateUser(int id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await db.update('users', updates, where: 'id = ?', whereArgs: [id]);
    final user = await getUser(id);
    if (user == null) throw Exception('User not found');
    return user;
  }

  static Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getUserCount() async {
    final db = await database;
    final x = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(x) ?? 0;
  }

  static Future<List<User>> searchUsers(String query) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((e) => User.fromJson(e)).toList();
  }

  // Database utility methods

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('posts');
    await db.delete('users');
    // Optionally reset auto-increment (sqlite):
    await db.execute(
        'DELETE FROM sqlite_sequence WHERE name="users" OR name="posts";');
  }

  static Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }
}
