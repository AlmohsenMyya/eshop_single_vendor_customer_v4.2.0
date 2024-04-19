import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode themeMode;


  ThemeNotifier(this.themeMode);

  getThemeMode() => themeMode;

  setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
  }
}
