import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picto_grid/models/pictogram.dart';

class PictogramService {
  static const String apiBaseUrl = 'https://api.arasaac.org/api/pictograms';
  static const String imageBaseUrl = 'https://static.arasaac.org/pictograms';

  Future<List<Pictogram>> searchPictograms(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/de/search/$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        return jsonData.map((json) {
          // Sichere Extraktion der Keywords
          final List<dynamic> keywords = json['keywords'] ?? [];
          String primaryKeyword = query;
          String description = '';

          if (keywords.isNotEmpty) {
            if (keywords[0] is Map) {
              primaryKeyword = keywords[0]['keyword'] ?? query;
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
        throw Exception('Fehler beim Laden der Piktogramme: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  String getImageUrl(int pictogramId) {
    return '$imageBaseUrl/$pictogramId/${pictogramId}_500.png';
  }
}
