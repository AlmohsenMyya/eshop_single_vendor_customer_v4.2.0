import 'package:flutter/material.dart';

import '../../Helper/Color.dart';
import 'package:google_fonts/google_fonts.dart';
ThemeData lightTheme = ThemeData(
  useMaterial3: false,
  canvasColor: ThemeData().colorScheme.lightWhite,
  cardColor: colors.cardColor,
  dialogBackgroundColor: ThemeData().colorScheme.white,
  iconTheme: ThemeData().iconTheme.copyWith(color: colors.primary),
  primarySwatch: colors.primary_app,
  primaryColor: ThemeData().colorScheme.lightWhite,
  fontFamily: GoogleFonts.cairo().fontFamily,
  colorScheme: ColorScheme.fromSwatch(primarySwatch: colors.primary_app)
      .copyWith(secondary: colors.secondary, brightness: Brightness.light),
  textTheme: TextTheme(

          titleLarge: TextStyle(
            color: ThemeData().colorScheme.fontColor,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
              color: ThemeData().colorScheme.fontColor,
              fontWeight: FontWeight.bold))
      .apply(bodyColor: ThemeData().colorScheme.fontColor),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: false,
  canvasColor: colors.darkColor,
  cardColor: colors.darkColor2,
  dialogBackgroundColor: colors.darkColor2,
  primaryColor: colors.darkColor,
  textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.darkIcon,
      selectionColor: colors.darkIcon,
      selectionHandleColor: colors.darkIcon),
  fontFamily: GoogleFonts.cairo().fontFamily,
  //brightness: Brightness.dark,
  iconTheme: ThemeData().iconTheme.copyWith(color: colors.primary),
  textTheme: TextTheme(
          titleLarge: TextStyle(
            color: ThemeData().colorScheme.fontColor,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
              color: ThemeData().colorScheme.fontColor,
              fontWeight: FontWeight.bold))
      .apply(bodyColor: ThemeData().colorScheme.fontColor),
  colorScheme: ColorScheme.fromSwatch(primarySwatch: colors.primary_app)
      .copyWith(secondary: colors.darkIcon, brightness: Brightness.dark),
  checkboxTheme: CheckboxThemeData(
    fillColor:
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return colors.primary;
      }
      return null;
    }),
  ),
  radioTheme: RadioThemeData(
    fillColor:
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return colors.primary;
      }
      return null;
    }),
  ),
  switchTheme: SwitchThemeData(
    thumbColor:
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return colors.primary;
      }
      return null;
    }),
    trackColor:
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return colors.primary;
      }
      return null;
    }),
  ),
);
