# PictoGrid

[English](#english) | [Deutsch](#deutsch)

## English

### Overview
PictoGrid is a Flutter-based Android application designed to create and manage visual communication grids using pictograms. It's particularly useful for alternative and augmentative communication (AAC) purposes.

### Features
- **Flexible Grid Layouts**
  - 4x2 and 8x3 grid configurations
  - Optimized space utilization
  - Responsive design adapting to different screen sizes

- **Pictogram Management**
  - Easy pictogram search and selection
  - Drag-and-drop functionality for arrangement
  - Support for custom grid layouts

- **User Interface**
  - Clean and intuitive design
  - Grid editing mode
  - Visual feedback during interactions
  - Grid size adjustment options

- **Grid Management**
  - Create multiple grids
  - Name and organize grids
  - Delete unwanted grids
  - Switch between different grids

### Technical Details
- **Framework**: Flutter
- **Platform**: Android
- **Architecture**: Provider pattern for state management
- **Total Code Base**: ~1600 lines of Dart code
- **Main Components**:
  - PictogramGrid Widget
  - Grid Provider
  - Pictogram Provider
  - Search Functionality

### Installation
1. Clone the repository
2. Ensure Flutter is installed and properly set up
3. Run `flutter pub get` to install dependencies
4. Connect an Android device or emulator
5. Run `flutter run` to start the application

### Development
The project follows Flutter best practices and uses the following structure:
```
lib/
  ├── main.dart
  ├── models/
  ├── providers/
  ├── screens/
  ├── services/
  └── widgets/
```

---

## Deutsch

### Überblick
PictoGrid ist eine auf Flutter basierende Android-Anwendung zur Erstellung und Verwaltung von visuellen Kommunikationsrastern mit Piktogrammen. Sie ist besonders nützlich für alternative und unterstützende Kommunikation (UK).

### Funktionen
- **Flexible Rasterlayouts**
  - 4x2 und 8x3 Rasterkonfigurationen
  - Optimierte Platznutzung
  - Responsive Design für verschiedene Bildschirmgrößen

- **Piktogramm-Verwaltung**
  - Einfache Piktogramm-Suche und -Auswahl
  - Drag-and-Drop-Funktionalität zur Anordnung
  - Unterstützung für benutzerdefinierte Rasterlayouts

- **Benutzeroberfläche**
  - Übersichtliches und intuitives Design
  - Raster-Bearbeitungsmodus
  - Visuelle Rückmeldung bei Interaktionen
  - Optionen zur Rastergrößenanpassung

- **Raster-Verwaltung**
  - Erstellung mehrerer Raster
  - Benennung und Organisation von Rastern
  - Löschen unerwünschter Raster
  - Wechsel zwischen verschiedenen Rastern

### Technische Details
- **Framework**: Flutter
- **Plattform**: Android
- **Architektur**: Provider-Pattern für State-Management
- **Gesamter Code**: ~1600 Zeilen Dart-Code
- **Hauptkomponenten**:
  - PictogramGrid Widget
  - Grid Provider
  - Pictogram Provider
  - Suchfunktionalität

### Installation
1. Repository klonen
2. Flutter-Installation und -Einrichtung sicherstellen
3. `flutter pub get` ausführen, um Abhängigkeiten zu installieren
4. Android-Gerät oder Emulator verbinden
5. `flutter run` ausführen, um die Anwendung zu starten

### Entwicklung
Das Projekt folgt Flutter-Best-Practices und verwendet folgende Struktur:
```
lib/
  ├── main.dart
  ├── models/
  ├── providers/
  ├── screens/
  ├── services/
  └── widgets/
```
