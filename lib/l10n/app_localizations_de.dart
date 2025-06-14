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
  String get editmodeactiveText =>
      'Bearbeitungsmodus aktiviert - Klicken Sie auf ein Feld, um Piktogramme hinzuzufügen';

  @override
  String get editmodeinactiveText => 'Bearbeitungsmodus deaktiviert';

  @override
  String get activateEditModeText => 'Bearbeitungsmodus aktivieren';

  @override
  String gridsAvailableText(Object count) {
    return '$count Grid(s) verfügbar';
  }

  @override
  String get chooseGridText =>
      'Wählen Sie ein Grid aus der Dropdown-Liste oben aus';

  @override
  String profileText(Object profilename) {
    return 'Profil: $profilename';
  }

  @override
  String get searchPictoGramPlaceHolder => 'Piktogramm suchen...';

  @override
  String get localPictogramSearchTitle => 'Lokale Piktogramme suchen';

  @override
  String get searchFieldPlaceholder => 'Geben Sie einen Suchbegriff ein';

  @override
  String get searchFieldNoResults => 'Keine Ergebnisse gefunden';

  @override
  String get addPictogramText => 'Piktogramm hinzufügen';

  @override
  String get addPictogramContentText =>
      'Wie möchten Sie ein Piktogramm hinzufügen?';

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

  @override
  String get descriptionPictogramPlaceholder => 'More Details';

  @override
  String ttsErrorText(Object keyword) {
    return 'Sprache: $keyword';
  }

  @override
  String get gridSettingsText => 'Rastereinstellungen';

  @override
  String get gridSizeText => 'Rastergröße';

  @override
  String get showGridLinesText => 'Rasterlinien anzeigen';

  @override
  String get languageSettingsText => 'Sprache-Einstellungen';

  @override
  String get volumeText => 'Lautstärke: ';

  @override
  String get speechRateText => 'Geschwindigkeit: ';

  @override
  String get resetText => 'Zurücksetzen';

  @override
  String get closeText => 'Schließen';

  @override
  String get deletePictogramText => 'Piktogramm löschen';

  @override
  String deletePictogramContent(Object keyword) {
    return 'Möchten Sie das Piktogramm \"$keyword\" wirklich aus dem Grid entfernen?';
  }

  @override
  String get cancelText => 'Abbrechen';

  @override
  String get deleteText => 'Löschen';

  @override
  String removedFromGridText(Object keyword) {
    return '$keyword wurde aus dem Grid entfernt';
  }

  @override
  String get nameForSpeechLabel => 'Name für Sprachausgabe *';

  @override
  String addedToGridText(Object keyword) {
    return '$keyword wurde hinzugefügt';
  }

  @override
  String get infoNoProfile =>
      'Erstellen Sie ein Profil, um loszulegen. Pro Profil können Sie bis zu 3 Grids anlegen.';

  @override
  String get infoNoGrid =>
      'Erstellen Sie ein Grid für dieses Profil. Aktivieren Sie dann den Bearbeitungsmodus (✏️), um Piktogramme hinzuzufügen.';

  @override
  String get infoEditHint =>
      'Aktivieren Sie den Bearbeitungsmodus (✏️) und klicken Sie auf ein Kästchen, um Piktogramme hinzuzufügen.';

  @override
  String get welcomeText => 'Willkommen bei PictoGrid!';

  @override
  String get createProfilePrompt => 'Erstellen Sie zuerst ein Profil';

  @override
  String get createProfileButton => 'Neues Profil erstellen';

  @override
  String profileCreated(Object name) {
    return 'Profil \"$name\" wurde erstellt';
  }

  @override
  String profileCreateError(Object error) {
    return 'Fehler beim Erstellen: $error';
  }

  @override
  String get profileDeleteText => 'Profil löschen';

  @override
  String profileDeleteContent(Object profile) {
    return 'Möchten Sie das Profil \"$profile\" wirklich löschen?\n\nAlle Grids in diesem Profil werden ebenfalls gelöscht.';
  }

  @override
  String get profileDeleteCancel => 'Abbrechen';

  @override
  String get profileDeleteConfirm => 'Löschen';

  @override
  String get profileDeleted => 'Profil wurde gelöscht';

  @override
  String profileDeleteError(Object error) {
    return 'Fehler beim Löschen: $error';
  }

  @override
  String get noGrids => 'Noch keine Grids vorhanden';

  @override
  String get createFirstGridButton => 'Erstes Grid erstellen';

  @override
  String gridCreated(Object name) {
    return 'Grid \"$name\" wurde erstellt';
  }

  @override
  String gridCreateError(Object error) {
    return 'Fehler beim Erstellen: $error';
  }

  @override
  String get gridDeleteText => 'Grid löschen';

  @override
  String gridDeleteContent(Object grid) {
    return 'Möchten Sie das Grid \"$grid\" wirklich löschen?';
  }

  @override
  String get gridDeleteCancel => 'Abbrechen';

  @override
  String get gridDeleteConfirm => 'Löschen';

  @override
  String get gridDeleted => 'Grid wurde gelöscht';

  @override
  String gridDeleteError(Object error) {
    return 'Fehler beim Löschen: $error';
  }

  @override
  String get profile => 'Profil';

  @override
  String get manageProfiles => 'Profile verwalten';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String get createNewGrid => 'Neues Grid erstellen';

  @override
  String maxGridsReached(Object max) {
    return 'Maximum $max Grids erreicht';
  }

  @override
  String get createNewProfile => 'Neues Profil erstellen';

  @override
  String get prfileName => 'Profil-Name';

  @override
  String get profileNamePlaceholder => 'z.B. Person, Familie, Einrichtung...';

  @override
  String get createButtonText => 'Erstellen';

  @override
  String get gridName => 'Grid-Name';

  @override
  String get gridNamePlaceholder =>
      'z.B. Grundwortschatz, Essen, Aktivitäten...';

  @override
  String get nameText => 'Name *';

  @override
  String savePictogramText(Object name) {
    return 'Piktogramm \'$name\' wurde gespeichert';
  }
}
