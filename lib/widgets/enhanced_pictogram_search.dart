import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/pictogram.dart';
import '../services/local_pictogram_service.dart';
import '../services/custom_pictogram_service.dart';

enum PictogramSource {
  local,
  custom,
  all,
}

class EnhancedPictogramSearch extends StatefulWidget {

  const EnhancedPictogramSearch({
    super.key,
    required this.onPictogramSelected,
  });
  final Function(Pictogram) onPictogramSelected;

  @override
  State<EnhancedPictogramSearch> createState() =>
      _EnhancedPictogramSearchState();
}

class _EnhancedPictogramSearchState extends State<EnhancedPictogramSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocalPictogramService _localPictogramService =
      LocalPictogramService.instance;
  final CustomPictogramService _customPictogramService =
      CustomPictogramService.instance;

  List<Pictogram> _searchResults = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  PictogramSource _selectedSource = PictogramSource.all;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showDropdown = false;
        });
      }
    });

    // Initialisiere Custom Pictogram Service
    _customPictogramService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchPictograms(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    try {
      List<Pictogram> results = [];

      // Suche basierend auf ausgewählter Quelle
      switch (_selectedSource) {
        case PictogramSource.local:
          results = await _localPictogramService.searchPictograms(query);
          break;
        case PictogramSource.custom:
          results = await _customPictogramService.searchCustomPictograms(query);
          break;
        case PictogramSource.all:
          final localResults =
              await _localPictogramService.searchPictograms(query);
          final customResults =
              await _customPictogramService.searchCustomPictograms(query);
          results = [...customResults, ...localResults]; // Custom zuerst
          break;
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Fehler bei der Suche: $e');
      }
    }
  }

  /// Zeigt den Dialog zum Benennen eines neuen Piktogramms
  Future<void> _showNamingDialog(Pictogram pictogram) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Piktogramm benennen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vorschau des Bildes
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(pictogram.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'z.B. Haus, Auto, spielen...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  hintText: 'Weitere Details...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
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
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Erstelle neues Piktogramm mit Namen
      final namedPictogram = Pictogram(
        id: pictogram.id,
        keyword: result['name']!,
        imageUrl: pictogram.imageUrl,
        description: result['description'] ?? '',
        category: 'Benutzerdefiniert',
      );

      // Speichere das Piktogramm
      await _customPictogramService.addCustomPictogram(namedPictogram);

      // Füge es direkt zum Grid hinzu
      widget.onPictogramSelected(namedPictogram);

      // Zeige Bestätigung
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Piktogramm "${result['name']}" wurde gespeichert'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Startet den Kamera-Workflow
  Future<void> _captureFromCamera() async {
    try {
      final Pictogram? pictogram =
          await _customPictogramService.captureFromCamera();
      if (pictogram != null) {
        await _showNamingDialog(pictogram);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Startet den Galerie-Workflow
  Future<void> _pickFromGallery() async {
    try {
      final Pictogram? pictogram =
          await _customPictogramService.pickFromGallery();
      if (pictogram != null) {
        await _showNamingDialog(pictogram);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Zeigt Auswahlmöglichkeiten für neue Piktogramme
  void _showImageSourceOptions() {
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
            const Text(
              'Neues Piktogramm hinzufügen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Foto aufnehmen'),
              subtitle: const Text('Mit der Kamera fotografieren'),
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Aus Galerie wählen'),
              subtitle: const Text('Bild aus dem Gerätespeicher auswählen'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quellen-Auswahl und Aktions-Buttons
        Row(
          children: [
            // Quellen-Dropdown
            Expanded(
              child: DropdownButtonFormField<PictogramSource>(
                value: _selectedSource,
                decoration: const InputDecoration(
                  labelText: 'Quelle',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PictogramSource.all,
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 20),
                        SizedBox(width: 8),
                        Text('Alle'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: PictogramSource.local,
                    child: Row(
                      children: [
                        Icon(Icons.inventory, size: 20),
                        SizedBox(width: 8),
                        Text('Lokale Assets'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: PictogramSource.custom,
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Eigene Bilder'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSource = value;
                    });
                    // Neue Suche mit geänderter Quelle
                    if (_searchController.text.isNotEmpty) {
                      _searchPictograms(_searchController.text);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Kamera/Galerie Button
            ElevatedButton.icon(
              onPressed: _showImageSourceOptions,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Neu'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Suchfeld
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: _selectedSource == PictogramSource.local
                ? 'In lokalen Piktogrammen suchen...'
                : _selectedSource == PictogramSource.custom
                    ? 'In eigenen Bildern suchen...'
                    : 'Piktogramm suchen...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _showDropdown = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _searchPictograms(value);
          },
        ),

        // Suchergebnisse Dropdown
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Keine Ergebnisse gefunden'),
                            const SizedBox(height: 8),
                            if (_selectedSource != PictogramSource.custom)
                              TextButton.icon(
                                onPressed: _showImageSourceOptions,
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Eigenes Bild hinzufügen'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final pictogram = _searchResults[index];
                          final isCustom =
                              pictogram.category == 'Benutzerdefiniert';

                          return ListTile(
                            leading: SizedBox(
                              width: 40,
                              height: 40,
                              child: isCustom
                                  ? Image.file(
                                      File(pictogram.imageUrl),
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error_outline,
                                            color: Colors.red);
                                      },
                                    )
                                  : pictogram.imageUrl.startsWith('assets/')
                                      ? Image.asset(
                                          pictogram.imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.error_outline,
                                                color: Colors.red);
                                          },
                                        )
                                      : Image.network(
                                          pictogram.imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.error_outline,
                                                color: Colors.red);
                                          },
                                        ),
                            ),
                            title: Text(pictogram.keyword),
                            subtitle: Text(
                              isCustom ? 'Eigenes Bild' : 'Lokales Asset',
                              style: TextStyle(
                                color: isCustom ? Colors.blue : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: isCustom
                                ? PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Löschen'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Piktogramm löschen'),
                                            content: Text(
                                                'Möchten Sie "${pictogram.keyword}" wirklich löschen?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Abbrechen'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Löschen'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          await _customPictogramService
                                              .deleteCustomPictogram(
                                                  pictogram.id);
                                          _searchPictograms(_searchController
                                              .text); // Aktualisiere Suche
                                        }
                                      }
                                    },
                                  )
                                : null,
                            onTap: () {
                              widget.onPictogramSelected(pictogram);
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _showDropdown = false;
                              });
                              _focusNode.unfocus();
                            },
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
