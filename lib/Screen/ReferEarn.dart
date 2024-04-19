import 'dart:math';

import 'package:eshop/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Helper/Color.dart';

import '../Provider/SettingProvider.dart';
import '../Provider/UserProvider.dart';
import '../ui/widgets/SimBtn.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/SimpleAppBar.dart';
import 'HomePage.dart';

class ReferEarn extends StatefulWidget {
  const ReferEarn({Key? key}) : super(key: key);

  @override
  _ReferEarnState createState() => _ReferEarnState();
}

class _ReferEarnState extends State<ReferEarn> {
  bool isLoading = true;

  @override
  void initState() {
    getReferCode();
    super.initState();
  }

  getReferCode() async {
    if (REFER_CODE == null || REFER_CODE == '' || REFER_CODE!.isEmpty) {
      REFER_CODE =
          await context.read<SettingProvider>().getPrefrence(REFERCODE);

      setState(() {
        isLoading = true;
      });
      generateReferral();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<void> generateReferral() async {
    try {
      String refer = getRandomString(8);

      //////

      Map parameter = {
        REFERCODE: refer,
      };

      apiBaseHelper.postAPICall(validateReferalApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          REFER_CODE = refer;

          Map parameter = {
            USER_ID: context.read<UserProvider>().userId,
            REFERCODE: refer,
          };

          apiBaseHelper.postAPICall(getUpdateUserApi, parameter);
        } else {
          if (count < 5) generateReferral();
          count++;
        }

        setState(() {
          isLoading = false;
        });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        setState(() {
          isLoading = false;
        });
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: scaffoldKey,
      appBar: getSimpleAppBar(getTranslated(context, 'REFEREARN')!, context),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/images/refer.svg",
                  colorFilter:
                      const ColorFilter.mode(colors.primary, BlendMode.srcIn),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 28.0),
                  child: Text(
                    getTranslated(context, 'REFEREARN')!,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    getTranslated(context, 'REFER_TEXT')!,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 28.0),
                  child: Text(
                    getTranslated(context, 'YOUR_CODE')!,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          style: BorderStyle.solid,
                          color: colors.secondary,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          REFER_CODE!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                        ),
                      )),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.lightWhite,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4.0))),
                      child: Text(getTranslated(context, 'TAP_TO_COPY')!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ))),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: REFER_CODE!));
                    setSnackbar('Refercode Copied to clipboard', context);
                  },
                ),
                SimBtn(
                  width: 0.8,
                  height: 35,
                  title: getTranslated(context, "SHARE_APP"),
                  onBtnSelected: () {
                    var str =
                        "$appName\nRefer Code:$REFER_CODE\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n\n${getTranslated(context, 'IOSLBL')}\n$iosLink";
                    Share.share(str);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
