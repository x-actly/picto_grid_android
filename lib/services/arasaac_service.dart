import 'package:picto_grid/models/pictogram.dart';
import 'package:picto_grid/services/local_pictogram_service.dart';

/// Service für lokale Piktogramme (ehemals ARASAAC)
/// Entfernt die Online-API-Funktionalität und nutzt nur noch lokale Dateien
class ArasaacService {
  final LocalPictogramService _localService = LocalPictogramService.instance;

  /// Sucht Piktogramme nur in lokalen Dateien
  Future<List<Pictogram>> searchPictograms(String keyword) async {
    return await _localService.searchPictograms(keyword);
  }

  /// Gibt die lokale Bildpfad zurück
  String getImageUrl(int pictogramId) {
    return _localService.getLocalImagePath('$pictogramId.png');
  }

  /// Alias für getImageUrl (Kompatibilität)
  String getPictogramUrl(int pictogramId) {
    return getImageUrl(pictogramId);
  }
}
