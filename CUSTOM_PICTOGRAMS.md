# 📸 Custom Pictograms - Eigene Piktogramme

## Überblick

PictoGrid wurde um die Möglichkeit erweitert, **eigene Piktogramme** zu erstellen und zu verwenden. Sie können jetzt zwischen verschiedenen Quellen wählen:

- 🗂️ **Lokale Assets**: Die vorinstallierten 13.514 Piktogramme
- 📸 **Eigene Bilder**: Selbst aufgenommene oder ausgewählte Fotos
- 🔄 **Alle zusammen**: Kombinierte Suche in beiden Quellen

## 🚀 Neue Funktionen

### 1. **Kästchen-basierte Auswahl**

- **Direkter Zugriff**: Klick auf leeres Grid-Kästchen im Bearbeitungsmodus
- **Kontextuelle Auswahl**: Dialog mit zwei klaren Optionen pro Kästchen
- **Visuelle Führung**: ➕-Symbol zeigt verfügbare Kästchen an

### 2. **Foto-Integration**

```
📷 Kamera            📱 Galerie
├─ Direktaufnahme    ├─ DCIM-Ordner
├─ Automatische      ├─ Downloads
   Größenanpassung   ├─ Beliebige Ordner
└─ Sofortige         └─ Alle Bildformate
   Benennung
```

### 3. **Piktogramm-Verwaltung**

- **Benennung**: Jedes eigene Bild bekommt einen aussagekräftigen Namen
- **Beschreibung**: Optional zusätzliche Details
- **Kategorie**: Automatisch als "Benutzerdefiniert" kategorisiert
- **Löschen**: Eigene Piktogramme können gelöscht werden

## 📋 Benutzer-Workflow

### Neues Piktogramm hinzufügen:

1. **Bearbeitungsmodus aktivieren** (✏️-Button in der AppBar)
1. **Leeres Kästchen im Grid anklicken** (mit ➕-Symbol)
1. **Auswahl zwischen zwei Optionen**:
   - 🔍 **"Lokale Piktogramme durchsuchen"** → Durchsuchbarer Dialog mit 13.514 Piktogrammen
   - 📁 **"Bilder vom Gerät auswählen"** → Kamera oder Galerie
1. **Bei eigenen Bildern**:
   - 📷 "Foto aufnehmen" → Kamera wird geöffnet
   - 📱 "Aus Galerie wählen" → DCIM, Downloads, etc.
1. **Bild benennen**:
   - Name eingeben (z.B. "Mein Auto", "Lieblingsspielzeug")
   - Optional: Beschreibung hinzufügen
1. **Speichern** → Piktogramm wird sofort ins Kästchen eingefügt

### Piktogramm verwenden:

1. **In der Suchleiste** tippen (z.B. "Auto")
1. **Eigenes Bild** erscheint in den Suchergebnissen
1. **Antippen** → Wird dem Grid hinzugefügt
1. **TTS funktioniert** mit dem vergebenen Namen

### Piktogramm verwalten:

- **Suchen**: In "Eigene Bilder" nach Namen suchen
- **Löschen**: 3-Punkte-Menü → "Löschen"
- **Aktualisieren**: Automatisch in allen Grids

## 🔒 Berechtigungen

Die App fragt beim ersten Mal nach folgenden Berechtigungen:

### Android:

- **Kamera**: Für Fotoaufnahme
- **Speicher**: Für Galerie-Zugriff (Android < 13)
- **Medien**: Für Bilder-Zugriff (Android 13+)

### Automatische Behandlung:

- Berechtigungen werden nur bei Bedarf angefragt
- Fallback-Verhalten bei fehlenden Berechtigungen
- Klare Fehlermeldungen für den Benutzer

## 💾 Datenspeicherung

### Speicherort:

```
/data/data/com.example.picto_grid/files/
└── custom_pictograms/
    ├── metadata.json         # Piktogramm-Informationen
    ├── custom_1734567890.jpg # Bild 1
    ├── custom_1734567891.jpg # Bild 2
    └── ...
```

### Datenformat (metadata.json):

```json
[
  {
    "id": 1734567890,
    "keyword": "Mein Auto",
    "imageUrl": "/path/to/custom_1734567890.jpg",
    "description": "Mein rotes Familienauto",
    "category": "Benutzerdefiniert"
  }
]
```

### Sicherheit:

- **App-privater Speicher**: Nur die App kann auf die Bilder zugreifen
- **Automatische Bereinigung**: Bei App-Deinstallation werden alle Daten entfernt
- **Keine Cloud-Synchronisation**: Alle Daten bleiben lokal

## 🎯 Technische Details

### Bildverarbeitung:

- **Automatische Größenanpassung**: Max. 1024×1024 Pixel
- **Komprimierung**: 85% Qualität für optimale Performance
- **Format**: JPEG für kleinere Dateigröße
- **Eindeutige IDs**: Timestamp-basiert für Kollisionsvermeidung

### Performance:

- **Lazy Loading**: Bilder werden nur bei Bedarf geladen
- **Caching**: Schnelle Wiederholung von Suchergebnissen
- **Asynchrone Verarbeitung**: UI bleibt responsiv

### Integration:

- **Nahtlose Grid-Integration**: Custom Pictograms funktionieren wie lokale Assets
- **TTS-Unterstützung**: Spricht den vergebenen Namen aus
- **Drag-and-Drop**: Funktioniert in allen Grid-Modi

## 🔧 Für Entwickler

### Neue Services:

```dart
// Custom Pictogram Service
CustomPictogramService.instance.captureFromCamera()
CustomPictogramService.instance.pickFromGallery()
CustomPictogramService.instance.addCustomPictogram(pictogram)
CustomPictogramService.instance.searchCustomPictograms(query)
```

### Erweiterte UI-Komponenten:

```dart
// Neue erweiterte Suchkomponente
EnhancedPictogramSearch(
  onPictogramSelected: (pictogram) => handleSelection(pictogram),
)
```

### Dependencies hinzugefügt:

- `image_picker: ^1.0.4` - Kamera/Galerie-Zugriff
- `permission_handler: ^11.0.1` - Berechtigungsmanagement

## 🚨 Bekannte Limitierungen

1. **iOS-Support**: Noch nicht implementiert (nur Android-Berechtigungen)
1. **Cloud-Sync**: Keine Synchronisation zwischen Geräten
1. **Bulk-Import**: Noch kein Massen-Import von Bildern
1. **Kategorien**: Custom Pictograms sind alle in "Benutzerdefiniert"

## 📈 Zukünftige Erweiterungen

### Geplante Features:

- **📁 Kategorien-Editor**: Eigene Kategorien für Custom Pictograms
- **🔄 Export/Import**: Backup und Wiederherstellung von Custom Pictograms
- **🎨 Bildbearbeitung**: Zuschneiden und Filter direkt in der App
- **👥 Teilen**: Custom Pictograms mit anderen Benutzern teilen
- **🌐 Cloud-Sync**: Optional synchronisation über Cloud-Dienste

### Technische Verbesserungen:

- **iOS-Unterstützung**: Vollständige iOS-Implementierung
- **Bulk-Operations**: Mehrere Bilder gleichzeitig verarbeiten
- **Advanced Search**: Erweiterte Suchfilter für Custom Pictograms
- **Metadaten-Editor**: Nachträgliche Bearbeitung von Namen/Beschreibungen

______________________________________________________________________

**Die Custom Pictogram-Funktionalität macht PictoGrid zu einer vollständig personalisierbaren Kommunikationshilfe! 🎉**
