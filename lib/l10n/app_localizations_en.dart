// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loadingText => 'Loading pictograms...';

  @override
  String get editmodeactiveText => 'Edit mode activated - Click on a box to add pictograms';

  @override
  String get editmodeinactiveText => 'Edit mode deactivated';

  @override
  String gridsAvailableText(Object count) {
    return '$count Grid(s) available';
  }

  @override
  String get chooseGridText => 'Select a grid from the dropdown above';

  @override
  String profileText(Object profilename) {
    return 'Profile: $profilename';
  }

  @override
  String get localPictogramSearchTitle => 'Search local pictograms';

  @override
  String get searchPictoGramPlaceHolder => 'Search pictogram...';

  @override
  String get searchFieldPlaceholder => 'Enter search term';

  @override
  String get searchFieldNoResults => 'No results found';

  @override
  String get addPictogramText => 'Add pictogram';

  @override
  String get addPictogramContentText => 'How would you like to add a pictogram?';

  @override
  String get removePictogramText => 'Remove pictogram';

  @override
  String get editPictogramText => 'Edit pictogram';

  @override
  String get namePictogramText => 'Name pictogram';

  @override
  String get namePictogramPlaceholder => 'e.g. House, Car, Play...';

  @override
  String get cancelButtonText => 'Cancel';

  @override
  String get saveText => 'Save';

  @override
  String get confirmText => 'Confirm';

  @override
  String get selectImageFromDeviceTitle => 'Select images from device';

  @override
  String get selectSingleImageFromDeviceText => 'Select image from device';

  @override
  String get takePhotoText => 'Take photo';

  @override
  String get takePhotoSubtitleText => 'Take a photo with the camera';

  @override
  String get selectFromGalleryText => 'Select from gallery';

  @override
  String get selectFromGallerySubtitleText => 'DCIM, Downloads, etc.';

  @override
  String get descriptionText => 'Description';
}
