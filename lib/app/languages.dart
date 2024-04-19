import 'package:eshop/Model/language_model.dart';

import '../utils/language_manager.dart';

class Languages extends LanguageManager {
  @override
  final String defaultLanguageCode = "en";

  @override
  List<Language> supported() {
    return const [
      Language(code: "en", languageName: "English", languageSubName: "English"),
      Language(code: "zh", languageName: "Chinese", languageSubName: "中国人"),
      Language(
          code: "es", languageName: "Spanish", languageSubName: "Española"),
      Language(code: "hi", languageName: "Hindi", languageSubName: "हिंदी"),
      Language(code: "ar", languageName: "Arabic", languageSubName: "عربي"),
      Language(code: "ru", languageName: "Russian", languageSubName: "Русский"),
      Language(code: "ja", languageName: "Japanese", languageSubName: "日本"),
      Language(code: "de", languageName: "German", languageSubName: "Deutsch"),
    ];
  }
}
