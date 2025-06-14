import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Text shown while pictograms are loading
  ///
  /// In de, this message translates to:
  /// **'Piktogramme werden geladen...'**
  String get loadingText;

  /// Text wird angezeigt, wenn der Bearbeitungsmodus aktiviert ist
  ///
  /// In de, this message translates to:
  /// **'Bearbeitungsmodus aktiviert - Klicken Sie auf ein Feld, um Piktogramme hinzuzufügen'**
  String get editmodeactiveText;

  /// Text wird angezeigt, wenn der Bearbeitungsmodus deaktiviert ist
  ///
  /// In de, this message translates to:
  /// **'Bearbeitungsmodus deaktiviert'**
  String get editmodeinactiveText;

  /// Text, der angezeigt wird, um den Bearbeitungsmodus zu aktivieren
  ///
  /// In de, this message translates to:
  /// **'Bearbeitungsmodus aktivieren'**
  String get activateEditModeText;

  /// Text wird angezeigt, wenn Raster verfügbar sind
  ///
  /// In de, this message translates to:
  /// **'{count} Grid(s) verfügbar'**
  String gridsAvailableText(Object count);

  /// Text, der angezeigt wird, wenn ein Raster ausgewählt werden soll
  ///
  /// In de, this message translates to:
  /// **'Wählen Sie ein Grid aus der Dropdown-Liste oben aus'**
  String get chooseGridText;

  /// Text, der für den Profilbereich angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Profil: {profilename}'**
  String profileText(Object profilename);

  /// Text, der für die Piktogrammsuche angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Piktogramm suchen...'**
  String get searchPictoGramPlaceHolder;

  /// Titel für den Abschnitt der lokalen Piktogrammsuche
  ///
  /// In de, this message translates to:
  /// **'Lokale Piktogramme suchen'**
  String get localPictogramSearchTitle;

  /// Platzhaltertext für das Suchfeld
  ///
  /// In de, this message translates to:
  /// **'Geben Sie einen Suchbegriff ein'**
  String get searchFieldPlaceholder;

  /// Text, der angezeigt wird, wenn keine Ergebnisse gefunden wurden
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse gefunden'**
  String get searchFieldNoResults;

  /// Text, der für das Hinzufügen eines Piktogramms angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Piktogramm hinzufügen'**
  String get addPictogramText;

  /// Text, der für das Hinzufügen eines Piktogramminhalts angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Wie möchten Sie ein Piktogramm hinzufügen?'**
  String get addPictogramContentText;

  /// Text, der für das Entfernen eines Piktogramms angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Piktogramm entfernen'**
  String get removePictogramText;

  /// Text, der für das Bearbeiten eines Piktogramms angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Piktogramm bearbeiten'**
  String get editPictogramText;

  /// Text, der für das Benennen eines Piktogramms angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Piktogramm benennen'**
  String get namePictogramText;

  /// Platzhaltertext für das Benennen eines Piktogramms
  ///
  /// In de, this message translates to:
  /// **'z.B. Haus, Auto, spielen...'**
  String get namePictogramPlaceholder;

  /// Text, der für das Abbrechen einer Aktion angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancelButtonText;

  /// Text, der für das Speichern einer Aktion angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get saveText;

  /// Text, der für die Bestätigung einer Aktion angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirmText;

  /// Text, der für das Hinzufügen von lokalen Piktogrammen angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Bilder vom Gerät auswählen'**
  String get selectImageFromDeviceTitle;

  /// Text, der für das Hinzufügen eines einzelnen lokalen Piktogramms angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Bild vom Gerät wählen'**
  String get selectSingleImageFromDeviceText;

  /// Text, der für das Aufnehmen eines Fotos angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get takePhotoText;

  /// Text, der für das Aufnehmen eines Piktogramms mit der Kamera angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Mit der Kamera fotografieren'**
  String get takePhotoSubtitleText;

  /// Text, der für das Auswählen eines Piktogramms aus der Galerie angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie auswählen'**
  String get selectFromGalleryText;

  /// Text, der für das Auswählen eines Piktogramms aus der Galerie angezeigt wird
  ///
  /// In de, this message translates to:
  /// **'DCIM, Downloads, etc.'**
  String get selectFromGallerySubtitleText;

  /// Label für die optionale Beschreibung eines Piktogramms
  ///
  /// In de, this message translates to:
  /// **'Beschreibung (optional)'**
  String get descriptionText;

  /// Button text to show more details in the dialog
  ///
  /// In de, this message translates to:
  /// **'More Details'**
  String get descriptionPictogramPlaceholder;

  /// Fallback-Text, wenn TTS nicht funktioniert
  ///
  /// In de, this message translates to:
  /// **'Sprache: {keyword}'**
  String ttsErrorText(Object keyword);

  /// Titel für das Grid-Einstellungs-Dialogfenster
  ///
  /// In de, this message translates to:
  /// **'Rastereinstellungen'**
  String get gridSettingsText;

  /// Label für die Gridgröße im Einstellungsdialog
  ///
  /// In de, this message translates to:
  /// **'Rastergröße'**
  String get gridSizeText;

  /// Label für den Switch zum Anzeigen der Rasterlinien
  ///
  /// In de, this message translates to:
  /// **'Rasterlinien anzeigen'**
  String get showGridLinesText;

  /// Label für den Sprach-Einstellungsbereich
  ///
  /// In de, this message translates to:
  /// **'Sprache-Einstellungen'**
  String get languageSettingsText;

  /// Label für den Lautstärke-Slider
  ///
  /// In de, this message translates to:
  /// **'Lautstärke: '**
  String get volumeText;

  /// Label für den Geschwindigkeit-Slider
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit: '**
  String get speechRateText;

  /// Button-Text zum Zurücksetzen der Einstellungen
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get resetText;

  /// Button-Text zum Schließen des Dialogs
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get closeText;

  /// Titel für das Löschen-Dialogfenster
  ///
  /// In de, this message translates to:
  /// **'Piktogramm löschen'**
  String get deletePictogramText;

  /// Text für das Löschen-Dialogfenster
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie das Piktogramm \"{keyword}\" wirklich aus dem Grid entfernen?'**
  String deletePictogramContent(Object keyword);

  /// Button-Text zum Abbrechen
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancelText;

  /// Button-Text zum Löschen
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get deleteText;

  /// Snackbar-Text nach Entfernen eines Piktogramms
  ///
  /// In de, this message translates to:
  /// **'{keyword} wurde aus dem Grid entfernt'**
  String removedFromGridText(Object keyword);

  /// Label für das Namensfeld im Benennungsdialog
  ///
  /// In de, this message translates to:
  /// **'Name für Sprachausgabe *'**
  String get nameForSpeechLabel;

  /// Snackbar-Text nach Hinzufügen eines Piktogramms
  ///
  /// In de, this message translates to:
  /// **'{keyword} wurde hinzugefügt'**
  String addedToGridText(Object keyword);

  /// Hinweistext, wenn kein Profil existiert
  ///
  /// In de, this message translates to:
  /// **'Erstellen Sie ein Profil, um loszulegen. Pro Profil können Sie bis zu 3 Grids anlegen.'**
  String get infoNoProfile;

  /// Hinweistext, wenn kein Grid existiert
  ///
  /// In de, this message translates to:
  /// **'Erstellen Sie ein Grid für dieses Profil. Aktivieren Sie dann den Bearbeitungsmodus (✏️), um Piktogramme hinzuzufügen.'**
  String get infoNoGrid;

  /// Hinweistext, wie man Piktogramme hinzufügt
  ///
  /// In de, this message translates to:
  /// **'Aktivieren Sie den Bearbeitungsmodus (✏️) und klicken Sie auf ein Kästchen, um Piktogramme hinzuzufügen.'**
  String get infoEditHint;

  /// Willkommensüberschrift
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei PictoGrid!'**
  String get welcomeText;

  /// Aufforderung, ein Profil zu erstellen
  ///
  /// In de, this message translates to:
  /// **'Erstellen Sie zuerst ein Profil'**
  String get createProfilePrompt;

  /// Button-Text für neues Profil
  ///
  /// In de, this message translates to:
  /// **'Neues Profil erstellen'**
  String get createProfileButton;

  /// Snackbar-Text nach Profil-Erstellung
  ///
  /// In de, this message translates to:
  /// **'Profil \"{name}\" wurde erstellt'**
  String profileCreated(Object name);

  /// Fehlertext bei Profil-Erstellung
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Erstellen: {error}'**
  String profileCreateError(Object error);

  /// Titel für Profil löschen Dialog
  ///
  /// In de, this message translates to:
  /// **'Profil löschen'**
  String get profileDeleteText;

  /// Inhalt für Profil löschen Dialog
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie das Profil \"{profile}\" wirklich löschen?\n\nAlle Grids in diesem Profil werden ebenfalls gelöscht.'**
  String profileDeleteContent(Object profile);

  /// Button-Text zum Abbrechen
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get profileDeleteCancel;

  /// Button-Text zum Löschen
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get profileDeleteConfirm;

  /// Snackbar-Text nach Profil-Löschung
  ///
  /// In de, this message translates to:
  /// **'Profil wurde gelöscht'**
  String get profileDeleted;

  /// Fehlertext bei Profil-Löschung
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen: {error}'**
  String profileDeleteError(Object error);

  /// Text, wenn noch keine Grids existieren
  ///
  /// In de, this message translates to:
  /// **'Noch keine Grids vorhanden'**
  String get noGrids;

  /// Button-Text für erstes Grid
  ///
  /// In de, this message translates to:
  /// **'Erstes Grid erstellen'**
  String get createFirstGridButton;

  /// Snackbar-Text nach Grid-Erstellung
  ///
  /// In de, this message translates to:
  /// **'Grid \"{name}\" wurde erstellt'**
  String gridCreated(Object name);

  /// Fehlertext bei Grid-Erstellung
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Erstellen: {error}'**
  String gridCreateError(Object error);

  /// Titel für Grid löschen Dialog
  ///
  /// In de, this message translates to:
  /// **'Grid löschen'**
  String get gridDeleteText;

  /// Inhalt für Grid löschen Dialog
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie das Grid \"{grid}\" wirklich löschen?'**
  String gridDeleteContent(Object grid);

  /// Button-Text zum Abbrechen
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get gridDeleteCancel;

  /// Button-Text zum Löschen
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get gridDeleteConfirm;

  /// Snackbar-Text nach Grid-Löschung
  ///
  /// In de, this message translates to:
  /// **'Grid wurde gelöscht'**
  String get gridDeleted;

  /// Fehlertext bei Grid-Löschung
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen: {error}'**
  String gridDeleteError(Object error);

  /// Label für den Profilbereich
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profile;

  /// Button-Text zum Verwalten von Profilen
  ///
  /// In de, this message translates to:
  /// **'Profile verwalten'**
  String get manageProfiles;

  /// Button-Text zum Erstellen eines neuen Profils
  ///
  /// In de, this message translates to:
  /// **'Neues Profil'**
  String get newProfile;

  /// Button-Text zum Löschen eines Profils
  ///
  /// In de, this message translates to:
  /// **'Profil löschen'**
  String get deleteProfile;

  /// Button-Text zum Erstellen eines neuen Grids
  ///
  /// In de, this message translates to:
  /// **'Neues Grid erstellen'**
  String get createNewGrid;

  /// Text shown when the maximum number of grids is reached
  ///
  /// In de, this message translates to:
  /// **'Maximum {max} Grids erreicht'**
  String maxGridsReached(Object max);

  /// Button-Text zum Erstellen eines neuen Profils
  ///
  /// In de, this message translates to:
  /// **'Neues Profil erstellen'**
  String get createNewProfile;

  /// Label für das Profil-Name Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'Profil-Name'**
  String get prfileName;

  /// Platzhaltertext für das Profil-Name Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'z.B. Person, Familie, Einrichtung...'**
  String get profileNamePlaceholder;

  /// Button-Text zum Erstellen eines Profils oder Grids
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get createButtonText;

  /// Label für das Grid-Name Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'Grid-Name'**
  String get gridName;

  /// Platzhaltertext für das Grid-Name Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'z.B. Grundwortschatz, Essen, Aktivitäten...'**
  String get gridNamePlaceholder;

  /// Label für das Namensfeld im Benennungsdialog
  ///
  /// In de, this message translates to:
  /// **'Name *'**
  String get nameText;

  /// Snackbar-Text nach dem Speichern eines Piktogramms
  ///
  /// In de, this message translates to:
  /// **'Piktogramm \'{name}\' wurde gespeichert'**
  String savePictogramText(Object name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
