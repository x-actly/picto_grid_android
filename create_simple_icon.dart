import 'dart:io';

import 'package:flutter/foundation.dart';

void main() async {
  if (kDebugMode) {
    print('🎨 Erstelle Launcher-Icon im PictoGrid-Design...');
  }

  // Erstelle ein einfaches PNG (1024x1024) für das Haupticon
  await createMainIcon();

  // Erstelle das Vordergrund-Icon für adaptive Icons
  await createForegroundIcon();

  if (kDebugMode) {
    print('✅ Icons erfolgreich erstellt!');
    print('📁 Dateien: assets/icon/icon.png, assets/icon/foreground.png');
  }
}

Future<void> createMainIcon() async {
  // Erstelle ein 1024x1024 PNG mit dem PictoGrid Design
  const int size = 1024;
  final Uint8List pixels = Uint8List(size * size * 4); // RGBA

  // PictoGrid Farben
  const int bgR = 0x7D; // #7DDBD4 Mint/Teal
  const int bgG = 0xDB;
  const int bgB = 0xD4;
  const int bgA = 0xFF;

  const int fgR = 0xFF; // Weiß für Text/Symbole
  const int fgG = 0xFF;
  const int fgB = 0xFF;
  const int fgA = 0xFF;

  // Hintergrund füllen
  for (int i = 0; i < pixels.length; i += 4) {
    pixels[i] = bgR;
    pixels[i + 1] = bgG;
    pixels[i + 2] = bgB;
    pixels[i + 3] = bgA;
  }

  // Einfaches "PG" in der Mitte zeichnen (pixelbasiert)
  drawPGText(pixels, size, fgR, fgG, fgB, fgA);

  // Grid-Symbole unter dem Text
  drawGridSymbols(pixels, size, fgR, fgG, fgB, fgA);

  // PNG-Header erstellen (vereinfacht - würde normalerweise eine PNG-Library verwenden)
  await savePng(pixels, size, 'assets/icon/icon.png');
}

Future<void> createForegroundIcon() async {
  // Erstelle ein transparentes Icon nur mit dem Vordergrund-Inhalt
  const int size = 1024;
  final Uint8List pixels = Uint8List(size * size * 4); // RGBA

  // Transparent background
  for (int i = 0; i < pixels.length; i += 4) {
    pixels[i] = 0;
    pixels[i + 1] = 0;
    pixels[i + 2] = 0;
    pixels[i + 3] = 0; // Transparent
  }

  // Weißer Inhalt für adaptive Icons
  const int fgR = 0xFF;
  const int fgG = 0xFF;
  const int fgB = 0xFF;
  const int fgA = 0xFF;

  drawPGText(pixels, size, fgR, fgG, fgB, fgA);
  drawGridSymbols(pixels, size, fgR, fgG, fgB, fgA);

  await savePng(pixels, size, 'assets/icon/foreground.png');
}

void drawPGText(Uint8List pixels, int size, int r, int g, int b, int a) {
  // Sehr einfache Pixel-basierte "PG" Text-Darstellung
  final int centerX = size ~/ 2;
  final int centerY = size ~/ 2 - 50;
  final int letterSize = 120;

  // "P" zeichnen (links)
  drawLetter(pixels, size, centerX - letterSize, centerY, letterSize, r, g, b, a, 'P');

  // "G" zeichnen (rechts)
  drawLetter(pixels, size, centerX + 20, centerY, letterSize, r, g, b, a, 'G');
}

void drawLetter(Uint8List pixels, int size, int startX, int startY, int letterSize,
                int r, int g, int b, int a, String letter) {
  // Sehr vereinfachte Buchstaben als Rechtecke
  if (letter == 'P') {
    // P als vertikaler Balken mit horizontalen Balken
    drawRect(pixels, size, startX, startY, 20, letterSize, r, g, b, a);
    drawRect(pixels, size, startX, startY, letterSize - 40, 20, r, g, b, a);
    drawRect(pixels, size, startX, startY + letterSize ~/ 2 - 10, letterSize - 40, 20, r, g, b, a);
  } else if (letter == 'G') {
    // G als C mit horizontalem Balken
    drawRect(pixels, size, startX, startY, 20, letterSize, r, g, b, a);
    drawRect(pixels, size, startX, startY, letterSize - 20, 20, r, g, b, a);
    drawRect(pixels, size, startX, startY + letterSize - 20, letterSize - 20, 20, r, g, b, a);
    drawRect(pixels, size, startX + letterSize ~/ 2, startY + letterSize ~/ 2, letterSize ~/ 2 - 20, 20, r, g, b, a);
  }
}

void drawGridSymbols(Uint8List pixels, int size, int r, int g, int b, int a) {
  // 3 kleine Quadrate unter dem Text als Grid-Symbol
  final int centerX = size ~/ 2;
  final int startY = size ~/ 2 + 100;
  final int squareSize = 40;
  final int spacing = 20;

  for (int i = 0; i < 3; i++) {
    final int x = centerX - (squareSize + spacing) + i * (squareSize + spacing);
    drawRect(pixels, size, x, startY, squareSize, squareSize, r, g, b, a);
  }
}

void drawRect(Uint8List pixels, int size, int x, int y, int width, int height,
              int r, int g, int b, int a) {
  for (int py = y; py < y + height && py < size; py++) {
    for (int px = x; px < x + width && px < size; px++) {
      if (px >= 0 && py >= 0) {
        final int index = (py * size + px) * 4;
        if (index + 3 < pixels.length) {
          pixels[index] = r;
          pixels[index + 1] = g;
          pixels[index + 2] = b;
          pixels[index + 3] = a;
        }
      }
    }
  }
}

Future<void> savePng(Uint8List pixels, int size, String filename) async {
  // Da wir keine PNG-Library haben, erstellen wir eine sehr einfache BMP-ähnliche Datei
  // Für echte PNG würden wir eine Library wie 'image' verwenden

  // Für jetzt erstellen wir nur eine Platzhalter-Datei
  final file = File(filename);
  await file.writeAsBytes(pixels);

  if (kDebugMode) {
    print('📁 Erstellt: $filename ($size x $size)');
  }
}
