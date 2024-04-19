import 'package:hive_flutter/hive_flutter.dart';

import 'hive_keys.dart';

class HiveUtils {
  ///private constructor
  HiveUtils._();

  static initBoxes() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveKeys.userDetailsBox);
  }

  static String? getJWT() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.jwtToken);
  }

  static Future<void> setJWT(String jwt) async {
    await Hive.box(HiveKeys.userDetailsBox).put(HiveKeys.jwtToken, jwt);
  }
  static void clearUserBox(){
    Hive.box(HiveKeys.userDetailsBox).clear();
  }
}
