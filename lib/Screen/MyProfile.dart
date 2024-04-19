import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eshop/Helper/ApiBaseHelper.dart';
import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Helper/routes.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/FavoriteProvider.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Customer_Support.dart';
import 'package:eshop/Screen/ReferEarn.dart';
import 'package:eshop/app/languages.dart';
import 'package:eshop/app/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helper/Constant.dart';
import '../Provider/Theme.dart';
import '../main.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../utils/Hive/hive_utils.dart';
import 'Faqs.dart';
import 'HomePage.dart';
import 'Privacy_Policy.dart';

GlobalKey _scaffold = GlobalKey();

class MyProfile extends StatefulWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProfile();
}

class StateProfile extends State<MyProfile> with TickerProviderStateMixin {
  final InAppReview _inAppReview = InAppReview.instance;
  var isDarkTheme;
  bool isDark = false;
  late ThemeNotifier themeNotifier;
  Languages languages = Languages();
  late List<String> langCode = languages.codesString();
  List<String?> themeList = [];

  late List<String?> languageList = languages.getNameList();
  late List<String?> sublanguageList = languages.getSubNameList();

  final GlobalKey<FormState> _formkey1 = GlobalKey<FormState>();
  int? selectLan, curTheme;

  // TextEditingController? curPassC, confPassC;
  String? curPass, newPass, confPass, pass, mob;

  //String? name, email, mobile;

  final GlobalKey<FormState> _changePwdKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _changeUserDetailsKey = GlobalKey<FormState>();
  final confirmpassController = TextEditingController();
  final newpassController = TextEditingController();
  final passwordController = TextEditingController();
  final passController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  String? currentPwd, newPwd, confirmPwd;
  FocusNode confirmPwdFocus = FocusNode();
  File? image;

  bool _isNetworkAvail = true;
  late Function sheetSetState;
  bool countDownComplete = false;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final ScrollController _scrollBottomBarController = ScrollController();
  bool isLoading = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Animation? buttonSqueezeanimation1;
  AnimationController? buttonController1;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      _getSaved();

      buttonController1 = AnimationController(
          duration: const Duration(milliseconds: 2000), vsync: this);

      buttonSqueezeanimation1 = Tween(
        begin: deviceWidth! * 0.7,
        end: 50.0,
      ).animate(CurvedAnimation(
        parent: buttonController1!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ));

      buttonController = AnimationController(
          duration: const Duration(milliseconds: 2000), vsync: this);

      buttonSqueezeanimation = Tween(
        begin: deviceWidth! * 0.7,
        end: 50.0,
      ).animate(CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ));
    });

    super.initState();
  }

  _getSaved() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    mob = await settingsProvider.getPrefrence(MOBILE) ?? '';
    context
        .read<UserProvider>()
        .setUserId(await settingsProvider.getPrefrence(ID) ?? '');

    nameController.text = context.read<UserProvider>().curUserName;
    emailController.text = context.read<UserProvider>().email;
    mobileController.text = context.read<UserProvider>().mob;

    print("mobile controller***${mobileController.text}");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? get = prefs.getString(APP_THEME);

    curTheme = themeList.indexOf(get == '' || get == DEFAULT_SYSTEM
        ? getTranslated(context, 'SYSTEM_DEFAULT')
        : get == LIGHT
            ? getTranslated(context, 'LIGHT_THEME')
            : getTranslated(context, 'DARK_THEME'));

    String getlng = await settingsProvider.getPrefrence(LAGUAGE_CODE) ?? '';

    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);

    if (mounted) setState(() {});
  }

  _getHeader() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10.0, top: 10),
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: 10.0,
          ),
          child: Row(
            children: [
              Selector<UserProvider, String>(
                  selector: (_, provider) => provider.profilePic,
                  builder: (context, profileImage, child) {
                    return getUserImage(
                        profileImage, openChangeUserDetailsBottomSheet);
                  }),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.curUserName,
                      builder: (context, userName, child) {
                        nameController = TextEditingController(text: userName);
                        return Text(
                          userName == ""
                              ? getTranslated(context, 'GUEST')!
                              : userName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                        );
                      }),
                  /* Selector<UserProvider, String>(
                      selector: (_, provider) => provider.mob,
                      builder: (context, userMobile, child) {
                        return userMobile != ""
                            ? Text(
                                userMobile,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal),
                              )
                            : Container(
                                height: 0,
                              );
                      }),*/
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.mob,
                      builder: (context, userMobile, child) {
                        mobileController =
                            TextEditingController(text: userMobile);
                        return userMobile != ""
                            ? Text(
                                userMobile,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal),
                              )
                            : Container(
                                height: 0,
                              );
                      }),
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.email,
                      builder: (context, userEmail, child) {
                        emailController =
                            TextEditingController(text: userEmail);
                        return userEmail != ""
                            ? Text(
                                userEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal),
                              )
                            : Container(
                                height: 0,
                              );
                      }),
                  Consumer<UserProvider>(builder: (context, userProvider, _) {
                    return userProvider.curUserName == ""
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(top: 7),
                            child: InkWell(
                              child: Text(
                                  getTranslated(context, 'LOGIN_REGISTER_LBL')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: colors.primary,
                                        decoration: TextDecoration.underline,
                                      )),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routers.loginScreen,
                                  arguments: {
                                    "isPop": true,
                                    "classType": MyProfile()
                                  },
                                );
                              },
                            ))
                        : const SizedBox.shrink();
                  }),
                ],
              ),
            ],
          ),
        ));
  }

  List<Widget> getLngList(BuildContext ctx) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  if (mounted) {
                    selectLan = index;
                    _changeLan(langCode[index], ctx);
                    // });
                    //  });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectLan == index
                                    ? colors.primary
                                    : Theme.of(ctx).colorScheme.white,
                                border: Border.all(color: colors.primary)),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: selectLan == index
                                  ? Icon(
                                      Icons.check,
                                      size: 17.0,
                                      color: Theme.of(ctx).colorScheme.white,
                                    )
                                  : Icon(
                                      Icons.check_box_outline_blank,
                                      size: 17.0,
                                      color: Theme.of(ctx).colorScheme.white,
                                    ),
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 30.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageList[index]!,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .lightBlack),
                                  ),
                                  Text(
                                    sublanguageList[index]!,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .lightBlack),
                                  )
                                ],
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  void _changeLan(String language, BuildContext ctx) async {
    Locale locale = await setLocale(language);

    MyApp.setLocale(ctx, locale);
  }

  Future<void> setUpdateUser(String userID,
      [oldPwd, newPwd, username, userEmail, userMob]) async {
    var apiBaseHelper = ApiBaseHelper();
    var data = {USER_ID: userID};
    if ((oldPwd != "") && (newPwd != "")) {
      data[OLDPASS] = oldPwd;
      data[NEWPASS] = newPwd;
    }
    if (username != "") {
      data[USERNAME] = username;
    }
    if (userEmail != "") {
      data[EMAIL] = userEmail;
    }

    if (userMob != "") {
      data[MOBILE] = userMob;
    }

    print("profile data****$data");
    final Map<String, dynamic> result =
        await apiBaseHelper.postAPICall(getUpdateUserApi, data);
    bool error = result["error"];
    String? msg = result["message"];
    await buttonController1!.reverse();
    Navigator.of(context).pop();
    if (!error) {
      var settingProvider =
          Provider.of<SettingProvider>(context, listen: false);
      var userProvider = Provider.of<UserProvider>(context, listen: false);

      if (username != "") {
        setState(() {
          settingProvider.setPrefrence(USERNAME, username);
          userProvider.setName(username);
        });
      }
      if (userEmail != "") {
        setState(() {
          settingProvider.setPrefrence(EMAIL, userEmail);
          userProvider.setEmail(userEmail);
        });
      }

      if (userMob != "") {
        setState(() {
          settingProvider.setPrefrence(MOBILE, userMob);
          userProvider.setMobile(userMob);
        });
      }

      setSnackbar(getTranslated(context, 'USER_UPDATE_MSG')!, context);
    } else {
      setSnackbar(msg!, context);
    }
    context.read<UserProvider>().setProgress(false);
  }

  _getDrawer() {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'MY_ORDERS_LBL')!,
                'assets/images/pro_myorder.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'MANAGE_ADD_LBL')!,
                'assets/images/pro_address.svg'),
        //CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'MYWALLET')!,
                'assets/images/pro_wh.svg'),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'YOUR_PROM_CO')!,
                'assets/images/promo.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'MYTRANSACTION')!,
                'assets/images/pro_th.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),

        if (disableDarkTheme == false) ...{
          _getDrawerItem(getTranslated(context, 'CHANGE_THEME_LBL')!,
              'assets/images/pro_theme.svg'),
        },

        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'CHANGE_LANGUAGE_LBL')!,
            'assets/images/pro_language.svg'),
        //  CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
        context.read<UserProvider>().userId == "" ||
                context.read<UserProvider>().loginType != PHONE_TYPE
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'CHANGE_PASS_LBL')!,
                'assets/images/pro_pass.svg'),
        // _getDivider(),
        context.read<UserProvider>().userId == "" || !refer
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'REFEREARN')!,
                'assets/images/pro_referral.svg'),
        // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'CUSTOMER_SUPPORT')!,
                'assets/images/pro_customersupport.svg'),
        // _getDivider(),
        context.read<UserProvider>().userId == ''
            ? const SizedBox()
            : _getDrawerItem(
                getTranslated(context, 'CHAT')!, 'assets/images/pro_chat.svg'),
        _getDrawerItem(getTranslated(context, 'ABOUT_LBL')!,
            'assets/images/pro_aboutus.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'CONTACT_LBL')!,
            'assets/images/pro_contact_us.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'FAQS')!, 'assets/images/pro_faq.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'PRIVACY')!, 'assets/images/pro_pp.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'TERM')!, 'assets/images/pro_tc.svg'),
        _getDrawerItem(getTranslated(context, 'SHIPPING_PO_LBL')!,
            'assets/images/shipping_policy.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'RETURN_PO_LBL')!,
            'assets/images/return_policy.svg'),
        // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'RATE_US')!, 'assets/images/pro_rateus.svg'),
        // _getDivider(),
        _getDrawerItem(getTranslated(context, 'SHARE_APP')!,
            'assets/images/pro_share.svg'),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'DEL_ACC_LBL')!, ''),
        // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
        context.read<UserProvider>().userId == ""
            ? const SizedBox.shrink()
            : _getDrawerItem(getTranslated(context, 'LOGOUT')!,
                'assets/images/pro_logout.svg'),
      ],
    );
  }

  _getDrawerItem(String title, String img) {
    return Card(
      // color: colors.whiteTemp,
      elevation: 0,
      child: ListTile(
        trailing: Icon(
          Icons.navigate_next,
          color: Theme.of(context).colorScheme.blackInverseInDarkTheme,
        ),
        dense: false,
        leading: title == getTranslated(context, 'DEL_ACC_LBL')
            ? const Icon(
                Icons.delete,
                size: 25,
                color: colors.primary,
              )
            : SvgPicture.asset(
                img,
                height: 25,
                width: 25,
                colorFilter:
                    const ColorFilter.mode(colors.primary, BlendMode.srcIn),
              ),
        title: Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.lightBlack,
              fontSize: 15,
              fontWeight: FontWeight.normal),
        ),
        onTap: () {
          if (title == getTranslated(context, 'MY_ORDERS_LBL')) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => const MyOrder(),
            //     ));
            Navigator.pushNamed(context, Routers.myOrderScreen);
            //sendAndRetrieveMessage();
          } else if (title == getTranslated(context, 'MYTRANSACTION')) {
            Navigator.pushNamed(context, Routers.transactionHistoryScreen);
          } else if (title == getTranslated(context, 'MYWALLET')) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => const MyWalletScreen(),
            //     ));

            Navigator.pushNamed(context, Routers.myWalletScreen);
          } else if (title == getTranslated(context, 'YOUR_PROM_CO')) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => const PromoCodeScreen(from: "Profile"),
            //     ));
            Navigator.pushNamed(context, Routers.promoCodeScreen,
                arguments: {"from": "Profile"});
          } else if (title == getTranslated(context, 'MANAGE_ADD_LBL')) {
            Navigator.pushNamed(context, Routers.manageAddressScreen,
                arguments: {
                  "home": true,
                });
          } else if (title == getTranslated(context, 'REFEREARN')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ReferEarn(),
                ));
          } else if (title == getTranslated(context, 'CONTACT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'CONTACT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'CHAT')) {
            Routes.navigateToConverstationListScreen(context);
          } else if (title == getTranslated(context, 'CUSTOMER_SUPPORT')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const CustomerSupport()));
          } else if (title == getTranslated(context, 'TERM')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'TERM'),
                  ),
                ));
          } else if (title == getTranslated(context, 'PRIVACY')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'PRIVACY'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RATE_US')) {
            _openStoreListing();
          } else if (title == getTranslated(context, 'SHARE_APP')) {
            var str =
                "$appName\n\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n\n ${getTranslated(context, 'IOSLBL')}\n$iosLink";

            Share.share(str);
          } else if (title == getTranslated(context, 'ABOUT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'ABOUT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'SHIPPING_PO_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'SHIPPING_PO_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RETURN_PO_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'RETURN_PO_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'FAQS')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Faqs(
                    title: getTranslated(context, 'FAQS'),
                  ),
                ));
          } else if (title == getTranslated(context, 'CHANGE_THEME_LBL')) {
            openChangeThemeBottomSheet();
          } else if (title == getTranslated(context, 'LOGOUT')) {
            logOutDailog(context);
          } else if (title == getTranslated(context, 'CHANGE_PASS_LBL')) {
            openChangePasswordBottomSheet();
          } else if (title == getTranslated(context, 'CHANGE_LANGUAGE_LBL')) {
            openChangeLanguageBottomSheet();
          } else if (title == getTranslated(context, 'DEL_ACC_LBL')) {
            _showDialog();
          }
        },
      ),
    );
  }

  void changeVal() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (!countDownComplete) {
          sheetSetState(() {
            countDownComplete = true;
          });
        }
      }
    });
  }

  _showDialog() async {
    changeVal();
    await showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(opacity: a1.value, child: deleteConfirmDailog()),
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
        ).then((value) {
      if (countDownComplete) {
        sheetSetState(() {
          countDownComplete = false;
        });
      }
    });
  }

  deleteConfirmDailog() {
    int from = 0;
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0))),
      title: Text(
        getTranslated(context, 'DEL_YR_ACC_LBL')!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      content: StatefulBuilder(builder: (context, StateSetter setStater) {
        sheetSetState = setStater;
        return Form(
          key: _formkey1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                from == 0
                    ? getTranslated(context, 'DEL_WHOLE_TXT_LBL')!
                    : getTranslated(context, 'ADD_PASS_DEL_LBL')!,
                textAlign: TextAlign.center,
                style: Theme.of(this.context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
              if (from == 1)
                Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25)),
                      height: 50,
                      child: TextFormField(
                        controller: passController,
                        autofocus: false,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor),
                        onSaved: (val) {
                          setStater(() {
                            pass = val;
                          });
                        },
                        validator: (val) => validatePass(
                            val!,
                            getTranslated(context, 'PWD_REQUIRED'),
                            getTranslated(context, 'PASSWORD_VALIDATION'),
                            from: 123), //this is to not apply 2nd validation
                        enabled: true,
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          errorMaxLines: 4,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.gray),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(15.0, 10.0, 10, 10.0),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          fillColor: Theme.of(context).colorScheme.gray,
                          filled: true,
                          isDense: true,
                          hintText: getTranslated(context, 'PASSHINT_LBL'),
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.7),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                        ),
                      ),
                    )),
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0, top: 20),
                child: from == 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20),
                                  // width: double.maxFinite,
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    //color: colors.primary,
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0)),
                                  ),
                                  child: Text(getTranslated(context, 'CANCEL')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                          )))),
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: countDownComplete
                                  ? () {
                                      print(
                                          "login type***${context.read<UserProvider>().loginType}");
                                      if (context
                                              .read<UserProvider>()
                                              .loginType ==
                                          PHONE_TYPE) {
                                        setStater(() {
                                          from = 1;
                                        });
                                      } else {
                                        User? currentUser =
                                            FirebaseAuth.instance.currentUser;
                                        print("currentUser is:$currentUser");
                                        if (currentUser != null) {
                                          currentUser
                                              .delete()
                                              .then((value) async {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop(true);
                                            setDeleteSocialAcc();
                                          });
                                        } else {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop(true);
                                          setSnackbar(
                                              getTranslated(
                                                  context, 'RELOGIN_REQ')!,
                                              context);
                                        }
                                      }
                                    }
                                  : null,
                              child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20),
                                  //width: double.maxFinite,
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    color: countDownComplete
                                        ? colors.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .lightWhite,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0)),
                                  ),
                                  child: Text(
                                      getTranslated(context, 'CONFIRM')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: countDownComplete
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack,
                                            fontWeight: FontWeight.bold,
                                          )))),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                          final form = _formkey1.currentState!;

                          form.save();
                          if (form.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            Navigator.of(context, rootNavigator: true)
                                .pop(true);
                            setDeleteAcc();
                          }
                        },
                        child: Container(
                            margin: EdgeInsetsDirectional.only(
                                top: 10,
                                bottom: 10,
                                start: deviceWidth! / 5.3,
                                end: deviceWidth! / 5.3),
                            height: 40,
                            alignment: FractionalOffset.center,
                            decoration: const BoxDecoration(
                              color: colors.primary,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Text(getTranslated(context, 'DEL_ACC_LBL')!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold,
                                    )))),
              )
            ],
          ),
        );
      }),
    );
  }

  Future<void> setDeleteSocialAcc() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
        };

        apiBaseHelper.postAPICall(deleteSocialAccApi, parameter).then(
            (getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!, context);

            SettingProvider settingProvider =
                Provider.of<SettingProvider>(context, listen: false);

            context.read<FavoriteProvider>().setFavlist([]);
            context.read<CartProvider>().setCartlist([]);
            settingProvider.clearUserSession(context);
            Future.delayed(Duration.zero, () {
              // Navigator.of(context).pushAndRemoveUntil(
              //     MaterialPageRoute(
              //         builder: (BuildContext context) => const LoginScreen(
              //               isPop: false,
              //             )),
              //     (Route<dynamic> route) => false);

              Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routers.loginScreen,
                  arguments: {"isPop": false},
                  (route) => false);
            });
            setState(() {
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Future<void> setDeleteAcc() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PASSWORD: passController.text.trim(),
          MOBILE: mob
        };

        apiBaseHelper.postAPICall(setDeleteAccApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!, context);

            passController.clear();

            SettingProvider settingProvider =
                Provider.of<SettingProvider>(context, listen: false);

            context.read<FavoriteProvider>().setFavlist([]);
            context.read<CartProvider>().setCartlist([]);
            settingProvider.clearUserSession(context);
            Future.delayed(Duration.zero, () {
              // Navigator.of(context).pushAndRemoveUntil(
              //     MaterialPageRoute(
              //         builder: (BuildContext context) => const LoginScreen(
              //               isPop: false,
              //             )),
              //     (Route<dynamic> route) => false);

              Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routers.loginScreen,
                  arguments: {"isPop": false},
                  (route) => false);
            });
            setState(() {
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  List<Widget> themeListView(BuildContext ctx) {
    return themeList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  _updateState(index, ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: curTheme == index
                                    ? colors.primary
                                    : Theme.of(ctx).colorScheme.white,
                                border: Border.all(color: colors.primary)),
                            child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: curTheme == index
                                    ? Icon(
                                        Icons.check,
                                        size: 17.0,
                                        color: Theme.of(ctx).colorScheme.white,
                                      )
                                    : Icon(
                                        Icons.check_box_outline_blank,
                                        size: 17.0,
                                        color: Theme.of(ctx).colorScheme.white,
                                      )),
                          ),
                          Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 15.0,
                              ),
                              child: Text(
                                themeList[index]!,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .lightBlack),
                              ))
                        ],
                      ),
                      // index == themeList.length - 1
                      //     ? Container(
                      //         margin: EdgeInsetsDirectional.only(
                      //           bottom: 10,
                      //         ),
                      //       )
                      //     : Divider(
                      //         color: Theme.of(context).colorScheme.lightBlack,
                      //       )
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  _updateState(int position, BuildContext ctx) {
    curTheme = position;

    onThemeChanged(themeList[position]!, ctx);
  }

  void onThemeChanged(
    String value,
    BuildContext ctx,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == getTranslated(ctx, 'SYSTEM_DEFAULT')) {
      themeNotifier.setThemeMode(ThemeMode.system);
      prefs.setString(APP_THEME, DEFAULT_SYSTEM);

      var brightness = SchedulerBinding.instance.window.platformBrightness;
      if (mounted) {
        isDark = brightness == Brightness.dark;
        if (isDark) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        } else {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        }
      }
    } else if (value == getTranslated(ctx, 'LIGHT_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.light);
      prefs.setString(APP_THEME, LIGHT);
      if (mounted) {
        isDark = false;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      }
    } else if (value == getTranslated(ctx, 'DARK_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.dark);
      prefs.setString(APP_THEME, DARK);
      if (mounted) {
        isDark = true;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      }
    }
    ISDARK = isDark.toString();

    //Provider.of<SettingProvider>(context,listen: false).setPrefrence(APP_THEME, value);
  }

  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: 'microsoftStoreId',
      );

  logOutDailog(BuildContext context) async {
    await dialogAnimate(
        context,
        AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
          content: Text(
            getTranslated(this.context, 'LOGOUTTXT')!,
            style: Theme.of(this.context)
                .textTheme
                .titleMedium!
                .copyWith(color: Theme.of(this.context).colorScheme.fontColor),
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                  getTranslated(this.context, 'NO')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(this.context).colorScheme.lightBlack,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                }),
            TextButton(
                child: Text(
                  getTranslated(this.context, 'YES')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(this.context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  SettingProvider settingProvider =
                      Provider.of<SettingProvider>(context, listen: false);

                  context.read<FavoriteProvider>().setFavlist([]);
                  context.read<CartProvider>().setCartlist([]);
                  HiveUtils.clearUserBox();

                  Navigator.of(context, rootNavigator: true).pop(true);
                  if (context.read<UserProvider>().loginType != PHONE_TYPE) {
                    signOut(context.read<UserProvider>().loginType);
                  }

                  settingProvider.clearUserSession(context);
                })
          ],
        ));
  }

  Future<void> signOut(String type) async {
    _firebaseAuth.signOut();
    if (type == GOOGLE_TYPE) {
      _googleSignIn.signOut();
    } else {
      _firebaseAuth.signOut();
    }
  }

  @override
  void dispose() {
    passController.dispose();
    buttonController!.dispose();
    buttonController1!.dispose();
    _scrollBottomBarController.removeListener(() {});
    _scrollBottomBarController.dispose();
    confirmpassController.dispose();

    emailController.dispose();
    mobileController.dispose();
    nameController.dispose();
    newpassController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    hideAppbarAndBottomBarOnScroll(_scrollBottomBarController, context);

    themeList = [
      getTranslated(context, 'SYSTEM_DEFAULT'),
      getTranslated(context, 'LIGHT_THEME'),
      getTranslated(context, 'DARK_THEME')
    ];

    themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
        body: Consumer<UserProvider>(builder: (context, data, child) {
      return _isNetworkAvail
          ? Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  controller: _scrollBottomBarController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getHeader(),
                      _getDrawer(),
                    ],
                  ),
                ),
                showCircularProgress(isLoading, colors.primary),
              ],
            )
          : noInternet(context);
    }));
  }

  Future<void> _playAnimation(AnimationController ctrl) async {
    try {
      await ctrl.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation(buttonController!);
            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (BuildContext context) => super.widget));
              } else {
                await buttonController!.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        )
      ]),
    );
  }

  Widget getUserImage(String profileImage, VoidCallback? onBtnSelected) {
    return InkWell(
        child: Stack(
          children: <Widget>[
            Container(
              margin: const EdgeInsetsDirectional.only(end: 20),
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      width: 1.0, color: Theme.of(context).colorScheme.white)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child:
                    Consumer<UserProvider>(builder: (context, userProvider, _) {
                  return userProvider.profilePic != ''
                      ? networkImageCommon(userProvider.profilePic, 64, false,
                          height: 64, width: 64)
                      /*CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          imageUrl: userProvider.profilePic,
                          height: 64.0,
                          width: 64.0,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(64),
                          placeholder: (context, url) {
                            return placeHolder(64);
                          })*/
                      : imagePlaceHolder(62, context);
                }),
              ),
            ),
            if (context.read<UserProvider>().userId != "")
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 20,
                  bottom: 5,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        border: Border.all(color: colors.primary)),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.white,
                      size: 10,
                    ),
                  )),
          ],
        ),
        onTap: () {
          if (mounted) {
            if (context.read<UserProvider>().userId != "") onBtnSelected!();
          }
        });
  }

  void openChangeUserDetailsBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changeUserDetailsKey,
                  child:
                      Consumer<UserProvider>(builder: (context, provider, _) {
                    return Column(mainAxisSize: MainAxisSize.max, children: [
                      bottomSheetHandle(context),
                      bottomsheetLabel("EDIT_PROFILE_LBL", context),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child:
                            getUserImage(provider.profilePic, _imgFromGallery),
                      ),
                      setNameField(),
                      setEmailField(),
                      setMobileField(),
                      saveButton(
                          getTranslated(context, "SAVE_LBL")!,
                          !provider.getProgress
                              ? () {
                                  validateAndSave(_changeUserDetailsKey);
                                }
                              : () {})
                    ]);
                  }),
                ),
              ),
            ],
          );
        });
  }

  /* void _imgFromGallery() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      File? image = File(result.files.single.path!);
    //crop functionality\


      await setProfilePic(image);
    } else {
      // User canceled the picker
    }
  }*/

  void _imgFromGallery() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        File? image = File(result.files.single.path!);

        print('file image***$image');

        // Create an instance of ImageCropper
        ImageCropper imageCropper = ImageCropper();

        // Crop the selected image
        CroppedFile? croppedImage = await imageCropper
            .cropImage(sourcePath: image.path, aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ], uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ]);

        if (croppedImage != null) {
          File croppedFile = File(croppedImage.path);
          await setProfilePic(croppedFile);
        } else {
          // User canceled cropping
        }
      } else {
        // User canceled the picker
      }
    } catch (e) {
      setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
    }
  }

  Future<void> setProfilePic(File image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var request = http.MultipartRequest("POST", (getUpdateUserApi));
        request.headers.addAll(headers);
        request.fields[USER_ID] = context.read<UserProvider>().userId;
        final mimeType = lookupMimeType(image.path);

        var extension = mimeType!.split("/");

        var pic = await http.MultipartFile.fromPath(
          IMAGE,
          image.path,
          contentType: MediaType('image', extension[1]),
        );

        request.files.add(pic);

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);

        var getdata = json.decode(responseString);

        bool error = getdata["error"];
        String? msg = getdata['message'];

        if (!error) {
          var data = getdata["data"];
          var image;
          image = data[IMAGE];
          var settingProvider =
              Provider.of<SettingProvider>(context, listen: false);
          settingProvider.setPrefrence(IMAGE, image!);

          var userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setProfilePic(image!);
          setSnackbar(getTranslated(context, 'PROFILE_UPDATE_MSG')!, context);
        } else {
          setSnackbar(msg!, context);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Widget setNameField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              controller: nameController,
              decoration: InputDecoration(
                  label: Text(getTranslated(context, "NAME_LBL")!),
                  fillColor: Theme.of(context).colorScheme.white,
                  border: InputBorder.none),
              validator: (val) => validateUserName(
                  val!,
                  getTranslated(context, 'USER_REQUIRED'),
                  getTranslated(context, 'USER_LENGTH')),
            ),
          ),
        ),
      );

  Widget setEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            readOnly: (context.read<UserProvider>().loginType != GOOGLE_TYPE)
                ? false
                : true,
            //initialValue: emailController.text,
            controller: emailController,
            decoration: InputDecoration(
                label: Text(getTranslated(context, "EMAILHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            validator: (val) => validateEmail(
                val!,
                getTranslated(context, 'EMAIL_REQUIRED'),
                getTranslated(context, 'VALID_EMAIL')),
          ),
        ),
      ),
    );
  }

  /* Widget setMobileField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              readOnly: context.read<UserProvider>().loginType != PHONE_TYPE
                  ? false
                  : true,
              controller: mobileController,
              onChanged: (value) {
                mobileController.text = value; // Update the controller's value
              },
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              // initialValue: mobileController.text,

              decoration: InputDecoration(
                  label: Text(getTranslated(context, "MOBILEHINT_LBL")!),
                  fillColor: Theme.of(context).colorScheme.white,
                  border: InputBorder.none),
              validator: (val) => validateMob(
                  val!,
                  getTranslated(context, 'MOB_REQUIRED'),
                  getTranslated(context, 'VALID_MOB'),
                  check: false),
            ),
          ),
        ),
      ); */

  Widget setMobileField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              readOnly: context.read<UserProvider>().loginType != PHONE_TYPE
                  ? false
                  : true,
              controller: mobileController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              decoration: InputDecoration(
                labelText: getTranslated(context, "MOBILEHINT_LBL")!,
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,
              ),
              validator: (val) => validateMob(
                val!,
                getTranslated(context, 'MOB_REQUIRED'),
                getTranslated(context, 'VALID_MOB'),
                check: false,
              ),
            ),
          ),
        ),
      );

  Widget saveButton(String title, VoidCallback? onBtnSelected) {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 8.0, end: 8.0, top: 15.0),
        child: AppBtn(
            title: title,
            btnAnim: buttonSqueezeanimation1,
            btnCntrl: buttonController1,
            onBtnSelected:
                onBtnSelected) /*SimBtn(
          onBtnSelected: onBtnSelected,
          title: title,
          height: 45.0,
          width: deviceWidth,
        )*/
        );
  }

  Future<bool> validateAndSave(GlobalKey<FormState> key) async {
    final form = key.currentState!;
    form.save();
    if (form.validate()) {
      _playAnimation(buttonController1!);
      context.read<UserProvider>().setProgress(true);
      if (key == _changePwdKey) {
        await setUpdateUser(context.read<UserProvider>().userId,
            passwordController.text, newpassController.text, "", "", "");
        passwordController.clear();
        newpassController.clear();
        passwordController.clear();
        confirmpassController.clear();
      } else if (key == _changeUserDetailsKey) {
        print("change details***${mobileController.text}");
        setUpdateUser(context.read<UserProvider>().userId, "", "",
            nameController.text, emailController.text, mobileController.text);
      }
      return true;
    }
    return false;
  }

  void openChangePasswordBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child:
                      Consumer<UserProvider>(builder: (context, provider, _) {
                    return Form(
                      key: _changePwdKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          bottomSheetHandle(context),
                          bottomsheetLabel("CHANGE_PASS_LBL", context),
                          setCurrentPasswordField(),
                          setForgotPwdLable(),
                          newPwdField(),
                          confirmPwdField(),
                          saveButton(
                              getTranslated(context, "SAVE_LBL")!,
                              !provider.getProgress
                                  ? () {
                                      validateAndSave(_changePwdKey);
                                    }
                                  : () {}),
                        ],
                      ),
                    );
                  })),
            ],
          );
        });
  }

  void openChangeLanguageBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    bottomSheetHandle(context),
                    bottomsheetLabel("CHOOSE_LANGUAGE_LBL", context),
                    SingleChildScrollView(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: getLngList(context)),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  void openChangeThemeBottomSheet() {
    themeList = [
      getTranslated(context, 'SYSTEM_DEFAULT'),
      getTranslated(context, 'LIGHT_THEME'),
      getTranslated(context, 'DARK_THEME')
    ];

    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(context),
                      bottomsheetLabel("CHOOSE_THEME_LBL", context),
                      SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: themeListView(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget setCurrentPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: passwordController,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                errorMaxLines: 4,
                label: Text(getTranslated(context, "CUR_PASS_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            onSaved: (String? value) {
              currentPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PASSWORD_VALIDATION')),
          ),
        ),
      ),
    );
  }

  Widget setForgotPwdLable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          child: Text(getTranslated(context, "FORGOT_PASSWORD_LBL")!),
          onTap: () {
            // Navigator.of(context).push(CupertinoPageRoute(
            //     builder: (context) => SendOtp(
            //           title: ,
            //         )));
            //
            Navigator.pushNamed(context, Routers.sendOTPScreen, arguments: {
              "title": getTranslated(context, 'FORGOT_PASS_TITLE')
            });
          },
        ),
      ),
    );
  }

  Widget newPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: newpassController,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                errorMaxLines: 4,
                label: Text(getTranslated(context, "NEW_PASS_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            onSaved: (String? value) {
              newPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PASSWORD_VALIDATION')),
          ),
        ),
      ),
    );
  }

  Widget confirmPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: confirmpassController,
            focusNode: confirmPwdFocus,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                label: Text(getTranslated(context, "CONFIRMPASSHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            validator: (value) {
              if (value!.isEmpty) {
                return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
              }
              if (value != newPwd) {
                confirmpassController.text = "";
                confirmPwdFocus.requestFocus();
                return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
              } else {
                return null;
              }
            },
          ),
        ),
      ),
    );
  }
}
