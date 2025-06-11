import 'package:flutter/foundation.dart';
import '../models/pictogram.dart';
import '../services/database_helper.dart';
import '../services/local_pictogram_service.dart';

class GridProvider with ChangeNotifier {

  GridProvider() {
    loadGrids();
  }
  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocalPictogramService _localPictogramService =
      LocalPictogramService.instance;
  List<Map<String, dynamic>> _grids = [];
  int? _selectedGridId;
  List<Pictogram> _currentGridPictograms = [];

  List<Map<String, dynamic>> get grids => _grids;
  int? get selectedGridId => _selectedGridId;
  List<Pictogram> get currentGridPictograms =>
      List.from(_currentGridPictograms);

  Future<void> loadGrids() async {
    _grids = await _db.getAllGrids();
    notifyListeners();
  }

  Future<void> createGrid(String name) async {
    final id = await _db.createGrid(name);
    _grids = await _db.getAllGrids();
    _selectedGridId = id;
    _currentGridPictograms = [];
    notifyListeners();
  }

  Future<void> selectGrid(int gridId) async {
    _selectedGridId = gridId;
    await loadGridPictograms();
    notifyListeners();
  }

  Future<void> loadGridPictograms() async {
    if (_selectedGridId == null) return;

    final pictograms = await _db.getPictogramsInGrid(_selectedGridId!);
    _currentGridPictograms = [];

    for (var p in pictograms) {
      final pictogramId = p['pictogram_id'] as int;

      final keyword = p['keyword'] as String? ?? 'Piktogramm $pictogramId';

      // NUR NAMENSBASIERTE SUCHE (komplett offline)
      final localPictogramByName =
          await _localPictogramService.getPictogramByName(keyword);

      if (localPictogramByName != null) {
        if (kDebugMode) {
          print(
            '✅ Piktogramm gefunden: "$keyword" → ${localPictogramByName.imageUrl}');
        }
        _currentGridPictograms.add(localPictogramByName);
      } else {
        // PIKTOGRAMM NICHT GEFUNDEN: Überspringe es (Offline-Modus)
        if (kDebugMode) {
          print('❌ Piktogramm nicht gefunden (offline): "$keyword"');
        }
        // Füge das Piktogramm NICHT hinzu - es wird einfach nicht angezeigt
      }
    }

    notifyListeners();
  }

  Future<void> addPictogramToGrid(Pictogram pictogram) async {
    if (_selectedGridId == null) return;

    if (kDebugMode) {
      print('GridProvider: Füge Piktogramm zum Grid $_selectedGridId hinzu');
    }
    if (kDebugMode) {
      print(
        'GridProvider: Aktuelle Piktogramme vor dem Hinzufügen: ${_currentGridPictograms.length}');
    }

    await _db.addPictogramToGrid(
      _selectedGridId!,
      pictogram,
      _currentGridPictograms.length,
    );

    _currentGridPictograms.add(pictogram);
    if (kDebugMode) {
      print(
        'GridProvider: Piktogramm zur Liste hinzugefügt, neue Länge: ${_currentGridPictograms.length}');
    }

    await loadGridPictograms(); // Lade die Piktogramme neu von der Datenbank
    if (kDebugMode) {
      print(
        'GridProvider: Piktogramme neu geladen, aktuelle Länge: ${_currentGridPictograms.length}');
    }

    notifyListeners();
  }

  Future<void> removePictogramFromGrid(Pictogram pictogram) async {
    if (_selectedGridId == null) return;

    await _db.removePictogramFromGrid(_selectedGridId!, pictogram.id);
    _currentGridPictograms.removeWhere((p) => p.id == pictogram.id);
    notifyListeners();
  }

  Future<void> deleteGrid(int gridId) async {
    await _db.deleteGrid(gridId);
    if (_selectedGridId == gridId) {
      _selectedGridId = null;
      _currentGridPictograms = [];
    }
    await loadGrids();
    notifyListeners();
  }
}
