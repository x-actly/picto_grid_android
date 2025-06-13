import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

void main() async {
  // Stelle sicher, dass das assets/icon Verzeichnis existiert
  final iconDir = Directory('assets/icon');
  if (!iconDir.existsSync()) {
    iconDir.createSync(recursive: true);
  }

  // Erstelle das normale Icon (für Kompatibilität, aber wird nicht primär verwendet)
  await createNormalIcon();

  // Erstelle das Foreground-Icon mit korrekten Farben und "PG" Text
  await createForegroundIcon();

  if (kDebugMode) {
    print('✅ Icons erfolgreich erstellt!');
    print('- assets/icon/icon.png (Normales Icon mit türkisem Hintergrund)');
    print('- assets/icon/foreground.png (Foreground für Adaptive Icons)');
  }
}

Future<void> createNormalIcon() async {
  // Erstelle 512x512 Icon mit türkisem Hintergrund und weißem "PG"
  final image = Image(width: 512, height: 512);

  // Türkiser Hintergrund (#7DDBD4)
  fill(image, color: ColorRgb8(125, 219, 212));

  // Füge "PG" Text hinzu
  drawString(
    image,
    'PG',
    font: arial48,
    x: (512 - 120) ~/ 2, // Zentriert
    y: (512 - 60) ~/ 2,  // Zentriert
    color: ColorRgb8(255, 255, 255), // Weiß
  );

  // Speichere das Icon
  final iconFile = File('assets/icon/icon.png');
  await iconFile.writeAsBytes(encodePng(image));
}

Future<void> createForegroundIcon() async {
  // Erstelle transparentes 432x432 Foreground-Icon
  final image = Image(width: 432, height: 432);

  // Transparenter Hintergrund
  fill(image, color: ColorRgba8(0, 0, 0, 0));

  // Türkiser "PG" Text für bessere Sichtbarkeit auf weißem Adaptive-Hintergrund
  // Verwende die gleiche türkise Farbe wie der Hintergrund für Konsistenz
  drawString(
    image,
    'PG',
    font: arial48,
    x: (432 - 120) ~/ 2, // Zentriert
    y: (432 - 60) ~/ 2,  // Zentriert
    color: ColorRgb8(125, 219, 212), // Türkis wie im Design
  );

  // Speichere das Foreground-Icon
  final foregroundFile = File('assets/icon/foreground.png');
  await foregroundFile.writeAsBytes(encodePng(image));
}
