import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eshop/Model/language_model.dart';
import 'package:eshop/app/languages.dart';
import 'package:eshop/utils/Hive/hive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app_Localization.dart';
import 'String.dart';

setPrefrenceBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode =
      prefs.getString(LAGUAGE_CODE) ?? Languages().defaultLanguageCode;
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  List<Language> supportedLanguages = Languages().supported();

  Language language = supportedLanguages.firstWhere(
    (element) => element.code == languageCode,
    orElse: () {
      return Languages().getDefaultLanguage();
    },
  );
  return Locale(language.code);
}

String? getTranslated(BuildContext context, String key) {
  return AppLocalization.of(context)!.translate(key) ?? key;
}

String getToken() {
  // final claimSet = JwtClaim(
  //     issuer: issuerName,
  //     // maxAge: const Duration(minutes: 1),
  //     maxAge: const Duration(days: tokenExpireTime),
  //     issuedAt: DateTime.now().toUtc());
  //
  // String token = issueJwtHS256(claimSet, Hive);
  // print("token is $token");
  return HiveUtils.getJWT() ?? "";
}

Map<String, String> get headers => {
      "Authorization": 'Bearer ${getToken()}',
    };
