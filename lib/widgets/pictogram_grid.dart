import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:picto_grid/l10n/app_localizations.dart';
import 'dart:io';
import 'package:picto_grid/models/pictogram.dart';
import 'package:provider/provider.dart';
import 'package:picto_grid/providers/grid_provider.dart';
import 'package:picto_grid/services/tts_service.dart';
import 'package:picto_grid/widgets/pictogram_selection_dialog.dart';
import 'package:picto_grid/services/custom_pictogram_service.dart';
import 'package:picto_grid/services/database_helper.dart';

class PictogramGrid extends StatefulWidget {
  const PictogramGrid({
    super.key,
    required this.pictograms,
    this.itemSize = 150.0,
    this.onGridSettingsPressed,
    this.onEditModeChanged,
  });
  final List<Pictogram> pictograms;
  final double itemSize;
  final Function? onGridSettingsPressed;
  final Function(bool)? onEditModeChanged;

  @override
  State<PictogramGrid> createState() => PictogramGridState();
}

class GridDimensions {
  GridDimensions({
    required this.columns,
    required this.rows,
    required this.itemWidth,
    required this.itemHeight,
    required this.maxGridSize,
  });
  final int columns;
  final int rows;
  final double itemWidth;
  final double itemHeight;
  final int maxGridSize;
}

class PictogramGridState extends State<PictogramGrid>
    with TickerProviderStateMixin {
  late List<PictogramPosition> _pictogramPositions;
  bool _showGridLines = true;
  bool _isEditMode = false;
  bool _isInitialized = false;
  bool _isEnglish = false; // Default to false (Deutsch)
  int? _lastKnownGridSize; // 🔧 Für Grid-Größen-Änderungs-Detection

  // TTS und visuelles Feedback
  final TtsService _ttsService = TtsService();
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  Pictogram? _activePictogram;
  double _ttsVolume = 0.8;
  double _ttsSpeechRate = 0.5;

  static const int minGridSize = 4; // Minimum ist jetzt 4
  static const int maxGridSize = 8; // Maximum ist jetzt 8

  // Definiere die verfügbaren Grid-Größen
  static const Map<int, int> availableGridSizes = {
    4: 2, // 4x2
    8: 3, // 8x3
  };

  // Hilfsfunktion um die aktuelle Grid-Größe zu erhalten
  int get _gridSize {
    try {
      final gridProvider = context.read<GridProvider>();
      return gridProvider.currentGridSize;
    } catch (e) {
      // Fallback wenn Provider noch nicht verfügbar ist
      return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialisiere mit Standardwerten
    _pictogramPositions = List.generate(
      widget.pictograms.length,
      (index) => PictogramPosition(
        pictogram: widget.pictograms[index],
        row: index ~/ 4, // Verwende erstmal Standard-Wert
        column: index % 4,
      ),
    );

    // Initialisiere TTS-Service
    _ttsService.initialize();

    // Initialisiere Animation für visuelles Feedback (dezenter)
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _feedbackAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.05, // Weniger Skalierung
        ).animate(
          CurvedAnimation(
            parent: _feedbackController,
            curve: Curves.easeOut, // Sanftere Kurve
          ),
        );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// Hilfsfunktion zum Laden von Bildern (lokal oder online)
  Widget _buildPictogramImage(
    Pictogram pictogram, {
    BoxFit fit = BoxFit.contain,
  }) {
    return _PictogramImageWidget(imageUrl: pictogram.imageUrl, fit: fit);
  }

  // Piktogramm sprechen und visuelles Feedback anzeigen
  Future<void> _playPictogram(Pictogram pictogram) async {
    if (_isEditMode) return; // Kein TTS im Bearbeitungsmodus

    if (kDebugMode) {
      print('Spiele Piktogramm ab: ${pictogram.keyword}');
    }

    setState(() {
      _activePictogram = pictogram;
    });

    // Visuelles Feedback starten
    _feedbackController.forward().then((_) {
      _feedbackController.reverse();
    });

    // TTS abspielen
    try {
      await _ttsService.speak(pictogram.keyword);
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei TTS: $e');
      }
      // Fallback: Zeige Snackbar wenn TTS nicht funktioniert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.ttsErrorText(pictogram.keyword),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    // Nach kurzer Zeit das aktive Piktogramm zurücksetzen (dezenter)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _activePictogram = null;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _lastKnownGridSize = _gridSize; // 🔧 Initialisiere Grid-Größe
      _updatePositionsWithCurrentDimensions();
    }
  }

  void _updatePositionsWithCurrentDimensions() async {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final dimensions = calculateGridDimensions(size);

    // Lade Positionsdaten vom Provider
    final gridProvider = context.read<GridProvider>();
    final pictogramData = gridProvider.currentGridPictogramData;

    // 🔧 Erst DB-Operationen außerhalb von setState
    final tempPositions = <PictogramPosition>[];

    for (int i = 0; i < widget.pictograms.length; i++) {
      final pictogram = widget.pictograms[i];
      int targetRow = i ~/ dimensions.columns;
      int targetColumn = i % dimensions.columns;

      // Suche nach den gespeicherten Positionsdaten für dieses Piktogramm
      final dataList = pictogramData
          .where((data) => data['pictogram_id'] == pictogram.id)
          .toList();

      if (kDebugMode) {
        print(
          'PictogramGrid: 🔍 Suche ${pictogram.keyword} (ID: ${pictogram.id}) in ${pictogramData.length} DB-Einträgen',
        );
        if (pictogramData.isNotEmpty) {
          print(
            'PictogramGrid: 📋 Verfügbare DB-IDs: ${pictogramData.map((d) => d['pictogram_id']).toList()}',
          );
        }
      }

      if (dataList.isNotEmpty) {
        final data = dataList.first;

        // 🎯 VERWENDE NUR DIE GESPEICHERTEN ROW/COLUMN WERTE (KEIN FALLBACK)!
        if (data.containsKey('row_position') &&
            data.containsKey('column_position')) {
          final int savedRow = data['row_position'] ?? 0;
          final int savedColumn = data['column_position'] ?? 0;

          // Prüfe, ob die gespeicherte Position im aktuellen Grid gültig ist
          if (kDebugMode) {
            print(
              'PictogramGrid: ${pictogram.keyword} - Validierung: ($savedRow,$savedColumn) gegen Grid ${dimensions.columns}x${dimensions.rows}',
            );
            print(
              'PictogramGrid: Prüfung: $savedRow < ${dimensions.rows} = ${savedRow < dimensions.rows}, $savedColumn < ${dimensions.columns} = ${savedColumn < dimensions.columns}',
            );
          }

          if (savedRow < dimensions.rows && savedColumn < dimensions.columns) {
            targetRow = savedRow;
            targetColumn = savedColumn;

            if (kDebugMode) {
              print(
                'PictogramGrid: ${pictogram.keyword} → ($targetRow,$targetColumn) [gespeicherte row/col - GÜLTIG]',
              );
            }
          } else {
            if (kDebugMode) {
              print(
                'PictogramGrid: ${pictogram.keyword} → ($savedRow,$savedColumn) außerhalb Grid ${dimensions.columns}x${dimensions.rows}, verwende Index-Position ($targetRow,$targetColumn)',
              );
            }
          }
        } else {
          if (kDebugMode) {
            print(
              'PictogramGrid: ${pictogram.keyword} → ($targetRow,$targetColumn) [keine row/col Daten in DB - Index-Position]',
            );
          }
        }
      } else {
        // Keine Daten für dieses Piktogramm gefunden - SOFORT REPARIEREN
        final gridProvider = context.read<GridProvider>();

        // 🔧 SELBST-REPARIEREND: Speichere Index-Position sofort in DB
        final db = DatabaseHelper.instance;
        final linearPosition = targetRow * dimensions.columns + targetColumn;
        await db.updatePictogramPosition(
          gridProvider.selectedGridId!,
          pictogram.id,
          linearPosition,
          rowPosition: targetRow,
          columnPosition: targetColumn,
        );

        if (kDebugMode) {
          print(
            'PictogramGrid: ${pictogram.keyword} → ($targetRow,$targetColumn) [keine DB-Daten - Index-Position gespeichert]',
          );
        }
      }

      tempPositions.add(
        PictogramPosition(
          pictogram: pictogram,
          row: targetRow,
          column: targetColumn,
        ),
      );
    }

    // Jetzt setState mit den vorbereiteten Daten
    setState(() {
      _pictogramPositions = tempPositions;
    });
  }

  @override
  void didUpdateWidget(PictogramGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Prüfe auf Änderungen der Piktogramme
    if (widget.pictograms.length != oldWidget.pictograms.length ||
        !listEquals(widget.pictograms, oldWidget.pictograms)) {
      if (kDebugMode) {
        print('PictogramGrid: Piktogramme haben sich geändert');
        print('Alte Anzahl: ${oldWidget.pictograms.length}');
        print('Neue Anzahl: ${widget.pictograms.length}');
      }
      _updatePositionsWithCurrentDimensions();
      return;
    }

    // 🔧 BUGFIX: Prüfe auch auf Grid-Größen-Änderungen
    final currentGridSize = _gridSize;
    if (_lastKnownGridSize != currentGridSize) {
      if (kDebugMode) {
        print(
          'PictogramGrid: Grid-Größe hat sich geändert: $_lastKnownGridSize → $currentGridSize',
        );
      }
      _lastKnownGridSize = currentGridSize;
      _updatePositionsWithCurrentDimensions();
    }
  }

  GridDimensions calculateGridDimensions(Size size) {
    // Berechne den tatsächlich verfügbaren Platz
    final availableWidth = size.width;
    final availableHeight = size.height;

    // Bestimme die Spalten basierend auf der gewählten Gridgröße
    final columns = _gridSize;
    final rows = availableGridSizes[columns] ?? 2;

    // Berechne die Kästchengröße so, dass der gesamte verfügbare Platz genutzt wird
    final itemWidth = availableWidth / columns;
    final itemHeight = availableHeight / rows;

    return GridDimensions(
      columns: columns,
      rows: rows,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      maxGridSize: maxGridSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final dimensions = calculateGridDimensions(
              Size(constraints.maxWidth, constraints.maxHeight),
            );

            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.grey[100],
              child: Stack(
                children: [
                  if (_showGridLines) _buildGridLines(dimensions),
                  if (_isEditMode) _buildDropTargets(dimensions),
                  ..._buildPictogramTiles(dimensions),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropTargets(GridDimensions dimensions) {
    return Stack(
      children: [
        for (int row = 0; row < dimensions.rows; row++)
          for (int col = 0; col < dimensions.columns; col++)
            if (_getPictogramAtPosition(row, col) == null)
              Positioned(
                left: col * dimensions.itemWidth,
                top: row * dimensions.itemHeight,
                width: dimensions.itemWidth,
                height: dimensions.itemHeight,
                child: DragTarget<PictogramPosition>(
                  onWillAcceptWithDetails: (data) => true,
                  onAcceptWithDetails: (details) {
                    _movePictogram(details.data, row, col);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isTargeted = candidateData.isNotEmpty;
                    final existingPictogram = _getPictogramAtPosition(row, col);
                    final willSwap = isTargeted && existingPictogram != null;

                    return GestureDetector(
                      onTap: () =>
                          _showPictogramSelectionDialog(context, row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isTargeted
                                ? (willSwap ? Colors.blue : Colors.orange)
                                : Colors.grey.withAlpha(30),
                            width: isTargeted ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isTargeted
                              ? (willSwap
                                    ? Colors.blue.withAlpha(15)
                                    : Colors.orange.withAlpha(10))
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: willSwap
                              ? const Icon(
                                  Icons.swap_horiz,
                                  color: Colors.blue,
                                  size: 32,
                                )
                              : const Icon(
                                  Icons.add,
                                  color: Colors.grey,
                                  size: 32,
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

  List<Widget> _buildPictogramTiles(GridDimensions dimensions) {
    return _pictogramPositions.map((position) {
      final tile = SizedBox(
        width: dimensions.itemWidth,
        height: dimensions.itemHeight,
        child: _buildPictogramCard(position.pictogram, dimensions.itemWidth),
      );

      if (!_isEditMode) {
        return Positioned(
          left: position.column * dimensions.itemWidth,
          top: position.row * dimensions.itemHeight,
          child: tile,
        );
      }

      return Positioned(
        left: position.column * dimensions.itemWidth,
        top: position.row * dimensions.itemHeight,
        child: DragTarget<PictogramPosition>(
          onWillAcceptWithDetails: (data) =>
              data.data != position, // Nicht auf sich selbst droppen
          onAcceptWithDetails: (details) {
            _movePictogram(details.data, position.row, position.column);
          },
          builder: (context, candidateData, rejectedData) {
            final isTargeted = candidateData.isNotEmpty;
            final willSwap = isTargeted && candidateData.first != position;

            return Draggable<PictogramPosition>(
              data: position,
              feedback: _buildPictogramCard(
                position.pictogram,
                dimensions.itemWidth,
                opacity: 0.7,
              ),
              childWhenDragging: Container(
                width: dimensions.itemWidth,
                height: dimensions.itemHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withAlpha(30),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: willSwap
                    ? const Center(
                        child: Icon(
                          Icons.swap_horiz,
                          color: Colors.blue,
                          size: 32,
                        ),
                      )
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: willSwap
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  color: willSwap ? Colors.blue.withAlpha(15) : null,
                ),
                child: GestureDetector(
                  onTap: () => _playPictogram(position.pictogram),
                  onLongPress: () =>
                      _showDeleteDialog(context, position.pictogram),
                  child: Stack(
                    children: [
                      tile,
                      if (_isEditMode)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: willSwap
                                  ? Colors.blue.withAlpha(80)
                                  : Colors.orange.withAlpha(80),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              willSwap
                                  ? Icons.swap_horiz
                                  : Icons.drag_indicator,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (willSwap)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(80),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildGridLines(GridDimensions dimensions) {
    return Stack(
      children: [
        ...List.generate(dimensions.rows + 1, (row) {
          return Positioned(
            top: row * dimensions.itemHeight,
            left: 0,
            right: 0,
            child: Container(height: 1, color: Colors.grey[300]),
          );
        }),
        ...List.generate(dimensions.columns + 1, (col) {
          return Positioned(
            left: col * dimensions.itemWidth,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: Colors.grey[300]),
          );
        }),
      ],
    );
  }

  Widget _buildPictogramCard(
    Pictogram pictogram,
    double size, {
    double opacity = 1.0,
  }) {
    final isActive = _activePictogram?.id == pictogram.id;

    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        final scale = isActive ? _feedbackAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: () => _playPictogram(pictogram),
              child: Card(
                elevation: _isEditMode
                    ? 4
                    : (isActive ? 3 : 2), // Weniger Elevation
                color: isActive
                    ? Colors.teal.withAlpha(5)
                    : null, // Weniger sichtbare Farbe
                child: Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(4),
                  decoration: isActive
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.withAlpha(
                              60,
                            ), // Weniger intensive Randfarbe
                            width: 1.5, // Dünnerer Rand
                          ),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            _buildPictogramImage(pictogram),
                            if (isActive)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withAlpha(80),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                    size: 14, // Kleineres Icon
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          pictogram.keyword,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.normal, // Weniger fett
                            color: isActive
                                ? Colors.teal.withAlpha(80)
                                : null, // Weniger intensive Textfarbe
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _movePictogram(
    PictogramPosition pictogram,
    int newRow,
    int newCol,
  ) async {
    final existingPictogram = _getPictogramAtPosition(newRow, newCol);
    final bool isSwap = existingPictogram != null;

    setState(() {
      if (existingPictogram != null) {
        // 🔄 SWAP: Tausche die Positionen der beiden Piktogramme
        final oldRow = pictogram.row;
        final oldCol = pictogram.column;
        existingPictogram.row = oldRow;
        existingPictogram.column = oldCol;

        if (kDebugMode) {
          print(
            'PictogramGrid: 🔄 SWAP - "${pictogram.pictogram.keyword}" ↔ "${existingPictogram.pictogram.keyword}"',
          );
          print(
            '  "${pictogram.pictogram.keyword}": ($oldRow,$oldCol) → ($newRow,$newCol)',
          );
          print(
            '  "${existingPictogram.pictogram.keyword}": ($newRow,$newCol) → ($oldRow,$oldCol)',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            'PictogramGrid: ➡️ MOVE - "${pictogram.pictogram.keyword}" zu freier Position ($newRow,$newCol)',
          );
        }
      }

      pictogram.row = newRow;
      pictogram.column = newCol;
    });

    // 🔧 SOFORT Positionen in DB aktualisieren
    final gridProvider = context.read<GridProvider>();
    final db = DatabaseHelper.instance;
    final dimensions = calculateGridDimensions(MediaQuery.of(context).size);

    // Hauptpiktogramm aktualisieren
    final linearPosition = newRow * dimensions.columns + newCol;
    await db.updatePictogramPosition(
      gridProvider.selectedGridId!,
      pictogram.pictogram.id,
      linearPosition,
      rowPosition: newRow,
      columnPosition: newCol,
    );

    // Bei Swap: Auch das getauschte Piktogramm aktualisieren
    if (isSwap) {
      final swapLinearPosition =
          existingPictogram.row * dimensions.columns + existingPictogram.column;
      await db.updatePictogramPosition(
        gridProvider.selectedGridId!,
        existingPictogram.pictogram.id,
        swapLinearPosition,
        rowPosition: existingPictogram.row,
        columnPosition: existingPictogram.column,
      );
    }

    // Speichere alle aktualisierten Positionen in der Datenbank
    _savePictogramPositions();
  }

  /// Löscht ein Piktogramm komplett aus dem Grid und der Datenbank
  void _deletePictogram(PictogramPosition pictogramPosition) async {
    final gridProvider = context.read<GridProvider>();
    final db = DatabaseHelper.instance;

    // 🔧 KOMPLETTES Löschen aus der Datenbank
    await db.removePictogramFromGrid(
      gridProvider.selectedGridId!,
      pictogramPosition.pictogram.id,
    );

    if (kDebugMode) {
      print(
        'PictogramGrid: "${pictogramPosition.pictogram.keyword}" komplett aus Grid und DB gelöscht',
      );
    }

    // UI aktualisieren - Position wird automatisch frei
    setState(() {
      _pictogramPositions.removeWhere(
        (pos) => pos.pictogram.id == pictogramPosition.pictogram.id,
      );
    });

    // Grid-Provider benachrichtigen
    await gridProvider.loadGridPictograms();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.removedFromGridText(pictogramPosition.pictogram.keyword),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Speichert alle aktuellen Piktogramm-Positionen in der Datenbank
  void _savePictogramPositions() {
    if (!mounted) return;

    final gridProvider = context.read<GridProvider>();
    final dimensions = calculateGridDimensions(MediaQuery.of(context).size);

    final pictogramPositions = _pictogramPositions.map((pos) {
      // Berechne lineare Position basierend auf row/column
      final linearPosition = pos.row * dimensions.columns + pos.column;
      return {
        'pictogram_id': pos.pictogram.id,
        'position': linearPosition,
        'row': pos.row, // 🎯 Speichere row direkt!
        'column': pos.column, // 🎯 Speichere column direkt!
      };
    }).toList();

    gridProvider.savePictogramPositions(pictogramPositions);

    if (kDebugMode) {
      print(
        'PictogramGrid: ${pictogramPositions.length} Positionen gespeichert (mit row/column)',
      );
    }
  }

  PictogramPosition? _getPictogramAtPosition(int row, int col) {
    try {
      final result = _pictogramPositions.firstWhere(
        (pos) => pos.row == row && pos.column == col,
      );
      if (kDebugMode) {
        print(
          'PictogramGrid: Position ($row,$col) ist belegt mit: ${result.pictogram.keyword}',
        );
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('PictogramGrid: Position ($row,$col) ist frei');
      }
      return null;
    }
  }

  void showGridSettingsDialog(GridDimensions dimensions) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.gridSettingsText),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.gridSizeText),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (!mounted) return;
                          final gridProvider = context.read<GridProvider>();
                          final navigator = Navigator.of(context);
                          await gridProvider.updateGridSize(4);
                          if (mounted) {
                            setState(() {
                              _showGridLines = true;
                            });
                          }
                          navigator.pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _gridSize == 4
                              ? Colors.teal.withAlpha(20)
                              : null,
                        ),
                        child: const Text('4x2'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (!mounted) return;
                          final gridProvider = context.read<GridProvider>();
                          final navigator = Navigator.of(context);
                          await gridProvider.updateGridSize(8);
                          if (mounted) {
                            setState(() {});
                          }
                          navigator.pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _gridSize == 8
                              ? Colors.teal.withAlpha(20)
                              : null,
                        ),
                        child: const Text('8x3'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.showGridLinesText,
                    ),
                    value: _showGridLines,
                    onChanged: (value) {
                      setState(() {
                        _showGridLines = value;
                      });
                      this.setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.languageSettingsText),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.volumeText),
                      Expanded(
                        child: Slider(
                          value: _ttsVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_ttsVolume * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              _ttsVolume = value;
                            });
                            this.setState(() {});
                            _ttsService.setVolume(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.speechRateText),
                      Expanded(
                        child: Slider(
                          value: _ttsSpeechRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(_ttsSpeechRate * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              _ttsSpeechRate = value;
                            });
                            this.setState(() {});
                            _ttsService.setSpeechRate(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: !_isEnglish,
                        onChanged: (value) {
                          setState(() {
                            _isEnglish = false;
                          });
                          this.setState(() {});
                          _flutterTts.setLanguage('de-DE');
                        },
                      ),
                      const Text('Deutsch'),
                      Checkbox(
                        value: _isEnglish,
                        onChanged: (value) {
                          setState(() {
                            _isEnglish = true;
                          });
                          this.setState(() {});
                          _flutterTts.setLanguage('en-US');
                        },
                      ),
                      const Text('English'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (!mounted) return;
                    final gridProvider = context.read<GridProvider>();
                    await gridProvider.updateGridSize(4);
                    if (mounted) {
                      setState(() {
                        _showGridLines = true;
                      });
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.resetText),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.closeText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Pictogram pictogram,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePictogramText),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deletePictogramContent(pictogram.keyword),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteText),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // 🔧 Finde die PictogramPosition für das zu löschende Piktogramm
      final pictogramPosition = _pictogramPositions.firstWhere(
        (pos) => pos.pictogram.id == pictogram.id,
        orElse: () =>
            PictogramPosition(pictogram: pictogram, row: 0, column: 0),
      );

      // Verwende die neue _deletePictogram Methode
      _deletePictogram(pictogramPosition);
    }
  }

  void toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    widget.onEditModeChanged?.call(_isEditMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? AppLocalizations.of(context)!.editmodeactiveText
              : AppLocalizations.of(context)!.editmodeinactiveText,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Zeigt den Piktogramm-Auswahl-Dialog für ein spezifisches Kästchen
  void _showPictogramSelectionDialog(BuildContext context, int row, int col) {
    if (kDebugMode) {
      print(
        '🔵 Grid: Zeige Piktogramm-Auswahl-Dialog für Kästchen ($row,$col)',
      );
    }
    PictogramSelectionDialog.show(context, (selectedPictogram) async {
      if (kDebugMode) {
        print('🔵 Grid: Piktogramm ausgewählt: ${selectedPictogram.keyword}');
      }

      // Prüfe ob es sich um ein temporäres benutzerdefiniertes Piktogramm handelt
      if (_isTemporaryCustomPictogram(selectedPictogram)) {
        if (kDebugMode) {
          print('🔵 Grid: Zeige Naming-Dialog für temporäres Piktogramm');
        }
        final renamedPictogram = await _showNamingDialogForPictogram(
          context,
          selectedPictogram,
        );
        if (renamedPictogram != null && context.mounted) {
          _addPictogramToGrid(
            context,
            renamedPictogram,
            targetRow: row,
            targetCol: col,
          );
        }
      } else {
        _addPictogramToGrid(
          context,
          selectedPictogram,
          targetRow: row,
          targetCol: col,
        );
      }
    });
  }

  /// Prüft ob es sich um ein temporäres benutzerdefiniertes Piktogramm handelt
  bool _isTemporaryCustomPictogram(Pictogram pictogram) {
    return pictogram.keyword.startsWith('Galerie_') ||
        pictogram.keyword.startsWith('Foto_');
  }

  /// Zeigt den Naming-Dialog für ein Piktogramm an
  Future<Pictogram?> _showNamingDialogForPictogram(
    BuildContext context,
    Pictogram pictogram,
  ) async {
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
                  child: _PictogramImageWidget(
                    imageUrl: pictogram.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.nameForSpeechLabel,
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
        print(
          '🔵 Grid: Benenne Piktogramm um: ${pictogram.keyword} → ${result['name']}',
        );
      }

      // Erstelle neues Piktogramm mit dem gewählten Namen
      final renamedPictogram = Pictogram(
        id: pictogram.id,
        keyword: result['name']!,
        imageUrl: pictogram.imageUrl,
        description: result['description'] ?? '',
        category: 'Benutzerdefiniert',
      );

      // Aktualisiere das Custom-Piktogramm im Service
      await CustomPictogramService.instance.updateCustomPictogram(
        renamedPictogram,
      );

      return renamedPictogram;
    }

    return null;
  }

  /// Fügt ein Piktogramm zum Grid hinzu
  void _addPictogramToGrid(
    BuildContext context,
    Pictogram pictogram, {
    required int targetRow,
    required int targetCol,
  }) async {
    if (kDebugMode) {
      print(
        'PictogramGrid: Versuche Piktogramm "${pictogram.keyword}" zu Position ($targetRow,$targetCol) hinzuzufügen',
      );
      print(
        'PictogramGrid: Aktuelle _pictogramPositions Anzahl: ${_pictogramPositions.length}',
      );
      print(
        'PictogramGrid: widget.pictograms Anzahl: ${widget.pictograms.length}',
      );
    }

    // Füge das Piktogramm zum Grid hinzu
    final gridProvider = context.read<GridProvider>();
    await gridProvider.addPictogramToGrid(
      pictogram,
      targetRow: targetRow,
      targetCol: targetCol,
    );

    if (kDebugMode) {
      print(
        'PictogramGrid: Piktogramm "${pictogram.keyword}" zu Position ($targetRow,$targetCol) hinzugefügt',
      );
    }

    // Aktualisiere die Position im Grid nach dem Hinzufügen
    if (mounted) {
      setState(() {
        _updatePositionsWithCurrentDimensions();
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.addedToGridText(pictogram.keyword),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

/// Wiederverwendbares Widget für Piktogramm-Bilder
class _PictogramImageWidget extends StatelessWidget {
  const _PictogramImageWidget({
    required this.imageUrl,
    this.fit = BoxFit.contain,
  });
  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      // Lokales Asset-Bild
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('Fehler beim Laden des lokalen Bildes: $error');
          }
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      );
    } else if (imageUrl.startsWith('/') ||
        imageUrl.contains('custom_pictograms')) {
      // Benutzerdefiniertes lokales Bild
      return Image.file(
        File(imageUrl),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('Fehler beim Laden des benutzerdefinierten Bildes: $error');
          }
          return const Center(child: Icon(Icons.photo, color: Colors.grey));
        },
      );
    } else {
      // Fallback für unbekannte Bildtypen - versuche als Asset
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('Fehler beim Laden des Bildes: $error');
          }
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      );
    }
  }
}

class PictogramPosition {
  PictogramPosition({
    required this.pictogram,
    required this.row,
    required this.column,
  });
  final Pictogram pictogram;
  int row;
  int column;
}

class DraggablePictogramTile extends StatelessWidget {
  const DraggablePictogramTile({
    super.key,
    required this.position,
    required this.size,
  });
  final PictogramPosition position;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Draggable<PictogramPosition>(
      data: position,
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _PictogramImageWidget(
                  imageUrl: position.pictogram.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                position.pictogram.keyword,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(30), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Card(
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _PictogramImageWidget(
                  imageUrl: position.pictogram.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                position.pictogram.keyword,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
