import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

void main() async {
  if (kDebugMode) {
    print('🎨 Erstelle PictoGrid Launcher-Icons...');
  }

  // Haupticon erstellen (1024x1024)
  await createMainIcon();

  // Vordergrund-Icon für adaptive Icons erstellen
  await createForegroundIcon();

  if (kDebugMode) {
    print('✅ Icons erfolgreich erstellt!');
    print('📁 Haupticon: assets/icon/icon.png');
    print('📁 Vordergrund: assets/icon/foreground.png');
  }
}

Future<void> createMainIcon() async {
  // 1024x1024 Bild erstellen
  const int size = 1024;
  final image = img.Image(width: size, height: size);

  // Mint/Teal Hintergrund (#7DDBD4)
  img.fill(image, color: img.ColorRgb8(0x7D, 0xDB, 0xD4));

  // Abgerundete Ecken (optional)
  createRoundedCorners(image, 100);

  // "PG" Text in Weiß zeichnen
  drawPGText(image);

  // Grid-Symbole zeichnen
  drawGridSymbols(image);

  // PNG speichern
  final pngBytes = img.encodePng(image);
  await File('assets/icon/icon.png').writeAsBytes(pngBytes);

  if (kDebugMode) {
    print('📱 Haupticon erstellt (1024x1024)');
  }
}

Future<void> createForegroundIcon() async {
  // 1024x1024 transparentes Bild
  const int size = 1024;
  final image = img.Image(width: size, height: size);

  // Transparent füllen
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Weißen Inhalt zeichnen
  drawPGText(image, isTransparent: true);
  drawGridSymbols(image, isTransparent: true);

  // PNG speichern
  final pngBytes = img.encodePng(image);
  await File('assets/icon/foreground.png').writeAsBytes(pngBytes);

  if (kDebugMode) {
    print('📱 Vordergrund-Icon erstellt (1024x1024)');
  }
}

void createRoundedCorners(img.Image image, int radius) {
  // Einfache abgerundete Ecken durch Transparenz
  final int width = image.width;
  final int height = image.height;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // Prüfe ob Pixel in den Ecken liegt
      bool shouldBeTransparent = false;

      // Obere linke Ecke
      if (x < radius && y < radius) {
        final dx = x - radius;
        final dy = y - radius;
        shouldBeTransparent = (dx * dx + dy * dy) > (radius * radius);
      }
      // Obere rechte Ecke
      else if (x >= width - radius && y < radius) {
        final dx = x - (width - radius);
        final dy = y - radius;
        shouldBeTransparent = (dx * dx + dy * dy) > (radius * radius);
      }
      // Untere linke Ecke
      else if (x < radius && y >= height - radius) {
        final dx = x - radius;
        final dy = y - (height - radius);
        shouldBeTransparent = (dx * dx + dy * dy) > (radius * radius);
      }
      // Untere rechte Ecke
      else if (x >= width - radius && y >= height - radius) {
        final dx = x - (width - radius);
        final dy = y - (height - radius);
        shouldBeTransparent = (dx * dx + dy * dy) > (radius * radius);
      }

      if (shouldBeTransparent) {
        image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      }
    }
  }
}

void drawPGText(img.Image image, {bool isTransparent = false}) {
  final color = isTransparent
    ? img.ColorRgba8(255, 255, 255, 255)
    : img.ColorRgb8(255, 255, 255);

  // Vereinfachte "P" und "G" Buchstaben
  final int centerX = image.width ~/ 2;
  final int centerY = image.height ~/ 2 - 80;
  final int strokeWidth = 40;
  final int letterHeight = 200;
  final int letterWidth = 120;

  // "P" zeichnen (links)
  drawLetter(image, centerX - letterWidth - 20, centerY, letterWidth, letterHeight, strokeWidth, color, 'P');

  // "G" zeichnen (rechts)
  drawLetter(image, centerX + 20, centerY, letterWidth, letterHeight, strokeWidth, color, 'G');
}

void drawLetter(img.Image image, int x, int y, int width, int height, int strokeWidth, img.Color color, String letter) {
  if (letter == 'P') {
    // P: Vertikaler Strich + 2 horizontale Striche
    img.fillRect(image, x1: x, y1: y, x2: x + strokeWidth, y2: y + height, color: color);
    img.fillRect(image, x1: x, y1: y, x2: x + width - 20, y2: y + strokeWidth, color: color);
    img.fillRect(image, x1: x, y1: y + height ~/ 2 - strokeWidth ~/ 2, x2: x + width - 20, y2: y + height ~/ 2 + strokeWidth ~/ 2, color: color);
  } else if (letter == 'G') {
    // G: C-Form + horizontaler Strich in der Mitte
    img.fillRect(image, x1: x, y1: y, x2: x + strokeWidth, y2: y + height, color: color);
    img.fillRect(image, x1: x, y1: y, x2: x + width, y2: y + strokeWidth, color: color);
    img.fillRect(image, x1: x, y1: y + height - strokeWidth, x2: x + width, y2: y + height, color: color);
    img.fillRect(image, x1: x + width ~/ 2, y1: y + height ~/ 2 - strokeWidth ~/ 2, x2: x + width, y2: y + height ~/ 2 + strokeWidth ~/ 2, color: color);
  }
}

void drawGridSymbols(img.Image image, {bool isTransparent = false}) {
  final color = isTransparent
    ? img.ColorRgba8(255, 255, 255, 255)
    : img.ColorRgb8(255, 255, 255);

  // 3 kleine Quadrate als Grid-Symbol
  final int centerX = image.width ~/ 2;
  final int startY = image.height ~/ 2 + 120;
  final int squareSize = 60;
  final int spacing = 30;

  for (int i = 0; i < 3; i++) {
    final int x = centerX - squareSize - spacing + i * (squareSize + spacing);
    img.fillRect(image, x1: x, y1: startY, x2: x + squareSize, y2: startY + squareSize, color: color);
  }
}
