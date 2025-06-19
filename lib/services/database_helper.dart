import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:picto_grid/models/pictogram.dart';

class DatabaseHelper {
  // Version 6: Grid-Size pro Grid hinzugefügt

  // Singleton-Pattern
  DatabaseHelper._privateConstructor();
  static const String _databaseName = 'pictogrid.db';
  static const int _databaseVersion =
      8; // Erhöht für Piktogramm-Reset (ID-Konsistenz-Fix)
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

  // Hilfsfunktion: Prüft, ob eine Tabelle existiert
  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Fehler beim Prüfen der Tabelle $tableName: $e');
      }
      return false;
    }
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

    // Tabelle für gespeicherte Grids (mit Profil-Referenz und grid_size)
    await db.execute('''
      CREATE TABLE grids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        grid_size INTEGER DEFAULT 4,
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
        row_position INTEGER DEFAULT 0,
        column_position INTEGER DEFAULT 0,
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
      final List<Map<String, dynamic>> oldData = await db.query(
        'grid_pictograms',
      );

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
          'DatabaseHelper: Lösche alle Piktogramme wegen Dateinamen-Korrektur',
        );
      }
      await db.execute('DELETE FROM grid_pictograms');
    }

    if (oldVersion < 4) {
      // Version 4: Kompletter Neuaufbau - lösche alle ARASAAC-basierten Daten
      await db.execute('DELETE FROM grid_pictograms');
      if (kDebugMode) {
        print(
          '🔄 DatabaseHelper: Kompletter Neuaufbau - alle alten Piktogramme entfernt (Version 4)',
        );
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

      // Prüfe, ob Profile-Tabelle bereits existiert
      final profilesExists = await _tableExists(db, 'profiles');

      int standardProfileId;
      if (!profilesExists) {
        // Erstelle Profile-Tabelle nur wenn sie nicht existiert
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Erstelle Standard-Profil
        standardProfileId = await db.insert('profiles', {
          'name': 'Standard-Profil',
        });
        if (kDebugMode) {
          print('✅ Profile-Tabelle erstellt und Standard-Profil angelegt');
        }
      } else {
        // Profile-Tabelle existiert bereits, finde Standard-Profil oder erstelle es
        final existingProfiles = await db.query(
          'profiles',
          where: 'name = ?',
          whereArgs: ['Standard-Profil'],
        );
        if (existingProfiles.isNotEmpty) {
          standardProfileId = existingProfiles.first['id'] as int;
          if (kDebugMode) {
            print(
              '✅ Standard-Profil bereits vorhanden (ID: $standardProfileId)',
            );
          }
        } else {
          standardProfileId = await db.insert('profiles', {
            'name': 'Standard-Profil',
          });
          if (kDebugMode) {
            print('✅ Standard-Profil erstellt (ID: $standardProfileId)');
          }
        }
      }

      // Sichere bestehende Grids (falls vorhanden)
      List<Map<String, dynamic>> existingGrids = [];
      try {
        existingGrids = await db.query('grids');
      } catch (e) {
        if (kDebugMode) {
          print(
            'ℹ️ Keine bestehenden Grids gefunden oder Tabelle existiert nicht: $e',
          );
        }
      }

      // Prüfe, ob die Grids-Tabelle bereits die neue Struktur hat
      bool gridsNeedUpdate = false;
      try {
        await db.rawQuery('SELECT profile_id FROM grids LIMIT 1');
        if (kDebugMode) {
          print('✅ Grids-Tabelle hat bereits die neue Struktur');
        }
      } catch (e) {
        gridsNeedUpdate = true;
        if (kDebugMode) {
          print('🔄 Grids-Tabelle muss aktualisiert werden');
        }
      }

      if (gridsNeedUpdate) {
        // Lösche alte Grids-Tabelle
        await db.execute('DROP TABLE IF EXISTS grids');

        // Erstelle neue Grids-Tabelle mit Profil-Referenz
        await db.execute('''
          CREATE TABLE grids (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            grid_size INTEGER DEFAULT 4,
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
          print(
            '✅ DatabaseHelper: ${existingGrids.length} Grids zum Standard-Profil migriert',
          );
        }
      }
    }

    if (oldVersion < 6) {
      // Version 6: Grid-Size pro Grid hinzufügen
      if (kDebugMode) {
        print(
          '🏗️ DatabaseHelper: Erweitere Datenbank um Grid-Size (Version 6)',
        );
      }

      // Prüfe, ob die Grids-Tabelle bereits die grid_size Spalte hat
      bool gridSizeExists = false;
      try {
        await db.rawQuery('SELECT grid_size FROM grids LIMIT 1');
        gridSizeExists = true;
        if (kDebugMode) {
          print('✅ grid_size Spalte existiert bereits');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔄 grid_size Spalte muss hinzugefügt werden');
        }
      }

      if (!gridSizeExists) {
        // Füge grid_size Spalte zur bestehenden Tabelle hinzu
        try {
          await db.execute(
            'ALTER TABLE grids ADD COLUMN grid_size INTEGER DEFAULT 4',
          );
          if (kDebugMode) {
            print('✅ grid_size Spalte erfolgreich hinzugefügt');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Fehler beim Hinzufügen der grid_size Spalte: $e');
          }
        }
      }
    }

    // Version 7: Füge row_position und column_position Spalten hinzu
    if (oldVersion < 7) {
      if (kDebugMode) {
        print(
          '🏗️ DatabaseHelper: Erweitere Datenbank um row/column Positionen (Version 7)',
        );
      }

      try {
        await db.execute(
          'ALTER TABLE grid_pictograms ADD COLUMN row_position INTEGER DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE grid_pictograms ADD COLUMN column_position INTEGER DEFAULT 0',
        );
        if (kDebugMode) {
          print(
            '✅ row_position und column_position Spalten erfolgreich hinzugefügt',
          );
        }

        // 🎯 MIGRIERE BESTEHENDE DATEN: Konvertiere lineare Positionen zu row/column
        final existingData = await db.query('grid_pictograms');
        if (existingData.isNotEmpty) {
          if (kDebugMode) {
            print(
              '🔄 Migriere ${existingData.length} bestehende Piktogramm-Positionen...',
            );
          }

          for (var row in existingData) {
            final gridId = row['grid_id'] as int;
            final pictogramId = row['pictogram_id'] as int;
            final linearPosition = row['position'] as int? ?? 0;

            // Hole die Grid-Größe für dieses Grid
            final gridData = await db.query(
              'grids',
              where: 'id = ?',
              whereArgs: [gridId],
            );
            int gridColumns = 4; // Default
            if (gridData.isNotEmpty) {
              gridColumns = gridData.first['grid_size'] as int? ?? 4;
            }

            // Berechne row/column aus linearer Position
            final migrationRow = linearPosition ~/ gridColumns;
            final migrationColumn = linearPosition % gridColumns;

            // Update das Piktogramm mit den berechneten row/column Werten
            await db.update(
              'grid_pictograms',
              {
                'row_position': migrationRow,
                'column_position': migrationColumn,
              },
              where: 'grid_id = ? AND pictogram_id = ?',
              whereArgs: [gridId, pictogramId],
            );

            if (kDebugMode) {
              print(
                '📍 Migriert: Grid$gridId Piktogramm$pictogramId: Position$linearPosition → ($migrationRow,$migrationColumn) [${gridColumns}x]',
              );
            }
          }

          if (kDebugMode) {
            print(
              '✅ Migration abgeschlossen - alle Positionen als row/column gespeichert',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Version 7 Migration: $e');
        }
      }
    }

    // Version 8: Lösche alle Piktogramme wegen ID-Konsistenz-Problemen
    if (oldVersion < 8) {
      if (kDebugMode) {
        print(
          '🧹 DatabaseHelper: Lösche alle Piktogramme wegen ID-Konsistenz (Version 8)',
        );
      }

      try {
        // Lösche alle bestehenden Piktogramme
        await db.execute('DELETE FROM grid_pictograms');

        if (kDebugMode) {
          print(
            '✅ Alle Piktogramme gelöscht - sauberer Neustart für ID-Konsistenz',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Version 8 Migration: $e');
        }
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
      'grid_size': 4, // Standard-Grid-Größe
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
    int gridId,
    Pictogram pictogram,
    int position, {
    int? rowPosition,
    int? columnPosition,
  }) async {
    final db = await database;
    if (kDebugMode) {
      print(
        'DatabaseHelper: Füge Piktogramm ${pictogram.id} zu Grid $gridId an Position $position hinzu',
      );
      if (rowPosition != null && columnPosition != null) {
        print('DatabaseHelper: Mit Row/Column: ($rowPosition,$columnPosition)');
      }
    }

    final insertData = {
      'grid_id': gridId,
      'pictogram_id': pictogram.id,
      'position': position,
      'keyword': pictogram.keyword,
      'description': pictogram.description,
      'category': pictogram.category,
    };

    // 🔧 Füge row/column Positionen hinzu, falls angegeben
    if (rowPosition != null && columnPosition != null) {
      insertData['row_position'] = rowPosition;
      insertData['column_position'] = columnPosition;
    }

    await db.insert('grid_pictograms', insertData);

    if (kDebugMode) {
      final rowColInfo = (rowPosition != null && columnPosition != null)
          ? ' → ($rowPosition,$columnPosition)'
          : '';
      print(
        'DatabaseHelper: Piktogramm erfolgreich eingefügt an Position $position$rowColInfo',
      );
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

  /// 🔧 RESET: Lösche alle Piktogramme aus allen Grids
  Future<void> clearAllPictograms() async {
    final db = await database;
    await db.delete('grid_pictograms');
    if (kDebugMode) {
      print('DatabaseHelper: 🧹 Alle Piktogramme aus der Datenbank gelöscht');
    }
  }

  // Aktualisiere die Position eines Piktogramms im Grid
  Future<void> updatePictogramPosition(
    int gridId,
    int pictogramId,
    int newPosition, {
    int? rowPosition,
    int? columnPosition,
  }) async {
    final db = await database;

    final updateData = {'position': newPosition};

    // 🔧 Füge row/column Positionen hinzu, falls angegeben
    if (rowPosition != null && columnPosition != null) {
      updateData['row_position'] = rowPosition;
      updateData['column_position'] = columnPosition;
    }

    await db.update(
      'grid_pictograms',
      updateData,
      where: 'grid_id = ? AND pictogram_id = ?',
      whereArgs: [gridId, pictogramId],
    );

    if (kDebugMode) {
      final rowColInfo = (rowPosition != null && columnPosition != null)
          ? ' → ($rowPosition,$columnPosition)'
          : '';
      print(
        'DatabaseHelper: Position von Piktogramm $pictogramId in Grid $gridId auf $newPosition$rowColInfo aktualisiert',
      );
    }
  }

  // Aktualisiere alle Positionen in einem Grid basierend auf einer Liste von Piktogrammen
  Future<void> updateAllPictogramPositions(
    int gridId,
    List<Map<String, dynamic>> pictogramPositions,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (var pictogramPos in pictogramPositions) {
      final updateData = {'position': pictogramPos['position']};

      // Speichere auch row/column direkt, falls vorhanden
      if (pictogramPos.containsKey('row') &&
          pictogramPos.containsKey('column')) {
        updateData['row_position'] = pictogramPos['row'];
        updateData['column_position'] = pictogramPos['column'];
      }

      batch.update(
        'grid_pictograms',
        updateData,
        where: 'grid_id = ? AND pictogram_id = ?',
        whereArgs: [gridId, pictogramPos['pictogram_id']],
      );
    }

    await batch.commit();
    if (kDebugMode) {
      print(
        'DatabaseHelper: ${pictogramPositions.length} Piktogramm-Positionen in Grid $gridId aktualisiert',
      );
    }
  }

  // Grid löschen
  Future<void> deleteGrid(int gridId) async {
    final db = await database;
    await db.delete('grids', where: 'id = ?', whereArgs: [gridId]);
  }

  // Grid-Size Operationen
  Future<void> updateGridSize(int gridId, int gridSize) async {
    final db = await database;
    await db.update(
      'grids',
      {'grid_size': gridSize},
      where: 'id = ?',
      whereArgs: [gridId],
    );
    if (kDebugMode) {
      print('DatabaseHelper: Grid-Size für Grid $gridId auf $gridSize gesetzt');
    }
  }

  Future<int> getGridSize(int gridId) async {
    final db = await database;
    final result = await db.query(
      'grids',
      columns: ['grid_size'],
      where: 'id = ?',
      whereArgs: [gridId],
    );

    if (result.isNotEmpty) {
      final gridSize = result.first['grid_size'] as int? ?? 4;
      if (kDebugMode) {
        print('DatabaseHelper: Grid-Size für Grid $gridId ist $gridSize');
      }
      return gridSize;
    }

    if (kDebugMode) {
      print(
        'DatabaseHelper: Grid $gridId nicht gefunden, verwende Standard-Size 4',
      );
    }
    return 4; // Standard-Wert
  }
}
