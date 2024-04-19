import 'dart:ui';

import '../Model/language_model.dart';

abstract class LanguageManager {
  abstract final String defaultLanguageCode;
  List<Language> supported();
  List<Locale> codes() {
    return supported().map((locale) => Locale(locale.code)).toList();
  }

  List<String> codesString() {
    return supported().map((locale) => locale.code).toList();
  }

  ///Get default language
  Language getDefaultLanguage() {
    return supported().firstWhere(
      (element) => element.code == defaultLanguageCode,
      orElse: () {
        throw "The default language is not available";
      },
    );
  }

  List<String> getSubNameList() {
    return supported().map((e) => e.languageSubName).toList();
  }

  List<String> getNameList() {
    return supported().map((e) => e.languageName).toList();
  }
}
