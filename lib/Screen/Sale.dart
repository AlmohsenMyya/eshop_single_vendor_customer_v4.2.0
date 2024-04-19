import 'dart:async';

import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/app/routes.dart';
import 'package:eshop/ui/widgets/AppBtn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../ui/styles/DesignConfig.dart';
import 'HomePage.dart';
import 'Product_DetailNew.dart';

class Sale extends StatefulWidget {
  const Sale({Key? key}) : super(key: key);

  @override
  _SaleState createState() => _SaleState();
}

class _SaleState extends State<Sale>
    with AutomaticKeepAliveClientMixin<Sale>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;

  final _controller = PageController();
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<Product> productList = [];
  List<Product> tempList = [];
  List<SectionModel> saleList = [];

  List<int> disList = [5, 10, 20, 30, 40, 50, 70, 80];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  int curDis = 0;
  bool _loading = true;
  bool _productLoading = true;
  final ScrollController _scrollBottomBarController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollBottomBarController.removeListener(() {});
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    callApi();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    hideAppbarAndBottomBarOnScroll(_scrollBottomBarController, context);
    return Scaffold(
        body: _isNetworkAvail
            ? RefreshIndicator(
                color: colors.primary,
                key: _refreshIndicatorKey,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  controller: _scrollBottomBarController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            bottom: 8.0, start: 10.0),
                        child: Text(
                          getTranslated(context, 'CHOOSE_DIS')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      discountRow(),
                      _product(),
                      _section()
                    ],
                  ),
                ))
            : noInternet(context));
  }

  Future<void> _refresh() {
    setState(() {
      _productLoading = true;
      _loading = true;
    });
    return callApi();
  }

  _singleSection(int index) {
    return saleList[index].productList!.isNotEmpty
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _getHeading(saleList[index].title ?? "", index),
                    _getSection(index),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  _getHeading(String title, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Container(
            padding: const EdgeInsetsDirectional.only(
              start: 15,
              bottom: 3,
              top: 3,
            ),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(saleList[index].shortDesc ?? "",
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      getTranslated(context, 'seeAll')!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: colors.primary),
                    ),
                  ),
                  onTap: () {
                    SectionModel model = saleList[index];

                    Navigator.pushNamed(context, Routers.saleSectionScreen,
                        arguments: {
                          "index": index,
                          "section_model": model,
                          "dis": disList[curDis],
                          "sectionList": saleList,
                        });
                  },
                ),
              ],
            )),
      ],
    );
  }

  _getSection(int i) {
    return saleList[i].productList!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
            child: GridView.count(
                padding: const EdgeInsetsDirectional.only(top: 5),
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 0.8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  saleList[i].productList!.length < 6
                      ? saleList[i].productList!.length
                      : 6,
                  (index) {
                    return sectionItem(i, index, index % 2 == 0 ? true : false);
                  },
                )),
          )
        : const SizedBox.shrink();
  }

  Widget productItem(int index, bool pad) {
    if (productList.length > index) {
      String? offPer;
      double price =
          double.parse(productList[index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(productList[index].prVarientList![0].price!);
      } else {
        double off =
            double.parse(productList[index].prVarientList![0].price!) - price;
        offPer = ((off * 100) /
                double.parse(productList[index].prVarientList![0].price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.5;

      return Card(
        elevation: 0.0,
        margin: const EdgeInsetsDirectional.only(bottom: 2, end: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5)),
                          child: Hero(
                              transitionOnUserGestures: true,
                              tag: "$saleHero$index${productList[index].id}0",
                              child: networkImageCommon(
                                  productList[index].image!, width, false,
                                  height: double.maxFinite,
                                  width: double.maxFinite)
                              /*CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 150),
                              imageUrl: productList[index].image!,
                              height: double.maxFinite,
                              width: double.maxFinite,
                              fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                              errorWidget: (context, error, stackTrace) =>
                                  erroWidget(double.maxFinite),
                              placeholder: (context,url) {return placeHolder(width);},
                            ),*/
                              )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 8.0,
                  top: 5,
                ),
                child: Text(
                  productList[index].name!,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 8.0,
                    top: 1,
                  ),
                  child: Text('${getPriceFormat(context, price)!} ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11))),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 8.0, bottom: 8, top: 1),
                child: double.parse(
                            productList[index].prVarientList![0].disPrice!) !=
                        0
                    ? Row(
                        children: <Widget>[
                          Text(
                            double.parse(productList[index]
                                        .prVarientList![0]
                                        .disPrice!) !=
                                    0
                                ? getPriceFormat(
                                    context,
                                    double.parse(productList[index]
                                        .prVarientList![0]
                                        .price!))!
                                : "",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.5)),
                          ),
                          Flexible(
                            child: Text(
                                " | " "-${productList[index].calDisPer}%",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                        color: colors.primary,
                                        letterSpacing: 0)),
                          ),
                        ],
                      )
                    : Container(
                        height: 5,
                      ),
              )
            ],
          ),
          onTap: () {
            Product model = productList[index];
            currentHero = saleHero;

            // Navigator.push(
            //   context,
            //   PageRouteBuilder(pageBuilder: (_, __, ___) => ProductDetail()),
            // );

            Navigator.pushNamed(context, Routers.productDetails, arguments: {
              "id": model.id!,
              "secPos": 0,
              "index": index,
              "list": false
            });
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget sectionItem(int secPos, int index, bool pad) {
    if (saleList[secPos].productList!.length > index) {
      String? offPer;
      double price = double.parse(
          saleList[secPos].productList![index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(
            saleList[secPos].productList![index].prVarientList![0].price!);
      } else {
        double off = double.parse(
                saleList[secPos].productList![index].prVarientList![0].price!) -
            price;
        offPer = ((off * 100) /
                double.parse(saleList[secPos]
                    .productList![index]
                    .prVarientList![0]
                    .price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.5;

      return Card(
        elevation: 0.0,
        margin: const EdgeInsetsDirectional.only(bottom: 2, end: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5)),
                          child: Hero(
                              transitionOnUserGestures: true,
                              tag:
                                  "$saleHero$index${saleList[secPos].productList![index].id}0",
                              child: networkImageCommon(
                                  saleList[secPos].productList![index].image!,
                                  width,
                                  false,
                                  height: double.maxFinite,
                                  width: double.maxFinite)
                              /*CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 150),
                              imageUrl:
                                  saleList[secPos].productList![index].image!,
                              height: double.maxFinite,
                              width: double.maxFinite,
                              fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                              errorWidget: (context, error, stackTrace) =>
                                  erroWidget(double.maxFinite),
                              placeholder: (context,url) {return placeHolder(width);},
                            ),*/
                              )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 8.0,
                  top: 5,
                ),
                child: Text(
                  saleList[secPos].productList![index].name!,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 8.0, top: 1.0),
                  child: Text('${getPriceFormat(context, price)!} ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11))),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 8.0, bottom: 8, top: 1),
                child: double.parse(saleList[secPos]
                            .productList![index]
                            .prVarientList![0]
                            .disPrice!) !=
                        0
                    ? Row(
                        children: <Widget>[
                          Text(
                            double.parse(saleList[secPos]
                                        .productList![index]
                                        .prVarientList![0]
                                        .disPrice!) !=
                                    0
                                ? getPriceFormat(
                                    context,
                                    double.parse(saleList[secPos]
                                        .productList![index]
                                        .prVarientList![0]
                                        .price!))!
                                : "",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.5)),
                          ),
                          Flexible(
                            child: Text(" | " "-$offPer%",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                        color: colors.primary,
                                        letterSpacing: 0)),
                          ),
                        ],
                      )
                    : Container(
                        height: 5,
                      ),
              )
            ],
          ),
          onTap: () {
            Product model = saleList[secPos].productList![index];
            currentHero = saleHero;

            Navigator.pushNamed(context, Routers.productDetails, arguments: {
              "id": model.id!,
              "secPos": secPos,
              "index": index,
              "list": false
            });
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  _section() {
    return _loading
        ? saleShimmer(6)
        : ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: saleList.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _singleSection(index);
            },
          );
  }

  saleShimmer(int length) {
    return SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.simmerBase,
            highlightColor: Theme.of(context).colorScheme.simmerHigh,
            child: GridView.count(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                crossAxisCount: length == 4 ? 2 : 3,
                shrinkWrap: true,
                childAspectRatio: 1.0,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                children: List.generate(
                  length,
                  (index) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Theme.of(context).colorScheme.white,
                    );
                  },
                ))));
  }

  _product() {
    return _productLoading
        ? saleShimmer(4)
        : productList.isNotEmpty
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                child: Column(
                  children: [
                    GridView.count(
                        padding: const EdgeInsetsDirectional.only(top: 5),
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        childAspectRatio: 1.2,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(
                          productList.length < 4 ? productList.length : 4,
                          (index) {
                            return productItem(
                                index, index % 2 == 0 ? true : false);
                          },
                        )),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: Theme.of(context).colorScheme.white,
                      ),
                      child: ListTile(
                        title: Text(
                          getTranslated(context, 'seeAll')!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: colors.primary),
                        ),
                        trailing: const Icon(
                          Icons.keyboard_arrow_right,
                          color: colors.primary,
                        ),
                        onTap: () {
                          // Navigator.push(
                          //     context,
                          //     CupertinoPageRoute(
                          //       builder: (context) => ProductListScreen(
                          //         name: getTranslated(context, 'OFFER'),
                          //         id: '',
                          //         tag: false,
                          //         dis: disList[curDis],
                          //         fromSeller: false,
                          //       ),
                          //     ));

                          Navigator.pushNamed(
                              context, Routers.productListScreen,
                              arguments: {
                                "name": getTranslated(context, 'OFFER'),
                                "id": '',
                                "tag": false,
                                "dis": disList[curDis],
                                "fromSeller": false,
                              });
                        },
                      ),
                    ),
                  ],
                ))
            : const SizedBox.shrink();
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Future<void> callApi() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      getProduct("0");
      getSection();
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
    return;
  }

  void getProduct(String top) {
    try {
      Map parameter = {TOP_RETAED: top, DISCOUNT: disList[curDis].toString()};

      if (context.read<UserProvider>().userId != "") {
        parameter[USER_ID] = context.read<UserProvider>().userId;
      }

      apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          total = int.parse(getdata["total"]);

          tempList.clear();

          var data = getdata["data"];
          tempList =
              (data as List).map((data) => Product.fromJson(data)).toList();

          if (getdata.containsKey(TAG)) {
            List<String> tempList = List<String>.from(getdata[TAG]);
            if (tempList.isNotEmpty) tagList = tempList;
          }

          getAvailVarient();
        } else {
          if (msg != "Products Not Found !") setSnackbar(msg!, context);
        }

        setState(() {
          _productLoading = false;
        });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        setState(() {
          _productLoading = false;
        });
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  void getAvailVarient() {
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
    productList.clear();
    productList.addAll(tempList);
  }

  void getSection() {
    try {
      Map parameter = {
        PRODUCT_LIMIT: "6",
        PRODUCT_OFFSET: "0",
        DISCOUNT: disList[curDis].toString()
      };

      if (context.read<UserProvider>().userId != "") {
        parameter[USER_ID] = context.read<UserProvider>().userId;
      }
      String curPin = context.read<UserProvider>().curPincode;
      if (curPin != '') parameter[ZIPCODE] = curPin;

      apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        saleList.clear();
        if (!error) {
          var data = getdata["data"];

          saleList = (data as List)
              .map((data) => SectionModel.fromJson(data))
              .toList();
        } else {
          if (curPin != '') context.read<UserProvider>().setPincode('');
          setSnackbar(msg!, context);
        }
        setState(() {
          _loading = false;
        });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        setState(() {
          _loading = false;
        });
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Widget homeShimmer() {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
            child: Column(
          children: [
            catLoading(),
            sliderLoading(),
            sectionLoading(),
          ],
        )),
      ),
    );
  }

  Widget sliderLoading() {
    double width = deviceWidth!;
    double height = width / 2;
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: height,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget deliverLoading() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((_) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            shape: BoxShape.circle,
                          ),
                          width: 50.0,
                          height: 50.0,
                        ))
                    .toList()),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
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
                  callApi();
                } else {
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  sectionLoading() {
    return Column(
        children: [0, 1, 2, 3, 4]
            .map((_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 40),
                                decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.white,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20)))),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              GridView.count(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  childAspectRatio: 1.0,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                  children: List.generate(
                                    4,
                                    (index) {
                                      return Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color:
                                            Theme.of(context).colorScheme.white,
                                      );
                                    },
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    sliderLoading()
                  ],
                ))
            .toList());
  }

  discountRow() {
    return Container(
        height: 50,
        color: Theme.of(context).colorScheme.white,
        child: Center(
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: disList.length,
            itemBuilder: (context, index) {
              return InkWell(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    curDis == index
                        ? SvgPicture.asset(
                            '${imagePath}tap.svg',
                            colorFilter: const ColorFilter.mode(
                                colors.primary, BlendMode.srcIn),
                          )
                        : const SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${disList[index]}%",
                        style: TextStyle(
                            color: curDis == index
                                ? Theme.of(context).colorScheme.white
                                : Theme.of(context).colorScheme.fontColor),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    curDis = index;
                    _loading = true;
                    _productLoading = true;
                  });
                  getSection();
                  getProduct("0");
                },
              );
            },
          ),
        ));
  }
}
