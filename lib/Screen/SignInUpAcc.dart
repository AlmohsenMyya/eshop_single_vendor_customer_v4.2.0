import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Screen/Dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Helper/Color.dart';
import '../app/routes.dart';
import 'SendOtp.dart';

class SignInUpAcc extends StatefulWidget {
  const SignInUpAcc({Key? key}) : super(key: key);

  @override
  _SignInUpAccState createState() => _SignInUpAccState();
}

class _SignInUpAccState extends State<SignInUpAcc> {
  _subLogo() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 30.0),
        child: SvgPicture.asset(
          'assets/images/homelogo.svg',
          colorFilter: const ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ));
  }

  welcomeEshopTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 30.0),
      child: Text(
        getTranslated(context, 'WELCOME_ESHOP')!,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  eCommerceforBusinessTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 5.0,
      ),
      child: Text(
        getTranslated(context, 'ECOMMERCE_APP_FOR_ALL_BUSINESS')!,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
      ),
    );
  }

  signInyourAccTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 80.0, bottom: 40),
      child: Text(
        getTranslated(context, 'SIGNIN_ACC_LBL')!,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  signInBtn() {
    return CupertinoButton(
      child: Container(
          width: deviceWidth! * 0.8,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: const BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Text(getTranslated(context, 'SIGNIN_LBL')!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colors.whiteTemp, fontWeight: FontWeight.normal))),
      onPressed: () {
        Navigator.pushNamed(context, Routers.loginScreen,
            arguments: {"isPop": false});
      },
    );
  }

  createAccBtn() {
    return CupertinoButton(
      child: Container(
          width: deviceWidth! * 0.8,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: const BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Text(getTranslated(context, 'CREATE_ACC_LBL')!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colors.whiteTemp, fontWeight: FontWeight.normal))),
      onPressed: () {


        Navigator.pushNamed(context, Routers.sendOTPScreen,arguments: {
          "title":getTranslated(context, 'SEND_OTP_TITLE')
        });

      },
    );
  }

  skipSignInBtn() {
    return CupertinoButton(
      child: Container(
          width: deviceWidth! * 0.8,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: const BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Text(getTranslated(context, 'SKIP_SIGNIN_LBL')!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colors.whiteTemp, fontWeight: FontWeight.normal))),
      onPressed: () {
        Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();

        Navigator.pushReplacementNamed(
          context,
          Routers.dashboardScreen,
        );
      },
    );
  }

  // backBtn() {
  //   return Container(
  //     padding: const EdgeInsetsDirectional.only(top: 34.0, start: 5.0),
  //     alignment: Alignment.topLeft,
  //     width: 60,
  //     child: Material(
  //         color: Colors.transparent,
  //         child: Container(
  //           margin: const EdgeInsets.all(10),
  //           decoration: shadow(),
  //           child: Card(
  //             elevation: 0,
  //             child: InkWell(
  //               borderRadius: BorderRadius.circular(4),
  //               onTap: () => Navigator.of(context).pop(),
  //               child: const Center(
  //                 child: Icon(
  //                   Icons.keyboard_arrow_left,
  //                   color: colors.primary,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         )),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.lightWhite,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _subLogo(),
                welcomeEshopTxt(),
                eCommerceforBusinessTxt(),
                signInyourAccTxt(),
                signInBtn(),
                createAccBtn(),
                skipSignInBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
