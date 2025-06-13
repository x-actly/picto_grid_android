import 'package:flutter/foundation.dart';
import 'package:picto_grid/models/pictogram.dart';
import 'package:picto_grid/services/arasaac_service.dart';

class PictogramProvider with ChangeNotifier {
  final ArasaacService _arasaacService = ArasaacService();
  List<Pictogram> _searchResults = [];
  bool _isLoading = false;
  String _error = '';

  List<Pictogram> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> searchPictograms(String keyword) async {
    if (keyword.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _searchResults = await _arasaacService.searchPictograms(keyword);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
