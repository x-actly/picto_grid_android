import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pictogram.dart';

class DatabaseHelper {
  static const String _databaseName = 'pictogrid.db';
  static const int _databaseVersion =
      4; // Version 4: Kompletter Neuaufbau für lokale Dateien

  // Singleton-Pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabelle für gespeicherte Grids
    await db.execute('''
      CREATE TABLE grids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Tabelle für Piktogramme in Grids
    await db.execute('''
      CREATE TABLE grid_pictograms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grid_id INTEGER,
        pictogram_id INTEGER,
        position INTEGER,
        keyword TEXT,
        description TEXT,
        category TEXT,
        FOREIGN KEY (grid_id) REFERENCES grids (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Backup der alten Daten
      final List<Map<String, dynamic>> oldData =
          await db.query('grid_pictograms');

      // Alte Tabelle löschen
      await db.execute('DROP TABLE grid_pictograms');

      // Neue Tabelle erstellen
      await db.execute('''
        CREATE TABLE grid_pictograms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          grid_id INTEGER,
          pictogram_id INTEGER,
          position INTEGER,
          keyword TEXT,
          description TEXT,
          category TEXT,
          FOREIGN KEY (grid_id) REFERENCES grids (id) ON DELETE CASCADE
        )
      ''');

      // Alte Daten wiederherstellen
      for (var row in oldData) {
        await db.insert('grid_pictograms', {
          'grid_id': row['grid_id'],
          'pictogram_id': row['pictogram_id'],
          'position': row['position'],
          'keyword': 'Piktogramm ${row['pictogram_id']}',
          'description': '',
          'category': 'Gespeichert',
        });
      }
    }

    if (oldVersion < 3) {
      // Version 3: Lösche alle gespeicherten Piktogramme wegen Dateinamen-Änderung
      print(
          'DatabaseHelper: Lösche alle Piktogramme wegen Dateinamen-Korrektur');
      await db.execute('DELETE FROM grid_pictograms');
    }

    if (oldVersion < 4) {
      // Version 4: Kompletter Neuaufbau - lösche alle ARASAAC-basierten Daten
      await db.execute('DELETE FROM grid_pictograms');
      print(
          '🔄 DatabaseHelper: Kompletter Neuaufbau - alle alten Piktogramme entfernt (Version 4)');
      print('💡 Ab jetzt werden nur noch lokale Dateien verwendet');
    }
  }

  // Grid-Operationen
  Future<int> createGrid(String name) async {
    final db = await database;
    return await db.insert('grids', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getAllGrids() async {
    final db = await database;
    return await db.query('grids');
  }

  // Piktogramm-Operationen
  Future<void> addPictogramToGrid(
      int gridId, Pictogram pictogram, int position) async {
    final db = await database;
    print(
        'DatabaseHelper: Füge Piktogramm ${pictogram.id} zu Grid $gridId hinzu');

    await db.insert('grid_pictograms', {
      'grid_id': gridId,
      'pictogram_id': pictogram.id,
      'position': position,
      'keyword': pictogram.keyword,
      'description': pictogram.description,
      'category': pictogram.category,
    });

    print('DatabaseHelper: Piktogramm erfolgreich in Datenbank eingefügt');
  }

  Future<List<Map<String, dynamic>>> getPictogramsInGrid(int gridId) async {
    final db = await database;
    print('DatabaseHelper: Lade Piktogramme für Grid $gridId');

    final results = await db.query(
      'grid_pictograms',
      where: 'grid_id = ?',
      whereArgs: [gridId],
      orderBy: 'position',
    );

    print('DatabaseHelper: ${results.length} Piktogramme gefunden');
    return results;
  }

  Future<void> removePictogramFromGrid(int gridId, int pictogramId) async {
    final db = await database;
    await db.delete(
      'grid_pictograms',
      where: 'grid_id = ? AND pictogram_id = ?',
      whereArgs: [gridId, pictogramId],
    );
  }

  // Grid löschen
  Future<void> deleteGrid(int gridId) async {
    final db = await database;
    await db.delete(
      'grids',
      where: 'id = ?',
      whereArgs: [gridId],
    );
  }
}
