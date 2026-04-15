import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted UI language (`en` / `es` / `pt`). `null` = follow device locale.
class AppLocalePreferences {
  AppLocalePreferences._();

  static const _key = 'app_locale_language_code';

  static Future<String?> loadSavedLanguageCode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  static Future<void> saveLanguageCode(String? languageCode) async {
    final p = await SharedPreferences.getInstance();
    if (languageCode == null || languageCode.isEmpty) {
      await p.remove(_key);
    } else {
      await p.setString(_key, languageCode);
    }
  }

  static Locale? localeFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }
}
