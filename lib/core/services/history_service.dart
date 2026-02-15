import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/history_item.dart';

class HistoryService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id TEXT PRIMARY KEY,
            toolName TEXT,
            toolId TEXT,
            fileName TEXT,
            fileSize INTEGER,
            timestamp TEXT,
            status TEXT,
            inputPath TEXT,
            outputPath TEXT,
            errorMessage TEXT
          )
        ''');
      },
    );
  }
  
  Future<void> saveHistory(HistoryItem item) async {
    final db = await database;
    await db.insert(
      'history',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<HistoryItem>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history', orderBy: 'timestamp DESC');
    
    return List.generate(maps.length, (i) {
      return HistoryItem.fromJson(maps[i]);
    });
  }
  
  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
  
  Future<void> deleteHistory(String id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}
