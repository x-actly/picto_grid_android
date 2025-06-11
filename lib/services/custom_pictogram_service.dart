import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pictogram.dart';

class CustomPictogramService {

  CustomPictogramService._internal();
  static CustomPictogramService? _instance;
  static CustomPictogramService get instance {
    _instance ??= CustomPictogramService._internal();
    return _instance!;
  }

  final ImagePicker _picker = ImagePicker();
  List<Pictogram> _customPictograms = [];
  String? _customPictogramsDir;
  bool _isInitialized = false;

  /// Initialisiert den Service und lädt gespeicherte Custom Pictogramme
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Erstelle das Verzeichnis für Custom Pictogramme
      final Directory appDir = await getApplicationDocumentsDirectory();
      _customPictogramsDir = '${appDir.path}/custom_pictograms';
      final Directory customDir = Directory(_customPictogramsDir!);

      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }

      // Lade gespeicherte Custom Pictogramme
      await _loadCustomPictograms();
      _isInitialized = true;

      if (kDebugMode) {
        print(
          'Custom Pictogram Service initialisiert: ${_customPictograms.length} Piktogramme geladen');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Initialisieren des Custom Pictogram Service: $e');
      }
      _customPictograms = [];
      _isInitialized = true;
    }
  }

  /// Lädt Custom Pictogramme aus der JSON-Datei
  Future<void> _loadCustomPictograms() async {
    try {
      final File metadataFile = File('$_customPictogramsDir/metadata.json');
      if (await metadataFile.exists()) {
        final String jsonContent = await metadataFile.readAsString();
        final List<dynamic> jsonData = json.decode(jsonContent);

        _customPictograms = jsonData.map((data) {
          return Pictogram(
            id: data['id'],
            keyword: data['keyword'],
            imageUrl: data['imageUrl'],
            description: data['description'] ?? '',
            category: data['category'] ?? 'Benutzerdefiniert',
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Laden der Custom Pictogram Metadaten: $e');
      }
      _customPictograms = [];
    }
  }

  /// Speichert Custom Pictogramme in die JSON-Datei
  Future<void> _saveCustomPictograms() async {
    try {
      final File metadataFile = File('$_customPictogramsDir/metadata.json');
      final List<Map<String, dynamic>> jsonData =
          _customPictograms.map((pictogram) {
        return {
          'id': pictogram.id,
          'keyword': pictogram.keyword,
          'imageUrl': pictogram.imageUrl,
          'description': pictogram.description,
          'category': pictogram.category,
        };
      }).toList();

      await metadataFile.writeAsString(json.encode(jsonData));
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Speichern der Custom Pictogram Metadaten: $e');
      }
    }
  }

  /// Nimmt ein Foto mit der Kamera auf
  Future<Pictogram?> captureFromCamera() async {
    if (kDebugMode) {
      print('🔵 Service: Initialize...');
    }
    await initialize();

    // Überprüfe Kamera-Berechtigung
    if (kDebugMode) {
      print('🔵 Service: Prüfe Kamera-Berechtigung...');
    }
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (kDebugMode) {
        print('🔴 Service: Kamera-Berechtigung verweigert');
      }
      throw Exception('Kamera-Berechtigung wurde nicht gewährt');
    }

    try {
      if (kDebugMode) {
        print('🔵 Service: Öffne Kamera...');
      }
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (kDebugMode) {
          print('🔵 Service: Bild erhalten, verarbeite: ${image.path}');
        }
        final result = await _processSelectedImage(image);
        if (kDebugMode) {
          print('🔵 Service: Verarbeitung abgeschlossen: ${result?.imageUrl}');
        }
        return result;
      } else {
        if (kDebugMode) {
          print('🔴 Service: Kein Bild von der Kamera erhalten');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Service: Fehler beim Aufnehmen des Fotos: $e');
      }
      throw Exception('Fehler beim Aufnehmen des Fotos: $e');
    }
  }

  /// Wählt ein Bild aus der Galerie
  Future<Pictogram?> pickFromGallery() async {
    await initialize();

    // Überprüfe Speicher-Berechtigung (für Android < 13)
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        // Versuche photos permission für Android 13+
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          throw Exception('Speicher-Berechtigung wurde nicht gewährt');
        }
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return await _processSelectedImage(image);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Auswählen des Bildes: $e');
      }
      throw Exception('Fehler beim Auswählen des Bildes: $e');
    }
  }

  /// Verarbeitet das ausgewählte Bild
  Future<Pictogram?> _processSelectedImage(XFile image) async {
    try {
      if (kDebugMode) {
        print('🔵 Service: Starte Bildverarbeitung...');
      }
      // Generiere eine eindeutige ID
      final int newId = DateTime.now().millisecondsSinceEpoch;
      final String filename = 'custom_$newId.jpg';
      final String targetPath = '$_customPictogramsDir/$filename';

      if (kDebugMode) {
        print('🔵 Service: Kopiere Bild von ${image.path} nach $targetPath');
      }
      // Kopiere das Bild in das App-Verzeichnis
      final File sourceFile = File(image.path);
      final File targetFile = File(targetPath);
      await sourceFile.copy(targetPath);

      // Prüfe ob Datei existiert
      final bool exists = await targetFile.exists();
      if (kDebugMode) {
        print('🔵 Service: Zieldatei existiert: $exists');
      }

      // Erstelle das Pictogram-Objekt (noch ohne Namen)
      final Pictogram pictogram = Pictogram(
        id: newId,
        keyword: 'Neues Piktogramm', // Temporärer Name
        imageUrl: targetPath,
        description: 'Benutzerdefiniertes Piktogramm',
        category: 'Benutzerdefiniert',
      );

      if (kDebugMode) {
        print('🔵 Service: Pictogram erstellt: ID=$newId, Pfad=$targetPath');
      }
      return pictogram;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Service: Fehler beim Verarbeiten des Bildes: $e');
      }
      throw Exception('Fehler beim Verarbeiten des Bildes: $e');
    }
  }

  /// Fügt ein benanntes Custom Pictogram hinzu
  Future<void> addCustomPictogram(Pictogram pictogram) async {
    await initialize();

    _customPictograms.add(pictogram);
    await _saveCustomPictograms();
  }

  /// Sucht in Custom Pictogrammen
  Future<List<Pictogram>> searchCustomPictograms(String keyword) async {
    await initialize();

    if (keyword.isEmpty) {
      return _customPictograms;
    }

    final String searchTerm = keyword.toLowerCase().trim();

    return _customPictograms.where((pictogram) {
      return pictogram.keyword.toLowerCase().contains(searchTerm) ||
          pictogram.description.toLowerCase().contains(searchTerm) ||
          pictogram.category.toLowerCase().contains(searchTerm);
    }).toList();
  }

  /// Gibt alle Custom Pictogramme zurück
  Future<List<Pictogram>> getAllCustomPictograms() async {
    await initialize();
    return List.from(_customPictograms);
  }

  /// Löscht ein Custom Pictogram
  Future<void> deleteCustomPictogram(int id) async {
    await initialize();

    final pictogram = _customPictograms.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Piktogramm nicht gefunden'),
    );

    // Lösche die Bilddatei
    try {
      final File imageFile = File(pictogram.imageUrl);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Löschen der Bilddatei: $e');
      }
    }

    // Entferne aus der Liste
    _customPictograms.removeWhere((p) => p.id == id);
    await _saveCustomPictograms();
  }

  /// Aktualisiert ein Custom Pictogram
  Future<void> updateCustomPictogram(Pictogram updatedPictogram) async {
    await initialize();

    final index =
        _customPictograms.indexWhere((p) => p.id == updatedPictogram.id);
    if (index != -1) {
      _customPictograms[index] = updatedPictogram;
      await _saveCustomPictograms();
    }
  }

  /// Überprüft, ob Berechtigungen verfügbar sind
  Future<Map<String, bool>> checkPermissions() async {
    final Map<String, bool> permissions = {};

    permissions['camera'] = await Permission.camera.isGranted;
    permissions['storage'] = await Permission.storage.isGranted;
    permissions['photos'] = await Permission.photos.isGranted;

    return permissions;
  }

  /// Fordert alle benötigten Berechtigungen an
  Future<bool> requestPermissions() async {
    final List<Permission> permissionsToRequest = [
      Permission.camera,
    ];

    // Für Android
    if (Platform.isAndroid) {
      permissionsToRequest.add(Permission.storage);
      permissionsToRequest.add(Permission.photos);
    }

    final Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();

    // Überprüfe, ob mindestens Kamera-Berechtigung gewährt wurde
    final bool cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    bool storageGranted = true; // Default für iOS

    if (Platform.isAndroid) {
      storageGranted = statuses[Permission.storage]?.isGranted ??
          statuses[Permission.photos]?.isGranted ??
          false;
    }

    return cameraGranted && storageGranted;
  }

  /// Gibt das Custom Pictograms Verzeichnis zurück
  Future<String> getCustomPictogramsDir() async {
    await initialize();
    return _customPictogramsDir!;
  }
}
