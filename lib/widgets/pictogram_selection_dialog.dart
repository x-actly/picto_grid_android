import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picto_grid/l10n/app_localizations.dart';
import 'dart:io';
import 'package:picto_grid/models/pictogram.dart';
import 'package:picto_grid/services/local_pictogram_service.dart';
import 'package:picto_grid/services/custom_pictogram_service.dart';

class PictogramSelectionDialog {
  static Future<void> show(
    BuildContext context,
    Function(Pictogram) onSelected,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addPictogramText),
        content: Text(AppLocalizations.of(context)!.addPictogramContentText),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showLocalPictogramSearch(context, onSelected);
                },
                icon: const Icon(Icons.search),
                label: Text(
                  AppLocalizations.of(context)!.localPictogramSearchTitle,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeviceImageOptions(context, onSelected);
                },
                icon: const Icon(Icons.folder),
                label: Text(
                  AppLocalizations.of(context)!.selectImageFromDeviceTitle,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancelButtonText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showLocalPictogramSearch(
    BuildContext context,
    Function(Pictogram) onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: LocalPictogramSearchWidget(
            onPictogramSelected: (pictogram) {
              Navigator.pop(context);
              onSelected(pictogram);
            },
          ),
        ),
      ),
    );
  }

  static void _showDeviceImageOptions(
    BuildContext context,
    Function(Pictogram) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.selectImageFromDeviceTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.takePhotoText),
              subtitle: Text(
                AppLocalizations.of(context)!.takePhotoSubtitleText,
              ),
              onTap: () async {
                Navigator.pop(context);
                // Starte Kamera-Capture im nächsten Frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _captureFromCamera(context, onSelected);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: Text(AppLocalizations.of(context)!.selectFromGalleryText),
              subtitle: Text(
                AppLocalizations.of(context)!.selectFromGallerySubtitleText,
              ),
              onTap: () async {
                Navigator.pop(context);
                // Starte Galerie-Auswahl im nächsten Frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pickFromGallery(context, onSelected);
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<void> _captureFromCamera(
    BuildContext context,
    Function(Pictogram) onSelected,
  ) async {
    try {
      if (kDebugMode) {
        print('🔵 Starte Kamera-Aufnahme...');
      }

      // Prüfe Context vorm ersten Schritt
      if (!context.mounted) {
        if (kDebugMode) {
          print('🔴 Context bereits unmounted vor Kamera-Aufnahme');
        }
        return;
      }

      final pictogram = await CustomPictogramService.instance
          .captureFromCamera();
      if (kDebugMode) {
        print('🔵 Kamera-Aufnahme abgeschlossen: ${pictogram?.imageUrl}');
      }

      if (pictogram != null) {
        // Verwende den Root-Context für den Dialog
        if (context.mounted) {
          final rootContext = Navigator.of(
            context,
            rootNavigator: true,
          ).context;
          if (kDebugMode) {
            print('🔵 Zeige Benennungs-Dialog mit Root-Context...');
          }
          await _showNamingDialog(rootContext, pictogram, onSelected);
        } else {
          if (kDebugMode) {
            print('🔴 Context ist nicht mehr mounted');
          }
          // Erstelle einen temporären Namen wenn Context verloren
          final tempName = 'Foto_${DateTime.now().millisecondsSinceEpoch}';
          final namedPictogram = Pictogram(
            id: pictogram.id,
            keyword: tempName,
            imageUrl: pictogram.imageUrl,
            description: 'Automatisch benanntes Foto',
            category: 'Benutzerdefiniert',
          );
          await CustomPictogramService.instance.addCustomPictogram(
            namedPictogram,
          );
          onSelected(namedPictogram);
          if (kDebugMode) {
            print('🔵 Temporäres Piktogramm erstellt: $tempName');
          }
        }
      } else {
        if (kDebugMode) {
          print('🔴 Kein Bild von der Kamera erhalten');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Fehler bei Kamera-Aufnahme: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> _pickFromGallery(
    BuildContext context,
    Function(Pictogram) onSelected,
  ) async {
    try {
      if (kDebugMode) {
        print('🔵 Starte Galerie-Auswahl...');
      }

      if (!context.mounted) {
        if (kDebugMode) {
          print('🔴 Context bereits unmounted vor Galerie-Auswahl');
        }
        return;
      }

      final pictogram = await CustomPictogramService.instance.pickFromGallery();
      if (kDebugMode) {
        print('🔵 Galerie-Auswahl abgeschlossen: ${pictogram?.imageUrl}');
      }

      if (pictogram != null) {
        if (context.mounted) {
          final rootContext = Navigator.of(
            context,
            rootNavigator: true,
          ).context;
          if (kDebugMode) {
            print('🔵 Zeige Benennungs-Dialog mit Root-Context...');
          }
          await _showNamingDialog(rootContext, pictogram, onSelected);
        } else {
          if (kDebugMode) {
            print('🔴 Context ist nicht mehr mounted');
          }
          // Erstelle einen temporären Namen wenn Context verloren
          final tempName = 'Galerie_${DateTime.now().millisecondsSinceEpoch}';
          final namedPictogram = Pictogram(
            id: pictogram.id,
            keyword: tempName,
            imageUrl: pictogram.imageUrl,
            description: 'Automatisch benanntes Bild',
            category: 'Benutzerdefiniert',
          );
          await CustomPictogramService.instance.addCustomPictogram(
            namedPictogram,
          );
          onSelected(namedPictogram);
          if (kDebugMode) {
            print('🔵 Temporäres Piktogramm erstellt: $tempName');
          }
        }
      } else {
        if (kDebugMode) {
          print('🔴 Kein Bild aus der Galerie erhalten');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Fehler bei Galerie-Auswahl: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> _showNamingDialog(
    BuildContext context,
    Pictogram pictogram,
    Function(Pictogram) onSelected,
  ) async {
    if (kDebugMode) {
      print('🔵 Benennungs-Dialog gestartet für: ${pictogram.imageUrl}');
    }
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.namePictogramText),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: pictogram.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          pictogram.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            );
                          },
                        )
                      : pictogram.category == 'Benutzerdefiniert'
                      ? Image.file(
                          File(pictogram.imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            );
                          },
                        )
                      : Image.asset(
                          pictogram.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  hintText: AppLocalizations.of(
                    context,
                  )!.namePictogramPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.descriptionText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButtonText),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
              }
            },
            child: Text(AppLocalizations.of(context)!.saveText),
          ),
        ],
      ),
    );

    if (result != null) {
      if (kDebugMode) {
        print('🔵 Dialog: Benutzer hat Namen eingegeben: ${result['name']}');
      }
      final namedPictogram = Pictogram(
        id: pictogram.id,
        keyword: result['name']!,
        imageUrl: pictogram.imageUrl,
        description: result['description'] ?? '',
        category: 'Benutzerdefiniert',
      );

      if (kDebugMode) {
        print('🔵 Dialog: Speichere Piktogramm...');
      }
      await CustomPictogramService.instance.addCustomPictogram(namedPictogram);

      if (kDebugMode) {
        print('🔵 Dialog: Rufe onSelected Callback...');
      }
      onSelected(namedPictogram);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Piktogramm "${result['name']}" wurde hinzugefügt'),
          ),
        );
      }
    } else {
      if (kDebugMode) {
        print('🔴 Dialog: Benutzer hat Dialog abgebrochen');
      }
    }
  }
}

class LocalPictogramSearchWidget extends StatefulWidget {
  const LocalPictogramSearchWidget({
    super.key,
    required this.onPictogramSelected,
  });
  final Function(Pictogram) onPictogramSelected;

  @override
  State<LocalPictogramSearchWidget> createState() =>
      _LocalPictogramSearchWidgetState();
}

class _LocalPictogramSearchWidgetState
    extends State<LocalPictogramSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final LocalPictogramService _localService = LocalPictogramService.instance;
  List<Pictogram> _searchResults = [];
  bool _isLoading = false;
  String? _selectedCategory;

  // Definiere Kategorien mit spezifischen Piktogrammen (alle über IDs)
  final Map<String, Map<String, dynamic>> _categories = {
    'Essen': {
      'icon_id':
          4610, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        // Hier fügst du die IDs der Essen-Piktogramme ein
        4610, // Essen (Kategorie-Icon)
        2527,
        2494,
        25363,
        2502,
        2461,
        4653,
        28343,
        35209,
        2334,
        2427,
        2573,
        // Weitere IDs werden hier hinzugefügt sobald du sie aus dem Browser hast
      ],
    },
    'Trinken': {
      'icon_id':
          2248, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        // Hier fügst du die IDs der Essen-Piktogramme ein
        2248, // Trinken (Kategorie-Icon)
        2445,
        8503,
        11461,
        6551,
        4940,
        2338,
        2296,
        // Weitere IDs werden hier hinzugefügt sobald du sie aus dem Browser hast
      ],
    },
    'Kommunikation': {
      'icon_id':
          11476, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        6632, // Kommunikation (Kategorie-Icon)
        6625,
        5584,
        5526,
        34641,
        34639,
        37826,
        37825,
        11476,
        13630,
        37182,
        38481,
        30620,
        35533,
        35545,
        35539,
        35529,
        31744,
        35537,
        38930,
        35541,
        30389,
        26986,
        // Weitere IDs werden hier hinzugefügt sobald du sie aus dem Browser hast
      ],
    },
    'Menschen': {
      'icon_id':
          24525, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        24525, // Menschen (Kategorie-Icon)
        2617,
        6480,
        7028,
        2458,
        2497,
        7030,
        2457,
        2422,
        2423,
        2608,
        7185,
        23710,
        23718,
        // Weitere IDs werden hier hinzugefügt sobald du sie aus dem Browser hast
      ],
    },
    'Verben': {
      'icon_id':
          7297, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        2432, // Verben (Kategorie-Icon)
        6456,
        6061,
        6572,
        6564,
        25275,
        32751,
        6517,
        7271,
        28431,
        2781,
        6479,
        6537,
        28665,
        27126,
        39445,
        32669,
        31748,
        38796,
        7147,
        13354,
        34492,
        16475,
        16697,
        28613,
        // Weitere IDs werden hier hinzugefügt sobald du sie aus dem Browser hast
      ],
    },
    'Körper': {
      'icon_id':
          6473, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        2367, // Körper (Kategorie-Icon)
        2673,
        2851,
        2887,
        2871,
        6573,
        3011,
        8319,
        2663,
        2737,
        2953,
        2504,
        2853,
        3000,
        2748,
        2977,
        2669,
        2707,
        2904,
        2928,
        3298,
        2786,
        8666,
        26030,
        3362,
        3410,
        2810,
        3405,
        25327,
      ],
    },
    'Kleidung': {
      'icon_id':
          32570, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        32570, // Kleidung (Kategorie-Icon)
        2309,
        2280,
        13640,
        2391,
        2613,
        2565,
        2436,
        4872,
        2303,
        2289,
        2576,
        2298,
        2522,
        2332,
        2775,
        2287,
        2622,
        2621,
        2270,
        2601,
        2411,
        8122,
        25804,
        4927,
        2415,
        2290,
        2336,
        6900,
        2515,
        6937,
        2668,
        2723,
        2549,
        22017,
      ],
    },
    'Dinge': {
      'icon_id':
          11318, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        4630, // Dinge (Kategorie-Icon)
        4698,
        3141,
        8511,
        25467,
        2500,
        3329,
        2549,
        27616,
      ],
    },
    'Wetter': {
      'icon_id':
          24721, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        24721, // Wetter (Kategorie-Icon)
        5553,
        5604,
        5531,
        5493,
        7252,
        34383,
        34896,
        7148,
        7172,
        35105,
        34892,
        2986,
        35049,
        35591,
        7259,
        35107,
      ],
    },
    'Orte': {
      'icon_id':
          6964, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        6964, // Orte (Kategorie-Icon)
        3082,
        2859,
        2823,
        3116,
        2299,
        9116,
        3142,
        6587,
        30387,
        11361,
        11344,
        27493,
        29905,
        6031,
        15730,
        2909,
        2666,
        2826,
        3145,
        2974,
      ],
    },
    'Beschreibung': {
      'icon_id':
          11713, // ID des Piktogramms das als Kategorie-Icon verwendet wird
      'item_ids': [
        4658, // Beschreibung (Kategorie-Icon)
        4716,
        26172,
        25253,
        26459,
        25437,
        4637,
        4578,
        4685,
        4737,
        4636,
        4739,
        25121,
        25044,
        25048,
        25133,
        26114,
        26090,
        26753,
        26993,
        5306,
        4676,
        32388,
        11355,
      ],
    },
  };

  // Cache für Kategorie-Icons
  final Map<String, Pictogram?> _categoryIcons = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryIcons();
  }

  Future<void> _loadCategoryIcons() async {
    for (String category in _categories.keys) {
      final categoryData = _categories[category]!;

      // Prüfe ob icon_id definiert ist
      if (categoryData.containsKey('icon_id')) {
        final iconId = categoryData['icon_id'] as int;
        final results = await _localService.getPictogramById(iconId);
        if (results != null) {
          _categoryIcons[category] = results;
        } else {
          // Fallback falls ID nicht gefunden wird
          _categoryIcons[category] = Pictogram(
            id: iconId,
            keyword: category,
            imageUrl: 'assets/pictograms/${category}_$iconId.png',
            description: '$category Kategorie',
            category: category,
          );
        }
      } else if (categoryData.containsKey('icon_keyword')) {
        // Fallback für alte icon_keyword Struktur
        final iconKeyword = categoryData['icon_keyword'] as String;
        final results = await _localService.searchPictograms(iconKeyword);
        if (results.isNotEmpty) {
          _categoryIcons[category] = results.first;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPictograms(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedCategory = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedCategory = null;
    });

    try {
      final results = await _localService.searchPictograms(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategoryPictograms(String category) async {
    final categoryData = _categories[category];
    if (categoryData == null) return;

    final itemIds = categoryData['item_ids'] as List<int>? ?? [];
    if (itemIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      List<Pictogram> categoryResults = [];

      // Lade jedes Piktogramm über seine ID
      for (int id in itemIds) {
        final pictogram = await _localService.getPictogramById(id);
        if (pictogram != null) {
          categoryResults.add(pictogram);
        }
      }

      setState(() {
        _searchResults = categoryResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoriesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Kategorien',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories.keys.elementAt(index);
              final categoryIcon = _categoryIcons[category];

              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => _loadCategoryPictograms(category),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        // Piktogramm als Kategorie-Icon
                        Expanded(
                          flex: 3,
                          child: categoryIcon != null
                              ? Image.asset(
                                  categoryIcon.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      _getCategoryIcon(category),
                                      size: 32,
                                      color: Theme.of(context).primaryColor,
                                    );
                                  },
                                )
                              : Icon(
                                  _getCategoryIcon(category),
                                  size: 32,
                                  color: Theme.of(context).primaryColor,
                                ),
                        ),
                        const SizedBox(height: 2),
                        // Kategorie-Name
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Essen':
        return Icons.restaurant;
      case 'Gefühle':
        return Icons.sentiment_satisfied;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (_selectedCategory != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _searchResults = [];
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: Text(
                _selectedCategory != null
                    ? 'Kategorie: $_selectedCategory'
                    : AppLocalizations.of(context)!.localPictogramSearchTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchPictoGramPlaceHolder,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _selectedCategory = null;
                      });
                    },
                  )
                : null,
          ),
          onChanged: _searchPictograms,
          autofocus:
              false, // Nicht mehr autofocus, damit Kategorien sichtbar bleiben
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty &&
                    _searchController.text.isEmpty &&
                    _selectedCategory == null
              ? _buildCategoriesView()
              : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.searchFieldNoResults,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final pictogram = _searchResults[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => widget.onPictogramSelected(pictogram),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: pictogram.imageUrl.startsWith('assets/')
                                    ? Image.asset(
                                        pictogram.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                              );
                                            },
                                      )
                                    : pictogram.category == 'Benutzerdefiniert'
                                    ? Image.file(
                                        File(pictogram.imageUrl),
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                              );
                                            },
                                      )
                                    : Image.asset(
                                        pictogram.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                              );
                                            },
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                pictogram.keyword,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
