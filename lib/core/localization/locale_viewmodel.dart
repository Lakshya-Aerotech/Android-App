import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

final localeViewModelProvider = StateNotifierProvider<LocaleViewModel, Locale?>(
  (ref) {
    return LocaleViewModel()..loadSavedLocale();
  },
);

class LocaleViewModel extends StateNotifier<Locale?> {
  LocaleViewModel() : super(null);

  static const _languageCodeKey = 'selected_language_code';

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode == null || languageCode.isEmpty) return;

    final locale = Locale(languageCode);
    if (_isSupported(locale)) {
      state = locale;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
  }

  bool _isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }
}
