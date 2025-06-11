import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:picto_grid/providers/pictogram_provider.dart';
import 'package:picto_grid/providers/grid_provider.dart';
import 'package:picto_grid/widgets/pictogram_grid.dart';

import 'package:picto_grid/services/tts_service.dart';
import 'package:picto_grid/services/local_pictogram_service.dart';
import 'package:picto_grid/services/custom_pictogram_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TTS-Service initialisieren
  await TtsService().initialize();

  // Lokalen Piktogramm-Service initialisieren
  await LocalPictogramService.instance.initialize();

  // Custom Piktogramm-Service initialisieren
  await CustomPictogramService.instance.initialize();

  runApp(const PictoGridApp());
}

class PictoGridApp extends StatelessWidget {
  const PictoGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PictogramProvider()),
        ChangeNotifierProvider(create: (_) => GridProvider()),
      ],
      child: MaterialApp(
        title: 'PictoGrid',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSearch = true;
  final _gridKey = GlobalKey<PictogramGridState>();

  @override
  Widget build(BuildContext context) {
    final gridProvider = context.watch<GridProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: gridProvider.grids.isNotEmpty
            ? Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: gridProvider.selectedGridId,
                      items: gridProvider.grids.map((grid) {
                        return DropdownMenuItem(
                          value: grid['id'] as int,
                          child: Text(
                            grid['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) gridProvider.selectGrid(id);
                      },
                      underline: Container(),
                      dropdownColor:
                          Theme.of(context).colorScheme.inversePrimary,
                      icon: const Icon(Icons.arrow_drop_down),
                    ),
                  ),
                  if (gridProvider.selectedGridId != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Grid löschen',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Grid löschen'),
                            content: const Text(
                                'Möchten Sie dieses Grid wirklich löschen?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Abbrechen'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Löschen'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await gridProvider
                              .deleteGrid(gridProvider.selectedGridId!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Grid wurde gelöscht'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                ],
              )
            : const Text('PictoGrid'),
        actions: [
          if (gridProvider.selectedGridId != null) ...[
            IconButton(
              icon: const Icon(Icons.grid_4x4),
              tooltip: 'Rastergröße ändern',
              onPressed: () {
                if (_gridKey.currentState != null) {
                  _gridKey.currentState!.showGridSettingsDialog(
                    _gridKey.currentState!.calculateGridDimensions(
                      MediaQuery.of(context).size,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Bearbeitungsmodus',
              onPressed: () {
                if (_gridKey.currentState != null) {
                  _gridKey.currentState!.toggleEditMode();
                }
              },
            ),
          ],
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            tooltip: _showSearch ? 'Suche ausblenden' : 'Suche einblenden',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neues Grid erstellen',
            onPressed: () async {
              final name = await showDialog<String>(
                context: context,
                builder: (context) => const NewGridDialog(),
              );
              if (name != null && name.isNotEmpty) {
                await gridProvider.createGrid(name);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info-Karte für Bearbeitungsmodus
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aktivieren Sie den Bearbeitungsmodus (✏️) und klicken Sie auf ein Kästchen, um Piktogramme hinzuzufügen.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Grid
          Expanded(
            child: gridProvider.selectedGridId != null
                ? PictogramGrid(
                    key: _gridKey,
                    pictograms: gridProvider.currentGridPictograms,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Kein Grid ausgewählt',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final name = await showDialog<String>(
                              context: context,
                              builder: (context) => const NewGridDialog(),
                            );
                            if (name != null && name.isNotEmpty) {
                              await gridProvider.createGrid(name);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Neues Grid erstellen'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class NewGridDialog extends StatefulWidget {
  const NewGridDialog({super.key});

  @override
  State<NewGridDialog> createState() => _NewGridDialogState();
}

class _NewGridDialogState extends State<NewGridDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neues Grid erstellen'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Grid-Name',
          hintText: 'Geben Sie einen Namen für das neue Grid ein',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
