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
}
