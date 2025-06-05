import 'package:flutter/foundation.dart';
import '../models/pictogram.dart';
import '../services/database_helper.dart';
import '../services/arasaac_service.dart';

class GridProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ArasaacService _arasaacService = ArasaacService();
  List<Map<String, dynamic>> _grids = [];
  int? _selectedGridId;
  List<Pictogram> _currentGridPictograms = [];

  GridProvider() {
    loadGrids();
  }

  List<Map<String, dynamic>> get grids => _grids;
  int? get selectedGridId => _selectedGridId;
  List<Pictogram> get currentGridPictograms => List.from(_currentGridPictograms);

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
    _currentGridPictograms = pictograms.map((p) {
      final pictogramId = p['pictogram_id'] as int;
      return Pictogram(
        id: pictogramId,
        keyword: p['keyword'] as String? ?? 'Piktogramm $pictogramId',
        imageUrl: _arasaacService.getPictogramUrl(pictogramId),
        description: p['description'] as String? ?? '',
        category: p['category'] as String? ?? 'Gespeichert',
      );
    }).toList();
    
    notifyListeners();
  }

  Future<void> addPictogramToGrid(Pictogram pictogram) async {
    if (_selectedGridId == null) return;

    print('GridProvider: Füge Piktogramm zum Grid ${_selectedGridId} hinzu');
    print('GridProvider: Aktuelle Piktogramme vor dem Hinzufügen: ${_currentGridPictograms.length}');

    await _db.addPictogramToGrid(
      _selectedGridId!,
      pictogram,
      _currentGridPictograms.length,
    );
    
    _currentGridPictograms.add(pictogram);
    print('GridProvider: Piktogramm zur Liste hinzugefügt, neue Länge: ${_currentGridPictograms.length}');
    
    await loadGridPictograms();  // Lade die Piktogramme neu von der Datenbank
    print('GridProvider: Piktogramme neu geladen, aktuelle Länge: ${_currentGridPictograms.length}');
    
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