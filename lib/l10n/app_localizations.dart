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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Text shown while pictograms are loading
  ///
  /// In en, this message translates to:
  /// **'Loading pictograms...'**
  String get loadingText;

  /// Text shown while in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit mode activated - Click on a box to add pictograms'**
  String get editmodeactiveText;

  /// Text shown when edit mode is deactivated
  ///
  /// In en, this message translates to:
  /// **'Edit mode deactivated'**
  String get editmodeinactiveText;

  /// Text shown when grids are available
  ///
  /// In en, this message translates to:
  /// **'{count} Grid(s) available'**
  String gridsAvailableText(Object count);

  /// Text shown when a grid should be selected
  ///
  /// In en, this message translates to:
  /// **'Select a grid from the dropdown above'**
  String get chooseGridText;

  /// Text shown for the profile section
  ///
  /// In en, this message translates to:
  /// **'Profile: {profilename}'**
  String profileText(Object profilename);

  /// Title for the local pictogram search section
  ///
  /// In en, this message translates to:
  /// **'Search local pictograms'**
  String get localPictogramSearchTitle;

  /// Text shown for the pictogram search
  ///
  /// In en, this message translates to:
  /// **'Search pictogram...'**
  String get searchPictoGramPlaceHolder;

  /// Placeholder text for the search field
  ///
  /// In en, this message translates to:
  /// **'Enter search term'**
  String get searchFieldPlaceholder;

  /// Text shown when no results are found
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchFieldNoResults;

  /// Text shown for adding a pictogram
  ///
  /// In en, this message translates to:
  /// **'Add pictogram'**
  String get addPictogramText;

  /// Text shown for adding pictogram content
  ///
  /// In en, this message translates to:
  /// **'How would you like to add a pictogram?'**
  String get addPictogramContentText;

  /// Text shown for removing a pictogram
  ///
  /// In en, this message translates to:
  /// **'Remove pictogram'**
  String get removePictogramText;

  /// Text shown for editing a pictogram
  ///
  /// In en, this message translates to:
  /// **'Edit pictogram'**
  String get editPictogramText;

  /// Text shown for naming a pictogram
  ///
  /// In en, this message translates to:
  /// **'Name pictogram'**
  String get namePictogramText;

  /// Placeholder text for naming a pictogram
  ///
  /// In en, this message translates to:
  /// **'e.g. House, Car, Play...'**
  String get namePictogramPlaceholder;

  /// Text shown for canceling an action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonText;

  /// Text shown for saving an action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveText;

  /// Text shown for confirming an action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmText;

  /// Text shown for adding local pictograms
  ///
  /// In en, this message translates to:
  /// **'Select images from device'**
  String get selectImageFromDeviceTitle;

  /// Text shown for adding a single local pictogram
  ///
  /// In en, this message translates to:
  /// **'Select image from device'**
  String get selectSingleImageFromDeviceText;

  /// Text shown for taking a pictogram with the camera
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhotoText;

  /// Text shown for taking a pictogram with the camera
  ///
  /// In en, this message translates to:
  /// **'Take a photo with the camera'**
  String get takePhotoSubtitleText;

  /// Text shown for selecting a pictogram from the gallery
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGalleryText;

  /// Text shown for selecting a pictogram from the gallery
  ///
  /// In en, this message translates to:
  /// **'DCIM, Downloads, etc.'**
  String get selectFromGallerySubtitleText;

  /// Text shown for the description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionText;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
