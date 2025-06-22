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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPictograms(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.localPictogramSearchTitle,
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
                      });
                    },
                  )
                : null,
          ),
          onChanged: _searchPictograms,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? AppLocalizations.of(
                                context,
                              )!.searchFieldPlaceholder
                            : AppLocalizations.of(
                                context,
                              )!.searchFieldNoResults,
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
