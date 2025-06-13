// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get loadingText => 'Piktogramme werden geladen...';

  @override
  String get editmodeactiveText => 'Bearbeitungsmodus TSSTS - Klicken Sie auf ein Feld, um Piktogramme hinzuzufügen';

  @override
  String get editmodeinactiveText => 'Bearbeitungsmodus deaktiviert';

  @override
  String gridsAvailableText(Object count) {
    return '$count Grid(s) verfügbar';
  }

  @override
  String get chooseGridText => 'Wählen Sie ein Grid aus der Dropdown-Liste oben aus';

  @override
  String profileText(Object profilename) {
    return 'Profil: $profilename';
  }

  @override
  String get localPictogramSearchTitle => 'Lokale Piktogramme suchen';

  @override
  String get searchPictoGramPlaceHolder => 'Search pictogram...';

  @override
  String get searchFieldPlaceholder => 'Geben Sie einen Suchbegriff ein';

  @override
  String get searchFieldNoResults => 'Keine Ergebnisse gefunden';

  @override
  String get addPictogramText => 'Piktogramm hinzufügen';

  @override
  String get addPictogramContentText => 'Wie möchten Sie ein Piktogramm hinzufügen?';

  @override
  String get removePictogramText => 'Piktogramm entfernen';

  @override
  String get editPictogramText => 'Piktogramm bearbeiten';

  @override
  String get namePictogramText => 'Piktogramm benennen';

  @override
  String get namePictogramPlaceholder => 'z.B. Haus, Auto, spielen...';

  @override
  String get cancelButtonText => 'Abbrechen';

  @override
  String get saveText => 'Speichern';

  @override
  String get confirmText => 'Bestätigen';

  @override
  String get selectImageFromDeviceTitle => 'Bilder vom Gerät auswählen';

  @override
  String get selectSingleImageFromDeviceText => 'Bild vom Gerät wählen';

  @override
  String get takePhotoText => 'Foto aufnehmen';

  @override
  String get takePhotoSubtitleText => 'Mit der Kamera fotografieren';

  @override
  String get selectFromGalleryText => 'Aus Galerie auswählen';

  @override
  String get selectFromGallerySubtitleText => 'DCIM, Downloads, etc.';

  @override
  String get descriptionText => 'Beschreibung (optional)';
}
