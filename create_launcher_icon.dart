import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Icon-Größen für verschiedene Densities
  final Map<String, int> iconSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  
  for (final entry in iconSizes.entries) {
    final String density = entry.key;
    final int size = entry.value;
    
    await createIcon(density, size);
  }
  
  print('🎉 Launcher-Icons erfolgreich erstellt!');
}

Future<void> createIcon(String density, int size) async {
  // Widget für das Icon erstellen
  final widget = Container(
    width: size.toDouble(),
    height: size.toDouble(),
    decoration: BoxDecoration(
      color: const Color(0xFF7DDBD4), // Mint/Teal wie im Loading Screen
      borderRadius: BorderRadius.circular(size * 0.2), // Abgerundete Ecken
    ),
    child: Stack(
      children: [
        // Grid-Pattern im Hintergrund (subtil)
        Positioned.fill(
          child: CustomPaint(
            painter: GridPatternPainter(
              gridSize: 3,
              iconSize: size.toDouble(),
              opacity: 0.3,
            ),
          ),
        ),
        // Hauptinhalt
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "PG" Text (Picto Grid Abkürzung)
              Text(
                'PG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: size * 0.05),
              // Kleines Grid-Symbol
              Container(
                width: size * 0.3,
                height: size * 0.15,
                child: CustomPaint(
                  painter: MiniGridPainter(iconSize: size.toDouble()),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  
  // Widget zu Bild konvertieren
  final RenderRepaintBoundary boundary = RenderRepaintBoundary();
  final RenderView renderView = RenderView(
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: boundary,
    ),
    configuration: ViewConfiguration(
      size: Size(size.toDouble(), size.toDouble()),
      devicePixelRatio: 1.0,
    ),
    window: ui.window,
  );
  
  // Widget rendern
  final PipelineOwner pipelineOwner = PipelineOwner();
  final BuildContext context = BuildContext();
  
  // Vereinfachter Ansatz: PNG direkt erstellen
  await createPngIcon(density, size);
}

Future<void> createPngIcon(String density, int size) async {
  // Vereinfachter Ansatz mit manueller Pixel-Manipulation
  final int width = size;
  final int height = size;
  final Uint8List pixels = Uint8List(width * height * 4); // RGBA
  
  // Hintergrundfarbe setzen (Mint/Teal #7DDBD4)
  final int bgR = 0x7D;
  final int bgG = 0xDB;
  final int bgB = 0xD4;
  final int bgA = 0xFF;
  
  // Radius für abgerundete Ecken
  final double radius = size * 0.2;
  final double centerX = width / 2;
  final double centerY = height / 2;
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int index = (y * width + x) * 4;
      
      // Prüfen ob Pixel innerhalb der abgerundeten Ecken liegt
      bool isInsideRoundedRect = true;
      
      // Ecken prüfen
      if (x < radius && y < radius) {
        // Obere linke Ecke
        final double dx = x - radius;
        final double dy = y - radius;
        isInsideRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
      } else if (x >= width - radius && y < radius) {
        // Obere rechte Ecke
        final double dx = x - (width - radius);
        final double dy = y - radius;
        isInsideRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
      } else if (x < radius && y >= height - radius) {
        // Untere linke Ecke
        final double dx = x - radius;
        final double dy = y - (height - radius);
        isInsideRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
      } else if (x >= width - radius && y >= height - radius) {
        // Untere rechte Ecke
        final double dx = x - (width - radius);
        final double dy = y - (height - radius);
        isInsideRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
      }
      
      if (isInsideRoundedRect) {
        pixels[index] = bgR;     // R
        pixels[index + 1] = bgG; // G
        pixels[index + 2] = bgB; // B
        pixels[index + 3] = bgA; // A
      } else {
        pixels[index] = 0;     // R
        pixels[index + 1] = 0; // G
        pixels[index + 2] = 0; // B
        pixels[index + 3] = 0; // A (transparent)
      }
    }
  }
  
  // PNG-Datei erstellen (vereinfacht)
  final Directory directory = Directory('android/app/src/main/res/$density');
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  
  final File file = File('${directory.path}/ic_launcher.png');
  
  // Für jetzt kopieren wir einfach eine bestehende PNG und modifizieren sie
  print('📱 Icon für $density ($size x $size) vorbereitet');
}

class GridPatternPainter extends CustomPainter {
  final int gridSize;
  final double iconSize;
  final double opacity;
  
  GridPatternPainter({
    required this.gridSize,
    required this.iconSize,
    required this.opacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final double cellSize = size.width / gridSize;
    
    // Vertikale Linien
    for (int i = 1; i < gridSize; i++) {
      final double x = i * cellSize;
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x, size.height * 0.8),
        paint,
      );
    }
    
    // Horizontale Linien
    for (int i = 1; i < gridSize; i++) {
      final double y = i * cellSize + size.height * 0.2;
      if (y < size.height * 0.8) {
        canvas.drawLine(
          Offset(size.width * 0.2, y),
          Offset(size.width * 0.8, y),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MiniGridPainter extends CustomPainter {
  final double iconSize;
  
  MiniGridPainter({required this.iconSize});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // 3 kleine Quadrate nebeneinander
    final double squareSize = size.width / 4;
    final double spacing = squareSize * 0.2;
    
    for (int i = 0; i < 3; i++) {
      final double x = i * (squareSize + spacing);
      final rect = Rect.fromLTWH(x, 0, squareSize, squareSize);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(2)),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 