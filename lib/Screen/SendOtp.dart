import 'dart:async';
import 'dart:io';

import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Screen/Privacy_Policy.dart';
import 'package:eshop/ui/widgets/cropped_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/BehaviorWidget.dart';
import '../utils/Hive/hive_utils.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import 'Verify_Otp.dart';

class SendOtp extends StatefulWidget {
  String? title;
  static route(RouteSettings settings) {
    Map? arguments = settings?.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SendOtp(
          title: arguments?['title'],
        );
      },
    );
  }

  SendOtp({Key? key, this.title}) : super(key: key);

  @override
  _SendOtpState createState() => _SendOtpState();
}

class _SendOtpState extends State<SendOtp> with TickerProviderStateMixin {
  bool visible = false;
  final mobileController = TextEditingController();
  final ccodeController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? mobile, id, countrycode, countryName, mobileno;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool acceptTnC = false;

  void validateAndSubmit() async {
    if (validateAndSave()) {
      if (widget.title != getTranslated(context, 'SEND_OTP_TITLE')) {
        _playAnimation();
        checkNetwork();
      } else {
        if (acceptTnC) {
          _playAnimation();
          checkNetwork();
        } else {
          setSnackbar(getTranslated(context, 'TnCNOTACCEPTED')!, context);
        }
      }
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      getVerifyUser();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController!.reverse();
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      if (mobileController.text.trim().isEmpty) {
        setSnackbar(getTranslated(context, 'MOB_REQUIRED')!, context);
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: kToolbarHeight),
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

  Future<void> getVerifyUser() async {
    try {
      var data = {
        MOBILE: mobile,
        "is_forgot_password":
            (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')
                    ? 1
                    : 0)
                .toString()
      };

      apiBaseHelper.postAPICall(getVerifyUserApi, data).then((getdata) async {
        bool? error = getdata["error"];
        String? msg = getdata["message"];
        await buttonController!.reverse();

        print("RESPONSE  $error");
        SettingProvider settingsProvider =
            Provider.of<SettingProvider>(context, listen: false);

        if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
          if (!error!) {
            setSnackbar(msg!, context);

            Future.delayed(const Duration(seconds: 1)).then((_) {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => VerifyOtp(
                            mobileNumber: mobile!,
                            countryCode: countrycode,
                            title: getTranslated(context, 'SEND_OTP_TITLE'),
                          )));
            });
          } else {
            setSnackbar(msg!, context);
          }
        }
        if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
          if (!error!) {
            print("IS TRUE");
            Future.delayed(const Duration(seconds: 1)).then((_) {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => VerifyOtp(
                            mobileNumber: mobile!,
                            countryCode: countrycode,
                            title: getTranslated(context, 'FORGOT_PASS_TITLE'),
                          )));
            });
          } else {
            setSnackbar(getTranslated(context, 'FIRSTSIGNUP_MSG')!, context);
          }
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      await buttonController!.reverse();
    }

    return;
    // try {
    //   Map<String, dynamic> data = {
    //     "mobile": "6359676012",
    //     "is_forgot_password":
    //         (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')
    //                 ? 1
    //                 : 0)
    //             .toString()
    //   };
    //
    //   try {
    //     Dio dio = Dio();
    //     Response response = await dio.post(getVerifyUserApi.toString(), data: {
    //       "mobile": 6359676012,
    //       "is_forgot_password": 1,
    //     });
    //     print("RESP  ${response.data}");
    //     await buttonController!.reverse();
    //     SettingProvider settingsProvider =
    //         Provider.of<SettingProvider>(context, listen: false);
    //     String? msg = response.data["message"];
    //
    //     log("SMS SEND RESPONSE $msg");
    //     if (response.data['error']) {}
    //
    //     if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
    //       if (!response.data['error']!) {
    //         setSnackbar(msg!, context);
    //
    //         Future.delayed(const Duration(seconds: 1)).then((_) {
    //           Navigator.pushNamed(context, Routers.verifyOTPScreen, arguments: {
    //             "mobileNumber": mobile!,
    //             "countryCode": countrycode,
    //             "title": getTranslated(context, 'SEND_OTP_TITLE'),
    //           });
    //         });
    //       } else {
    //         setSnackbar(msg!, context);
    //       }
    //     }
    //     if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
    //       if (!response.data['error']!) {
    //         Future.delayed(const Duration(seconds: 1)).then((_) {
    //           Navigator.pushNamed(context, Routers.verifyOTPScreen, arguments: {
    //             "mobileNumber": mobile!,
    //             "countryCode": countrycode,
    //             "title": getTranslated(context, 'FORGOT_PASS_TITLE'),
    //           });
    //         });
    //       } else {
    //         setSnackbar(getTranslated(context, 'FIRSTSIGNUP_MSG')!, context);
    //       }
    //     }
    //   } catch (e) {
    //     setSnackbar(e.toString(), context);
    //   }
    //   return;
    //   // apiBaseHelper
    //   //     .postAPICall(getVerifyUserApi, data.cast<String, dynamic>())
    //   //     .then((getdata) async {
    //   //   bool? error = getdata["error"];
    //   //   String? msg = getdata["message"];
    //   //
    //   //   await buttonController!.reverse();
    //   //
    //   //   SettingProvider settingsProvider =
    //   //       Provider.of<SettingProvider>(context, listen: false);
    //   //
    //   //   if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
    //   //     if (!error!) {
    //   //       setSnackbar(msg!, context);
    //   //
    //   //       Future.delayed(const Duration(seconds: 1)).then((_) {
    //   //         Navigator.pushNamed(context, Routers.verifyOTPScreen, arguments: {
    //   //           "mobileNumber": mobile!,
    //   //           "countryCode": countrycode,
    //   //           "title": getTranslated(context, 'SEND_OTP_TITLE'),
    //   //         });
    //   //       });
    //   //     } else {
    //   //       setSnackbar(msg!, context);
    //   //     }
    //   //   }
    //   //   if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
    //   //     if (error!) {
    //   //       Future.delayed(const Duration(seconds: 1)).then((_) {
    //   //         Navigator.pushNamed(context, Routers.verifyOTPScreen, arguments: {
    //   //           "mobileNumber": mobile!,
    //   //           "countryCode": countrycode,
    //   //           "title": getTranslated(context, 'FORGOT_PASS_TITLE'),
    //   //         });
    //   //       });
    //   //     } else {
    //   //       setSnackbar(getTranslated(context, 'FIRSTSIGNUP_MSG')!, context);
    //   //     }
    //   //   }
    //   // }, onError: (error, st) {
    //   //   print("ERRROR IN ERROR $st");
    //   //   setSnackbar(error.toString(), context);
    //   // });
    // } on TimeoutException catch (_) {
    //   setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    //   await buttonController!.reverse();
    // }
  }

  createAccTxt() {
    return Padding(
        padding: const EdgeInsets.only(
          top: 30.0,
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            widget.title == getTranslated(context, 'SEND_OTP_TITLE')
                ? getTranslated(context, 'CREATE_ACC_LBL')!
                : getTranslated(context, 'FORGOT_PASSWORDTITILE')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold),
          ),
        ));
  }

  Widget verifyCodeTxt() {
    return Padding(
        padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            getTranslated(context, 'SEND_VERIFY_CODE_LBL')!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal,
                ),
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 1,
          ),
        ));
  }

/*  Widget setCodeWithMono() {
    return SizedBox(
        width: deviceWidth! * 0.9,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: setCountryCode(),
            ),
            Expanded(
              flex: 4,
              child: setMono(),
            )
          ],
        ));
  }*/

  setCodeWithMono() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
      child: IntlPhoneField(
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        controller: mobileController,
        decoration: InputDecoration(
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          hintText: getTranslated(context, 'MOBILEHINT_LBL'),
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(10)),
          fillColor: Theme.of(context).colorScheme.lightWhite,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        ),
        initialCountryCode: defaultCountryCode,
        onSaved: (phoneNumber) {
          setState(() {
            countrycode =
                phoneNumber!.countryCode.toString().replaceFirst('+', '');
            mobile = phoneNumber.number;
          });
        },
        onCountryChanged: (country) {
          setState(() {
            countrycode = country.dialCode;
          });
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autofocus: true,
        disableLengthCheck: false,
        validator: (val) => validateMobIntl(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB')),
        onChanged: (phone) {},
        showDropdownIcon: false,
        //invalidNumberMessage: getTranslated(context, 'VALID_MOB'),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        flagsButtonMargin: const EdgeInsets.only(left: 20, right: 20),
        pickerDialogStyle: PickerDialogStyle(
          countryNameStyle:
              TextStyle(color: Theme.of(context).colorScheme.fontColor),
          padding: const EdgeInsets.only(left: 10, right: 10),
        ),
      ),
    );
  }

/*  Widget setCountryCode() {
    double width = deviceWidth!;
    double height = deviceHeight! * 0.9;
    return CountryCodePicker(
        searchStyle: TextStyle(color: Theme.of(context).colorScheme.fontColor),
        showCountryOnly: false,
        flagWidth: 20,
        boxDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.lightWhite,
        ),
        searchDecoration: InputDecoration(
          hintText: getTranslated(context, 'COUNTRY_CODE_LBL'),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.fontColor),
          fillColor: Theme.of(context).colorScheme.fontColor,
        ),
        showOnlyCountryWhenClosed: false,
        initialSelection: 'IN',
        dialogSize: Size(width, height),
        alignLeft: true,
        textStyle: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.bold),
        onChanged: (CountryCode countryCode) {
          countrycode = countryCode.toString().replaceFirst("+", "");
          countryName = countryCode.name;
        },
        onInit: (code) {
          countrycode = code.toString().replaceFirst("+", "");
        });

  }*/

  Widget setMono() {
    return TextFormField(
        keyboardType: TextInputType.number,
        controller: mobileController,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB')),
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'MOBILEHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          focusedBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ));
  }

  Widget verifyBtn() {
    return AppBtn(
        title: widget.title == getTranslated(context, 'SEND_OTP_TITLE')
            ? getTranslated(context, 'SEND_OTP')
            : getTranslated(context, 'CONTINUE'),
        btnAnim: buttonSqueezeanimation,
        btnCntrl: buttonController,
        onBtnSelected: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          validateAndSubmit();
        });
  }

  Widget termAndPolicyTxt() {
    return widget.title == getTranslated(context, 'SEND_OTP_TITLE')
        ? Padding(
            padding: const EdgeInsets.only(
                bottom: 0.0, left: 25.0, right: 25.0, top: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                        activeColor: colors.primary,
                        value: acceptTnC,
                        onChanged: (newValue) {
                          setState(() => acceptTnC = newValue!);
                        }),
                    Text(getTranslated(context, 'CONTINUE_AGREE_LBL')!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => PrivacyPolicy(
                                      title: getTranslated(context, 'TERM'),
                                    )));
                      },
                      child: Text(
                        getTranslated(context, 'TERMS_SERVICE_LBL')!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.normal),
                      )),
                  const SizedBox(
                    width: 5.0,
                  ),
                  Text(getTranslated(context, 'AND_LBL')!,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.normal)),
                  const SizedBox(
                    width: 5.0,
                  ),
                  InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => PrivacyPolicy(
                                      title: getTranslated(context, 'PRIVACY'),
                                    )));
                      },
                      child: Text(
                        getTranslated(context, 'PRIVACY')!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.normal),
                      )),
                ]),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  backBtn() {
    return Platform.isIOS
        ? Positioned(
            top: 34.0,
            left: 5.0,
            child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: shadow(),
                  child: Card(
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Icon(
                          Icons.keyboard_arrow_left,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                )),
          )
        : const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    print("JWT IS:" + HiveUtils.getJWT().toString());
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
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
                ],
              )
            : noInternet(context));
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      top: MediaQuery.of(context).size.height * 0.2,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.6),
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
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.title ==
                                    getTranslated(context, 'SEND_OTP_TITLE')
                                ? getTranslated(context, 'SIGN_UP_LBL')!
                                : getTranslated(
                                    context, 'FORGOT_PASSWORDTITILE')!,
                            style: const TextStyle(
                              color: colors.primary,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      verifyCodeTxt(),
                      setCodeWithMono(),
                      termAndPolicyTxt(),
                      verifyBtn(),
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
    );
  }

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
