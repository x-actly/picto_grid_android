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
}
