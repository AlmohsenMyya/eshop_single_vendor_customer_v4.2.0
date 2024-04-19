import 'dart:async';
import 'dart:io';

import 'package:eshop/Helper/String.dart';
import 'package:eshop/ui/widgets/cropped_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/BehaviorWidget.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class SetPass extends StatefulWidget {
  final String mobileNumber;
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SetPass(
          mobileNumber: arguments?['mobileNumber'],
        );
      },
    );
  }

  const SetPass({
    Key? key,
    required this.mobileNumber,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<SetPass> with TickerProviderStateMixin {
  final confirmpassController = TextEditingController();
  final passwordController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? password, comfirmpass;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;

  ValueNotifier<bool> obsecurePassword = ValueNotifier(true);
  ValueNotifier<bool> obsecureConfirmPassword = ValueNotifier(true);

  AnimationController? buttonController;

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      getResetPass();
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

  Future<void> getResetPass() async {
    try {
      var data = {MOBILENO: widget.mobileNumber, NEWPASS: password};
      apiBaseHelper.postAPICall(getResetPassApi, data).then((getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        // await HiveUtils.setJWT(getdata['token']);
        await buttonController!.reverse();
        if (!error) {
          setSnackbar(getTranslated(context, 'PASS_SUCCESS_MSG')!, context);
          Future.delayed(const Duration(seconds: 1)).then((_) {
            // Navigator.of(context).pushReplacement(CupertinoPageRoute(
            //   builder: (BuildContext context) =>
            //       const LoginScreen(isPop: false),
            // ));
            Navigator.pushReplacementNamed(context, Routers.loginScreen,
                arguments: {"isPop": false});
          });
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted) setState(() {});
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      await buttonController!.reverse();
    }
  }

  subLogo() {
    return Expanded(
      child: Center(
        child: SvgPicture.asset(
          'assets/images/homelogo.svg',
          colorFilter: const ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
      ),
    );
  }

  forgotpassTxt() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            getTranslated(context, 'FORGOT_PASSWORDTITILE')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: colors.primary,
                fontSize: 30,
                fontWeight: FontWeight.bold),
          ),
        ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  setPass() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 30.0),
        child: ValueListenableBuilder<bool>(
            valueListenable: obsecurePassword,
            builder: (context, value, child) {
              return TextFormField(
                keyboardType: TextInputType.text,
                obscureText: value,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.normal),
                controller: passwordController,
                validator: (val) => validatePass(
                    val!,
                    getTranslated(context, 'PWD_REQUIRED'),
                    getTranslated(context, 'PASSWORD_VALIDATION')),
                onSaved: (String? value) {
                  password = value;
                },
                decoration: InputDecoration(
                  suffixIcon: InkWell(
                    onTap: () {
                      obsecurePassword.value = !obsecurePassword.value;
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10.0),
                      child: Icon(
                        !value ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.4),
                        size: 18,
                      ),
                    ),
                  ),
                  errorMaxLines: 4,
                  prefixIcon: SvgPicture.asset(
                    "assets/images/password.svg",
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.fontColor,
                        BlendMode.srcIn),
                  ),
                  hintText: getTranslated(context, 'PASSHINT_LBL'),
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal),
                  // filled: true,
                  // fillColor: Theme.of(context).colorScheme.lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 25),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 25),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: colors.primary),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.lightBlack2),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                ),
              );
            }));
  }

  setConfirmpss() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 20.0),
        child: ValueListenableBuilder(
            valueListenable: obsecureConfirmPassword,
            builder: (context, value, child) {
              return TextFormField(
                keyboardType: TextInputType.text,
                obscureText: value,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.normal),
                controller: confirmpassController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
                  }
                  if (value != password) {
                    return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
                  } else {
                    return null;
                  }
                },
                onSaved: (String? value) {
                  comfirmpass = value;
                },
                decoration: InputDecoration(
                  suffixIcon: InkWell(
                    onTap: () {
                      obsecureConfirmPassword.value =
                          !obsecureConfirmPassword.value;
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10.0),
                      child: Icon(
                        !value ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.4),
                        size: 18,
                      ),
                    ),
                  ),
                  prefixIcon: SvgPicture.asset(
                    "assets/images/password.svg",
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.fontColor,
                        BlendMode.srcIn),
                  ),
                  hintText: getTranslated(context, 'CONFIRMPASSHINT_LBL'),
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal),
                  // filled: true,
                  // fillColor: Theme.of(context).colorScheme.lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 25),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 25),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: colors.primary),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.lightBlack2),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              );
            }));
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

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  setPassBtn() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 20.0, bottom: 20.0),
        child: AppBtn(
          title: getTranslated(context, 'SET_PASSWORD'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            validateAndSubmit();
          },
        ));
  }

  expandedBottomView() {
    return Expanded(
        child: SingleChildScrollView(
      child: Form(
        key: _formkey,
        child: Card(
          elevation: 0.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsetsDirectional.only(
              start: 20.0, end: 20.0, top: 20.0),
          child: Column(
            children: [
              forgotpassTxt(),
              setPass(),
              setConfirmpss(),
              setPassBtn(),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  backBtn(),
                ],
              )
            : noInternet(context));
  }

  backBtn() {
    return Platform.isIOS
        ? Positioned(
            top: 34.0,
            left: 5.0,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: shadow(),
                    child: const Card(
                      elevation: 0,
                      child: Center(
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

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      // end: width * 0.025,
      // top: width * 0.45,
      top: MediaQuery.of(context).size.height * 0.2, //original
      //    bottom: height * 0.1,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.8),
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
                      forgotpassTxt(),
                      setPass(),
                      setConfirmpss(),
                      setPassBtn(),
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
}
