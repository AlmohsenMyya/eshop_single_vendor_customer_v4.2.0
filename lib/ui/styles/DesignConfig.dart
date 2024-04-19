import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../Helper/Color.dart';
import '../../Helper/Constant.dart';
import '../../Helper/Session.dart';
import '../../Helper/String.dart';
import '../../Helper/cart_var.dart';
import '../../Provider/HomeProvider.dart';

void hideAppbarAndBottomBarOnScroll(
  ScrollController scrollBottomBarController,
  BuildContext context,
) {
  scrollBottomBarController.addListener(() {
    if (scrollBottomBarController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (!context.read<HomeProvider>().animationController.isAnimating) {
        context.read<HomeProvider>().animationController.forward();
        context.read<HomeProvider>().showBars(false);
      }
    } else {
      if (!context.read<HomeProvider>().animationController.isAnimating) {
        context.read<HomeProvider>().animationController.reverse();
        context.read<HomeProvider>().showBars(true);
      }
    }
  });
}

shadow() {
  return const BoxDecoration(
    boxShadow: [
      BoxShadow(color: Color(0x1a0400ff), offset: Offset(0, 0), blurRadius: 30)
    ],
  );
}

placeHolder(double height) {
  return const AssetImage(
    'assets/images/Placeholder_Rectangle.png',
  );
}

erroWidget(double size) {
  return Image.asset(
    "assets/images/Placeholder_Rectangle.png",
    color: colors.primary,
    width: size,
    height: size,
  );
}

Widget networkImageCommon(String image, double placeHeight, bool isSlider,
    {double? height, double? width, BoxFit? boxFit}) {
  return FadeInImage(
    fadeInDuration: const Duration(milliseconds: 150),
    image: NetworkImage(image),
    height: height ?? height,
    width: width ?? width,
    fit: boxFit ?? (extendImg ? BoxFit.cover : BoxFit.contain),
    placeholder: isSlider ? sliderPlaceHolder() : placeHolder(placeHeight),
    placeholderErrorBuilder: ((context, error, stackTrace) {
      return erroWidget(placeHeight);
    }),
    imageErrorBuilder: ((context, error, stackTrace) {
      return erroWidget(placeHeight);
    }),
  );
}

sliderPlaceHolder() {
  return const AssetImage(
    "assets/images/sliderph.png",
  );
}

errorAccWidget(double size) {
  return Icon(
    Icons.account_circle,
    color: Colors.grey,
    size: size,
  );
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

cartTotalClear() {
  totalPrice = 0;
  // oriPrice = 0;

  taxPer = 0;
  delCharge = 0;
  addressList.clear();

  promoAmt = 0;
  remWalBal = 0;
  usedBal = 0;
  payMethod = '';
  isPromoValid = false;
  isPromoLen = false;
  isUseWallet = false;
  isPayLayShow = true;
  selectedMethod = null;
  selectedTime = null;
  selectedDate = null;
  selAddress = '';
  selTime = "";
  selDate = "";
  promocode = "";
  codDeliverChargesOfShipRocket = 0.0;
  prePaidDeliverChargesOfShipRocket = 0.0;
  isLocalDelCharge = null;
  shipRocketDeliverableDate = '';
}

getThemeColor(BuildContext context) {
  var systemBrightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  var applicationBrightness = Theme.of(context).brightness;

  if (systemBrightness == Brightness.dark &&
      applicationBrightness == Brightness.light) {
    return 'assets/images/loginlogo.svg';
  } else if (systemBrightness == Brightness.light &&
      applicationBrightness == Brightness.light) {
    return 'assets/images/loginlogo.svg';
  } else {
    return 'assets/images/dark_loginlogo.svg';
  }
}

Widget bottomSheetHandle(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10.0),
    child: Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Theme.of(context).colorScheme.lightBlack),
      height: 5,
      width: MediaQuery.of(context).size.width * 0.3,
    ),
  );
}

Widget bottomsheetLabel(String labelName, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 30.0, bottom: 20),
    child: getHeading(labelName, context),
  );
}

Widget getHeading(String title, BuildContext context) {
  return Text(
    getTranslated(context, title)!,
    style: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.fontColor,
        ),
  );
}

noIntImage() {
  return SvgPicture.asset('assets/images/no_internet.svg', fit: BoxFit.contain);
}

setSnackbar(String msg, BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showToast(msg,
      fullWidth: true,
      context: context,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.slideToBottom,
      position: StyledToastPosition.bottom,
      animDuration: const Duration(milliseconds: 300),
      duration: const Duration(seconds: 2),
      curve: Curves.elasticOut,
      reverseCurve: Curves.linear,
      borderRadius: BorderRadius.circular(10.0),
      backgroundColor: Theme.of(context).colorScheme.white,
      textStyle: TextStyle(color: Theme.of(context).colorScheme.black));
}

/*setSnackbar(String msg, BuildContext context) {
  try {
    scaffoldMessageKey.currentState!.showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  } catch (e) {
    print(e);
  }
}*/

String imagePath = 'assets/images/';

noIntText(BuildContext context) {
  return Text(getTranslated(context, 'NO_INTERNET')!,
      style: Theme.of(context)
          .textTheme
          .headlineSmall!
          .copyWith(color: colors.primary, fontWeight: FontWeight.normal));
}

noIntDec(BuildContext context) {
  return Container(
    padding:
        const EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
    child: Text(getTranslated(context, 'NO_INTERNET_DISC')!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.lightBlack2,
              fontWeight: FontWeight.normal,
            )),
  );
}

Widget showCircularProgress(bool isProgress, Color color) {
  if (isProgress) {
    return Center(
        child: CircularProgressIndicator(
      color: colors.primary,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ));
  }
  return const SizedBox(
    height: 0.0,
    width: 0.0,
  );
}

imagePlaceHolder(double size, BuildContext context) {
  return SizedBox(
    height: size,
    width: size,
    child: Icon(
      Icons.account_circle,
      color: Theme.of(context).colorScheme.white,
      size: size,
    ),
  );
}

Widget getProgress() {
  return const Center(
      child: CircularProgressIndicator(
    color: colors.primary,
  ));
}

Widget getNoItem(BuildContext context) {
  return Center(
      child: Text(
    getTranslated(context, 'noItem')!,
    style: Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: Theme.of(context).colorScheme.fontColor),
  ));
}

Widget shimmer(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    child: Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.simmerBase,
      highlightColor: Theme.of(context).colorScheme.simmerHigh,
      child: SingleChildScrollView(
        child: Column(
          children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
              .map((_) => Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80.0,
                          height: 80.0,
                          color: Theme.of(context).colorScheme.white,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                              ),
                              Container(
                                width: double.infinity,
                                height: 8.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                              ),
                              Container(
                                width: 100.0,
                                height: 8.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                              ),
                              Container(
                                width: 20.0,
                                height: 8.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    ),
  );
}

Widget singleItemSimmer(BuildContext context) {
  return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.simmerBase,
          highlightColor: Theme.of(context).colorScheme.simmerHigh,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80.0,
                  height: 80.0,
                  color: Theme.of(context).colorScheme.white,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 18.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      Container(
                        width: double.infinity,
                        height: 8.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      Container(
                        width: 100.0,
                        height: 8.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      Container(
                        width: 20.0,
                        height: 8.0,
                        color: Theme.of(context).colorScheme.white,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )));
}

simmerSingleProduct(BuildContext context) {
  return Container(
      //width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          color: Theme.of(context).colorScheme.white,
        ),
      ));
}

/*String? getPriceFormat(BuildContext context, double price) {
  //var SUPPORTED_LOCALS= context.read<SettingProvider>().supportedLocales;

  return NumberFormat.simpleCurrency(locale: SUPPORTED_LOCALES)
      .format(price)
      .toString();
}*/

String? getPriceFormat(BuildContext context, double price) {
  return NumberFormat.currency(
          locale: Platform.localeName,
          name: SUPPORTED_LOCALES,
          symbol: CUR_CURRENCY,
          decimalDigits: decimalPoints)
      .format(price)
      .toString();
}

dialogAnimate(BuildContext context, Widget dialge) {
  return showGeneralDialog(
      barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(opacity: a1.value, child: dialge),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      context: context,
      // pageBuilder: null
      pageBuilder: (context, animation1, animation2) {
        return const SizedBox.shrink();
      } //as Widget Function(BuildContext, Animation<double>, Animation<double>)
      );
}
