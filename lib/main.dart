import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picto_grid/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:picto_grid/providers/pictogram_provider.dart';
import 'package:picto_grid/providers/grid_provider.dart';
import 'package:picto_grid/providers/profile_provider.dart';
import 'package:picto_grid/widgets/pictogram_grid.dart';
import 'package:picto_grid/widgets/loading_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProxyProvider<ProfileProvider, GridProvider>(
          create: (_) => GridProvider(),
          update: (_, profileProvider, gridProvider) {
            gridProvider?.setCurrentProfile(profileProvider.selectedProfileId);
            return gridProvider ?? GridProvider();
          },
        ),
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
        builder: (context, child) {
          return child!;
        },
        // Localization support
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
  bool _isEditMode = false;
  final _gridKey = GlobalKey<PictogramGridState>();
  bool _isLoading = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Sofortige Orientierungs-Einstellung für bessere UX
    _setInitialOrientation();
  }

  void _setInitialOrientation() {
    // App-UI rotiert sich automatisch über Transform.rotate
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hideInfoOverlay();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Simulate loading time to show the loading screen
    await Future.delayed(const Duration(seconds: 5));

    // Nach Loading Screen: Orientierung auf Querformat setzen
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // System UI optimieren
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Zeige Hinweise für 4 Sekunden nach dem Laden
      _showHintsTemporarily();
    }
  }

  void _showHintsTemporarily() {
    _showInfoOverlay();

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _hideInfoOverlay();
      }
    });
  }

  OverlayEntry? _overlayEntry;

  void _showInfoOverlay() {
    if (_overlayEntry != null) return; // Bereits angezeigt

    final profileProvider = context.read<ProfileProvider>();
    final gridProvider = context.read<GridProvider>();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Optional: Semi-transparenter Hintergrund
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _hideInfoOverlay(),
              child: Container(color: Colors.black.withAlpha(20)),
            ),
          ),
          // Info-Overlay
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final clampedValue = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: clampedValue,
                    child: Material(
                      elevation: 16,
                      borderRadius: BorderRadius.circular(16),
                      shadowColor: Colors.blue.withAlpha(100),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                profileProvider.selectedProfileId == null
                                    ? AppLocalizations.of(
                                        context,
                                      )!.infoNoProfile
                                    : gridProvider.selectedGridId == null
                                    ? AppLocalizations.of(context)!.infoNoGrid
                                    : AppLocalizations.of(
                                        context,
                                      )!.infoEditHint,
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                onPressed: () => _hideInfoOverlay(),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideInfoOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _hintTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    final profileProvider = context.watch<ProfileProvider>();
    final gridProvider = context.watch<GridProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            // Profil-Auswahl
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.profile,
                    style: const TextStyle(fontSize: 12),
                  ),
                  DropdownButton<int>(
                    value: profileProvider.selectedProfileId,
                    items: profileProvider.profiles.map((profile) {
                      return DropdownMenuItem(
                        value: profile['id'] as int,
                        child: Text(
                          profile['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) profileProvider.selectProfile(id);
                    },
                    underline: Container(),
                    dropdownColor: Theme.of(context).colorScheme.inversePrimary,
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
                ],
              ),
            ),
            // Delete-Button für aktuelles Grid (nur wenn Grid ausgewählt)
            if (gridProvider.selectedGridId != null) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: AppLocalizations.of(context)!.gridDeleteText,
                onPressed: () => _showDeleteGridDialog(context, gridProvider),
              ),
            ],
          ],
        ),
        actions: [
          // Profil-Management
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            tooltip: AppLocalizations.of(context)!.manageProfiles,
            onSelected: (value) async {
              switch (value) {
                case 'new_profile':
                  await _showNewProfileDialog(context, profileProvider);
                  break;
                case 'delete_profile':
                  await _showDeleteProfileDialog(context, profileProvider);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new_profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_add),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.newProfile),
                  ],
                ),
              ),
              if (profileProvider.profiles.length > 1)
                PopupMenuItem(
                  value: 'delete_profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.deleteProfile,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Grid-Actions (nur wenn Profil ausgewählt)
          if (profileProvider.selectedProfileId != null) ...[
            if (gridProvider.selectedGridId != null) ...[
              IconButton(
                icon: Icon(_isEditMode ? Icons.edit_off : Icons.edit),
                tooltip: _isEditMode
                    ? AppLocalizations.of(context)!.editmodeinactiveText
                    : AppLocalizations.of(context)!.activateEditModeText,
                onPressed: () {
                  if (_gridKey.currentState != null) {
                    _gridKey.currentState!.toggleEditMode();
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                  }
                },
              ),
            ],
            FutureBuilder<bool>(
              future: profileProvider.canCreateGrid(),
              builder: (context, snapshot) {
                final canCreate = snapshot.data ?? false;
                final int maxGrid = 3;
                return IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: canCreate ? null : Colors.grey,
                  ),
                  tooltip: canCreate
                      ? AppLocalizations.of(context)!.createNewGrid
                      : AppLocalizations.of(context)!.maxGridsReached(maxGrid),
                  onPressed: canCreate
                      ? () => _showNewGridDialog(context, gridProvider)
                      : null,
                );
              },
            ),
          ],

          IconButton(
            icon: Icon(
              _overlayEntry != null ? Icons.info : Icons.info_outlined,
            ),
            tooltip: 'Hinweise anzeigen',
            onPressed: () {
              if (_overlayEntry != null) {
                _hideInfoOverlay();
              } else {
                _showHintsTemporarily();
              }
            },
          ),

          if (gridProvider.selectedGridId != null)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Einstellungen',
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
        ],
      ),
      body: _buildMainContent(context, profileProvider, gridProvider),
      bottomNavigationBar: _buildBottomNavigationBar(context, gridProvider),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    GridProvider gridProvider,
  ) {
    // Zeige Bottom Navigation nur wenn Grids vorhanden sind
    if (gridProvider.grids.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: gridProvider.grids.asMap().entries.map((entry) {
                final index = entry.key;
                final grid = entry.value;
                final gridId = grid['id'] as int;
                final gridName = grid['name'] as String;
                final isSelected = gridProvider.selectedGridId == gridId;

                return Container(
                  width: 120, // Feste Breite für jeden Button
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        gridProvider.selectGrid(gridId);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getGridIcon(index),
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            size: 20, // Etwas kleiner
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gridName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                              fontSize: 10, // Kleinere Schrift
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getGridIcon(int index) {
    switch (index) {
      case 0:
        return Icons.grid_view;
      case 1:
        return Icons.dashboard;
      case 2:
        return Icons.apps;
      default:
        return Icons.grid_4x4;
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    ProfileProvider profileProvider,
    GridProvider gridProvider,
  ) {
    // Kein Profil ausgewählt
    if (profileProvider.selectedProfileId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.welcomeText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.createProfilePrompt,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showNewProfileDialog(context, profileProvider),
              icon: const Icon(Icons.person_add),
              label: Text(AppLocalizations.of(context)!.createProfileButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Profil ausgewählt, aber kein Grid vorhanden
    if (gridProvider.grids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_4x4, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Profil: ${profileProvider.selectedProfileName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noGrids,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FutureBuilder<bool>(
              future: profileProvider.canCreateGrid(),
              builder: (context, snapshot) {
                final canCreate = snapshot.data ?? false;
                return ElevatedButton.icon(
                  onPressed: canCreate
                      ? () => _showNewGridDialog(context, gridProvider)
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(
                    AppLocalizations.of(context)!.createFirstGridButton,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Grid ausgewählt - zeige PictogramGrid
    if (gridProvider.selectedGridId != null) {
      return PictogramGrid(
        key: _gridKey,
        pictograms: gridProvider.currentGridPictograms,
      );
    }

    // Grids vorhanden, aber noch keins ausgewählt - automatisch erstes Grid auswählen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (gridProvider.grids.isNotEmpty) {
        final firstGridId = gridProvider.grids.first['id'] as int;
        gridProvider.selectGrid(firstGridId);
      }
    });

    // Zeige Loading-Indikator während automatischer Auswahl
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Grid wird geladen...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Dialog-Funktionen
  Future<void> _showNewProfileDialog(
    BuildContext context,
    ProfileProvider profileProvider,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const NewProfileDialog(),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await profileProvider.createProfile(name);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileCreated(name)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.profileCreateError(e),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteProfileDialog(
    BuildContext context,
    ProfileProvider profileProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.profileDeleteText),
        content: Text(
          AppLocalizations.of(
            context,
          )!.profileDeleteContent(profileProvider.selectedProfileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.profileDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && profileProvider.selectedProfileId != null) {
      try {
        await profileProvider.deleteProfile(profileProvider.selectedProfileId!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileDeleted),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.profileDeleteError(e),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showNewGridDialog(
    BuildContext context,
    GridProvider gridProvider,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const NewGridDialog(),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await gridProvider.createGrid(name);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.gridCreated(name)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.gridCreateError(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteGridDialog(
    BuildContext context,
    GridProvider gridProvider,
  ) async {
    final currentGrid = gridProvider.grids.firstWhere(
      (grid) => grid['id'] == gridProvider.selectedGridId,
      orElse: () => {'name': 'Unbekannt'},
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.gridDeleteText),
        content: Text(
          AppLocalizations.of(
            context,
          )!.gridDeleteContent(currentGrid['name'] as String),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.gridDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && gridProvider.selectedGridId != null) {
      await gridProvider.deleteGrid(gridProvider.selectedGridId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.gridDeleted),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class NewProfileDialog extends StatefulWidget {
  const NewProfileDialog({super.key});

  @override
  State<NewProfileDialog> createState() => _NewProfileDialogState();
}

class _NewProfileDialogState extends State<NewProfileDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.createNewProfile),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.prfileName,
          hintText: AppLocalizations.of(context)!.profileNamePlaceholder,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelButtonText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(AppLocalizations.of(context)!.createButtonText),
        ),
      ],
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
      title: Text(AppLocalizations.of(context)!.createNewGrid),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.gridName,
          hintText: AppLocalizations.of(context)!.gridNamePlaceholder,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelButtonText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(AppLocalizations.of(context)!.createButtonText),
        ),
      ],
    );
  }
}
