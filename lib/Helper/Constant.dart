import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eshop/Screen/chat/converstationListScreen.dart';
import 'package:eshop/Screen/chat/converstationScreen.dart';
import 'package:eshop/settings.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const String appName = AppSettings.appName;
const String packageName = AppSettings.packageName;
const String iosPackage = AppSettings.iosPackage;
const String iosLink = AppSettings.iosLink;
const String appStoreId = AppSettings.appStoreId;

//change this with your client secret and API urls
const String baseUrl = AppSettings.baseUrl;
const String chatBaseUrl = AppSettings.chatBaseUrl;

const String deepLinkUrlPrefix = AppSettings.deepLinkUrlPrefix;
const String deepLinkName = AppSettings.deepLinkName;

const bool disableDarkTheme = AppSettings.disableDarkTheme;
bool? isFirebaseAuth;
bool? isCityWiseDelivery;
const String defaultLanguageCode = AppSettings.defaultLanguageCode;
const String defaultCountryCode = AppSettings.defaultCountryCode;

const int decimalPoints = AppSettings.decimalPoints;

const int timeOut = AppSettings.timeOut;
const int perPage = AppSettings.perPage;

///Below declared variables and functions are useful for chat feature
///Chat Features utility
///
const String messagesLoadLimit = AppSettings.messagesLoadLimit;
const double allowableTotalFileSizesInChatMediaInMB =
    AppSettings.allowableTotalFileSizesInChatMediaInMB;

//Token ExpireTime in minutes & issuer name
const int tokenExpireTime = 5;
const String issuerName = 'eshop'; //do not change it

const bool isDemoApp = true;

String getWhatsappShareText(
    {required String userName,
    required String productName,
    required String productDynamicLink}) {
  return "Hello there,\n\nI'm $userName. I saw the $productName on your application and I'm interested in purchasing it.\n\n$productDynamicLink";
}

//General Error Message
const String errorMesaage = 'Something went wrong, Error : ';
const String androidLink = 'https://play.google.com/store/apps/details?id=';

GlobalKey<ConverstationScreenState> converstationScreenStateKey =
    GlobalKey<ConverstationScreenState>();

GlobalKey<ConverstationListScreenState> converstationListScreenStateKey =
    GlobalKey<ConverstationListScreenState>();

bool isSameDay(
    {required DateTime dateTime,
    required bool takeCurrentDate,
    DateTime? givenDate}) {
  final dateToCompare = takeCurrentDate ? DateTime.now() : givenDate!;
  return (dateToCompare.day == dateTime.day) &&
      (dateToCompare.month == dateTime.month) &&
      (dateToCompare.year == dateTime.year);
}

String formatDateYYMMDD({required DateTime dateTime}) {
  return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
}

String formatDate(DateTime dateTime) {
  return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
}

//Key to store all queue notifications of chat messages in shared pref.
const String queueNotificationOfChatMessagesSharedPrefKey =
    'queueNotificationOfChatMessages';

Future<bool> hasStoragePermissionGiven() async {
  if (Platform.isIOS) {
    bool permissionGiven = await Permission.storage.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.storage.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  }
  final deviceInfoPlugin = DeviceInfoPlugin();
  final androidDeviceInfo = await deviceInfoPlugin.androidInfo;
  if (androidDeviceInfo.version.sdkInt < 33) {
    bool permissionGiven = await Permission.storage.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.storage.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  } else {
    bool permissionGiven = await Permission.photos.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.photos.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  }
}

Future<String> getExternalStoragePath() async {
  return Platform.isAndroid
      ? (await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS))
      : (await getApplicationDocumentsDirectory()).path;
}

Future<String> getTempStoragePath() async {
  return (await getTemporaryDirectory()).path;
}

Future<String> checkIfFileAlreadyDownloaded(
    {required String fileName,
    required String fileExtension,
    required bool downloadedInExternalStorage}) async {
  final filePath = downloadedInExternalStorage
      ? await getExternalStoragePath()
      : await getTempStoragePath();
  final File file = File('$filePath/$fileName.$fileExtension');

  return (await file.exists()) ? file.path : '';
}

Future<String?> getDownloadPath({Function(dynamic err)? onError}) async {
  Directory? directory;
  try {
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getDownloadsDirectory();
// Put file in global download folder, if for an unknown reason it didn't exist, we fallback
// ignore: avoid_slow_async_io
// if (!await directory.exists()) {
//   directory = await getDownloadsDirectory();
// }
    }
  } catch (err) {
    onError?.call(err);
  }
  return directory?.path;
}

///
///End of chat features utility
///
