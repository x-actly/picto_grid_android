# 🖼️ Piktogramm-Integration Anleitung

## Wo müssen die Bilddateien hin?

### 1. Verzeichnisstruktur
Platziere deine heruntergeladenen Piktogramm-Bilder in folgendem Verzeichnis:

```
assets/
└── pictograms/
    ├── 2.png
    ├── 5.png
    ├── 8.png
    ├── 11.png
    ├── 17.png
    ├── 20.png
    ├── 22.png
    ├── 23.png
    ├── 28.png
    ├── 35.png
    ├── 42.png
    ├── 50.png
    ├── 68.png
    ├── 71.png
    ├── 85.png
    ├── 90.png
    ├── 95.png
    ├── 100.png
    ├── 101.png
    ├── 120.png
    └── ... (weitere Bilder)
```

### 2. Dateinamen-Format
Die Bilddateien müssen nach folgendem Schema benannt werden:
- **Format:** `{ID}.png`
- **Beispiel:** `2.png`, `5.png`, `120.png`

### 3. Metadaten erweitern
Um weitere Piktogramme hinzuzufügen, bearbeite die Datei:
```
assets/data/pictograms.json
```

Beispiel für einen neuen Eintrag:
```json
{
  "id": 150,
  "keywords": ["schlafen", "Bett", "müde"],
  "category": "Aktivitäten",
  "filename": "150.png"
}
```

## Offline-/Online-Modus wechseln

In der Datei `lib/services/arasaac_service.dart` kannst du zwischen lokalem und Online-Modus wechseln:

```dart
// Für lokale Piktogramme (Offline)
static const bool useLocalPictograms = true;

// Für Online-API-Zugriff
static const bool useLocalPictograms = false;
```

## Vorteile der lokalen Integration

✅ **Offline-Funktionalität:** Keine Internetverbindung erforderlich  
✅ **Schnellere Ladezeiten:** Bilder werden direkt aus den App-Assets geladen  
✅ **Reduzierter Datenverbrauch:** Keine Downloads zur Laufzeit  
✅ **Zuverlässigkeit:** Keine Abhängigkeit von externer API-Verfügbarkeit  
✅ **Bessere Performance:** Assets werden beim App-Build optimiert  

## Entwicklung mit eigenen Piktogrammen

1. **Neue Bilder hinzufügen:**
   - Platziere PNG-Dateien in `assets/pictograms/`
   - Benenne sie nach ID-Schema: `{ID}.png`

2. **Metadaten aktualisieren:**
   - Erweitere `assets/data/pictograms.json`
   - Füge Keywords und Kategorien hinzu

3. **Hot Reload verwenden:**
   - Nach Änderungen in `pubspec.yaml`: App neu starten
   - Nach Änderungen in JSON: Hot Reload reicht

## Bildformate und -größen

- **Format:** PNG (empfohlen)
- **Größe:** Optimal 500x500px (wie ARASAAC Standard)
- **Hintergrund:** Transparent oder weiß
- **Komprimierung:** Für Web optimiert

## Fehlerbehebung

### Problem: Bild wird nicht angezeigt
1. Prüfe Dateiname und Pfad
2. Stelle sicher, dass die JSON-Metadaten korrekt sind
3. Führe `flutter clean` und `flutter pub get` aus
4. Starte die App neu

### Problem: Assets nicht gefunden
1. Prüfe `pubspec.yaml` Assets-Konfiguration
2. Stelle sicher, dass Assets-Pfade korrekt sind
3. Führe `flutter pub get` aus 