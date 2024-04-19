import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Helper/SqliteData.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Provider/FavoriteProvider.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Dashboard.dart';
import 'package:eshop/app/routes.dart';
import 'package:eshop/ui/widgets/cropped_container.dart';
import 'package:eshop/utils/Hive/hive_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../Helper/Color.dart';
import '../Helper/PushNotificationService.dart';
import '../Helper/Session.dart';
import '../Model/Section_Model.dart';
import '../Provider/CartProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/ApiException.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/BehaviorWidget.dart';
import '../ui/widgets/Slideanimation.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import 'Privacy_Policy.dart';

class LoginScreen extends StatefulWidget {
  final Widget? classType;
  final bool isPop;
  final bool? isRefresh;
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return LoginScreen(
          isPop: arguments?['isPop'],
          isRefresh: arguments?['isRefresh'],
          classType: arguments?['classType'],
        );
      },
    );
  }

  const LoginScreen({
    Key? key,
    this.classType,
    this.isRefresh,
    required this.isPop,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> with TickerProviderStateMixin {
  final mobileController =
      TextEditingController(text: isDemoApp ? "9876543210" : "");
  final passwordController =
      TextEditingController(text: isDemoApp ? "12345678" : "");
  String? countryName;
  FocusNode? passFocus, monoFocus = FocusNode();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool visible = false;
  String? password,
      mobile,
      username,
      email,
      id,
      mobileno,
      city,
      area,
      pincode,
      address,
      latitude,
      longitude,
      image,
      loginType;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;

  AnimationController? buttonController;
  AnimationController? _animationController;
  var db = DatabaseHelper();
  bool acceptTnC = true;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool socialLoginLoading = false;
  bool? googleLogin, appleLogin;
  bool isShowPass = true;

  @override
  void initState() {
    super.initState();
    getSetting();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
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
  }

  @override
  void dispose() {
    _animationController!.dispose();
    buttonController!.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void getSetting() {
    try {
      apiBaseHelper.postAPICall(getSettingApi, {}).then((getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"]["system_settings"][0];

          print("data****${getdata["data"]["system_settings"][0].toString()}");
          setState(() {
            googleLogin = data[GOOGLE_LOGIN] == 1 ? true : false;
            appleLogin = data[APPLE_LOGIN] == 1 ? true : false;
          });
        } else {
          setSnackbar(msg!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  void onTapSignIn() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      signInProcess();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        await buttonController!.reverse();
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(top: kToolbarHeight),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation();

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

  Future<void> signInProcess() async {
    var data = {MOBILE: mobile, PASSWORD: password};
    print("PARAMS ARE $data");
    apiBaseHelper.postAPICall(getUserLoginApi, data).then((getdata) async {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      print("PARAMS ARE ${getdata['token']}");
      await buttonController!.reverse();
      if (!error) {
        await HiveUtils.setJWT(getdata['token']);

        setSnackbar(msg!, context);

        var i = getdata["data"][0];
        id = i[ID];
        username = i[USERNAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        city = i[CITY];
        area = i[AREA];
        address = i[ADDRESS];
        pincode = i[pinCodeOrCityNameKey];
        latitude = i[LATITUDE];
        longitude = i[LONGITUDE];
        image = i[IMAGE];
        loginType = i[TYPE];

        //CUR_USERID = id;

        SettingProvider settingProvider =
            Provider.of<SettingProvider>(context, listen: false);
        settingProvider.setPrefrenceBool(ISFIRSTTIME, true);

        settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
            address, pincode, latitude, longitude, image, loginType, context);

        Future.delayed(Duration.zero, () {
          PushNotificationService(context: context).setDeviceToken(
              clearSesssionToken: true, settingProvider: settingProvider);
        });
        offFavAdd().then((value) {
          db.clearFav();
          context.read<FavoriteProvider>().setFavlist([]);
          offCartAdd().then((value) {
            db.clearCart();
            offSaveAdd().then((value) {
              db.clearSaveForLater();
              if (widget.isPop) {
                if (widget.isRefresh != null) {
                  Navigator.pop(context, 'refresh');
                } else {
                  _getFav(context).whenComplete(() {
                    _getCart("0", context).whenComplete(() {
                      Future.delayed(const Duration(seconds: 2))
                          .whenComplete(() {
                        Navigator.of(context).pop();
                      });
                    });
                  });
                }
              } else {
                Navigator.pushAndRemoveUntil(context,
                    BlurredRouter(builder: (BuildContext context) {
                  Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();
                  return widget.classType ??
                      Dashboard(
                        key: Dashboard.dashboardScreenKey,
                      );
                }), (route) => false);
              }
            });
          });
        });
      } else {
        setSnackbar(msg!, context);
      }
    }, onError: (error) {
      setSnackbar(error.toString(), context);
    });
  }

  Future _getFav(BuildContext context) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          Map parameter = {
            USER_ID: context.read<UserProvider>().userId,
          };

          apiBaseHelper.postAPICall(getFavApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<FavoriteProvider>().setFavlist(tempList);
              });
            } else {
              if (msg != 'No Favourite(s) Product Are Added') {
                setSnackbar(msg!, context);
              }
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<FavoriteProvider>().setLoading(false);
            });
          }, onError: (error) {
            setSnackbar(error.toString(), context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<FavoriteProvider>().setLoading(false);
            });
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<FavoriteProvider>().setLoading(false);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> _getCart(String save, BuildContext context) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          try {
            var parameter = {
              USER_ID: context.read<UserProvider>().userId,
              SAVE_LATER: save,
              "only_delivery_charge": "0",
            };
            apiBaseHelper.postAPICall(getCartApi, parameter).then((getdata) {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              if (!error) {
                var data = getdata["data"];

                List<SectionModel> cartList = (data as List)
                    .map((data) => SectionModel.fromCart(data))
                    .toList();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print("inner widget:${cartList.length}");
                  context
                      .read<UserProvider>()
                      .setCartCount(cartList.length.toString());
                  print(
                      "cart count login****${context.read<UserProvider>().cartCount}");
                  context.read<CartProvider>().setCartlist(cartList);
                });
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          } on TimeoutException catch (_) {}
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  /*  void setToken() async {
    FirebaseMessaging.instance.getToken().then(
      (token) async {
        SettingProvider settingsProvider =
            Provider.of<SettingProvider>(context, listen: false);

        // String getToken = await settingsProvider.getPrefrence(FCMTOKEN) ?? '';
        print("fcm token****$token");
        if (token != null) {
          print("register token***$token");
          registerToken(token);
        }
      },
    );
  }

  void registerToken(String? token) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    var parameter = {
      FCM_ID: token,
    };
    if (settingsProvider.userId != null) {
      parameter[USER_ID] = settingsProvider.userId;
    }

    Response response =
        await post(updateFcmApi, body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

    var getdata = json.decode(response.body);

    print("param noti fcm***$parameter");

    print("value notification****$getdata");

    if (getdata['error'] == false) {
      print("fcm token****$token");
      settingsProvider.setPrefrence(FCMTOKEN, token!);
    }
  } */

  Future<void> offFavAdd() async {
    List favOffList = await db.getOffFav();

    if (favOffList.isNotEmpty) {
      for (int i = 0; i < favOffList.length; i++) {
        _setFav(favOffList[i]["PID"]);
      }
    }
  }

  _setFav(String pid) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PRODUCT_ID: pid
        };
        apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
          } else {
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
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

  Future<void> offCartAdd() async {
    List cartOffList = await db.getOffCart();

    if (cartOffList.isNotEmpty) {
      for (int i = 0; i < cartOffList.length; i++) {
        addToCartCheckout(cartOffList[i]["VID"], cartOffList[i]["QTY"]);
      }
    }
  }

  Future<void> addToCartCheckout(String varId, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          PRODUCT_VARIENT_ID: varId,
          USER_ID: context.read<UserProvider>().userId,
          QTY: qty,
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
          } else {}
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) _isNetworkAvail = false;

      setState(() {});
    }
  }

  Future<void> offSaveAdd() async {
    List saveOffList = await db.getOffSaveLater();

    if (saveOffList.isNotEmpty) {
      for (int i = 0; i < saveOffList.length; i++) {
        saveForLater(saveOffList[i]["VID"], saveOffList[i]["QTY"]);
      }
    }
  }

  saveForLater(String vid, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          PRODUCT_VARIENT_ID: vid,
          USER_ID: context.read<UserProvider>().userId,
          QTY: qty,
          SAVE_LATER: "1"
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
          } else {
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
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

  signInTxt() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(
          top: 30.0,
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            getTranslated(context, 'SIGNIN_LBL')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold),
          ),
        ));
  }

  setMobileNo() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.only(
        top: 15.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.number,
        controller: mobileController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB')),
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.phone_android,
            color: Theme.of(context).colorScheme.fontColor,
            size: 20,
          ),
          hintText: getTranslated(context, 'MOBILEHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );
  }

  setPass() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.only(
        top: 12.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.text,
        obscureText: isShowPass,
        controller: passwordController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        focusNode: passFocus,
        textInputAction: TextInputAction.next,
        validator: (val) => validatePass(
            val!,
            getTranslated(context, 'PWD_REQUIRED'),
            getTranslated(context, 'PASSWORD_VALIDATION'),
            from: 1),
        onSaved: (String? value) {
          password = value;
        },
        decoration: InputDecoration(
          errorMaxLines: 2,
          prefixIcon: SvgPicture.asset(
            "assets/images/password.svg",
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.fontColor, BlendMode.srcIn),
          ),
          suffixIcon: InkWell(
            onTap: () {
              setState(
                () {
                  isShowPass = !isShowPass;
                },
              );
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 10.0),
              child: Icon(
                !isShowPass ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.fontColor.withOpacity(0.4),
                size: 22,
              ),
            ),
          ),
          hintText: getTranslated(context, "PASSHINT_LBL")!,
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          focusedBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );
  }

  forgetPass() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 13.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routers.sendOTPScreen,
                  arguments: {
                    "title": getTranslated(context, 'FORGOT_PASS_TITLE')
                  },
                );
              },
              child: Text(getTranslated(context, 'FORGOT_PASSWORD_LBL')!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal)),
            ),
          ],
        ));
  }

  getSignUpText() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 20.0, start: 25.0, end: 25.0, top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(getTranslated(context, 'DONT_HAVE_AN_ACC')!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
          InkWell(
              onTap: () {
                // Navigator.of(context).push(CupertinoPageRoute(
                //   builder: (BuildContext context) => SendOtp(
                //     title: getTranslated(context, 'SEND_OTP_TITLE'),
                //   ),
                // ));

                Navigator.pushNamed(context, Routers.sendOTPScreen, arguments: {
                  "title": getTranslated(context, 'SEND_OTP_TITLE')
                });
              },
              child: Text(
                getTranslated(context, 'SIGN_UP_LBL')!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal),
              ))
        ],
      ),
    );
  }

  loginBtn() {
    return AppBtn(
      title: getTranslated(context, 'SIGNIN_LBL'),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        onTapSignIn();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: _isNetworkAvail
            ? Stack(
                children: [
                  Image.asset(
                    'assets/images/doodle.png',
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    color: colors.primary,
                  ),
                  getLoginContainer(),
                  getLogo(),
                  if (socialLoginLoading)
                    Positioned.fill(
                      child: Center(
                          child: showCircularProgress(
                              socialLoginLoading, colors.primary)),
                    ),
                  // backBtn(),
                ],
              )
            : noInternet(context));
  }

  // backBtn() {
  //   return Platform.isIOS
  //       ? Positioned(
  //           top: 34.0,
  //           left: 5.0,
  //           child: Material(
  //               color: Colors.transparent,
  //               child: InkWell(
  //                 onTap: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: Container(
  //                   margin: const EdgeInsets.all(10),
  //                   decoration: shadow(),
  //                   child: const Card(
  //                     elevation: 0,
  //                     child: Center(
  //                       child: Icon(
  //                         Icons.keyboard_arrow_left,
  //                         color: colors.primary,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               )),
  //         )
  //       : const SizedBox.shrink();
  // }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      top: MediaQuery.of(context).size.height * 0.2,
      textDirection: Directionality.of(context),
      child: SlideAnimation(
        position: 1,
        itemCount: 7,
        slideDirection: SlideDirection.fromBottom,
        animationController: _animationController,
        child: ClipPath(
          clipper: ContainerClipper(),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom * 0),
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.95,
            color: Theme.of(context).colorScheme.white,
            child: Form(
              key: _formkey,
              child: ScrollConfiguration(
                behavior: MyBehavior(),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.06,
                        ),
                        setSignInLabel(),
                        setMobileNo(),
                        setPass(),
                        forgetPass(),
                        loginBtn(),
                        orDivider(),
                        socialLoginBtn(),
                        SizedBox(
                          height: 5,
                        ),
                        termAndPolicyTxt(),
                        getSignUpText(),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget orDivider() {
    if (googleLogin == true || (Platform.isIOS ? appleLogin == true : false)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Flexible(
              child: Divider(
                indent: 30,
                endIndent: 15,
                color: Theme.of(context).colorScheme.fontColor.withOpacity(0.6),
              ),
            ),
            Text(
              getTranslated(context, 'OR_LOGIN_WITH_LBL')!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color:
                      Theme.of(context).colorScheme.fontColor.withOpacity(0.8)),
            ),
            Flexible(
                child: Divider(
              indent: 15,
              endIndent: 30,
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.6),
            )),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget termAndPolicyTxt() {
    if (googleLogin == true || (Platform.isIOS ? appleLogin == true : false)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 0.0, left: 25.0, right: 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: getTranslated(context, 'CONTINUE_AGREE_LBL')!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText2!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                        WidgetSpan(
                          child: SizedBox(width: 5.0),
                        ),
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) {
                                    return PrivacyPolicy(
                                      title: getTranslated(context, 'TERM'),
                                    );
                                  },
                                ),
                              );
                            },
                            child: Text(
                              getTranslated(context, 'TERMS_SERVICE_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ),
                        ),
                        WidgetSpan(
                          child: SizedBox(width: 5.0),
                        ),
                        TextSpan(
                          text: getTranslated(context, 'AND_LBL')!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText2!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                        WidgetSpan(
                          child: SizedBox(width: 5.0),
                        ),
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => PrivacyPolicy(
                                    title: getTranslated(context, 'PRIVACY'),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              getTranslated(context, 'PRIVACY')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Checkbox(
            //         activeColor: colors.primary,
            //         value: acceptTnC,
            //         onChanged: (newValue) {
            //           setState(() => acceptTnC = newValue!);
            //         }),
            //     Text(getTranslated(context, 'CONTINUE_AGREE_LBL')!,
            //         style: Theme.of(context).textTheme.bodySmall!.copyWith(
            //             color: Theme.of(context).colorScheme.fontColor,
            //             fontWeight: FontWeight.normal)),
            //   ],
            // ),
            // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            //   InkWell(
            //     onTap: () {
            //       Navigator.push(
            //         context,
            //         CupertinoPageRoute(
            //           builder: (context) {
            //             return PrivacyPolicy(
            //               title: getTranslated(context, 'TERM'),
            //             );
            //           },
            //         ),
            //       );
            //     },
            //     child: Text(
            //       getTranslated(context, 'TERMS_SERVICE_LBL')!,
            //       style: Theme.of(context).textTheme.bodySmall!.copyWith(
            //           color: Theme.of(context).colorScheme.fontColor,
            //           decoration: TextDecoration.underline,
            //           fontWeight: FontWeight.normal),
            //     ),
            //   ),
            //   const SizedBox(
            //     width: 5.0,
            //   ),
            //   Text(getTranslated(context, 'AND_LBL')!,
            //       style: Theme.of(context).textTheme.bodySmall!.copyWith(
            //           color: Theme.of(context).colorScheme.fontColor,
            //           fontWeight: FontWeight.normal)),
            //   const SizedBox(
            //     width: 5.0,
            //   ),
            //   InkWell(
            //       onTap: () {
            //         Navigator.push(
            //             context,
            //             CupertinoPageRoute(
            //                 builder: (context) => PrivacyPolicy(
            //                       title: getTranslated(context, 'PRIVACY'),
            //                     )));
            //       },
            //       child: Text(
            //         getTranslated(context, 'PRIVACY')!,
            //         style: Theme.of(context).textTheme.bodySmall!.copyWith(
            //             color: Theme.of(context).colorScheme.fontColor,
            //             decoration: TextDecoration.underline,
            //             fontWeight: FontWeight.normal),
            //       )),
            // ]),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<dynamic> loginAuth(
      {required String firebaseId,
      required String name,
      required String email,
      required String type,
      required String mobile}) async {
    try {
      final body = {
        NAME: name,
        TYPE: type,
      };

      if (mobile != "") {
        body[MOBILE] = mobile;
      }

      if (email != "") {
        body[EMAIL] = email;
      }
      if (firebaseId != "") {
        body[FCM_ID] = firebaseId;
      }
      print("login param****$body");
      var getData = apiBaseHelper.postAPICall(signUpUserApi, body);
      print("getdata******$getData");
      return getData;
    } catch (e) {
      print("auth error");
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<Map<String, dynamic>> onTapSocialLogin({
    required String type,
  }) async {
    try {
      final result = await socialSignInUser(type: type);
      final user = result['user'] as User;

      Map<String, dynamic> userDataTest = await loginAuth(
          mobile: user.providerData[0].phoneNumber ?? "",
          email: user.providerData[0].email ?? "",
          firebaseId: user.providerData[0].uid ?? "",
          name: user.providerData[0].displayName ??
              (type == APPLE_TYPE ? "Apple User" : ""),
          type: type);
      bool error = userDataTest["error"];
      String? msg = userDataTest["message"];
      print(":TOKENM ISS ${userDataTest}");
      await HiveUtils.setJWT(userDataTest['token']);
      setState(() {
        socialLoginLoading = false;
      });
      if (!error) {
        setSnackbar(msg!, context);

        var i = userDataTest["data"];
        id = i[ID];
        username = i[USERNAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        city = i[CITY];
        area = i[AREA];
        address = i[ADDRESS];
        pincode = i[pinCodeOrCityNameKey];
        latitude = i[LATITUDE];
        longitude = i[LONGITUDE];
        image = i[IMAGE];
        loginType = i[TYPE];

        SettingProvider settingProvider =
            Provider.of<SettingProvider>(context, listen: false);

        settingProvider.setPrefrenceBool(ISFIRSTTIME, true);

        settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
            address, pincode, latitude, longitude, image, loginType, context);
        Future.delayed(Duration.zero, () {
          PushNotificationService(context: context).setDeviceToken(
              clearSesssionToken: true, settingProvider: settingProvider);
        });
        /* setToken(); */
        offFavAdd().then((value) {
          db.clearFav();
          context.read<FavoriteProvider>().setFavlist([]);
          offCartAdd().then((value) {
            db.clearCart();
            offSaveAdd().then((value) {
              db.clearSaveForLater();
              if (widget.isPop) {
                if (widget.isRefresh != null) {
                  Navigator.pop(context, 'refresh');
                } else {
                  _getFav(context).whenComplete(() {
                    _getCart("0", context).whenComplete(() {
                      Future.delayed(const Duration(seconds: 2))
                          .whenComplete(() {
                        Navigator.of(context).pop();
                      });
                    });
                  });
                }
              } else {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();
                  return widget.classType ??
                      Dashboard(
                        key: Dashboard.dashboardScreenKey,
                      );
                }), (route) => false);
              }
            });
          });
        });
      } else {
        setSnackbar(msg!, context);
      }

      return userDataTest;
    } catch (e) {
      setState(() {
        socialLoginLoading = false;
      });
      print("login error*****${e.toString()}");
      signOut(type);
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<void> signOut(String type) async {
    _firebaseAuth.signOut();
    if (type == GOOGLE_TYPE) {
      _googleSignIn.signOut();
    } else {
      _firebaseAuth.signOut();
    }
  }

  Future<Map<String, dynamic>> socialSignInUser({required String type}) async {
    Map<String, dynamic> result = {};
    try {
      print("Calling google signin ${type}");

      if (type == GOOGLE_TYPE) {
        UserCredential? userCredential = await signInWithGoogle(context);
        print("Calling google signin ${userCredential}");

        if (userCredential != null) {
          result['user'] = userCredential.user!;
        } else {
          throw ApiMessageAndCodeException(
              errorMessage: getTranslated(context, 'somethingMSg')!);
        }
      } else if (type == APPLE_TYPE) {
        UserCredential? userCredential = await signInWithApple(context);
        if (userCredential != null) {
          result['user'] = userCredential.user!;
        } else {
          throw ApiMessageAndCodeException(
              errorMessage: getTranslated(context, 'somethingMSg')!);
        }
      }
      print("user result***$result");
      return result;
    } on SocketException catch (_) {
      throw ApiMessageAndCodeException(
          errorMessage: getTranslated(context, 'somethingMSg')!);
    } on FirebaseAuthException catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    } on PlatformException catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);

      return null;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    return userCredential;
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential?> signInWithApple(BuildContext context) async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      print('**********apple id:******$authResult');

      return authResult;
    } on FirebaseAuthException catch (authError) {
      print('**********errror id:******$authError');
      setSnackbar(authError.message!, context);

      return null;
    } on FirebaseException catch (e) {
      setSnackbar(e.toString(), context);

      return null;
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage == "Null check operator used on a null value") {
        //if user goes back from selecting Account
        //in case of User gmail not selected & back to Login screen
        setSnackbar(getTranslated(context, 'CANCEL_USER_MSG')!, context);

        return null;
      } else {
        setSnackbar(errorMessage, context);

        return null;
      }
    }
  }

  Widget socialLoginBtn() {
    ///DEBUG
    return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 15),
        child: Column(
          children: [
            if (googleLogin == true)
              InkWell(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  width: deviceWidth! * 0.7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: colors
                            .primary), /* color: Theme.of(context).colorScheme.lightWhite*/
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/google_button.svg',
                        height: 22,
                        width: 22,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15),
                        child: Text(
                            getTranslated(context, 'CONTINUE_WITH_GOOGLE')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.normal)),
                      )
                    ],
                  ),
                ),
                onTap: () async {
                  if (acceptTnC) {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      setState(() {
                        socialLoginLoading = true;
                      });
                      onTapSocialLogin(type: GOOGLE_TYPE);
                    } else {
                      Future.delayed(const Duration(seconds: 2))
                          .then((_) async {
                        await buttonController!.reverse();
                        if (mounted) {
                          setState(() {
                            _isNetworkAvail = false;
                          });
                        }
                      });
                    }
                  } else {
                    setSnackbar(
                        getTranslated(context, 'agreeTCFirst')!, context);
                  }
                },
              ),
            if (appleLogin == true)
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      width: deviceWidth! * 0.7,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.primary)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/apple_logo.svg',
                            height: 22,
                            width: 22,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Text(
                                getTranslated(context, 'CONTINUE_WITH_APPLE')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal)),
                          )
                        ],
                      ),
                    ),
                    onTap: () async {
                      if (acceptTnC) {
                        _isNetworkAvail = await isNetworkAvailable();
                        if (_isNetworkAvail) {
                          setState(() {
                            socialLoginLoading = true;
                          });
                          onTapSocialLogin(type: APPLE_TYPE);
                        } else {
                          Future.delayed(const Duration(seconds: 2))
                              .then((_) async {
                            await buttonController!.reverse();
                            if (mounted) {
                              setState(() {
                                _isNetworkAvail = false;
                              });
                            }
                          });
                        }
                      } else {
                        setSnackbar(
                            getTranslated(context, 'agreeTCFirst')!, context);
                      }
                    },
                  ),
                )
          ],
        ));
  }
  /* Widget socialLoginBtn() {
    if (socialLogin == true) {
      return Padding(
        padding: const EdgeInsets.only(top: 40, bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              child: Container(
                height: 57,
                width: 57,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).colorScheme.lightWhite),
                padding: EdgeInsets.all(15),
                child: SvgPicture.asset(
                  'assets/images/google_button.svg',
                  height: 30,
                  width: 30,
                ),
              ),
              onTap: () async {
                if (acceptTnC) {
                  _isNetworkAvail = await isNetworkAvailable();
                  if (_isNetworkAvail) {
                    setState(() {
                      socialLoginLoading = true;
                    });
                    signInUser(type: GOOGLE_TYPE);
                  } else {
                    Future.delayed(const Duration(seconds: 2)).then((_) async {
                      await buttonController!.reverse();
                      if (mounted) {
                        setState(() {
                          _isNetworkAvail = false;
                        });
                      }
                    });
                  }
                } else {
                  setSnackbar(getTranslated(context, 'agreeTCFirst')!, context);
                }
              },
            ),
            if (Platform.isIOS)
              InkWell(
                child: Container(
                  height: 57,
                  width: 57,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).colorScheme.lightWhite),
                  padding: EdgeInsets.all(15),
                  child: SvgPicture.asset(
                    'assets/images/apple_logo.svg',
                    height: 30,
                    width: 30,
                  ),
                ),
                onTap: () async {
                  if (acceptTnC) {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      setState(() {
                        socialLoginLoading = true;
                      });
                      signInUser(type: APPLE_TYPE);
                    } else {
                      Future.delayed(const Duration(seconds: 2))
                          .then((_) async {
                        await buttonController!.reverse();
                        if (mounted) {
                          setState(() {
                            _isNetworkAvail = false;
                          });
                        }
                      });
                    }
                  } else {
                    setSnackbar(
                        getTranslated(context, 'agreeTCFirst')!, context);
                  }
                },
              ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }*/

  Widget getLogo() {
    return Positioned(
      left: (MediaQuery.of(context).size.width / 2) - 50,
      top: (MediaQuery.of(context).size.height * 0.2) - 50,
      child: SizedBox(
        width: 100,
        height: 100,
        child: SvgPicture.asset(getThemeColor(context)),
      ),
    );
  }

  Widget setSignInLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          getTranslated(context, 'SIGNIN_LBL')!,
          style: const TextStyle(
            color: colors.primary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
