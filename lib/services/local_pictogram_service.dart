import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:picto_grid/models/pictogram.dart';
import 'package:picto_grid/services/custom_pictogram_service.dart';

class LocalPictogramService {

  LocalPictogramService._internal();
  static LocalPictogramService? _instance;
  static LocalPictogramService get instance {
    _instance ??= LocalPictogramService._internal();
    return _instance!;
  }

  List<Map<String, dynamic>>? _pictogramData;
  bool _isInitialized = false;

  /// Initialisiert den Service und lädt die Piktogramm-Daten
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/pictograms.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      _pictogramData = jsonData.cast<Map<String, dynamic>>();
      _isInitialized = true;
      if (kDebugMode) {
        print(
          'Lokale Piktogramm-Daten geladen: ${_pictogramData!.length} Einträge');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Laden der lokalen Piktogramm-Daten: $e');
      }
      _pictogramData = [];
      _isInitialized = true;
    }
  }

  /// Sucht nach Piktogrammen basierend auf einem Suchbegriff
  Future<List<Pictogram>> searchPictograms(String keyword) async {
    await initialize();

    // NEUE LOGIK: Suche in verfügbaren Dateien statt in JSON
    final availableFiles = await _loadAvailableFiles();

    if (availableFiles.isEmpty) {
      if (kDebugMode) {
        print('Keine lokalen Dateien verfügbar');
      }
      return [];
    }

    final String searchTerm = keyword.toLowerCase().trim();
    if (searchTerm.isEmpty) {
      return [];
    }

    final List<Pictogram> results = [];

    // Durchsuche alle verfügbaren Dateien
    for (var filename in availableFiles) {
      final nameFromFile = filename.split('_')[0].toLowerCase();
      final match = RegExp(r'_(\d+)\.png$').firstMatch(filename);
      final int fileId = match != null ? int.parse(match.group(1)!) : 0;

      bool matchFound = false;

      // 1. Exakte Übereinstimmung
      if (nameFromFile == searchTerm) {
        matchFound = true;
      }
      // 2. Beginnt mit Suchbegriff
      else if (nameFromFile.startsWith(searchTerm)) {
        matchFound = true;
      }
      // 3. Enthält Suchbegriff
      else if (nameFromFile.contains(searchTerm)) {
        matchFound = true;
      }
      // 4. Synonym-basierte Suche
      else if (_isSimilarName(searchTerm, nameFromFile)) {
        matchFound = true;
      }

      if (matchFound) {
        results.add(Pictogram(
          id: fileId,
          keyword: filename.split('_')[0], // Echter Dateiname
          imageUrl: getLocalImagePath(filename),
          description: 'Lokal verfügbare Datei: $filename',
          category: 'Lokal',
        ));
      }
    }

    // Sortiere Ergebnisse nach Relevanz
    results.sort((a, b) {
      final aLower = a.keyword.toLowerCase();
      final bLower = b.keyword.toLowerCase();

      // Exakte Treffer zuerst
      if (aLower == searchTerm && bLower != searchTerm) return -1;
      if (bLower == searchTerm && aLower != searchTerm) return 1;

      // Dann Treffer die mit dem Suchbegriff beginnen
      if (aLower.startsWith(searchTerm) && !bLower.startsWith(searchTerm)) {
        return -1;
      }
      if (bLower.startsWith(searchTerm) && !aLower.startsWith(searchTerm)) {
        return 1;
      }

      // Dann alphabetisch sortieren
      return aLower.compareTo(bLower);
    });

    // Begrenze die Anzahl der Ergebnisse für bessere Performance
    final limitedResults = results.take(50).toList();

    if (kDebugMode) {
      print(
        'Lokale Suche für "$keyword": ${limitedResults.length} von ${results.length} Ergebnissen angezeigt');
    }
    return limitedResults;
  }

  /// Gibt alle verfügbaren Piktogramme zurück (basierend auf echten Dateien)
  Future<List<Pictogram>> getAllPictograms() async {
    await initialize();
    final availableFiles = await _loadAvailableFiles();

    if (availableFiles.isEmpty) {
      return [];
    }

    return availableFiles.map((filename) {
      final match = RegExp(r'_(\d+)\.png$').firstMatch(filename);
      final int fileId = match != null ? int.parse(match.group(1)!) : 0;
      final nameFromFile = filename.split('_')[0];

      return Pictogram(
        id: fileId,
        keyword: nameFromFile,
        imageUrl: getLocalImagePath(filename),
        description: 'Lokal verfügbare Datei: $filename',
        category: 'Lokal',
      );
    }).toList();
  }

  /// Gibt alle verfügbaren Kategorien zurück
  Future<List<String>> getCategories() async {
    await initialize();

    if (_pictogramData == null || _pictogramData!.isEmpty) {
      return [];
    }

    final Set<String> categories = {};
    for (var data in _pictogramData!) {
      final String category = data['category'] ?? 'Allgemein';
      categories.add(category);
    }

    return categories.toList()..sort();
  }

  /// Sucht Piktogramme nach Kategorie
  Future<List<Pictogram>> getPictogramsByCategory(String category) async {
    await initialize();

    if (_pictogramData == null || _pictogramData!.isEmpty) {
      return [];
    }

    return _pictogramData!
        .where((data) => (data['category'] ?? 'Allgemein') == category)
        .map((data) {
      final List<dynamic> keywords = data['keywords'] ?? [];
      final int id = data['id'] ?? 0;
      final String filename = data['filename'] ?? '$id.png';

      return Pictogram(
        id: id,
        keyword:
            keywords.isNotEmpty ? keywords[0].toString() : 'Piktogramm $id',
        imageUrl: getLocalImagePath(filename),
        description: keywords.length > 1 ? keywords[1].toString() : '',
        category: category,
      );
    }).toList();
  }

  /// Gibt den lokalen Pfad für ein Piktogramm-Bild zurück
  String getLocalImagePath(String filename) {
    // Wenn der Filename nur eine ID ist, versuche verschiedene Formate
    if (RegExp(r'^\d+\.png$').hasMatch(filename)) {
      filename.replaceAll('.png', '');
      // Standardformat: versuche zuerst den originalen Dateinamen aus der JSON
      return 'assets/pictograms/$filename';
    }
    return 'assets/pictograms/$filename';
  }

  /// Gibt ein Piktogramm anhand seiner ID zurück
  Future<Pictogram?> getPictogramById(int id) async {
    await initialize();

    if (_pictogramData == null || _pictogramData!.isEmpty) {
      return null;
    }

    try {
      final data = _pictogramData!.firstWhere((item) => item['id'] == id);
      final List<dynamic> keywords = data['keywords'] ?? [];
      final String category = data['category'] ?? 'Allgemein';
      final String filename = data['filename'] ?? '$id.png';

      return Pictogram(
        id: id,
        keyword:
            keywords.isNotEmpty ? keywords[0].toString() : 'Piktogramm $id',
        imageUrl: getLocalImagePath(filename),
        description: keywords.length > 1 ? keywords[1].toString() : '',
        category: category,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Piktogramm mit ID $id nicht in lokalen Daten gefunden');
      }
      return null;
    }
  }

  /// Lädt die Liste aller verfügbaren Dateien
  List<String>? _availableFiles;

  Future<List<String>> _loadAvailableFiles() async {
    if (_availableFiles != null) return _availableFiles!;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/available_files.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      _availableFiles = jsonData.cast<String>();
      if (kDebugMode) {
        print('Verfügbare Dateien geladen: ${_availableFiles!.length} Dateien');
      }
      return _availableFiles!;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Laden der verfügbaren Dateien: $e');
      }
      return [];
    }
  }

  /// Sucht ein Piktogramm anhand des Namens direkt in den Dateinamen
  Future<Pictogram?> getPictogramByName(String name) async {
    await initialize();

    if (kDebugMode) {
      print('🔍 Suche nach Datei für Namen: "$name"');
    }

    // Zuerst prüfen ob es ein benutzerdefiniertes Piktogramm ist
    final customPictograms =
        await CustomPictogramService.instance.getAllCustomPictograms();
    for (final customPictogram in customPictograms) {
      if (customPictogram.keyword == name) {
        if (kDebugMode) {
          print(
            '✅ Benutzerdefiniertes Piktogramm gefunden: "$name" → "${customPictogram.imageUrl}"');
        }
        return customPictogram;
      }
    }

    final availableFiles = await _loadAvailableFiles();

    // 1. Exakte Übereinstimmung am Anfang des Dateinamens
    for (final filename in availableFiles) {
      final nameFromFile = filename.split('_')[0];
      if (nameFromFile.toLowerCase() == name.toLowerCase()) {
        final match = RegExp(r'_(\d+)\.png$').firstMatch(filename);
        final int fileId = match != null ? int.parse(match.group(1)!) : 0;

        if (kDebugMode) {
          print('✅ Exakte Übereinstimmung: "$name" → "$filename"');
        }
        return _createPictogramFromFile(filename, fileId, nameFromFile);
      }
    }

    // 2. Synonym-basierte Suche (z.B. "Spielzeugauto" → "Spielautomat")
    for (final filename in availableFiles) {
      final nameFromFile = filename.split('_')[0].toLowerCase();
      if (_isSimilarName(name.toLowerCase(), nameFromFile)) {
        final match = RegExp(r'_(\d+)\.png$').firstMatch(filename);
        final int fileId = match != null ? int.parse(match.group(1)!) : 0;

        if (kDebugMode) {
          print('✅ Synonym gefunden: "$name" → "$filename"');
        }
        return _createPictogramFromFile(
            filename, fileId, filename.split('_')[0]);
      }
    }

    // 3. Partielle Übereinstimmung (enthält)
    for (final filename in availableFiles) {
      if (filename.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(filename.split('_')[0].toLowerCase())) {
        final nameFromFile = filename.split('_')[0];
        final match = RegExp(r'_(\d+)\.png$').firstMatch(filename);
        final int fileId = match != null ? int.parse(match.group(1)!) : 0;

        if (kDebugMode) {
          print('✅ Partielle Übereinstimmung: "$name" → "$filename"');
        }
        return _createPictogramFromFile(filename, fileId, nameFromFile);
      }
    }

    if (kDebugMode) {
      print('❌ Keine Datei gefunden für Namen: "$name"');
    }
    return null;
  }

  /// Prüft ob zwei Namen ähnlich sind (für bessere Suche)
  bool _isSimilarName(String search, String fileName) {
    // Spezielle Zuordnungen für häufige Fälle
    final synonyms = {
      'spielzeugauto': ['spielautomat', 'auto'],
      'auto': ['spielautomat', 'fahrzeug'],
      'krankenwagen': ['ambulanz', 'rettungswagen'],
      'schlauchboot': ['boot', 'schiff'],
      'vagina': ['geschlecht', 'organ'],
    };

    // Prüfe Synonyme in beide Richtungen
    if (synonyms.containsKey(search)) {
      for (final synonym in synonyms[search]!) {
        if (fileName.contains(synonym)) {
          return true;
        }
      }
    }

    // Prüfe auch umgekehrt
    for (final entry in synonyms.entries) {
      if (entry.value.contains(search) && fileName.contains(entry.key)) {
        return true;
      }
    }

    return false;
  }

  /// Erstellt ein Pictogram-Objekt aus einem Dateinamen
  Pictogram _createPictogramFromFile(
      String filename, int fileId, String displayName) {
    return Pictogram(
      id: fileId,
      keyword: displayName,
      imageUrl: getLocalImagePath(filename),
      description: 'Gefunden über Dateiname: $filename',
      category: 'Lokal gefunden',
    );
  }

  /// Prüft, ob ein Piktogramm lokal verfügbar ist
  Future<bool> isPictogramAvailable(int id) async {
    await initialize();

    if (_pictogramData == null || _pictogramData!.isEmpty) {
      return false;
    }

    return _pictogramData!.any((item) => item['id'] == id);
  }
}
