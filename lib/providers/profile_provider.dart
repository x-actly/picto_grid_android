import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class ProfileProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _profiles = [];
  int? _selectedProfileId;

  ProfileProvider() {
    loadProfiles();
  }

  List<Map<String, dynamic>> get profiles => _profiles;
  int? get selectedProfileId => _selectedProfileId;

  String get selectedProfileName {
    if (_selectedProfileId == null) return '';
    final profile = _profiles.firstWhere(
      (p) => p['id'] == _selectedProfileId,
      orElse: () => {'name': ''},
    );
    return profile['name'] as String? ?? '';
  }

  Future<void> loadProfiles() async {
    _profiles = await _db.getAllProfiles();

    // Wähle das erste Profil als Standard aus, falls noch keins ausgewählt ist
    if (_selectedProfileId == null && _profiles.isNotEmpty) {
      _selectedProfileId = _profiles.first['id'] as int;
    }

    notifyListeners();
  }

  Future<void> createProfile(String name) async {
    final id = await _db.createProfile(name);
    await loadProfiles();
    _selectedProfileId = id;
    notifyListeners();
  }

  Future<void> selectProfile(int profileId) async {
    _selectedProfileId = profileId;
    notifyListeners();
  }

  Future<void> deleteProfile(int profileId) async {
    // Prüfe ob es das letzte Profil ist
    if (_profiles.length <= 1) {
      throw Exception('Das letzte Profil kann nicht gelöscht werden');
    }

    await _db.deleteProfile(profileId);

    // Falls das aktuelle Profil gelöscht wurde, wähle das erste verfügbare aus
    if (_selectedProfileId == profileId) {
      await loadProfiles();
      if (_profiles.isNotEmpty) {
        _selectedProfileId = _profiles.first['id'] as int;
      } else {
        _selectedProfileId = null;
      }
    } else {
      await loadProfiles();
    }

    notifyListeners();
  }

  Future<int> getGridCountForCurrentProfile() async {
    if (_selectedProfileId == null) return 0;
    return await _db.getGridCountForProfile(_selectedProfileId!);
  }

  Future<bool> canCreateGrid() async {
    final count = await getGridCountForCurrentProfile();
    return count < 3;
  }
}
