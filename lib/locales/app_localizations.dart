import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import 'en.dart';
import 'te.dart';
import 'hi.dart';
import 'sa.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': enStrings,
    'te': teStrings,
    'hi': hiStrings,
    'sa': saStrings,
  };

  static const List<Map<String, String>> supportedLanguages = [
    {
      'code': 'en',
      'nativeName': 'English',
      'englishName': 'English',
      'subtitle': 'Default Guide',
      'script': 'Latin',
    },
    {
      'code': 'te',
      'nativeName': 'తెలుగు',
      'englishName': 'Telugu',
      'subtitle': 'మాతృభాష',
      'script': 'Telugu',
    },
    {
      'code': 'hi',
      'nativeName': 'हिन्दी',
      'englishName': 'Hindi',
      'subtitle': 'राष्ट्रभाषा',
      'script': 'Devanagari',
    },
    {
      'code': 'sa',
      'nativeName': 'संस्कृतम्',
      'englishName': 'Sanskrit',
      'subtitle': 'देववाणी',
      'script': 'Devanagari',
    },
  ];

  static String tr(BuildContext context, String key, {String? fallback}) {
    String langCode = 'en';
    try {
      langCode = AppStateScope.of(context).selectedLanguage;
    } catch (_) {}

    final langMap = _localizedValues[langCode] ?? _localizedValues['en']!;
    return langMap[key] ?? _localizedValues['en']![key] ?? fallback ?? key;
  }

  static String getDirect(String langCode, String key, {String? fallback}) {
    final langMap = _localizedValues[langCode] ?? _localizedValues['en']!;
    return langMap[key] ?? _localizedValues['en']![key] ?? fallback ?? key;
  }
}

extension AppLocalizationsExt on BuildContext {
  String tr(String key, {String? fallback}) => AppLocalizations.tr(this, key, fallback: fallback);
}
