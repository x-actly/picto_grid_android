import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pictogram.dart';
import 'local_pictogram_service.dart';

class ArasaacService {
  static const String apiBaseUrl = 'https://api.arasaac.org/api/pictograms';
  static const String imageBaseUrl = 'https://static.arasaac.org/pictograms';

  // Flag um zwischen Online- und Offline-Modus zu wechseln
  static const bool useLocalPictograms = true;

  final LocalPictogramService _localService = LocalPictogramService.instance;

  Future<List<Pictogram>> searchPictograms(String keyword) async {
    if (useLocalPictograms) {
      // Verwende lokale Piktogramme
      return await _localService.searchPictograms(keyword);
    } else {
      // Verwende Online-API (ursprüngliche Implementierung)
      return await _searchPictogramsOnline(keyword);
    }
  }

  // Original-Online-Implementierung für Fallback
  Future<List<Pictogram>> _searchPictogramsOnline(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/de/search/$keyword'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isEmpty) {
          print('Keine Piktogramme gefunden für: $keyword');
          return [];
        }

        return jsonData.map((json) {
          // Sichere Extraktion der Keywords
          final List<dynamic> keywords = json['keywords'] ?? [];
          String primaryKeyword = keyword;
          String description = '';

          if (keywords.isNotEmpty) {
            if (keywords[0] is Map) {
              primaryKeyword = keywords[0]['keyword'] ?? keyword;
            } else if (keywords[0] is String) {
              primaryKeyword = keywords[0];
            }

            if (keywords.length > 1) {
              if (keywords[1] is Map) {
                description = keywords[1]['keyword'] ?? '';
              } else if (keywords[1] is String) {
                description = keywords[1];
              }
            }
          }

          return Pictogram(
            id: json['_id'] as int,
            keyword: primaryKeyword,
            imageUrl: getImageUrl(json['_id'] as int),
            description: description,
            category: json['category'] ?? 'Allgemein',
          );
        }).toList();
      } else {
        print('API Fehler: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception(
            'Fehler beim Laden der Piktogramme: ${response.statusCode}');
      }
    } catch (e) {
      print('Netzwerkfehler: $e');
      throw Exception('Netzwerkfehler: $e');
    }
  }

  String getImageUrl(int pictogramId) {
    if (useLocalPictograms) {
      return _localService.getLocalImagePath('$pictogramId.png');
    } else {
      return '$imageBaseUrl/$pictogramId/${pictogramId}_500.png';
    }
  }

  String getPictogramUrl(int pictogramId) {
    return getImageUrl(pictogramId);
  }
}
