import 'package:eshop/Helper/ApiBaseHelper.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/HomePage.dart';
import 'package:eshop/main.dart';
import 'package:eshop/ui/widgets/ApiException.dart';
import 'package:eshop/utils/Hive/hive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import 'SettingProvider.dart';

class PushNotificationProvider extends ChangeNotifier {
  void registerToken(String? token, BuildContext context) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    if (settingsProvider.getPrefrence(FCMTOKEN).toString().trim() != token) {
      var parameter = {
        FCM_ID: token,
      };
      if (context.read<UserProvider>().userId != '') {
        parameter[USER_ID] = context.read<UserProvider>().userId;
      }

      if (HiveUtils.getJWT() != null) {
        await updateFcmID(parameter: parameter).then((value) {
          if (value['error'] == false) {
            settingsProvider.setPrefrence(FCMTOKEN, token!);
          }
        });
      }
    }
  }

  static Future<Map<String, dynamic>> updateFcmID({
    required var parameter,
  }) async {
    try {
      var responseData = await ApiBaseHelper().postAPICall(
        updateFcmApi,
        parameter,
      );

      return responseData ?? {};
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    try {
      var parameter = {
        ID: id,
      };

      apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
        bool error = getdata["error"];
        // String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          List<Product> items = [];

          items = (data as List).map((data) => Product.fromJson(data)).toList();
          currentHero = notifyHero;

          Navigator.pushNamed(
              navigatorKey.currentContext!, Routers.productDetails,
              arguments: {
                "index": int.parse(id),
                "id": items[0].id!,
                "secPos": secPos,
                "list": list,
              });
        }
      }, onError: (error) {
        setSnackbar(error.toString(), navigatorKey.currentContext!);
      });
    } on Exception {}
  }
}
