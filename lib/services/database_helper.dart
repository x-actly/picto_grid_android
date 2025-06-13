import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:picto_grid/models/pictogram.dart';

class DatabaseHelper { // Version 5: Profile-System hinzugefügt

  // Singleton-Pattern
  DatabaseHelper._privateConstructor();
  static const String _databaseName = 'pictogrid.db';
  static const int _databaseVersion =
      5;
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
    // Tabelle für Profile
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabelle für gespeicherte Grids (mit Profil-Referenz)
    await db.execute('''
      CREATE TABLE grids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
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

    // Standard-Profil erstellen
    await db.insert('profiles', {'name': 'Standard-Profil'});
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
      if (kDebugMode) {
        print(
          'DatabaseHelper: Lösche alle Piktogramme wegen Dateinamen-Korrektur');
      }
      await db.execute('DELETE FROM grid_pictograms');
    }

    if (oldVersion < 4) {
      // Version 4: Kompletter Neuaufbau - lösche alle ARASAAC-basierten Daten
      await db.execute('DELETE FROM grid_pictograms');
      if (kDebugMode) {
        print(
          '🔄 DatabaseHelper: Kompletter Neuaufbau - alle alten Piktogramme entfernt (Version 4)');
      }
      if (kDebugMode) {
        print('💡 Ab jetzt werden nur noch lokale Dateien verwendet');
      }
    }

    if (oldVersion < 5) {
      // Version 5: Profile-System hinzufügen
      if (kDebugMode) {
        print('🏗️ DatabaseHelper: Erweitere Datenbank um Profile (Version 5)');
      }

      // Erstelle Profile-Tabelle
      await db.execute('''
        CREATE TABLE profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Erstelle Standard-Profil
      final standardProfileId = await db.insert('profiles', {'name': 'Standard-Profil'});

      // Sichere bestehende Grids
      final existingGrids = await db.query('grids');

      // Lösche alte Grids-Tabelle
      await db.execute('DROP TABLE grids');

      // Erstelle neue Grids-Tabelle mit Profil-Referenz
      await db.execute('''
        CREATE TABLE grids (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          profile_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
        )
      ''');

      // Migriere alte Grids zum Standard-Profil
      for (var grid in existingGrids) {
        await db.insert('grids', {
          'profile_id': standardProfileId,
          'name': grid['name'],
        });
      }

      if (kDebugMode) {
        print('✅ DatabaseHelper: ${existingGrids.length} Grids zum Standard-Profil migriert');
      }
    }
  }

  // Profil-Operationen
  Future<int> createProfile(String name) async {
    final db = await database;
    return await db.insert('profiles', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final db = await database;
    return await db.query('profiles', orderBy: 'created_at ASC');
  }

  Future<void> deleteProfile(int profileId) async {
    final db = await database;
    // Lösche Profil (Grids werden automatisch durch CASCADE gelöscht)
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
  }

  Future<int> getGridCountForProfile(int profileId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM grids WHERE profile_id = ?',
      [profileId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // Grid-Operationen (erweitert mit Profil-ID)
  Future<int> createGrid(String name, int profileId) async {
    final db = await database;

    // Prüfe ob das Profil bereits 3 Grids hat
    final gridCount = await getGridCountForProfile(profileId);
    if (gridCount >= 3) {
      throw Exception('Profil kann maximal 3 Grids haben');
    }

    return await db.insert('grids', {
      'name': name,
      'profile_id': profileId,
    });
  }

  Future<List<Map<String, dynamic>>> getAllGrids() async {
    final db = await database;
    return await db.query('grids', orderBy: 'created_at ASC');
  }

  Future<List<Map<String, dynamic>>> getGridsForProfile(int profileId) async {
    final db = await database;
    return await db.query(
      'grids',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'created_at ASC',
    );
  }

  // Piktogramm-Operationen
  Future<void> addPictogramToGrid(
      int gridId, Pictogram pictogram, int position) async {
    final db = await database;
    if (kDebugMode) {
      print(
        'DatabaseHelper: Füge Piktogramm ${pictogram.id} zu Grid $gridId hinzu');
    }

    await db.insert('grid_pictograms', {
      'grid_id': gridId,
      'pictogram_id': pictogram.id,
      'position': position,
      'keyword': pictogram.keyword,
      'description': pictogram.description,
      'category': pictogram.category,
    });

    if (kDebugMode) {
      print('DatabaseHelper: Piktogramm erfolgreich in Datenbank eingefügt');
    }
  }

  Future<List<Map<String, dynamic>>> getPictogramsInGrid(int gridId) async {
    final db = await database;
    if (kDebugMode) {
      print('DatabaseHelper: Lade Piktogramme für Grid $gridId');
    }

    final results = await db.query(
      'grid_pictograms',
      where: 'grid_id = ?',
      whereArgs: [gridId],
      orderBy: 'position',
    );

    if (kDebugMode) {
      print('DatabaseHelper: ${results.length} Piktogramme gefunden');
    }
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
