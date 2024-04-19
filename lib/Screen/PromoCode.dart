import 'dart:async';

import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Helper/cart_var.dart';
import '../Model/Section_Model.dart';
import '../Provider/CartProvider.dart';
import '../Provider/UserProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/SimBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class PromoCodeScreen extends StatefulWidget {
  final String from;
  final Function? updateParent;
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return PromoCodeScreen(
          from: arguments?['from'],
          updateParent: arguments?['updateParent'],
        );
      },
    );
  }

  const PromoCodeScreen({
    Key? key,
    required this.from,
    this.updateParent,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => StatePromoCode();
}

class StatePromoCode extends State<PromoCodeScreen>
    with TickerProviderStateMixin {
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<Promo> tempList = [];
  List<Promo> promoList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  final GlobalKey expansionTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    getPromoCodes();
    controller.addListener(_scrollListener);
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

  void _scrollToSelectedContent({GlobalKey? expansionTileKey}) {
    final keyContext = expansionTileKey!.currentContext;
    if (keyContext != null) {
      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        Scrollable.ensureVisible(keyContext,
            duration: const Duration(milliseconds: 200));
      });
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
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
      ),
    );
  }

  Future<void> getPromoCodes() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        apiBaseHelper.postAPICall(getPromoCodeApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata['total'].toString());
            if ((offset) < total) {
              tempList.clear();
              var promo = getdata[PROMO_CODES];
              tempList =
                  (promo as List).map((data) => Promo.fromJson(data)).toList();

              promoList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            setSnackbar(msg!, context);
            isLoadingmore = false;
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            _isLoading = false;
            isLoadingmore = false;
          });
        }
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;

            if (offset < total) getPromoCodes();
          });
        }
      }
    }
  }

  Future<void> _refresh() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    offset = 0;
    total = 0;
    promoList.clear();
    return getPromoCodes();
  }

  Future<void> validatePromo(String promo) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        setState(() {});
        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PROMOCODE: promo,
          FINAL_TOTAL: oriPrice.toString()
        };
        apiBaseHelper.postAPICall(validatePromoApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"][0];
            /* if (isStorePickUp == "false") {
              totalPrice = double.parse(data["final_total"]) + delCharge;
            } else {*/
            totalPrice = double.parse(data["final_total"]);
            /*  }*/

            promoAmt = double.parse(data["final_discount"]);

            promocode = data["promo_code"];

            isPromoValid = true;
            widget.updateParent!(promo);
            if (mounted) {
              setSnackbar(getTranslated(context, 'PROMO_SUCCESS')!, context);
            }
            Navigator.of(context).pop();
          } else {
            isPromoValid = false;
            promoAmt = 0;
            promocode = null;

            var data = getdata["data"];
            /* if (isStorePickUp == "false") {
              totalPrice = double.parse(data["final_total"]) + delCharge;
            } else {*/
            totalPrice = double.parse(data["final_total"]);
            /*  }*/
            if (mounted) {
              setSnackbar(msg!, context);
            }
          }

          if (isUseWallet!) {
            remWalBal = 0;
            payMethod = null;
            usedBal = 0;
            isUseWallet = false;
            isPayLayShow = true;

            selectedMethod = null;
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
            }
            //if (mounted && check) checkoutState!(() {});
            if (mounted) setState(() {});
          } else {
            //if (mounted && check) checkoutState!(() {});

            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              setState(() {});
            }
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        // if (mounted && check) checkoutState!(() {});
        setState(() {});
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      _isNetworkAvail = false;
      //if (mounted && check) checkoutState!(() {});
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar:
            getSimpleAppBar(getTranslated(context, 'YOUR_PROM_CO')!, context),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : promoList.isEmpty
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: kToolbarHeight),
                        child: Center(
                            child: Text(getTranslated(context, 'NO_PROMCO')!)))
                    : RefreshIndicator(
                        color: colors.primary,
                        key: _refreshIndicatorKey,
                        onRefresh: _refresh,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: (offset < total)
                                  ? promoList.length + 1
                                  : promoList.length,
                              itemBuilder: (context, index) {
                                return (index == promoList.length &&
                                        isLoadingmore)
                                    ? singleItemSimmer(context)
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Column(
                                          children: [
                                            ExpansionPanelList.radio(
                                                children: [
                                                  ExpansionPanelRadio(
                                                    body: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0,
                                                          vertical: 5.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .check_circle_outline,
                                                                size: 10,
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  "${getTranslated(context, "MIN_ORDER_VALUE")!} ${getPriceFormat(context, double.parse(promoList[index].minOrderAmt!))}",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .check_circle_outline,
                                                                size: 10,
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                    "${getTranslated(context, "MAX_DISCOUNT")!}  ${getPriceFormat(context, double.parse(promoList[index].maxDiscountAmt!))}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .check_circle_outline,
                                                                size: 10,
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                    "${getTranslated(context, "OFFER_VALID_FROM")!} ${promoList[index].startDate} to ${promoList[index].endDate}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .check_circle_outline,
                                                                size: 10,
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                child: promoList[index]
                                                                            .repeatUsage ==
                                                                        "Allowed"
                                                                    ? Text(
                                                                        "${getTranslated(context, "MAX_APPLICABLE")!}  ${promoList[index].noOfRepeatUsage} times",
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                12))
                                                                    : Text(
                                                                        getTranslated(
                                                                            context,
                                                                            "OFFER_VALID_ONCE")!,
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                12)),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    headerBuilder:
                                                        (context, isExpanded) {
                                                      return Column(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8),
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                  height: 50,
                                                                  width: 50,
                                                                  child: ClipRRect(
                                                                      borderRadius: BorderRadius.circular(7.0),
                                                                      child: Image.network(
                                                                        promoList[index]
                                                                            .image!,
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        fit: BoxFit
                                                                            .fill,
                                                                        errorBuilder: (context,
                                                                                error,
                                                                                stackTrace) =>
                                                                            erroWidget(
                                                                          80,
                                                                        ),
                                                                      )),
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          promoList[index].promoCode ??
                                                                              '',
                                                                          style:
                                                                              const TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                        Text(
                                                                          promoList[index].message ??
                                                                              "",
                                                                          style:
                                                                              const TextStyle(fontSize: 12),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                    value: index,
                                                    canTapOnHeader: true,

                                                    //isExpanded: promoList[index].isExpanded,
                                                  ),
                                                ],
                                                elevation: 0.0,
                                                animationDuration:
                                                    const Duration(
                                                        milliseconds: 700),
                                                expansionCallback:
                                                    (int item, bool status) {
                                                  setState(() {
                                                    promoList[index]
                                                        .isExpanded = !status;
                                                  });
                                                }),
                                            Container(
                                              alignment: Alignment.bottomRight,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .white,
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 5),
                                                  child:
                                                      widget.from == "Profile"
                                                          ? InkWell(
                                                              onTap: () {
                                                                Clipboard.setData(
                                                                    ClipboardData(
                                                                        text: promoList[index]
                                                                            .promoCode!));
                                                                setSnackbar(
                                                                    'Promo Code Copied to clipboard',
                                                                    context);
                                                              },
                                                              child: Stack(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            5),
                                                                    child: SvgPicture
                                                                        .asset(
                                                                      "assets/images/promo_light.svg",
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.4,
                                                                      colorFilter: ColorFilter.mode(
                                                                          Theme.of(context)
                                                                              .colorScheme
                                                                              .lightWhite,
                                                                          BlendMode
                                                                              .srcIn),
                                                                      height:
                                                                          35,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    promoList[index]
                                                                            .promoCode ??
                                                                        '',
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Stack(
                                                                        alignment:
                                                                            Alignment.center,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.only(left: 5),
                                                                            child:
                                                                                InkWell(
                                                                              child: SvgPicture.asset(
                                                                                "assets/images/promo_light.svg",
                                                                                width: MediaQuery.of(context).size.width * 0.4,
                                                                                colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.lightWhite, BlendMode.srcIn),
                                                                                height: 35,
                                                                              ),
                                                                              onTap: () {
                                                                                Clipboard.setData(ClipboardData(text: promoList[index].promoCode!));
                                                                                setSnackbar('Promo Code Copied to clipboard', context);
                                                                              },
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            promoList[index].promoCode ??
                                                                                '',
                                                                            style:
                                                                                const TextStyle(fontWeight: FontWeight.bold),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SimBtn(
                                                                  title: getTranslated(
                                                                      context,
                                                                      "APPLY"),
                                                                  height: 35,
                                                                  width: 0.2,
                                                                  onBtnSelected:
                                                                      () {
                                                                    validatePromo(
                                                                        promoList[index]
                                                                            .promoCode!);
                                                                  },
                                                                ),
                                                              ],
                                                            )),
                                            ),
                                          ],
                                        ));
                              }),
                        ))
            : noInternet(context));
  }
}
