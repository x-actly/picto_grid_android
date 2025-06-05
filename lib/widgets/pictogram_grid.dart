import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../models/pictogram.dart';
import 'package:provider/provider.dart';
import '../providers/grid_provider.dart';
import 'dart:math' as math;

class PictogramGrid extends StatefulWidget {
  final List<Pictogram> pictograms;
  final double itemSize;
  final Function? onGridSettingsPressed;
  final Function(bool)? onEditModeChanged;

  const PictogramGrid({
    super.key,
    required this.pictograms,
    this.itemSize = 150.0,
    this.onGridSettingsPressed,
    this.onEditModeChanged,
  });

  @override
  State<PictogramGrid> createState() => PictogramGridState();
}

class _GridDimensions {
  final int columns;
  final int rows;
  final double itemWidth;
  final double itemHeight;
  final int maxGridSize;

  _GridDimensions({
    required this.columns,
    required this.rows,
    required this.itemWidth,
    required this.itemHeight,
    required this.maxGridSize,
  });
}

class PictogramGridState extends State<PictogramGrid> {
  late List<PictogramPosition> _pictogramPositions;
  int _gridSize = 4;  // Standardmäßig 4x2
  bool _showGridLines = true;
  bool _isEditMode = false;
  final double _minItemSize = 100.0;
  final double _spacing = 10.0;
  bool _isInitialized = false;

  static const int MIN_GRID_SIZE = 4;  // Minimum ist jetzt 4
  static const int MAX_GRID_SIZE = 8;  // Maximum ist jetzt 8

  // Definiere die verfügbaren Grid-Größen
  static const Map<int, int> AVAILABLE_GRID_SIZES = {
    4: 2,  // 4x2
    8: 3,  // 8x3
  };

  @override
  void initState() {
    super.initState();
    // Initialisiere mit Standardwerten
    _pictogramPositions = List.generate(
      widget.pictograms.length,
      (index) => PictogramPosition(
        pictogram: widget.pictograms[index],
        row: index ~/ _gridSize,
        column: index % _gridSize,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _updatePositionsWithCurrentDimensions();
    }
  }

  void _updatePositionsWithCurrentDimensions() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final dimensions = calculateGridDimensions(size);
    setState(() {
      _pictogramPositions = List.generate(
        widget.pictograms.length,
        (index) => PictogramPosition(
          pictogram: widget.pictograms[index],
          row: index ~/ dimensions.columns,
          column: index % dimensions.columns,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(PictogramGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pictograms.length != oldWidget.pictograms.length ||
        !listEquals(widget.pictograms, oldWidget.pictograms)) {
      print('PictogramGrid: Piktogramme haben sich geändert');
      print('Alte Anzahl: ${oldWidget.pictograms.length}');
      print('Neue Anzahl: ${widget.pictograms.length}');
      _updatePositionsWithCurrentDimensions();
    }
  }

  _GridDimensions calculateGridDimensions(Size size) {
    // Berechne den tatsächlich verfügbaren Platz
    final availableWidth = size.width;
    final availableHeight = size.height;

    // Bestimme die Spalten basierend auf der gewählten Gridgröße
    final columns = _gridSize;
    final rows = AVAILABLE_GRID_SIZES[columns] ?? 2;

    // Berechne die Kästchengröße so, dass der gesamte verfügbare Platz genutzt wird
    final itemWidth = availableWidth / columns;
    final itemHeight = availableHeight / rows;

    return _GridDimensions(
      columns: columns,
      rows: rows,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      maxGridSize: MAX_GRID_SIZE,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = calculateGridDimensions(Size(
          constraints.maxWidth,
          constraints.maxHeight,
        ));

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
  }

  Widget _buildDropTargets(_GridDimensions dimensions) {
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
                  onWillAccept: (data) => true,
                  onAccept: (draggedPosition) {
                    _movePictogram(draggedPosition, row, col);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isTargeted = candidateData.isNotEmpty;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isTargeted ? Colors.orange : Colors.grey.withOpacity(0.3),
                          width: isTargeted ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isTargeted ? Colors.orange.withOpacity(0.1) : Colors.transparent,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  List<Widget> _buildPictogramTiles(_GridDimensions dimensions) {
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
        child: Draggable<PictogramPosition>(
          data: position,
          feedback: _buildPictogramCard(position.pictogram, dimensions.itemWidth, opacity: 0.7),
          childWhenDragging: Container(
            width: dimensions.itemWidth,
            height: dimensions.itemHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: GestureDetector(
            onLongPress: () => _showDeleteDialog(context, position.pictogram),
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
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.drag_indicator,
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
    }).toList();
  }

  Widget _buildGridLines(_GridDimensions dimensions) {
    return Stack(
      children: [
        ...List.generate(dimensions.rows + 1, (row) {
          return Positioned(
            top: row * dimensions.itemHeight,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: Colors.grey[300],
            ),
          );
        }),
        ...List.generate(dimensions.columns + 1, (col) {
          return Positioned(
            left: col * dimensions.itemWidth,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: Colors.grey[300],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPictogramCard(Pictogram pictogram, double size, {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: _isEditMode ? 4 : 1,
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Image.network(
                  pictogram.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Fehler beim Laden des Bildes: $error');
                    return const Center(
                      child: Icon(Icons.error),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  pictogram.keyword,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _movePictogram(PictogramPosition pictogram, int newRow, int newCol) {
    setState(() {
      final existingPictogram = _getPictogramAtPosition(newRow, newCol);
      if (existingPictogram != null) {
        final oldRow = pictogram.row;
        final oldCol = pictogram.column;
        existingPictogram.row = oldRow;
        existingPictogram.column = oldCol;
      }
      pictogram.row = newRow;
      pictogram.column = newCol;
    });
  }

  PictogramPosition? _getPictogramAtPosition(int row, int col) {
    try {
      return _pictogramPositions.firstWhere(
        (pos) => pos.row == row && pos.column == col,
      );
    } catch (e) {
      return null;
    }
  }

  void showGridSettingsDialog(_GridDimensions dimensions) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rastereinstellungen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rastergröße'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _gridSize = 4;
                          });
                          this.setState(() {});
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _gridSize == 4 ? Colors.teal.withOpacity(0.2) : null,
                        ),
                        child: const Text('4x2'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _gridSize = 8;
                          });
                          this.setState(() {});
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _gridSize == 8 ? Colors.teal.withOpacity(0.2) : null,
                        ),
                        child: const Text('8x3'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Rasterlinien anzeigen'),
                    value: _showGridLines,
                    onChanged: (value) {
                      setState(() {
                        _showGridLines = value;
                      });
                      this.setState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _gridSize = 4;
                      _showGridLines = true;
                    });
                    this.setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zurücksetzen'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Schließen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Pictogram pictogram) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Piktogramm löschen'),
        content: Text('Möchten Sie das Piktogramm "${pictogram.keyword}" wirklich aus dem Grid entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final gridProvider = context.read<GridProvider>();
      await gridProvider.removePictogramFromGrid(pictogram);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pictogram.keyword} wurde aus dem Grid entfernt'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    widget.onEditModeChanged?.call(_isEditMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode 
          ? 'Bearbeitungsmodus aktiviert' 
          : 'Bearbeitungsmodus deaktiviert'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class PictogramPosition {
  final Pictogram pictogram;
  int row;
  int column;

  PictogramPosition({
    required this.pictogram,
    required this.row,
    required this.column,
  });
}

class DraggablePictogramTile extends StatelessWidget {
  final PictogramPosition position;
  final double size;

  const DraggablePictogramTile({
    super.key,
    required this.position,
    required this.size,
  });

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
                child: Image.network(
                  position.pictogram.imageUrl,
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
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
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
                child: Image.network(
                  position.pictogram.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error_outline, color: Colors.red);
                  },
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