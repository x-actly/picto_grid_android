# PictoGrid - AAC Communication App

[English](#english) | [Deutsch](#deutsch)

______________________________________________________________________

## English

### 🗣️ **Augmentative and Alternative Communication (AAC) App**

PictoGrid is a comprehensive Flutter-based Android application designed to support non-verbal communication through visual pictograms. This assistive technology empowers individuals who cannot communicate verbally to express themselves using an intuitive grid-based interface with integrated text-to-speech functionality.

______________________________________________________________________

### 🎯 **Purpose & Target Users**

**PictoGrid serves as a communication aid for:**

- Individuals with speech disabilities
- People with autism spectrum disorders
- Stroke survivors with aphasia
- Children with developmental delays
- Anyone requiring alternative communication methods

**Key Benefits:**

- 🔊 **Independent communication** through pictogram selection
- 🧠 **Cognitive support** with visual communication aids
- 👥 **Social integration** enabling interaction with others
- 📚 **Learning assistance** for vocabulary and concept development

______________________________________________________________________

### ✨ **Core Features**

#### 🎤 **Text-to-Speech Integration**

- **German voice synthesis** with natural pronunciation
- **Immediate audio feedback** when pictograms are selected
- **Volume and speed controls** for personalized experience
- **Offline functionality** - no internet required for speech

#### 📱 **Advanced Grid System**

- **Flexible layouts**: 4x2 and 8x3 grid configurations
- **Responsive design** adapting to tablets and phones
- **Drag-and-drop editing** for easy pictogram arrangement
- **Multiple grids** for different contexts (home, school, medical)
- **Visual feedback** with smooth animations

#### 🖼️ **Comprehensive Pictogram Library**

- **13,514 local pictograms** covering diverse topics
- **High-quality images** optimized for clear recognition
- **Categorized content** for easy browsing
- **Intelligent search** with keyword matching
- **Offline accessibility** - all pictograms stored locally

#### 🔍 **Smart Search Functionality**

- **Real-time search** as you type
- **Keyword-based filtering** for quick access
- **Category browsing** for systematic exploration
- **Fuzzy matching** to find related pictograms
- **Visual results** with immediate preview

#### 🛠️ **User Customization**

- **Grid editing mode** for personalized layouts
- **Pictogram management** with add/remove functionality
- **Grid naming and organization** for different activities
- **Settings persistence** across app sessions
- **Intuitive controls** designed for accessibility

#### 🔄 **Advanced Drag & Swap System**

- **Intelligent positioning** with automatic grid snapping
- **Swap functionality** - drag pictograms onto occupied positions to exchange places
- **Visual feedback** with color-coded drop zones (orange for move, blue for swap)
- **Position persistence** across app sessions and grid size changes
- **Real-time updates** with immediate database synchronization

#### 🗂️ **Multi-Profile Management**

- **Profile system** for different users or contexts
- **Individual grid collections** per profile (up to 3 grids each)
- **Automatic profile switching** with seamless grid loading
- **Profile-specific customizations** and settings
- **Easy profile management** with create/delete functionality

#### 🧭 **Enhanced Navigation**

- **Bottom navigation bar** for quick grid switching
- **Automatic grid selection** when switching profiles or starting app
- **Streamlined interface** with reduced visual clutter
- **One-tap grid access** without dropdown menus
- **Responsive design** adapting to number of available grids

#### 🎯 **Smart Grid Management**

- **Automatic first grid selection** on profile switch
- **Position healing system** that repairs corrupted pictogram positions
- **Grid size conversion** with intelligent position mapping (4x2 ↔ 8x3)
- **Conflict resolution** for overlapping pictogram positions
- **Database migration** ensuring data integrity across app updates

#### 💾 **Data Management**

- **SQLite database** for reliable data storage
- **Grid configurations** saved automatically
- **Backup and restore** capabilities
- **Offline operation** - works without internet
- **Fast performance** with optimized data access

______________________________________________________________________

### 🏗️ **Technical Architecture**

**Framework & Platform:**

- **Flutter** for cross-platform development
- **Android** native integration
- **Provider pattern** for efficient state management
- **Clean architecture** with separation of concerns

**Key Components:**

- `PictogramGrid` - Interactive grid widget
- `TtsService` - Text-to-speech engine
- `LocalPictogramService` - Pictogram management
- `DatabaseHelper` - Data persistence
- `GridProvider` - State management

**Dependencies:**

```yaml
flutter_tts: ^4.0.2           # Text-to-speech functionality
sqflite: ^2.3.0              # Local database storage
provider: ^6.1.1             # State management
http: ^1.1.2                 # Network requests
path_provider: ^2.1.1        # File system access
reorderable_grid_view: ^2.2.8 # Drag-and-drop grids
```

______________________________________________________________________

### 📱 **User Interface**

**Design Principles:**

- **Accessibility-first** approach
- **Large, clear pictograms** for easy recognition
- **High contrast** for visual clarity
- **Simple navigation** with minimal complexity
- **Touch-friendly** interface optimized for tablets

**Key Screens:**

- **Main Grid View** - Primary communication interface
- **Search Interface** - Pictogram discovery
- **Grid Management** - Organization and customization
- **Settings Panel** - Voice and display preferences

______________________________________________________________________

### 🚀 **Installation & Setup**

#### **Prerequisites:**

- Android device (API level 21+)
- ~320MB storage space for app and pictograms

#### **Development Setup:**

```bash
# Clone the repository
git clone https://github.com/yourusername/picto_grid_android.git
cd picto_grid_android

# Install Flutter dependencies
flutter pub get

# Connect Android device/emulator
flutter devices

# Build and run
flutter run
```

#### **Release Build:**

```bash
# Build APK for distribution
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

______________________________________________________________________

### 💡 **Usage Guide**

1. **Getting Started:**

   - Launch PictoGrid on your Android device
   - Browse the default grid with common pictograms
   - Tap any pictogram to hear its pronunciation

1. **Communication:**

   - Select pictograms to form messages
   - Use TTS to speak selected words
   - Navigate between different grid contexts

1. **Customization:**

   - Enable edit mode to modify grids
   - Search and add relevant pictograms
   - Create specialized grids for different situations

1. **Advanced Features:**

   - Organize grids by activity or location
   - Adjust speech settings for optimal clarity
   - Use search to quickly find specific pictograms

1. **Multi-Profile Setup:**

   - Create profiles for different users or contexts
   - Each profile maintains separate grid collections
   - Switch profiles using the dropdown in the top-left
   - First grid automatically loads when switching profiles

1. **Advanced Grid Navigation:**

   - Use bottom navigation bar for quick grid switching
   - Drag pictograms between positions to rearrange
   - Drag onto occupied positions to swap pictograms
   - Visual indicators show move (orange) vs swap (blue) actions

1. **Position Management:**

   - Pictogram positions persist across sessions
   - Grid size changes automatically convert positions
   - System repairs any position conflicts automatically
   - All changes sync immediately to database

______________________________________________________________________

### 🤝 **Contributing**

We welcome contributions to improve PictoGrid's accessibility and functionality:

- **Bug Reports:** Use GitHub issues for bugs and feature requests
- **Code Contributions:** Follow Flutter best practices and accessibility guidelines
- **Translations:** Help expand language support
- **Accessibility Testing:** Assist with usability testing for diverse users

______________________________________________________________________

### 📄 **License**

This project is licensed under Apache-2.0 license - see the LICENSE file for details.

______________________________________________________________________

### 🙏 **Acknowledgments**

- Pictogram library sourced from open accessibility resources
- Text-to-speech powered by Flutter TTS
- Designed with input from AAC specialists and users

______________________________________________________________________

## Deutsch

### 🗣️ **Unterstützte Kommunikations-App (UK)**

PictoGrid ist eine umfassende, auf Flutter basierende Android-Anwendung zur Unterstützung der non-verbalen Kommunikation durch visuelle Piktogramme. Diese assistive Technologie befähigt Menschen, die nicht verbal kommunizieren können, sich über eine intuitive, rasterbasierte Oberfläche mit integrierter Sprachausgabe auszudrücken.

______________________________________________________________________

### 🎯 **Zweck & Zielgruppe**

**PictoGrid dient als Kommunikationshilfe für:**

- Menschen mit Sprachbehinderungen
- Personen mit Autismus-Spektrum-Störungen
- Schlaganfall-Überlebende mit Aphasie
- Kinder mit Entwicklungsverzögerungen
- Alle, die alternative Kommunikationsmethoden benötigen

**Hauptvorteile:**

- 🔊 **Selbständige Kommunikation** durch Piktogramm-Auswahl
- 🧠 **Kognitive Unterstützung** mit visuellen Kommunikationshilfen
- 👥 **Soziale Integration** ermöglicht Interaktion mit anderen
- 📚 **Lernhilfe** für Wortschatz- und Konzeptentwicklung

______________________________________________________________________

### ✨ **Kernfunktionen**

#### 🎤 **Text-zu-Sprache Integration**

- **Deutsche Sprachsynthese** mit natürlicher Aussprache
- **Sofortiges Hör-Feedback** bei Piktogramm-Auswahl
- **Lautstärke- und Geschwindigkeitsregelung** für personalisierte Erfahrung
- **Offline-Funktionalität** - kein Internet für Sprache erforderlich

#### 📱 **Fortschrittliches Raster-System**

- **Flexible Layouts**: 4x2 und 8x3 Raster-Konfigurationen
- **Responsive Design** angepasst an Tablets und Handys
- **Drag-and-Drop-Bearbeitung** für einfache Piktogramm-Anordnung
- **Mehrere Raster** für verschiedene Kontexte (Zuhause, Schule, Medizin)
- **Visuelles Feedback** mit flüssigen Animationen

#### 🖼️ **Umfassende Piktogramm-Bibliothek**

- **13.514 lokale Piktogramme** mit vielfältigen Themen
- **Hochwertige Bilder** optimiert für klare Erkennung
- **Kategorisierte Inhalte** für einfaches Durchsuchen
- **Intelligente Suche** mit Schlüsselwort-Matching
- **Offline-Zugriff** - alle Piktogramme lokal gespeichert

#### 🔍 **Intelligente Suchfunktion**

- **Echtzeit-Suche** während der Eingabe
- **Schlüsselwort-basierte Filterung** für schnellen Zugriff
- **Kategorie-Navigation** für systematische Erkundung
- **Fuzzy-Matching** zum Finden verwandter Piktogramme
- **Visuelle Ergebnisse** mit sofortiger Vorschau

#### 🛠️ **Benutzer-Anpassung**

- **Raster-Bearbeitungsmodus** für personalisierte Layouts
- **Piktogramm-Verwaltung** mit Hinzufügen/Entfernen-Funktionalität
- **Raster-Benennung und -Organisation** für verschiedene Aktivitäten
- **Einstellungs-Persistenz** über App-Sitzungen hinweg
- **Intuitive Bedienelemente** für Barrierefreiheit entwickelt

#### 🔄 **Fortschrittliches Drag & Swap System**

- **Intelligente Positionierung** mit automatischem Raster-Snapping
- **Tausch-Funktionalität** - Piktogramme auf belegte Positionen ziehen zum Platz tauschen
- **Visuelles Feedback** mit farbkodierten Drop-Zonen (Orange für Verschieben, Blau für Tauschen)
- **Positions-Persistenz** über App-Sitzungen und Rastergrößen-Änderungen hinweg
- **Echtzeit-Updates** mit sofortiger Datenbank-Synchronisation

#### 🗂️ **Multi-Profil-Verwaltung**

- **Profil-System** für verschiedene Benutzer oder Kontexte
- **Individuelle Raster-Sammlungen** pro Profil (bis zu 3 Raster jeweils)
- **Automatischer Profil-Wechsel** mit nahtlosem Raster-Laden
- **Profilspezifische Anpassungen** und Einstellungen
- **Einfache Profil-Verwaltung** mit Erstellen/Löschen-Funktionalität

#### 🧭 **Verbesserte Navigation**

- **Bottom-Navigation-Bar** für schnellen Raster-Wechsel
- **Automatische Raster-Auswahl** beim Profil-Wechsel oder App-Start
- **Optimierte Oberfläche** mit reduzierter visueller Unordnung
- **Ein-Tipp-Raster-Zugriff** ohne Dropdown-Menüs
- **Responsive Design** angepasst an Anzahl verfügbarer Raster

#### 🎯 **Intelligente Raster-Verwaltung**

- **Automatische Erste-Raster-Auswahl** bei Profil-Wechsel
- **Positions-Reparatur-System** das beschädigte Piktogramm-Positionen repariert
- **Rastergrößen-Konvertierung** mit intelligenter Positions-Zuordnung (4x2 ↔ 8x3)
- **Konflikt-Lösung** für überlappende Piktogramm-Positionen
- **Datenbank-Migration** gewährleistet Datenintegrität über App-Updates hinweg

#### 💾 **Datenmanagement**

- **SQLite-Datenbank** für zuverlässige Datenspeicherung
- **Raster-Konfigurationen** automatisch gespeichert
- **Backup- und Wiederherstellungs-Funktionen**
- **Offline-Betrieb** - funktioniert ohne Internet
- **Schnelle Leistung** mit optimiertem Datenzugriff

______________________________________________________________________

### 🏗️ **Technische Architektur**

**Framework & Plattform:**

- **Flutter** für plattformübergreifende Entwicklung
- **Android** native Integration
- **Provider-Pattern** für effizientes State-Management
- **Clean Architecture** mit Trennung der Belange

**Hauptkomponenten:**

- `PictogramGrid` - Interaktives Raster-Widget
- `TtsService` - Text-zu-Sprache-Engine
- `LocalPictogramService` - Piktogramm-Verwaltung
- `DatabaseHelper` - Daten-Persistierung
- `GridProvider` - State-Management

**Abhängigkeiten:**

```yaml
flutter_tts: ^4.0.2           # Text-zu-Sprache-Funktionalität
sqflite: ^2.3.0              # Lokale Datenbankspeicherung
provider: ^6.1.1             # State-Management
http: ^1.1.2                 # Netzwerk-Anfragen
path_provider: ^2.1.1        # Dateisystem-Zugriff
reorderable_grid_view: ^2.2.8 # Drag-and-Drop-Raster
```

______________________________________________________________________

### 📱 **Benutzeroberfläche**

**Design-Prinzipien:**

- **Barrierefreiheit-first** Ansatz
- **Große, klare Piktogramme** für einfache Erkennung
- **Hoher Kontrast** für visuelle Klarheit
- **Einfache Navigation** mit minimaler Komplexität
- **Touch-freundliche** Oberfläche optimiert für Tablets

**Hauptbildschirme:**

- **Haupt-Raster-Ansicht** - Primäre Kommunikationsschnittstelle
- **Such-Oberfläche** - Piktogramm-Entdeckung
- **Raster-Verwaltung** - Organisation und Anpassung
- **Einstellungs-Panel** - Sprach- und Anzeige-Einstellungen

______________________________________________________________________

### 🚀 **Installation & Einrichtung**

#### **Voraussetzungen:**

- Android-Gerät (API-Level 21+)
- ~320MB Speicherplatz für App und Piktogramme

#### **Entwicklungs-Setup:**

```bash
# Repository klonen
git clone https://github.com/yourusername/picto_grid_android.git
cd picto_grid_android

# Flutter-Abhängigkeiten installieren
flutter pub get

# Android-Gerät/Emulator verbinden
flutter devices

# Erstellen und ausführen
flutter run
```

#### **Release-Build:**

```bash
# APK für Verteilung erstellen
flutter build apk --release

# APK-Speicherort: build/app/outputs/flutter-apk/app-release.apk
```

______________________________________________________________________

### 💡 **Nutzungsanleitung**

1. **Erste Schritte:**

   - PictoGrid auf Ihrem Android-Gerät starten
   - Das Standard-Raster mit häufigen Piktogrammen durchsuchen
   - Beliebiges Piktogramm antippen, um die Aussprache zu hören

1. **Kommunikation:**

   - Piktogramme auswählen, um Nachrichten zu bilden
   - TTS verwenden, um ausgewählte Wörter zu sprechen
   - Zwischen verschiedenen Raster-Kontexten navigieren

1. **Anpassung:**

   - Bearbeitungsmodus aktivieren, um Raster zu modifizieren
   - Relevante Piktogramme suchen und hinzufügen
   - Spezialisierte Raster für verschiedene Situationen erstellen

1. **Erweiterte Funktionen:**

   - Raster nach Aktivität oder Ort organisieren
   - Sprach-Einstellungen für optimale Klarheit anpassen
   - Suche verwenden, um spezifische Piktogramme schnell zu finden

1. **Multi-Profil-Einrichtung:**

   - Profile für verschiedene Benutzer oder Kontexte erstellen
   - Jedes Profil verwaltet separate Raster-Sammlungen
   - Profile über Dropdown oben links wechseln
   - Erstes Raster lädt automatisch beim Profil-Wechsel

1. **Erweiterte Raster-Navigation:**

   - Bottom-Navigation-Bar für schnellen Raster-Wechsel verwenden
   - Piktogramme zwischen Positionen ziehen zum Umordnen
   - Auf belegte Positionen ziehen zum Piktogramm-Tausch
   - Visuelle Indikatoren zeigen Verschieben (Orange) vs Tauschen (Blau)

1. **Positions-Verwaltung:**

   - Piktogramm-Positionen bleiben über Sitzungen bestehen
   - Rastergrößen-Änderungen konvertieren Positionen automatisch
   - System repariert Positions-Konflikte automatisch
   - Alle Änderungen synchronisieren sofort mit Datenbank

______________________________________________________________________

### 🤝 **Mitwirken**

Wir begrüßen Beiträge zur Verbesserung der Barrierefreiheit und Funktionalität von PictoGrid:

- **Fehlermeldungen:** GitHub-Issues für Bugs und Feature-Anfragen verwenden
- **Code-Beiträge:** Flutter-Best-Practices und Barrierefreiheits-Richtlinien befolgen
- **Übersetzungen:** Bei der Erweiterung der Sprachunterstützung helfen
- **Barrierefreiheits-Tests:** Bei Usability-Tests für diverse Nutzer unterstützen

______________________________________________________________________

### 📄 **Lizenz**

Dieses Projekt ist unter Apache-2.0 license lizenziert - siehe die LICENSE-Datei für Details.

______________________________________________________________________

### 🙏 **Danksagungen**

- Piktogramm-Bibliothek aus offenen Barrierefreiheits-Ressourcen
- Text-zu-Sprache powered by Flutter TTS
- Entwickelt mit Input von UK-Spezialisten und Nutzern
