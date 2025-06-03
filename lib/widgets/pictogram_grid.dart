import 'package:flutter/material.dart';
import '../models/pictogram.dart';

class PictogramGrid extends StatefulWidget {
  final List<Pictogram> pictograms;
  final double itemSize;

  const PictogramGrid({
    super.key,
    required this.pictograms,
    this.itemSize = 150.0,
  });

  @override
  State<PictogramGrid> createState() => _PictogramGridState();
}

class _GridDimensions {
  final int columns;
  final int rows;
  final double itemSize;
  final int maxGridSize;

  _GridDimensions({
    required this.columns,
    required this.rows,
    required this.itemSize,
    required this.maxGridSize,
  });
}

class _PictogramGridState extends State<PictogramGrid> {
  late List<PictogramPosition> _pictogramPositions;
  int _gridSize = 4;
  bool _showGridLines = true;
  final ScrollController _scrollController = ScrollController();
  final double _minItemSize = 100.0;
  final double _spacing = 10.0;
  bool _isInitialized = false;

  static const int MIN_GRID_SIZE = 2;
  static const int MAX_GRID_SIZE = 8;

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
      _updatePictogramPositions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updatePictogramPositions() {
    if (!mounted) return;
    final dimensions = _calculateGridDimensions(MediaQuery.of(context).size);
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
    if (widget.pictograms != oldWidget.pictograms) {
      _updatePictogramPositions();
    }
  }

  _GridDimensions _calculateGridDimensions(Size size) {
    final aspectRatio = size.width / size.height;
    final isLandscape = aspectRatio > 1;

    final itemSizeWithSpacing = _minItemSize + _spacing;
    final smallerDimension = isLandscape ? size.height : size.width;
    final maxGridSize = ((smallerDimension - _spacing) / itemSizeWithSpacing).floor();

    final currentGridSize = _gridSize.clamp(MIN_GRID_SIZE, maxGridSize);

    final columns = currentGridSize;
    final rows = isLandscape 
        ? (currentGridSize * 1.5).floor() 
        : (currentGridSize * 2).floor();

    final itemSize = (size.width - (columns + 1) * _spacing) / columns;

    return _GridDimensions(
      columns: columns,
      rows: rows,
      itemSize: itemSize,
      maxGridSize: maxGridSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _calculateGridDimensions(Size(
          constraints.maxWidth,
          constraints.maxHeight,
        ));

        return _GridBuilder(
          dimensions: dimensions,
          pictogramPositions: _pictogramPositions,
          spacing: _spacing,
          showGridLines: _showGridLines,
          onShowSettingsDialog: () => _showGridSettingsDialog(dimensions),
          onMovePictogram: _movePictogram,
        );
      },
    );
  }

  void _showGridSettingsDialog(_GridDimensions dimensions) {
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
                  Slider(
                    value: _gridSize.toDouble(),
                    min: MIN_GRID_SIZE.toDouble(),
                    max: dimensions.maxGridSize.toDouble(),
                    divisions: dimensions.maxGridSize - MIN_GRID_SIZE,
                    label: _gridSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        _gridSize = value.round();
                      });
                      this.setState(() {
                        _updatePictogramPositions();
                      });
                    },
                  ),
                  Text('Aktuelle Größe: $_gridSize x ${dimensions.rows}'),
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
                    this.setState(() {
                      _updatePictogramPositions();
                    });
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

  void _movePictogram(PictogramPosition pictogram, int newRow, int newCol) {
    setState(() {
      final existingPictogram = _getPictogramAtPosition(newRow, newCol);
      if (existingPictogram != null) {
        existingPictogram.row = pictogram.row;
        existingPictogram.column = pictogram.column;
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
}

class _GridBuilder extends StatelessWidget {
  final _GridDimensions dimensions;
  final List<PictogramPosition> pictogramPositions;
  final double spacing;
  final bool showGridLines;
  final VoidCallback onShowSettingsDialog;
  final void Function(PictogramPosition, int, int) onMovePictogram;

  const _GridBuilder({
    required this.dimensions,
    required this.pictogramPositions,
    required this.spacing,
    required this.showGridLines,
    required this.onShowSettingsDialog,
    required this.onMovePictogram,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Stack(
        children: [
          if (showGridLines)
            ...List.generate(dimensions.rows + 1, (row) {
              return Positioned(
                top: row * (dimensions.itemSize + spacing),
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
              );
            }) +
            List.generate(dimensions.columns + 1, (col) {
              return Positioned(
                left: col * (dimensions.itemSize + spacing),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: Colors.grey[300],
                ),
              );
            }),

          ...List.generate(dimensions.rows * dimensions.columns, (index) {
            final row = index ~/ dimensions.columns;
            final col = index % dimensions.columns;
            final xPos = col * (dimensions.itemSize + spacing) + spacing / 2;
            final yPos = row * (dimensions.itemSize + spacing) + spacing / 2;

            return Positioned(
              left: xPos,
              top: yPos,
              width: dimensions.itemSize,
              height: dimensions.itemSize,
              child: _buildDragTarget(row, col),
            );
          }),

          ...pictogramPositions.map((position) {
            final xPos = position.column * (dimensions.itemSize + spacing) + spacing / 2;
            final yPos = position.row * (dimensions.itemSize + spacing) + spacing / 2;

            return Positioned(
              left: xPos,
              top: yPos,
              width: dimensions.itemSize,
              height: dimensions.itemSize,
              child: DraggablePictogramTile(
                key: ValueKey(position.pictogram.id),
                position: position,
                size: dimensions.itemSize,
              ),
            );
          }),

          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton(
              mini: true,
              onPressed: onShowSettingsDialog,
              child: const Icon(Icons.grid_4x4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(int row, int col) {
    return DragTarget<PictogramPosition>(
      onWillAccept: (data) => true,
      onAccept: (data) => onMovePictogram(data, row, col),
      builder: (context, candidateData, rejectedData) {
        final pictogram = pictogramPositions.cast<PictogramPosition?>().firstWhere(
          (pos) => pos?.row == row && pos?.column == col,
          orElse: () => null,
        );
        
        if (pictogram == null) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          );
        }
        return const SizedBox();
      },
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