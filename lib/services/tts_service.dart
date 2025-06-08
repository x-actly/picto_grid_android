import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verfügbare Sprachen und Stimmen abrufen
      List<dynamic> languages = await _flutterTts.getLanguages;
      List<dynamic> voices = await _flutterTts.getVoices;

      if (kDebugMode) {
        print('Verfügbare Sprachen: $languages');
        print('Verfügbare Stimmen: $voices');
      }

      // Versuche deutsche Stimme zu finden
      bool germanVoiceSet = false;

      // Suche nach deutschen Stimmen
      for (var voice in voices) {
        if (voice is Map) {
          voice['name']?.toString().toLowerCase();
          String? locale = voice['locale']?.toString().toLowerCase();

          if (locale != null &&
              (locale.contains('de-de') || locale.contains('de_de'))) {
            // Konvertiere zu Map<String, String> für setVoice
            Map<String, String> voiceMap = {
              'name': voice['name']?.toString() ?? '',
              'locale': voice['locale']?.toString() ?? '',
            };
            await _flutterTts.setVoice(voiceMap);
            if (kDebugMode) {
              print('Deutsche Stimme gefunden und gesetzt: $voice');
            }
            germanVoiceSet = true;
            break;
          }
        }
      }

      // Fallback: Sprache auf Deutsch setzen
      if (!germanVoiceSet) {
        // Versuche verschiedene deutsche Lokale
        List<String> germanLocales = ['de-DE', 'de-AT', 'de-CH', 'de'];
        for (String locale in germanLocales) {
          try {
            var result = await _flutterTts.setLanguage(locale);
            if (result == 1) {
              if (kDebugMode) {
                print('Deutsche Sprache gesetzt: $locale');
              }
              break;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Konnte Sprache $locale nicht setzen: $e');
            }
          }
        }
      }

      // Sprechgeschwindigkeit setzen (0.0 bis 1.0)
      await _flutterTts.setSpeechRate(0.4);

      // Lautstärke setzen (0.0 bis 1.0)
      await _flutterTts.setVolume(0.8);

      // Tonhöhe setzen (0.5 bis 2.0)
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      if (kDebugMode) {
        print('TTS-Service erfolgreich initialisiert');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei TTS-Initialisierung: $e');
      }
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Stoppe eventuelle laufende Sprachausgabe
      await _flutterTts.stop();

      // Spreche den Text
      await _flutterTts.speak(text);
      if (kDebugMode) {
        print('TTS spricht: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Sprachausgabe: $e');
      }
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Stoppen der TTS: $e');
      }
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Setzen der Lautstärke: $e');
      }
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Setzen der Sprechgeschwindigkeit: $e');
      }
    }
  }
}
