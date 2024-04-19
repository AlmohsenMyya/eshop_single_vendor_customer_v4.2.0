import 'dart:async';

import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/Faqs_Model.dart';
import 'package:eshop/ui/widgets/SimBtn.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/User.dart';
import '../Provider/CartProvider.dart';
import '../Provider/UserProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../ui/widgets/AppBtn.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import 'Product_DetailNew.dart';

class FaqsProduct extends StatefulWidget {
  final String? id;
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return FaqsProduct(arguments?['id']);
      },
    );
  }

  const FaqsProduct(this.id, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateFaqsProduct();
  }
}

class StateFaqsProduct extends State<FaqsProduct>
    with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  bool _isLoading = true;

  // bool _isProgress = false, _isLoading = true;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  List<User> tempList = [];
  final edtFaqs = TextEditingController();
  final GlobalKey<FormState> faqsKey = GlobalKey<FormState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final TextEditingController _controller1 = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool notificationisnodata = false;
  Timer? _debounce;
  String query = '';

  @override
  void initState() {
    faqsOffset = 0;
    controller = ScrollController(keepScrollOffset: true);
    controller.addListener(_scrollListener);
    _controller1.addListener(() {
      if (_controller1.text.isEmpty) {
        setState(() {
          query = '';
          faqsOffset = 0;
          isLoadingmore = true;
          getFaqs();
        });
      } else {
        query = _controller1.text;
        faqsOffset = 0;
        notificationisnodata = false;

        if (query.trim().isNotEmpty) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (query.trim().isNotEmpty) {
              isLoadingmore = true;
              faqsOffset = 0;
              getFaqs();
            }
          });
        }
      }
      ScaffoldMessenger.of(context).clearSnackBars();
    });
    getFaqs();
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
    super.initState();
  }

  @override
  void dispose() {
    buttonController!.dispose();
    edtFaqs.dispose();
    _controller1.dispose();
    controller.removeListener(() {});
    super.dispose();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;
            if (faqsOffset < faqsTotal) {
              getFaqs();
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            getAppBar(getTranslated(context, 'QUE_ANS_LBL')!, context, from: 1),
        bottomNavigationBar: bottomBtn(),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showForm(),
                  Selector<CartProvider, bool>(
                    builder: (context, data, child) {
                      return showCircularProgress(data, colors.primary);
                    },
                    selector: (_, provider) => provider.isProgress,
                  ),
                ],
              )
            : noInternet(context));
  }

  Widget bottomBtn() {
    return context.read<UserProvider>().userId != ""
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: 10, end: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(getTranslated(context, 'HAVE_DOUBTS_REG_THIS_PRO_LBL')!,
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.fontColor)),
                Padding(
                    padding:
                        const EdgeInsetsDirectional.only(top: 10, bottom: 5),
                    child: SimBtn(
                      onBtnSelected: () {
                        openPostQueBottomSheet();
                      },
                      title: "POST YOUR QUESTION",
                      height: 38.5,
                      width: double.maxFinite,
                    ))
              ],
            ),
          )
        : const SizedBox();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
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

  _showForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.center,
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          color: Theme.of(context).colorScheme.white,
          padding: const EdgeInsets.only(bottom: 15),
          //padding: const EdgeInsets.symmetric(vertical: ),
          child: Container(
            color: Theme.of(context).colorScheme.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(25)),
                height: 44,
                child: TextField(
                  controller: _controller1,
                  autofocus: false,
                  focusNode: searchFocusNode,
                  enabled: true,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
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
                          const EdgeInsets.fromLTRB(15.0, 5.0, 0, 5.0),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      fillColor: Theme.of(context).colorScheme.gray,
                      filled: true,
                      isDense: true,
                      hintText: "Have a question? Search for answers",
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
                      prefixIcon: const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Icon(
                            Icons.search,
                            color: colors.primary,
                          )),
                      suffixIcon: _controller1.text != ''
                          ? IconButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();

                                _controller1.text = '';
                                faqsOffset = 0;
                                getFaqs();
                              },
                              icon: const Icon(
                                Icons.close,
                                color: colors.primary,
                              ),
                            )
                          : const SizedBox()),
                ),
              ),
            ),
          ),
        ),
        _faqs(),
      ],
    );
  }

  void openPostQueBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return Form(
              key: faqsKey,
              child: Wrap(
                children: [
                  bottomSheetHandle(context),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40.0),
                        topRight: Radius.circular(40.0),
                      ),
                      color: Theme.of(context).colorScheme.white,
                    ),
                    padding: EdgeInsetsDirectional.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.only(top: 30.0, bottom: 20),
                            child: Text(
                              getTranslated(context, 'WRITE_QUE_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )),
                        Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(top: 10.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 20, end: 20),
                                    child: Container(
                                      // padding: EdgeInsetsDirectional.only(start: 10,end: 10),
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.25,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightWhite),
                                      child: TextFormField(
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                            fontSize: 14.0),
                                        onChanged: (value) {},
                                        onSaved: ((String? val) {}),
                                        maxLines: null,
                                        validator: (val) {
                                          if (val!.isEmpty) {
                                            return getTranslated(context,
                                                'PLS_PRO_MORE_DET_LBL');
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          hintText: getTranslated(
                                              context, 'TYPE_YR_QUE_LBL'),
                                          contentPadding:
                                              const EdgeInsetsDirectional.all(
                                                  25.0),
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .colorScheme
                                              .lightWhite,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              borderSide: const BorderSide(
                                                  width: 0.0,
                                                  style: BorderStyle.none)),
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        controller: edtFaqs,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.all(20),
                                    child: SimBtn(
                                      title:
                                          getTranslated(context, 'SUBMIT_LBL'),
                                      height: 45,
                                      width: deviceWidth,
                                      onBtnSelected: () {
                                        final form = faqsKey.currentState!;

                                        form.save();
                                        if (form.validate()) {
                                          context
                                              .read<CartProvider>()
                                              .setProgress(true);
                                          setFaqsQue();
                                        }
                                      },
                                    ),
                                  )
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  Future<void> setFaqsQue() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PRODUCT_ID: widget.id,
          QUESTION: edtFaqs.text.trim()
        };
        apiBaseHelper.postAPICall(setProductFaqsApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!, context);
            edtFaqs.clear();
            Navigator.pop(context);
          } else {
            setSnackbar(msg!, context);
          }
          context.read<CartProvider>().setProgress(false);
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

  Widget _faqs() {
    return _isLoading
        ? Padding(
            padding: EdgeInsetsDirectional.only(top: deviceHeight! / 3),
            child: const CircularProgressIndicator(
              color: colors.primary,
            ))
        : notificationisnodata
            ? Padding(
                padding: EdgeInsetsDirectional.only(top: deviceHeight! / 3),
                child: getNoItem(context))
            : Expanded(
                child: ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    controller: controller,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    itemCount: (faqsOffset < faqsTotal)
                        ? faqsProductList.length + 1
                        : faqsProductList.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index == faqsProductList.length && isLoadingmore) {
                        return const Center(
                            child: CircularProgressIndicator(
                          color: colors.primary,
                        ));
                      } else {
                        if (index < faqsProductList.length) {
                          return Padding(
                            padding: const EdgeInsets.all(7),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${getTranslated(context, 'Q_LBL')}: ${faqsProductList[index].question!}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontSize: 12.5),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "${getTranslated(context, 'A_LBL')}: ${faqsProductList[index].answer!}",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack,
                                        fontSize: 11),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    faqsProductList[index].uname!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack2,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack
                                            .withOpacity(0.8),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 3.0),
                                        child: Text(
                                          faqsProductList[index].ansBy!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack
                                                  .withOpacity(0.5),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      }
                    }),
              );
  }

  Future<void> getFaqs() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (isLoadingmore) {
          if (mounted) {
            setState(() {
              isLoadingmore = false;
              if (_controller1.hasListeners && _controller1.text.isNotEmpty) {
                _isLoading = true;
              }
            });
          }
          var parameter = {
            PRODUCT_ID: widget.id,
            LIMIT: perPage.toString(),
            OFFSET: faqsOffset.toString(),
            SEARCH: query,
          };

          apiBaseHelper.postAPICall(getProductFaqsApi, parameter).then(
              (getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            _isLoading = false;
            if (faqsOffset == 0) notificationisnodata = error;
            if (!error) {
              faqsTotal = int.parse(getdata["total"]);
              // faqsOffset = int.parse(faqsOffset);

              if (faqsOffset < faqsTotal) {
                var data = getdata["data"];

                if (faqsOffset == 0) {
                  faqsProductList = [];
                }
                List<FaqsModel> tempList = (data as List)
                    .map((data) => FaqsModel.fromJson(data))
                    .toList();
                faqsProductList.addAll(tempList);
                isLoadingmore = true;
                faqsOffset = faqsOffset + perPage;
              } else {
                if (msg != "FAQs does not exist") {
                  notificationisnodata = true;
                }
                isLoadingmore = false;
              }
            } else {
              if (msg != "FAQs does not exist") {
                notificationisnodata = true;
              }
              isLoadingmore = false;
              if (mounted) setState(() {});
            }

            setState(() {
              _isLoading = false;
            });
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            isLoadingmore = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }
}
