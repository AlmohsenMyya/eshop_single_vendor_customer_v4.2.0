import 'dart:async';
import 'dart:math';

import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/SqliteData.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../Provider/HomeProvider.dart';
import '../Provider/ProductProvider.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class SearchScreen extends StatefulWidget {
  final String? catId;
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SearchScreen(
          catId: arguments?['catId'],
        );
      },
    );
  }

  const SearchScreen({Key? key, this.catId}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

bool buildResult = false;

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  int pos = 0;
  bool _isProgress = false;
  List<Product> productList = [];
  final List<TextEditingController> _controllerList = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  String query = "";
  int notificationoffset = 0;
  ScrollController? notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;

  late AnimationController _animationController;
  Timer? _debounce;
  List<Product> history = [];
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;

  String lastStatus = '';
  String _currentLocaleId = '';
  String lastWords = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();
  late StateSetter setStater;
  ChoiceChip? tagChip;
  late UserProvider userProvider;
  var db = DatabaseHelper();

  @override
  void initState() {
    super.initState();

    productList.clear();

    notificationoffset = 0;

    notificationcontroller = ScrollController(keepScrollOffset: true);
    notificationcontroller!.addListener(_transactionscrollListener);

    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (mounted) {
          setState(() {
            query = "";
          });
        }
      } else {
        query = _controller.text;
        notificationoffset = 0;
        notificationisnodata = false;
        buildResult = false;
        if (query.trim().isNotEmpty) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (query.trim().isNotEmpty) {
              notificationisloadmore = true;
              notificationoffset = 0;

              getProduct();
            }
          });
        }
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

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

  _transactionscrollListener() {
    if (notificationcontroller!.offset >=
            notificationcontroller!.position.maxScrollExtent &&
        !notificationcontroller!.position.outOfRange) {
      if (mounted) {
        setState(() {
          getProduct();
        });
      }
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    notificationcontroller!.dispose();
    _controller.dispose();
    for (int i = 0; i < _controllerList.length; i++) {
      _controllerList[i].dispose();
    }
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
        appBar: AppBar(
          leading: Builder(builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.0),
                  child:
                      Icon(Icons.arrow_back_ios_rounded, color: colors.primary),
                ),
              ),
            );
          }),
          backgroundColor: Theme.of(context).colorScheme.white,
          title: TextField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
              hintText: getTranslated(context, 'SEARCH_LBL'),
              hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .blackInverseInDarkTheme
                      .withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.white),
              ),
            ),
          ),
          titleSpacing: 0,
          actions: [
            _controller.text != ""
                ? IconButton(
                    onPressed: () {
                      _controller.text = '';
                    },
                    icon: Icon(
                      Icons.close,
                      color:
                          Theme.of(context).colorScheme.blackInverseInDarkTheme,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.mic,
                      color:
                          Theme.of(context).colorScheme.blackInverseInDarkTheme,
                    ),
                    onPressed: () {
                      lastWords = '';
                      if (!_hasSpeech) {
                        initSpeechState();
                      } else {
                        showSpeechDialog();
                      }
                    },
                  )
          ],
        ),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(),
                  showCircularProgress(_isProgress, colors.primary),
                ],
              )
            : noInternet(context));
  }

  Widget listItem(int index) {
    Product model = productList[index];

    if (_controllerList.length < index + 1) {
      _controllerList.add(TextEditingController());
    }

    _controllerList[index].text =
        model.prVarientList![model.selVarient!].cartCount!;

    double price =
        double.parse(model.prVarientList![model.selVarient!].disPrice!);
    if (price == 0) {
      price = double.parse(model.prVarientList![model.selVarient!].price!);
    }

    List att = [], val = [];
    if (model.prVarientList![model.selVarient!].attr_name != null) {
      att = model.prVarientList![model.selVarient!].attr_name!.split(',');
      val = model.prVarientList![model.selVarient!].varient_value!.split(',');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          splashColor: colors.primary.withOpacity(0.2),
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
            currentHero = searchHero;
            Product model = productList[index];

            Navigator.pushNamed(context, Routers.productDetails, arguments: {
              "id": model.id!,
              "secPos": 0,
              "index": index,
              "list": true,
            });
          },
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Hero(
                      tag: "$searchHero$index${model.id}0",
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.0),
                          child: networkImageCommon(
                              productList[index].image!, 80, false,
                              height: 80, width: 80)
                          /*CachedNetworkImage(
                            imageUrl: productList[index].image!,
                            height: 80.0,
                            width: 80.0,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) =>
                                erroWidget(80),
                            placeholder: (context, url) {
                              return placeHolder(80);
                            },
                          )*/
                          )),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              model.name!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .lightBlack,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: <Widget>[
                                Text(
                                    model.isSalesOn == "1"
                                        ? getPriceFormat(
                                            context,
                                            double.parse(model
                                                .prVarientList![
                                                    model.selVarient!]
                                                .saleFinalPrice!))!
                                        : '${getPriceFormat(context, price)!} ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor)),
                                Text(
                                  double.parse(model
                                              .prVarientList![model.selVarient!]
                                              .disPrice!) !=
                                          0
                                      ? getPriceFormat(
                                          context,
                                          double.parse(model
                                              .prVarientList![model.selVarient!]
                                              .price!))!
                                      : "",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          letterSpacing: 0),
                                ),
                              ],
                            ),
                            model.prVarientList![model.selVarient!].attr_name !=
                                        null &&
                                    model.prVarientList![model.selVarient!]
                                        .attr_name!.isNotEmpty
                                ? ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: att.length,
                                    itemBuilder: (context, index) {
                                      return Row(children: [
                                        Flexible(
                                          child: Text(
                                            att[index].trim() + ":",
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 5.0),
                                          child: Text(
                                            val[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                        )
                                      ]);
                                    })
                                : const SizedBox.shrink(),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: colors.primary,
                                      size: 12,
                                    ),
                                    Text(
                                      " ${productList[index].rating!}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    Text(
                                      " (${productList[index].noOfRating!})",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    )
                                  ],
                                ),
                                const Spacer(),
                                model.availability == "0"
                                    ? const SizedBox.shrink()
                                    : cartBtnList
                                        ? Row(
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  InkWell(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2),
                                                      margin:
                                                          const EdgeInsetsDirectional
                                                              .only(end: 8),
                                                      decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .lightWhite,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          3))),
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      if (_isProgress ==
                                                              false &&
                                                          (int.parse(productList[
                                                                      index]
                                                                  .prVarientList![
                                                                      model
                                                                          .selVarient!]
                                                                  .cartCount!)) >
                                                              0) {
                                                        removeFromCart(index);
                                                      }
                                                    },
                                                  ),
                                                  SizedBox(
                                                    width: 40,
                                                    height: 20,
                                                    child: Stack(
                                                      children: [
                                                        TextField(
                                                          textAlign:
                                                              TextAlign.center,
                                                          readOnly: true,
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .fontColor),
                                                          controller:
                                                              _controllerList[
                                                                  index],
                                                          decoration:
                                                              InputDecoration(
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .fontColor,
                                                                  width: 0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .fontColor,
                                                                  width: 0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                          ),
                                                        ),
                                                        PopupMenuButton<String>(
                                                          tooltip: '',
                                                          icon: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 1,
                                                          ),
                                                          onSelected:
                                                              (String value) {
                                                            if (_isProgress ==
                                                                false) {
                                                              addToCart(
                                                                  index, value);
                                                            }
                                                          },
                                                          itemBuilder:
                                                              (BuildContext
                                                                  context) {
                                                            return model
                                                                .itemsCounter!
                                                                .map<
                                                                    PopupMenuItem<
                                                                        String>>((String
                                                                    value) {
                                                              return PopupMenuItem(
                                                                  value: value,
                                                                  child: Text(
                                                                      value,
                                                                      style: TextStyle(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .fontColor)));
                                                            }).toList();
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  InkWell(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2),
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .lightWhite,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          3))),
                                                      child: Icon(
                                                        Icons.add,
                                                        size: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      if (_isProgress ==
                                                          false) {
                                                        addToCart(
                                                            index,
                                                            ((int.parse(model
                                                                        .prVarientList![model
                                                                            .selVarient!]
                                                                        .cartCount!)) +
                                                                    int.parse(model
                                                                        .qtyStepSize!))
                                                                .toString());
                                                      }
                                                    },
                                                  )
                                                ],
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                              ],
                            ),
                          ],
                        )),
                  )
                ],
              ),
              productList[index].availability == "0"
                  ? Text(getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Colors.red, fontWeight: FontWeight.bold))
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> addToCart(int index, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (context.read<UserProvider>().userId != "") {
        try {
          if (mounted) {
            setState(() {
              _isProgress = true;
            });
          }

          if (int.parse(qty) < productList[index].minOrderQuntity!) {
            qty = productList[index].minOrderQuntity.toString();

            setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
          }

          var parameter = {
            USER_ID: context.read<UserProvider>().userId,
            PRODUCT_VARIENT_ID: productList[index]
                .prVarientList![productList[index].selVarient!]
                .id,
            QTY: qty
          };
          apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];
              userProvider.setCartCount(data['cart_count']);

              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .cartCount = qty.toString();
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                _isProgress = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
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

  Future<void> removeFromCart(int index) async {
    Product model = productList[index];
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (context.read<UserProvider>().userId != "") {
        try {
          if (mounted) {
            setState(() {
              _isProgress = true;
            });
          }

          int qty;

          qty = (int.parse(productList[index]
                  .prVarientList![model.selVarient!]
                  .cartCount!) -
              int.parse(productList[index].qtyStepSize!));

          if (qty < productList[index].minOrderQuntity!) {
            qty = 0;
          }

          var parameter = {
            PRODUCT_VARIENT_ID: model.prVarientList![model.selVarient!].id,
            USER_ID: context.read<UserProvider>().userId,
            QTY: qty.toString()
          };
          apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];

            if (!error) {
              var data = getdata["data"];
              String? qty = data["total_quantity"];
              userProvider.setCartCount(data['cart_count']);
              model.prVarientList![model.selVarient!].cartCount =
                  qty.toString();
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                _isProgress = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
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

  Future<void> getAvailVarient(List<Product> tempList) async {
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == "2") {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == "1") {
            tempList[j].selVarient = i;

            break;
          }
        }
      }
    }
    if (notificationoffset == 0) {
      productList = [];
    }

    if (notificationoffset == 0 && buildResult) {
      Product element = Product(
          name: 'Search Result for "$query"',
          image: "",
          catName: "All Categories",
          history: false);
      productList.insert(0, element);
      for (int i = 0; i < history.length; i++) {
        if (history[i].name == query) productList.insert(0, history[i]);
      }
    }

    productList.addAll(tempList);
    int p = 0;

    for (int j = 0; j < productList.length; j++) {
      bool? check = await db.checkMostLikeExists(productList[j].id!);

      if (p < 5) {
        if (!check!) {
          p = p + 1;
          await db.addMostLike(productList[j].id!);
        }
      }
    }
    await getMostLikePro();

    notificationisloadmore = true;
    notificationoffset = notificationoffset + perPage;
  }

  Future<void> getMostLikePro() async {
    List<String> proIds = [];
    proIds = (await db.getMostLike())!;

    if (proIds.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        try {
          var parameter = {"product_ids": proIds.join(',')};
          apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
            bool error = getdata["error"];
            if (!error) {
              var data = getdata["data"];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();

              context.read<ProductProvider>().setProductList(tempList);
            }
            if (mounted) {
              setState(() {
                context.read<HomeProvider>().setMostLikeLoading(false);
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<HomeProvider>().setMostLikeLoading(false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
            context.read<HomeProvider>().setMostLikeLoading(false);
          });
        }
      }
    } else {
      context.read<ProductProvider>().setProductList([]);
      setState(() {
        context.read<HomeProvider>().setMostLikeLoading(false);
      });
    }
  }

  Future getProduct() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (notificationisloadmore) {
          if (mounted) {
            setState(() {
              notificationisloadmore = false;
              notificationisgettingdata = true;
            });
          }

          var parameter = {
            SEARCH: query.trim(),
            LIMIT: perPage.toString(),
            OFFSET: notificationoffset.toString(),
          };

          if (context.read<UserProvider>().userId != "") {
            parameter[USER_ID] = context.read<UserProvider>().userId;
          }

          if (widget.catId != "" && widget.catId != null) {
            parameter[CATID] = widget.catId!;
          }
          apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];

            Map<String, dynamic> tempData = getdata;
            tagList.clear();
            if (tempData.containsKey(TAG)) {
              List<String> tempList = List<String>.from(getdata[TAG]);
              if (tempList.isNotEmpty) tagList = tempList;
            }

            String? search = getdata['search'];

            notificationisgettingdata = false;
            if (notificationoffset == 0) notificationisnodata = error;

            if (!error) {
              if (mounted) {
                Future.delayed(
                    Duration.zero,
                    () => setState(() {
                          List mainlist = getdata['data'];

                          if (mainlist.isNotEmpty) {
                            List<Product> items = [];
                            List<Product> allitems = [];

                            items.addAll(mainlist
                                .map((data) => Product.fromJson(data))
                                .toList());

                            allitems.addAll(items);

                            getAvailVarient(allitems);
                          } else {
                            notificationisloadmore = false;
                          }
                        }));
              }
            } else {
              notificationisloadmore = false;
              if (mounted) setState(() {});
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            notificationisloadmore = false;
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

  clearAll() {
    setState(() {
      query = _controller.text;
      notificationoffset = 0;
      notificationisloadmore = true;
      productList.clear();
    });
  }

  _tags() {
    if (tagList != null) {
      List<Widget> chips = [];
      for (int i = 0; i < tagList.length; i++) {
        tagChip = ChoiceChip(
          selected: false,
          label: Text(tagList[i],
              style: TextStyle(
                  color: Theme.of(context).colorScheme.white, fontSize: 12)),
          backgroundColor: colors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25))),
          onSelected: (bool selected) {
            if (mounted) {
              Navigator.pushNamed(context, Routers.productListScreen,
                  arguments: {
                    "name": tagList[i],
                    "fromSeller": false,
                    "tag": true,
                  });
            }
          },
        );

        chips.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: tagChip));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          tagList.isNotEmpty
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    getTranslated(context, 'OFFICE_LBL')!,
                  ))
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              children: chips.map<Widget>((Widget chip) {
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: chip,
                );
              }).toList(),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  _showContent() {
    if (_controller.text == "") {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      return FutureBuilder<List<String>>(
          future: settingsProvider.getPrefrenceList(HISTORYLIST),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final entities = snapshot.data!;
              List<Product> itemList = [];
              for (int i = 0; i < entities.length; i++) {
                Product item = Product.history(entities[i]);
                itemList.add(item);
              }
              history.clear();
              history.addAll(itemList);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _SuggestionList(
                      textController: _controller,
                      suggestions: itemList,
                      notificationcontroller: notificationcontroller,
                      getProduct: getProduct,
                      clearAll: clearAll,
                    ),
                    _tags()
                  ],
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          });
    } else if (buildResult) {
      return notificationisnodata
          ? getNoItem(context)
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                      padding: const EdgeInsetsDirectional.only(
                          bottom: 5, start: 10, end: 10, top: 12),
                      controller: notificationcontroller,
                      physics: const BouncingScrollPhysics(),
                      itemCount: productList.length,
                      itemBuilder: (context, index) {
                        Product? item;
                        try {
                          item =
                              productList.isEmpty ? null : productList[index];
                          if (notificationisloadmore &&
                              index == (productList.length - 1) &&
                              notificationcontroller!.position.pixels <= 0) {
                            getProduct();
                          }
                        } on Exception catch (_) {}

                        return item == null
                            ? const SizedBox.shrink()
                            : listItem(index);
                      }),
                ),
                notificationisgettingdata
                    ? const Padding(
                        padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            );
    }
    return notificationisnodata
        ? getNoItem(context)
        : Column(
            children: <Widget>[
              Expanded(
                  child: _SuggestionList(
                textController: _controller,
                suggestions: productList,
                notificationcontroller: notificationcontroller,
                getProduct: getProduct,
                clearAll: clearAll,
              )),
              notificationisgettingdata
                  ? const Padding(
                      padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          );
  }

  Future<void> initSpeechState() async {
    var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: false,
        finalTimeout: const Duration(milliseconds: 0));
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale?.localeId ?? '';
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
    if (hasSpeech) showSpeechDialog();
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      setSnackbar(error.errorMsg, context);
    });
  }

  void statusListener(String status) {
    setStater(() {
      lastStatus = status;
    });
  }

  void startListening() {
    lastWords = '';
    speech.listen(
        onResult: resultListener,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setStater(() {});
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);

    setStater(() {
      this.level = level;
    });
  }

  void stopListening() {
    speech.stop();
    setStater(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setStater(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    setStater(() {
      lastWords = result.recognizedWords;
      query = lastWords.replaceAll(' ', '');
    });

    if (result.finalResult) {
      Future.delayed(const Duration(seconds: 1)).then((_) async {
        clearAll();

        _controller.text = lastWords;
        _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length));

        setState(() {});
        Navigator.of(context).pop();
      });
    }
  }

  showSpeechDialog() {
    return dialogAnimate(context, StatefulBuilder(
        builder: (BuildContext context, StateSetter setStater1) {
      setStater = setStater1;
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        title: Text(
          'Search for desired product',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Theme.of(context).colorScheme.fontColor),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: .26,
                      spreadRadius: level * 1.5,
                      color:
                          Theme.of(context).colorScheme.black.withOpacity(.05))
                ],
                color: Theme.of(context).colorScheme.white,
                borderRadius: const BorderRadius.all(Radius.circular(50)),
              ),
              child: IconButton(
                  icon: const Icon(
                    Icons.mic,
                    color: colors.primary,
                  ),
                  onPressed: () {
                    if (!_hasSpeech) {
                      initSpeechState();
                    } else {
                      !_hasSpeech || speech.isListening
                          ? null
                          : startListening();
                    }
                  }),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(lastWords),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.1),
              child: Center(
                child: speech.isListening
                    ? Text(
                        "I'm listening...",
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.bold),
                      )
                    : Text(
                        'Not listening',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      );
    }));
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList(
      {this.suggestions,
      this.textController,
      this.notificationcontroller,
      this.getProduct,
      this.clearAll});

  final List<Product>? suggestions;
  final TextEditingController? textController;

  final notificationcontroller;
  final Function? getProduct, clearAll;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: suggestions!.length,
      shrinkWrap: true,
      controller: notificationcontroller,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemBuilder: (BuildContext context, int i) {
        final Product suggestion = suggestions![i];

        return ListTile(
            title: Text(
              suggestion.name!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: textController!.text.toString().trim().isEmpty ||
                    suggestion.history!
                ? null
                : Text(
                    "In ${suggestion.catName!}",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor),
                  ),
            leading: textController!.text.toString().trim().isEmpty ||
                    suggestion.history!
                ? const Icon(Icons.history)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: suggestion.image == ''
                        ? Image.asset(
                            'assets/images/Placeholder_Rectangle.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : networkImageCommon(suggestion.image!, 50, false,
                            height: 50, width: 50)
                    /*CachedNetworkImage(
                            imageUrl: suggestion.image!,
                            fadeInDuration: const Duration(milliseconds: 10),
                            fit: BoxFit.cover,
                            height: 50,
                            width: 50,
                            placeholder: (context, url) {
                              return placeHolder(50);
                            },
                            errorWidget: (context, error, stackTrace) =>
                                erroWidget(50),
                          )*/
                    ),
            trailing: const Icon(
              Icons.reply,
            ),
            onTap: () async {
              if (suggestion.name!.startsWith('Search Result for ')) {
                SettingProvider settingsProvider =
                    Provider.of<SettingProvider>(context, listen: false);

                settingsProvider.setPrefrenceList(
                    HISTORYLIST, textController!.text.toString().trim());

                buildResult = false;
                clearAll!();
                getProduct!();
              } else if (suggestion.history!) {
                clearAll!();

                buildResult = false;
                textController!.text = suggestion.name!;
                textController!.selection = TextSelection.fromPosition(
                    TextPosition(offset: textController!.text.length));
              } else {
                SettingProvider settingsProvider =
                    Provider.of<SettingProvider>(context, listen: false);

                settingsProvider.setPrefrenceList(
                    HISTORYLIST, textController!.text.toString().trim());
                buildResult = false;
                currentHero = searchHero;
                Product model = suggestion;

                Navigator.pushNamed(context, Routers.productDetails,
                    arguments: {
                      "id": model.id!,
                      "secPos": 0,
                      "index": i,
                      "list": true,
                    });
                // Navigator.push(
                //   context,
                //   PageRouteBuilder(
                //       pageBuilder: (_, __, ___) => ProductDetail()),
                // );
              }
            });
      },
    );
  }
}
