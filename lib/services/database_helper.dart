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
      10; // Erhöht für lineare Positionsduplikat-Reparatur
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
        // ABER: Handhabe Duplikate intelligent!
        final existingData = await db.query(
          'grid_pictograms',
          orderBy: 'grid_id, position',
        );
        if (existingData.isNotEmpty) {
          if (kDebugMode) {
            print(
              '🔄 Migriere ${existingData.length} bestehende Piktogramm-Positionen...',
            );
          }

          // Gruppiere nach Grid-ID um pro Grid separat zu migrieren
          final Map<int, List<Map<String, dynamic>>> gridsData = {};
          for (var row in existingData) {
            final gridId = row['grid_id'] as int;
            if (!gridsData.containsKey(gridId)) {
              gridsData[gridId] = [];
            }
            gridsData[gridId]!.add(row);
          }

          // Migriere jedes Grid separat
          for (var gridId in gridsData.keys) {
            final gridPictograms = gridsData[gridId]!;

            // Hole die Grid-Größe für dieses Grid
            final gridData = await db.query(
              'grids',
              where: 'id = ?',
              whereArgs: [gridId],
            );
            int gridColumns = 4; // Default
            int gridRows = 2; // Default
            if (gridData.isNotEmpty) {
              gridColumns = gridData.first['grid_size'] as int? ?? 4;
              // Berechne Zeilen basierend auf verfügbaren Größen
              if (gridColumns == 8) {
                gridRows = 3;
              } else if (gridColumns == 4) {
                gridRows = 2;
              }
            }

            if (kDebugMode) {
              print(
                '🏗️ Migriere Grid $gridId ($gridColumns x $gridRows) mit ${gridPictograms.length} Piktogrammen',
              );
            }

            // Tracke bereits belegte Positionen
            final Set<String> usedPositions = {};

            for (int i = 0; i < gridPictograms.length; i++) {
              final row = gridPictograms[i];
              final pictogramId = row['pictogram_id'] as int;
              final linearPosition = row['position'] as int? ?? 0;

              // Berechne row/column aus linearer Position
              int migrationRow = linearPosition ~/ gridColumns;
              int migrationColumn = linearPosition % gridColumns;

              // WICHTIG: Prüfe ob Position bereits belegt ist
              String posKey = '${migrationRow}_$migrationColumn';
              if (usedPositions.contains(posKey)) {
                // Suche freie Position
                bool foundFree = false;
                for (int r = 0; r < gridRows && !foundFree; r++) {
                  for (int c = 0; c < gridColumns && !foundFree; c++) {
                    final String checkKey = '${r}_$c';
                    if (!usedPositions.contains(checkKey)) {
                      migrationRow = r;
                      migrationColumn = c;
                      posKey = checkKey;
                      foundFree = true;
                      if (kDebugMode) {
                        print(
                          '⚠️ Position ($posKey) war belegt, verwende freie Position ($r,$c)',
                        );
                      }
                    }
                  }
                }
              }

              // Markiere Position als belegt
              usedPositions.add(posKey);

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
                  '📍 Migriert: Grid$gridId Piktogramm$pictogramId: Position$linearPosition → ($migrationRow,$migrationColumn) [$gridColumns x $gridRows]',
                );
              }
            }
          }

          if (kDebugMode) {
            print(
              '✅ Migration abgeschlossen - alle Positionen als row/column gespeichert (Duplikate behoben)',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Version 7 Migration: $e');
        }
      }

      // 🛠️ REPARATUR: Behebe bereits migrierte Duplikate
      if (kDebugMode) {
        print('🔧 Überprüfe und repariere Positionsduplikate...');
      }
      try {
        await _repairDuplicatePositions(db);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Duplikat-Reparatur: $e');
        }
      }
    }

    // Version 8: Repariere bestehende Positionsduplikate
    if (oldVersion < 8) {
      if (kDebugMode) {
        print('🔧 DatabaseHelper: Repariere Positionsduplikate (Version 8)');
      }
      try {
        await _repairDuplicatePositions(db);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Version 8 Duplikat-Reparatur: $e');
        }
      }
    }

    // Version 9: Aggressive Positionsreparatur
    if (oldVersion < 9) {
      if (kDebugMode) {
        print('🔧 DatabaseHelper: Aggressive Positionsreparatur (Version 9)');
      }
      try {
        await _repairDuplicatePositions(db);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Version 9 Aggressive Reparatur: $e');
        }
      }
    }

    // Version 10: Lineare Positionsduplikat-Reparatur
    if (oldVersion < 10) {
      if (kDebugMode) {
        print(
          '🔧 DatabaseHelper: Lineare Positionsduplikat-Reparatur (Version 10)',
        );
      }
      try {
        await _repairDuplicatePositions(db);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Fehler bei Version 10 Lineare Duplikat-Reparatur: $e');
        }
      }
    }
  }

  /// Repariert Positionsduplikate in der Datenbank
  Future<void> _repairDuplicatePositions(Database db) async {
    if (kDebugMode) {
      print('🔍 Suche nach Positionsduplikaten...');
    }

    // Hole alle Piktogramme gruppiert nach Grid
    final allData = await db.query(
      'grid_pictograms',
      orderBy: 'grid_id, row_position, column_position',
    );

    if (kDebugMode) {
      print('📊 Debug: Alle Piktogramme in der Datenbank:');
      for (var row in allData) {
        print(
          '  Grid ${row['grid_id']}: Piktogramm ${row['pictogram_id']} (${row['keyword']}) → Position ${row['position']}, Row: ${row['row_position']}, Col: ${row['column_position']}',
        );
      }
    }

    // Gruppiere nach Grid-ID
    final Map<int, List<Map<String, dynamic>>> gridsData = {};
    for (var row in allData) {
      final gridId = row['grid_id'] as int;
      if (!gridsData.containsKey(gridId)) {
        gridsData[gridId] = [];
      }
      gridsData[gridId]!.add(row);
    }

    int totalFixed = 0;

    // Repariere jedes Grid einzeln
    for (var gridEntry in gridsData.entries) {
      final gridId = gridEntry.key;
      final pictograms = gridEntry.value;

      if (pictograms.isEmpty) continue;

      // Hole Grid-Größe
      final gridData = await db.query(
        'grids',
        where: 'id = ?',
        whereArgs: [gridId],
      );
      int gridColumns = 4;
      int gridRows = 2;
      if (gridData.isNotEmpty) {
        gridColumns = gridData.first['grid_size'] as int? ?? 4;
        if (gridColumns == 8) {
          gridRows = 3;
        } else if (gridColumns == 4) {
          gridRows = 2;
        }
      }

      if (kDebugMode) {
        print(
          '🔍 Prüfe Grid $gridId ($gridColumns x $gridRows) mit ${pictograms.length} Piktogrammen',
        );
      }

      // Suche Positionsduplikate
      final Map<String, List<Map<String, dynamic>>> positionGroups = {};
      for (var pictogram in pictograms) {
        final row = pictogram['row_position'] as int? ?? 0;
        final col = pictogram['column_position'] as int? ?? 0;
        final posKey = '${row}_$col';

        if (!positionGroups.containsKey(posKey)) {
          positionGroups[posKey] = [];
        }
        positionGroups[posKey]!.add(pictogram);
      }

      // Repariere Duplikate
      final Set<String> usedPositions = {};
      int gridFixed = 0;

      for (var entry in positionGroups.entries) {
        final posKey = entry.key;
        final group = entry.value;

        if (group.length > 1) {
          if (kDebugMode) {
            print(
              '🔧 Grid $gridId: ${group.length} Duplikate bei Position $posKey gefunden',
            );
          }

          // Erste behalten, Rest reparieren
          for (int i = 1; i < group.length; i++) {
            final pictogram = group[i];
            final pictogramId = pictogram['pictogram_id'] as int;

            // Finde freie Position
            bool foundFree = false;
            for (int r = 0; r < gridRows && !foundFree; r++) {
              for (int c = 0; c < gridColumns && !foundFree; c++) {
                final String newPosKey = '${r}_$c';
                if (!usedPositions.contains(newPosKey) &&
                    !positionGroups.containsKey(newPosKey)) {
                  // Update Position
                  await db.update(
                    'grid_pictograms',
                    {'row_position': r, 'column_position': c},
                    where: 'grid_id = ? AND pictogram_id = ?',
                    whereArgs: [gridId, pictogramId],
                  );

                  usedPositions.add(newPosKey);
                  foundFree = true;
                  gridFixed++;

                  if (kDebugMode) {
                    print(
                      '🔧 Grid$gridId Piktogramm$pictogramId → repariert zu ($r,$c)',
                    );
                  }
                }
              }
            }
          }
        } else {
          // Keine Duplikate - als belegt markieren
          usedPositions.add(posKey);
        }
      }

      totalFixed += gridFixed;
      if (gridFixed > 0 && kDebugMode) {
        print('✅ Grid $gridId: $gridFixed Positionen repariert');
      }
    }

    if (totalFixed > 0 && kDebugMode) {
      print('✅ Insgesamt $totalFixed doppelte Positionen repariert');
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
    int? targetRow,
    int? targetColumn,
  }) async {
    final db = await database;
    if (kDebugMode) {
      print(
        'DatabaseHelper: Füge Piktogramm ${pictogram.id} zu Grid $gridId hinzu',
      );
      print('DatabaseHelper: Piktogramm-Name: "${pictogram.keyword}"');
      if (targetRow != null && targetColumn != null) {
        print('DatabaseHelper: Ziel-Position: ($targetRow, $targetColumn)');
      }
    }

    // Prüfe ob bereits ein Eintrag mit diesem Piktogramm existiert
    final existing = await db.query(
      'grid_pictograms',
      where: 'grid_id = ? AND pictogram_id = ?',
      whereArgs: [gridId, pictogram.id],
    );

    if (existing.isNotEmpty && kDebugMode) {
      print(
        '⚠️ DatabaseHelper: Piktogramm ${pictogram.id} ist bereits in Grid $gridId!',
      );
      print('Bestehender Eintrag: ${existing.first}');
    }

    // Berechne row/column falls angegeben
    int? rowPosition;
    int? columnPosition;
    if (targetRow != null && targetColumn != null) {
      rowPosition = targetRow;
      columnPosition = targetColumn;
    }

    await db.insert('grid_pictograms', {
      'grid_id': gridId,
      'pictogram_id': pictogram.id,
      'position': position,
      'keyword': pictogram.keyword,
      'description': pictogram.description,
      'category': pictogram.category,
      'row_position': rowPosition ?? 0,
      'column_position': columnPosition ?? 0,
    });

    if (kDebugMode) {
      print('DatabaseHelper: Piktogramm erfolgreich in Datenbank eingefügt');
      if (rowPosition != null && columnPosition != null) {
        print(
          'DatabaseHelper: Mit row/column Position: ($rowPosition, $columnPosition)',
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getPictogramsInGrid(int gridId) async {
    final db = await database;
    if (kDebugMode) {
      print('DatabaseHelper: Lade Piktogramme für Grid $gridId');
    }

    // ✅ KEINE automatische Reparatur mehr - nur beim DB-Upgrade
    // Die Reparatur hat das Problem verursacht, nicht gelöst!

    final results = await db.query(
      'grid_pictograms',
      where: 'grid_id = ?',
      whereArgs: [gridId],
      orderBy: 'row_position, column_position',
    );

    if (kDebugMode) {
      print('DatabaseHelper: ${results.length} Piktogramme gefunden');
    }
    return results;
  }

  Future<void> removePictogramFromGrid(int gridId, int pictogramId) async {
    final db = await database;

    if (kDebugMode) {
      print('DatabaseHelper: Lösche Piktogramm $pictogramId aus Grid $gridId');
    }

    final deletedCount = await db.delete(
      'grid_pictograms',
      where: 'grid_id = ? AND pictogram_id = ?',
      whereArgs: [gridId, pictogramId],
    );

    if (kDebugMode) {
      print('DatabaseHelper: $deletedCount Einträge gelöscht');
      if (deletedCount == 0) {
        print('⚠️ DatabaseHelper: KEIN Eintrag gefunden zum Löschen!');
        // Debug: Zeige was in der Datenbank vorhanden ist
        final existing = await db.query(
          'grid_pictograms',
          where: 'grid_id = ?',
          whereArgs: [gridId],
        );
        print(
          'DatabaseHelper: Aktuelle Einträge in Grid $gridId: ${existing.length}',
        );
        for (var entry in existing) {
          print('  - Piktogramm ${entry['pictogram_id']}: ${entry['keyword']}');
        }
      } else {
        print('✅ DatabaseHelper: Piktogramm erfolgreich gelöscht');
      }
    }
  }

  // Aktualisiere die Position eines Piktogramms im Grid
  Future<void> updatePictogramPosition(
    int gridId,
    int pictogramId,
    int newPosition,
  ) async {
    final db = await database;
    await db.update(
      'grid_pictograms',
      {'position': newPosition},
      where: 'grid_id = ? AND pictogram_id = ?',
      whereArgs: [gridId, pictogramId],
    );
    if (kDebugMode) {
      print(
        'DatabaseHelper: Position von Piktogramm $pictogramId in Grid $gridId auf $newPosition aktualisiert',
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
      // ✅ NUR row/column updaten - NICHT die lineare Position!
      final updateData = <String, dynamic>{};

      // Speichere row/column falls vorhanden
      if (pictogramPos.containsKey('row') &&
          pictogramPos.containsKey('column')) {
        updateData['row_position'] = pictogramPos['row'];
        updateData['column_position'] = pictogramPos['column'];
      }

      // Nur updaten wenn es etwas zu updaten gibt
      if (updateData.isNotEmpty) {
        batch.update(
          'grid_pictograms',
          updateData,
          where: 'grid_id = ? AND pictogram_id = ?',
          whereArgs: [gridId, pictogramPos['pictogram_id']],
        );
      }
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

  // Neue Methode für erweiterte Positionssuche
  Future<List<Map<String, dynamic>>> getPictogramsForGridWithPositions(
    int gridId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT gp.*, p.keyword, p.description, p.filename
      FROM grid_pictograms gp
      LEFT JOIN pictograms p ON gp.pictogram_id = p.id
      WHERE gp.grid_id = ?
      ORDER BY gp.row_position, gp.column_position
    ''',
      [gridId],
    );

    if (kDebugMode) {
      print(
        'DatabaseHelper: Lade ${result.length} Piktogramme für Grid $gridId mit Positionen',
      );
    }

    return result;
  }
}
