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
  int _currentGridSize = 4; // Standard-Rastergröße

  List<Map<String, dynamic>> get grids => _grids;
  int? get selectedGridId => _selectedGridId;
  List<Pictogram> get currentGridPictograms =>
      List.from(_currentGridPictograms);
  List<Map<String, dynamic>> get currentGridPictogramData =>
      List.from(_currentGridPictogramData);
  int get currentGridSize => _currentGridSize;

  void setCurrentProfile(int? profileId) {
    _currentProfileId = profileId;
    _selectedGridId = null;
    _currentGridPictograms = [];
    _currentGridPictogramData = [];
    loadGridsForCurrentProfile();
  }

  Future<void> loadGridsForCurrentProfile() async {
    if (_currentProfileId == null) {
      _grids = [];
    } else {
      _grids = await _db.getGridsForProfile(_currentProfileId!);
    }
    notifyListeners();
  }

  Future<void> createGrid(String name) async {
    if (_currentProfileId == null) {
      throw Exception('Kein Profil ausgewählt');
    }

    final id = await _db.createGrid(name, _currentProfileId!);
    await loadGridsForCurrentProfile();
    _selectedGridId = id;
    _currentGridPictograms = [];
    _currentGridPictogramData = [];
    notifyListeners();
  }

  Future<void> selectGrid(int gridId) async {
    _selectedGridId = gridId;
    await loadGridPictograms();
    await loadGridSize();
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

    // Sortiere nach Position
    pictogramDataWithObjects.sort(
      (a, b) => (a['position'] as int).compareTo(b['position'] as int),
    );

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

    await _db.removePictogramFromGrid(_selectedGridId!, pictogram.id);
    _currentGridPictograms.removeWhere((p) => p.id == pictogram.id);
    _currentGridPictogramData.removeWhere(
      (data) => data['pictogram_id'] == pictogram.id,
    );
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
      return;
    }

    _currentGridSize = await _db.getGridSize(_selectedGridId!);
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
        final newGridRows = gridSize == 4 ? 2 : 3;
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
