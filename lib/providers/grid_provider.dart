import 'package:flutter/foundation.dart';
import 'package:picto_grid/models/pictogram.dart';
import 'package:picto_grid/services/database_helper.dart';
import 'package:picto_grid/services/local_pictogram_service.dart';

class GridProvider with ChangeNotifier {
  GridProvider();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocalPictogramService _localPictogramService =
      LocalPictogramService.instance;
  List<Map<String, dynamic>> _grids = [];
  int? _selectedGridId;
  List<Pictogram> _currentGridPictograms = [];
  List<Map<String, dynamic>> _currentGridPictogramData =
      []; // Speichere Original-Daten mit Position
  int? _currentProfileId;
  int _currentGridSize = 4; // Standard-Rastergröße bleibt 4x2

  List<Map<String, dynamic>> get grids => _grids;
  int? get selectedGridId => _selectedGridId;
  List<Pictogram> get currentGridPictograms =>
      List.from(_currentGridPictograms);
  List<Map<String, dynamic>> get currentGridPictogramData =>
      List.from(_currentGridPictogramData);
  int get currentGridSize => _currentGridSize;

  void setCurrentProfile(int? profileId) {
    if (kDebugMode) {
      print(
        'GridProvider: Setze Profil auf $profileId (vorher: $_currentProfileId)',
      );
    }

    _currentProfileId = profileId;
    _selectedGridId = null; // Wichtig: Grid-Auswahl zurücksetzen
    _currentGridPictograms = [];
    _currentGridPictogramData = [];

    // Lade Grids für neues Profil und wähle automatisch das erste aus
    loadGridsForCurrentProfile();
  }

  Future<void> loadGridsForCurrentProfile() async {
    if (kDebugMode) {
      print('GridProvider: Lade Grids für Profil $_currentProfileId');
    }

    if (_currentProfileId == null) {
      _grids = [];
      if (kDebugMode) {
        print('GridProvider: Kein Profil ausgewählt, leere Grid-Liste');
      }
    } else {
      _grids = await _db.getGridsForProfile(_currentProfileId!);

      if (kDebugMode) {
        print(
          'GridProvider: ${_grids.length} Grids für Profil $_currentProfileId gefunden',
        );
        for (var grid in _grids) {
          print('  - Grid ${grid['id']}: ${grid['name']}');
        }
      }

      // 🎯 Automatische Grid-Auswahl: Wähle das erste Grid automatisch aus
      // NUR wenn noch kein Grid ausgewählt ist oder das ausgewählte Grid nicht mehr existiert
      if (_grids.isNotEmpty) {
        final firstGridId = _grids.first['id'] as int;

        // Prüfe ob das aktuell ausgewählte Grid noch existiert
        final currentGridExists =
            _selectedGridId != null &&
            _grids.any((grid) => grid['id'] == _selectedGridId);

        if (_selectedGridId == null || !currentGridExists) {
          if (kDebugMode) {
            print(
              'GridProvider: Automatische Auswahl des ersten Grids: $firstGridId (aktuell: $_selectedGridId)',
            );
          }
          await selectGrid(firstGridId);
          return; // selectGrid() ruft bereits notifyListeners() auf
        } else {
          if (kDebugMode) {
            print(
              'GridProvider: Behalte aktuell ausgewähltes Grid: $_selectedGridId',
            );
          }
          // Grid ist bereits ausgewählt und existiert noch - lade nur die Daten neu
          await loadGridSize();
          await loadGridPictograms();
        }
      } else {
        if (kDebugMode) {
          print(
            'GridProvider: Keine Grids für Profil $_currentProfileId vorhanden',
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> createGrid(String name, [int gridSize = 4]) async {
    if (_currentProfileId == null) {
      throw Exception('Kein Profil ausgewählt');
    }

    if (kDebugMode) {
      print(
        '🔵 GridProvider: createGrid aufgerufen mit name="$name", gridSize=$gridSize',
      );
    }

    final id = await _db.createGrid(name, _currentProfileId!, gridSize);

    if (kDebugMode) {
      print('🔵 GridProvider: Grid erstellt mit ID $id');
    }

    // Lade Grids neu
    await loadGridsForCurrentProfile();

    // Wähle das neu erstellte Grid explizit aus
    _selectedGridId = id;

    if (kDebugMode) {
      print('🔵 GridProvider: Wähle neu erstelltes Grid $id aus');
    }

    // Lade Grid-Größe und Piktogramme für das neue Grid
    await loadGridSize();
    await loadGridPictograms();

    if (kDebugMode) {
      print(
        '🔵 GridProvider: Neues Grid vollständig geladen - Größe: $_currentGridSize',
      );
    }

    notifyListeners();
  }

  Future<void> selectGrid(int gridId) async {
    _selectedGridId = gridId;
    // WICHTIG: Lade zuerst die Grid-Größe, bevor die Piktogramme geladen werden!
    await loadGridSize();
    await loadGridPictograms();
    notifyListeners();
  }

  Future<void> loadGridPictograms() async {
    if (_selectedGridId == null) return;

    final pictograms = await _db.getPictogramsInGrid(_selectedGridId!);
    _currentGridPictograms = [];
    _currentGridPictogramData = [];

    // Erstelle eine Liste mit Piktogramm-Objekten und ihren Positionsdaten
    final List<Map<String, dynamic>> pictogramDataWithObjects = [];

    for (var p in pictograms) {
      final pictogramId = p['pictogram_id'] as int;
      final keyword = p['keyword'] as String? ?? 'Piktogramm $pictogramId';
      final position = p['position'] as int? ?? 0;

      if (kDebugMode) {
        print(
          'GridProvider: Lade Piktogramm $pictogramId ($keyword) - Position: $position, Row: ${p['row_position']}, Column: ${p['column_position']}',
        );
      }

      // 🔧 BUGFIX: Suche nach ID statt nach Name für exakte Übereinstimmung
      final localPictogramById = await _localPictogramService.getPictogramById(
        pictogramId,
      );

      if (localPictogramById != null) {
        if (kDebugMode) {
          print(
            '✅ Piktogramm per ID gefunden: "$keyword" (ID: $pictogramId) → ${localPictogramById.imageUrl} (Position: $position)',
          );
        }

        pictogramDataWithObjects.add({
          'pictogram': localPictogramById,
          'position': position,
          'original_data': p,
        });
      } else {
        // FALLBACK: Wenn ID nicht gefunden, versuche Name-basierte Suche
        if (kDebugMode) {
          print(
            '⚠️ Piktogramm mit ID $pictogramId nicht gefunden, versuche Name-basierte Suche für "$keyword"',
          );
        }

        final localPictogramByName = await _localPictogramService
            .getPictogramByName(keyword);

        if (localPictogramByName != null) {
          if (kDebugMode) {
            print(
              '✅ Piktogramm per Name gefunden: "$keyword" → ${localPictogramByName.imageUrl} (Position: $position)',
            );
          }

          pictogramDataWithObjects.add({
            'pictogram': localPictogramByName,
            'position': position,
            'original_data': p,
          });
        } else {
          // PIKTOGRAMM NICHT GEFUNDEN: Überspringe es (Offline-Modus)
          if (kDebugMode) {
            print(
              '❌ Piktogramm weder per ID noch per Name gefunden: "$keyword" (ID: $pictogramId)',
            );
          }
        }
      }
    }

    // Sortiere nach row/column falls verfügbar, ansonsten nach linearer Position
    pictogramDataWithObjects.sort((a, b) {
      final aData = a['original_data'] as Map<String, dynamic>;
      final bData = b['original_data'] as Map<String, dynamic>;

      // Wenn beide row/column haben, sortiere nach diesen
      if (aData.containsKey('row_position') &&
          aData.containsKey('column_position') &&
          bData.containsKey('row_position') &&
          bData.containsKey('column_position')) {
        final aRow = aData['row_position'] as int? ?? 0;
        final bRow = bData['row_position'] as int? ?? 0;
        final aCol = aData['column_position'] as int? ?? 0;
        final bCol = bData['column_position'] as int? ?? 0;

        // Sortiere erst nach Row, dann nach Column
        final rowComparison = aRow.compareTo(bRow);
        if (rowComparison != 0) return rowComparison;
        return aCol.compareTo(bCol);
      }

      // Fallback: Sortiere nach linearer Position
      return (a['position'] as int).compareTo(b['position'] as int);
    });

    // Extrahiere die sortierten Piktogramme und Daten
    for (var item in pictogramDataWithObjects) {
      _currentGridPictograms.add(item['pictogram'] as Pictogram);
      _currentGridPictogramData.add(
        item['original_data'] as Map<String, dynamic>,
      );
    }

    notifyListeners();
  }

  Future<void> addPictogramToGrid(
    Pictogram pictogram, {
    int? targetRow,
    int? targetCol,
  }) async {
    if (_selectedGridId == null) return;

    if (kDebugMode) {
      print('GridProvider: Füge Piktogramm zum Grid $_selectedGridId hinzu');
      if (targetRow != null && targetCol != null) {
        print('GridProvider: Zielposition: ($targetRow, $targetCol)');
      }
    }

    // Berechne die Zielposition
    final int targetPosition;
    if (targetRow != null && targetCol != null) {
      // Berechne lineare Position basierend auf Grid-Größe
      final columns = _currentGridSize;
      targetPosition = targetRow * columns + targetCol;

      if (kDebugMode) {
        print(
          'GridProvider: Berechnete Zielposition: $targetPosition (Grid-Größe: ${columns}x${_currentGridSize == 4 ? 2 : 3})',
        );
      }
    } else {
      // Fallback: Am Ende hinzufügen
      targetPosition = _currentGridPictograms.length;
    }

    await _db.addPictogramToGrid(
      _selectedGridId!,
      pictogram,
      targetPosition,
      rowPosition: targetRow,
      columnPosition: targetCol,
    );

    // Lade alle Piktogramme neu, um korrekte Sortierung zu gewährleisten
    await loadGridPictograms();

    if (kDebugMode) {
      print(
        'GridProvider: Piktogramme neu geladen, aktuelle Länge: ${_currentGridPictograms.length}',
      );
    }

    notifyListeners();
  }

  Future<void> removePictogramFromGrid(Pictogram pictogram) async {
    if (_selectedGridId == null) return;

    // Finde die korrekte DB-ID für dieses Piktogramm
    final pictogramIndex = _currentGridPictograms.indexWhere(
      (p) => p.id == pictogram.id,
    );
    if (pictogramIndex == -1) {
      if (kDebugMode) {
        print(
          '⚠️ GridProvider: Piktogramm ${pictogram.keyword} nicht im Grid gefunden',
        );
      }
      return;
    }

    final pictogramData = _currentGridPictogramData[pictogramIndex];
    final dbPictogramId = pictogramData['pictogram_id'] as int;

    if (kDebugMode) {
      print(
        'GridProvider: Lösche Piktogramm ${pictogram.keyword} (Piktogramm-ID: ${pictogram.id}, DB-ID: $dbPictogramId) aus Grid $_selectedGridId',
      );

      // Debug: Zeige alle Piktogramme in diesem Grid vor dem Löschen
      print('GridProvider: Vor Löschung - Piktogramme in Grid:');
      for (int i = 0; i < _currentGridPictograms.length; i++) {
        final p = _currentGridPictograms[i];
        final data = _currentGridPictogramData[i];
        print('  - ${p.keyword} (ID: ${p.id}, DB-ID: ${data['pictogram_id']})');
      }
    }

    // 🎯 VERWENDE DIE DB-ID, NICHT DIE PIKTOGRAMM-ID!
    await _db.removePictogramFromGrid(_selectedGridId!, dbPictogramId);

    // Entferne aus dem lokalen State
    _currentGridPictograms.removeAt(pictogramIndex);
    _currentGridPictogramData.removeAt(pictogramIndex);

    if (kDebugMode) {
      print(
        'GridProvider: Nach Löschung verbleiben ${_currentGridPictograms.length} Piktogramme',
      );

      // Debug: Zeige verbleibende Piktogramme
      print('GridProvider: Nach Löschung - Verbleibende Piktogramme:');
      for (int i = 0; i < _currentGridPictograms.length; i++) {
        final p = _currentGridPictograms[i];
        final data = _currentGridPictogramData[i];
        print('  - ${p.keyword} (ID: ${p.id}, DB-ID: ${data['pictogram_id']})');
      }
    }

    notifyListeners();
  }

  Future<void> deleteGrid(int gridId) async {
    await _db.deleteGrid(gridId);
    if (_selectedGridId == gridId) {
      _selectedGridId = null;
      _currentGridPictograms = [];
      _currentGridPictogramData = [];
      _currentGridSize = 4; // Zurück auf Standard
    }
    await loadGridsForCurrentProfile();
    notifyListeners();
  }

  Future<void> loadGridSize() async {
    if (_selectedGridId == null) {
      _currentGridSize = 4;
      if (kDebugMode) {
        print('GridProvider: Keine Grid-ID, verwende Standard-Größe 4');
      }
      return;
    }

    _currentGridSize = await _db.getGridSize(_selectedGridId!);
    if (kDebugMode) {
      print('GridProvider: Grid $_selectedGridId hat Größe $_currentGridSize');
    }
  }

  Future<void> updateGridSize(int gridSize) async {
    if (_selectedGridId == null) return;

    final oldGridSize = _currentGridSize;

    // 🔧 BUGFIX: Konvertiere bestehende Positionen bei Grid-Größen-Änderung
    if (oldGridSize != gridSize && _currentGridPictogramData.isNotEmpty) {
      if (kDebugMode) {
        print(
          'GridProvider: Konvertiere Positionen von ${oldGridSize}x? zu ${gridSize}x?',
        );
      }

      final updatedPositions = <Map<String, dynamic>>[];

      for (int i = 0; i < _currentGridPictogramData.length; i++) {
        final data = _currentGridPictogramData[i];
        final pictogramId = data['pictogram_id'] as int;
        final oldPosition = data['position'] as int? ?? i;

        // Berechne alte row/column basierend auf alter Grid-Größe
        final oldRow = oldPosition ~/ oldGridSize;
        final oldColumn = oldPosition % oldGridSize;

        // Bestimme neue Position basierend auf neuer Grid-Größe
        int newRow = oldRow;
        int newColumn = oldColumn;

        // Prüfe, ob Position im neuen Grid gültig ist
        final newGridRows = gridSize == 4
            ? 2
            : gridSize == 8
            ? 3
            : 2; // 2x2, 4x2, 8x3
        if (newColumn >= gridSize || newRow >= newGridRows) {
          // Position ist ungültig, verwende Index-basierte Fallback-Position
          newRow = i ~/ gridSize;
          newColumn = i % gridSize;

          if (kDebugMode) {
            print(
              'GridProvider: Position ($oldRow,$oldColumn) ungültig für ${gridSize}x$newGridRows, verwende Fallback ($newRow,$newColumn)',
            );
          }
        }

        final newPosition = newRow * gridSize + newColumn;

        updatedPositions.add({
          'pictogram_id': pictogramId,
          'position': newPosition,
          'row': newRow,
          'column': newColumn,
        });

        if (kDebugMode) {
          final keyword = (_currentGridPictograms.length > i)
              ? _currentGridPictograms[i].keyword
              : 'Piktogramm $pictogramId';
          print(
            'GridProvider: $keyword: Position$oldPosition ($oldRow,$oldColumn) → Position$newPosition ($newRow,$newColumn)',
          );
        }
      }

      // Speichere die konvertierten Positionen
      await _db.updateAllPictogramPositions(_selectedGridId!, updatedPositions);
    }

    await _db.updateGridSize(_selectedGridId!, gridSize);
    _currentGridSize = gridSize;

    // Lade Piktogramme neu mit korrigierten Positionen
    await loadGridPictograms();

    notifyListeners();
  }

  Future<void> savePictogramPositions(
    List<Map<String, dynamic>> pictogramPositions,
  ) async {
    if (_selectedGridId == null) return;

    await _db.updateAllPictogramPositions(_selectedGridId!, pictogramPositions);
    if (kDebugMode) {
      print('GridProvider: Positionen für Grid $_selectedGridId gespeichert');
    }
  }

  /// 🔧 DEBUG: Lösche alle Piktogramme aus der Datenbank
  Future<void> clearAllPictograms() async {
    await _db.clearAllPictograms();
    _currentGridPictograms = [];
    _currentGridPictogramData = [];
    notifyListeners();
    if (kDebugMode) {
      print('GridProvider: 🧹 Alle Piktogramme gelöscht');
    }
  }
}
