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
  String get editmodeactiveText =>
      'Edit mode activated - Click on a box to add pictograms';

  @override
  String get editmodeinactiveText => 'Edit mode deactivated';

  @override
  String get activateEditModeText => 'Activate edit mode';

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
  String get searchPictoGramPlaceHolder => 'Search pictogram...';

  @override
  String get localPictogramSearchTitle => 'Search local pictograms';

  @override
  String get searchFieldPlaceholder => 'Enter search term';

  @override
  String get searchFieldNoResults => 'No results found';

  @override
  String get addPictogramText => 'Add pictogram';

  @override
  String get addPictogramContentText =>
      'How would you like to add a pictogram?';

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
  String get descriptionText => 'Description (optional)';

  @override
  String get descriptionPictogramPlaceholder => 'More Details';

  @override
  String ttsErrorText(Object keyword) {
    return 'Sprache: $keyword';
  }

  @override
  String get gridSettingsText => 'Grid Settings';

  @override
  String get gridSizeText => 'Grid Size';

  @override
  String get showGridLinesText => 'Show grid lines';

  @override
  String get languageSettingsText => 'Language Settings';

  @override
  String get volumeText => 'Volume: ';

  @override
  String get speechRateText => 'Speech Rate: ';

  @override
  String get resetText => 'Reset Settings';

  @override
  String get closeText => 'Close';

  @override
  String get deletePictogramText => 'Delete pictogram';

  @override
  String deletePictogramContent(Object keyword) {
    return 'Do you really want to remove the pictogram \"$keyword\" from the grid?';
  }

  @override
  String get cancelText => 'Cancel';

  @override
  String get deleteText => 'Delete';

  @override
  String removedFromGridText(Object keyword) {
    return '$keyword has been removed from the grid';
  }

  @override
  String get nameForSpeechLabel => 'Name for speech *';

  @override
  String addedToGridText(Object keyword) {
    return '$keyword has been added';
  }

  @override
  String get infoNoProfile =>
      'Create a profile first. Then you can add grids and pictograms.';

  @override
  String get infoNoGrid =>
      'Create a grid for this profile. Then activate the editing mode (✏️) to add pictograms.';

  @override
  String get infoEditHint =>
      'Activate the editing mode (✏️) and click on a box to add pictograms.';

  @override
  String get welcomeText => 'Welcome to the Pictogram App';

  @override
  String get createProfilePrompt => 'Please create a profile to get started.';

  @override
  String get createProfileButton => 'Create Profile';

  @override
  String profileCreated(Object name) {
    return 'Profile \"$name\" has been created';
  }

  @override
  String profileCreateError(Object error) {
    return 'Error creating profile: $error';
  }

  @override
  String get profileDeleteText => 'Delete Profile';

  @override
  String profileDeleteContent(Object profile) {
    return 'Do you really want to delete the profile \"$profile\"?';
  }

  @override
  String get profileDeleteCancel => 'Cancel';

  @override
  String get profileDeleteConfirm => 'Delete';

  @override
  String get profileDeleted => 'Profile has been deleted';

  @override
  String profileDeleteError(Object error) {
    return 'Error deleting profile: $error';
  }

  @override
  String get noGrids => 'No grids available';

  @override
  String get createFirstGridButton => 'Create First Grid';

  @override
  String gridCreated(Object name) {
    return 'Grid \"$name\" has been created';
  }

  @override
  String gridCreateError(Object error) {
    return 'Error creating grid: $error';
  }

  @override
  String get gridDeleteText => 'Delete Grid';

  @override
  String gridDeleteContent(Object grid) {
    return 'Do you really want to delete the grid \"$grid\"?';
  }

  @override
  String get gridDeleteCancel => 'Cancel';

  @override
  String get gridDeleteConfirm => 'Delete';

  @override
  String get gridDeleted => 'Grid has been deleted';

  @override
  String gridDeleteError(Object error) {
    return 'Error deleting grid: $error';
  }

  @override
  String get profile => 'Profile';

  @override
  String get manageProfiles => 'Manage Profiles';

  @override
  String get newProfile => 'New Profile';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String get createNewGrid => 'Create New Grid';

  @override
  String maxGridsReached(Object max) {
    return 'Maximum $max grids reached';
  }

  @override
  String get createNewProfile => 'Create New Profile';

  @override
  String get prfileName => 'Profile Name';

  @override
  String get profileNamePlaceholder => 'like \'My Profile\', \'Family\'...';

  @override
  String get createButtonText => 'Create';

  @override
  String get gridName => 'Grid Name';

  @override
  String get gridNamePlaceholder =>
      'e.g. basic vocabulary, food, activities...';

  @override
  String get nameText => 'Name *';

  @override
  String savePictogramText(Object name) {
    return 'Piktogramm \'$name\' wurde gespeichert';
  }
}
