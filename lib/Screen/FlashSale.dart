import 'dart:async';

import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/FlashSaleModel.dart';
import 'package:eshop/Provider/FlashSaleProvider.dart';
import 'package:eshop/Provider/OfferImagesProvider.dart';
import 'package:eshop/Screen/FlashSaleProductList.dart';
import 'package:eshop/Screen/MultipleTimer.dart';
import 'package:eshop/ui/widgets/AppBtn.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Model/OfferImages.dart';
import '../Model/Section_Model.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import 'HomePage.dart';

class FlashSale extends StatefulWidget {
  const FlashSale({Key? key}) : super(key: key);

  @override
  _FlashSaleState createState() => _FlashSaleState();
}

class _FlashSaleState extends State<FlashSale> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  // List<FlashSaleModel> saleList = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _loading = true;
  final ScrollController _scrollBottomBarController = ScrollController();
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateSlider());
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
                    child: Column(children: [_section(), _offerImagesList()])))
            : noInternet(context));
  }

  Future<void> _refresh() {
    setState(() {
      _loading = true;
    });
    return callApi();
  }

  _singleSection(int index, List<FlashSaleModel> saleList) {
    return saleList[index].products!.product!.isNotEmpty
        ? InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => FlashProductList(
                      index: index,
                      // model: model,
                      //serverTime: serverDate.toString(),
                    ),
                  ));
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).cardColor),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _getHeading(
                              saleList[index].title ?? "", index, saleList),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: networkImageCommon(
                                  saleList[index].image!, 180, true,
                                  height: 180,
                                  width: double
                                      .infinity) /*CachedNetworkImage(
                              imageUrl: saleList[index].image!,
                              placeholder: (BuildContext context, url) {
                                return Image.asset(
                                  "assets/images/sliderph.png",
                                );
                              },
                              height: 180,
                              width: double.infinity,
                              fit: extendImg ? BoxFit.fill : BoxFit.contain,
                              errorWidget: (context, error, stackTrace) =>
                                  erroWidget(180),
                            ),*/
                              ),
                          /* Container(
                            color: Colors.red,
                            height: 150,
                            width: double.infinity,
                          ),*/
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  _getHeading(String title, int index, List<FlashSaleModel> saleList) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsetsDirectional.only(
              bottom: 3,
              top: 3,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              Text(
                saleList[index].shortDescription ?? "",
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ]),
          ),
        ),
        if (saleList[index].status == "1" || saleList[index].status == "2")
          Align(
            alignment: Alignment.centerRight,
            child: MultipleTimer(
              startDateModel: saleList[index].startDate!,
              endDateModel: saleList[index].endDate!,
              serverDateModel: saleList[index].serverTime!,
              id: saleList[index].id!,
              newtimeDiff: saleList[index].timeDiff!,
              from: 1,
            ),
          ),
        //saleList[index].timer!,
      ]),
    );
  }

  _offerImagesList() {
    return _loading
        ? saleShimmer()
        : Selector<OfferImagesProvider, List<SliderImages>>(
            builder: (context, data, child) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 20),
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: data.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (data[index].style == "default" ||
                        data[index].style == "style_1") {
                      context
                          .read<OfferImagesProvider>()
                          .setOfferCurSlider(index);
                    }
                    return imageSliderWidget(index, data);
                  },
                ),
              );
            },
            selector: (_, offerProvider) => offerProvider.offerList);
  }

  onOfferImageClick(int i, List<SliderImages> data, int index) async {
    if (data[i].offerImages![index].type == "products") {
      String id = data[i].offerImages![index].data![0].id!;
      currentHero = homeHero;

      Navigator.pushNamed(context, Routers.productDetails, arguments: {
        "secPos": 0,
        "index": 0,
        "list": true,
        "id": id,
      });
    } else if (data[i].offerImages![index].type == "categories") {
      Product item = data[i].offerImages![index].data!;
      if (item.subList == null || item.subList!.isEmpty) {
        Navigator.pushNamed(context, Routers.productListScreen, arguments: {
          "name": item.name,
          "id": item.id,
          "tag": false,
          "fromSeller": false,
          "maxDis": data[i].offerImages![index].maxDiscount,
          "minDis": data[i].offerImages![index].minDiscount,
        });
      } else {
        // Navigator.push(
        //     context,
        //     CupertinoPageRoute(
        //       builder: (context) => SubCategoryScreen(
        //
        //       ),
        //     ));
        Navigator.pushNamed(context, Routers.subCategoryScreen, arguments: {
          "title": item.name!,
          "subList": item.subList,
          "maxDis": data[i].offerImages![index].maxDiscount,
          "minDis": data[i].offerImages![index].minDiscount,
        });
      }
    } else if (data[i].offerImages![index].type == "all_products") {
      // Navigator.push(
      //     context,
      //     CupertinoPageRoute(
      //       builder: (context) => ProductListScreen(
      //         tag: false,
      //         fromSeller: false,
      //         maxDis: data[i].offerImages![index].maxDiscount,
      //         minDis: data[i].offerImages![index].minDiscount,
      //       ),
      //     ));
      Navigator.pushNamed(context, Routers.productListScreen, arguments: {
        "tag": false,
        "fromSeller": false,
        "maxDis": data[i].offerImages![index].maxDiscount,
        "minDis": data[i].offerImages![index].minDiscount,
      });
    } else if (data[i].offerImages![index].type == "brand") {
      // Navigator.push(
      //     context,
      //     CupertinoPageRoute(
      //       builder: (context) => ProductListScreen(),
      //     ));
      Navigator.pushNamed(context, Routers.productListScreen, arguments: {
        "tag": false,
        "fromSeller": false,
        "maxDis": data[i].offerImages![index].maxDiscount,
        "minDis": data[i].offerImages![index].minDiscount,
        "brandId": data[i].offerImages![index].typeId,
        "name": data[i].offerImages![index].data![0].name!,
      });
    } else if (data[i].offerImages![index].type == "offer_url") {
      String url = data[i].offerImages![index].urlLink.toString();
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      } catch (e) {
        throw 'Something went wrong';
      }
    }
  }

  Widget imageSliderWidget(int i, List<SliderImages> data) {
    // double height = deviceWidth! / 2;

    return data[i].style == "default" || data[i].style == "style_1"
        ? Container(
            height: deviceWidth! / 1.7,
            padding: const EdgeInsetsDirectional.only(top: 20.0),
            child: PageView.builder(
              itemCount: data[i].offerImages!.length,
              scrollDirection: Axis.horizontal,
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              onPageChanged: (index) {
                context.read<OfferImagesProvider>().setCurSlider(index);
              },
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                    onTap: data[i].offerImages![index].type != "default"
                        ? () {
                            onOfferImageClick(i, data, index);
                          }
                        : null,
                    child: networkImageCommon(
                        data[i].offerImages![index].image!,
                        deviceWidth! / 1.7,
                        true) /*CachedNetworkImage(
                    imageUrl: data[i].offerImages![index].image!,
                    placeholder: (BuildContext context, url) {
                      return Image.asset(
                        "assets/images/sliderph.png",
                      );
                    },
                    // width: deviceWidth,
                    fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                    errorWidget: (context, error, stackTrace) =>
                        erroWidget(deviceWidth! / 1.7),
                  ),*/
                    );
              },
            ),
          )
        /*  : data[i].style == "style_1"
            ? GridView.count(
                padding:
                    const EdgeInsetsDirectional.only(top: 10, start: 7, end: 7),
                crossAxisCount: 2,
                childAspectRatio: 2 / 1.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(data[i].offerImages!.length, (index) {
                  return InkWell(
                    onTap: data[i].offerImages![index].type != "default"
                        ? () {
                            onOfferImageClick(i, data, index);
                          }
                        : null,
                    child: Padding(
                      padding: EdgeInsetsDirectional.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: data[i].offerImages![index].image!,
                          placeholder: (BuildContext context, url) {
                            return Image.asset(
                              "assets/images/sliderph.png",
                            );
                          },
                          // width: deviceWidth,
                          fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(deviceWidth! / 2),
                        ),
                      ),
                    ),
                  );
                })) */
        : data[i].style == "style_2"
            ? GridView.count(
                padding:
                    const EdgeInsetsDirectional.only(top: 10, start: 7, end: 7),
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 0.7,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(data[i].offerImages!.length, (index) {
                  return InkWell(
                    onTap: data[i].offerImages![index].type != "default"
                        ? () {
                            onOfferImageClick(i, data, index);
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(7),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: networkImageCommon(
                              data[i].offerImages![index].image!,
                              deviceWidth! / 2,
                              true) /*CachedNetworkImage(
                          imageUrl: data[i].offerImages![index].image!,
                          placeholder: (BuildContext context, url) {
                            return Image.asset(
                              "assets/images/sliderph.png",
                            );
                          },
                          // width: deviceWidth,
                          fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(deviceWidth! / 2),
                        ),*/
                          ),
                    ),
                  );
                }))
            : data[i].style == "style_3"
                ? SizedBox(
                    // padding: EdgeInsets.only(top: 10.0),
                    height: deviceWidth! / 1.9,
                    child: ListView.builder(
                        padding: const EdgeInsetsDirectional.only(
                            top: 10, start: 7, end: 7),
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: data[i].offerImages!.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: data[i].offerImages![index].type != "default"
                                ? () {
                                    onOfferImageClick(i, data, index);
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.all(7),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: networkImageCommon(
                                      data[i].offerImages![index].image!,
                                      deviceWidth! / 2,
                                      true,
                                      width: deviceWidth! / 2.85)
                                  /*CachedNetworkImage(
                                  imageUrl: data[i].offerImages![index].image!,
                                  placeholder: (BuildContext context, url) {
                                    return Image.asset(
                                      "assets/images/sliderph.png",
                                    );
                                  },
                                  width: deviceWidth! / 2.85,
                                  // width: deviceWidth,
                                  fit: extendImg
                                      ? BoxFit.fill
                                      : BoxFit.fitHeight,
                                  errorWidget: (context, error, stackTrace) =>
                                      erroWidget(deviceWidth! / 2),
                                ),*/
                                  ),
                            ),
                          );
                        }),
                  )
                : data[i].style == "style_4"
                    ? SizedBox(
                        // padding: EdgeInsets.only(top: 10.0),
                        height: deviceWidth! / 1.5,
                        child: ListView.builder(
                            padding: const EdgeInsetsDirectional.only(
                                top: 10, start: 7, end: 7),
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: data[i].offerImages!.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: data[i].offerImages![index].type !=
                                        "default"
                                    ? () {
                                        onOfferImageClick(i, data, index);
                                      }
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.all(7),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: networkImageCommon(
                                          data[i].offerImages![index].image!,
                                          deviceWidth! / 2,
                                          true,
                                          width: deviceWidth! / 2.2)
                                      /*CachedNetworkImage(
                                      imageUrl:
                                          data[i].offerImages![index].image!,
                                      placeholder: (BuildContext context, url) {
                                        return Image.asset(
                                          "assets/images/sliderph.png",
                                        );
                                      },
                                      width: deviceWidth! / 2.2,
                                      // width: deviceWidth,
                                      fit: extendImg
                                          ? BoxFit.fill
                                          : BoxFit.fitHeight,
                                      errorWidget:
                                          (context, error, stackTrace) =>
                                              erroWidget(deviceWidth! / 2),
                                    ),*/
                                      ),
                                ),
                              );
                            }),
                      )
                    : const SizedBox();
  }

  void _animateSlider() {
    if (mounted) {
      Future.delayed(const Duration(seconds: 4)).then((_) {
        int nextPage = _controller.hasClients
            ? _controller.page!.round() + 1
            : _controller.initialPage;

        if (mounted) {
          if (nextPage ==
              context
                  .read<OfferImagesProvider>()
                  .offerList[context.read<OfferImagesProvider>().curOfferIndex]
                  .offerImages!
                  .length) {
            nextPage = 0;
          }
        }
        if (_controller.hasClients) {
          _controller
              .animateToPage(nextPage,
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.linear)
              .then((_) {
            _animateSlider();
          });
        }
      });
    }
  }

  _section() {
    return _loading
        ? saleShimmer()
        : Consumer<FlashSaleProvider>(
            builder: (context, data, child) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(start: 14, end: 14),
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: data.saleList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _singleSection(index, data.saleList);
                  },
                ),
              );
            },
          );
  }

  saleShimmer() {
    return SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.simmerBase,
            highlightColor: Theme.of(context).colorScheme.simmerHigh,
            child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: List.generate(
                  3,
                  (index) {
                    return Container(
                      margin: const EdgeInsetsDirectional.all(13),
                      width: double.infinity,
                      height: deviceWidth! / 1.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.white,
                      ),
                    );
                  },
                ))));
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
      getFlashSale();
      getOfferImages();
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
    return;
  }

  void getFlashSale() {
    try {
      apiBaseHelper.postAPICall(getFlashSaleApi, {}).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (mounted) {
          context.read<FlashSaleProvider>().removeSaleList();
        }
        if (!error) {
          var data = getdata["data"];

          List<FlashSaleModel> saleList = (data as List)
              .map((data) => FlashSaleModel.fromJson(data))
              .toList();
          context.read<FlashSaleProvider>().setSaleList(saleList);
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

  void getOfferImages() {
    if (!mounted) {
      // The widget is no longer mounted, so exit early.
      return;
    }

    try {
      apiBaseHelper.postAPICall(getOfferImageApi, {}).then((getdata) {
        bool error = getdata["error"];
        if (mounted) {
          // Check again if the widget is still mounted.
          context.read<OfferImagesProvider>().removeOfferList();
        }
        if (!error) {
          var data = getdata["slider_images"];

          List<SliderImages> offerList = (data as List)
              .map((data) => SliderImages.fromJson(data))
              .toList();

          if (mounted) {
            // Check if the widget is still mounted before updating state.
            context.read<OfferImagesProvider>().setOfferList(offerList);
          }
        }
        if (mounted) {
          // Check if the widget is still mounted before updating state.
          setState(() {
            _loading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          // Check if the widget is still mounted before showing a snackbar.
          setSnackbar(error.toString(), context);
          setState(() {
            _loading = false;
          });
        }
      });
    } on FormatException catch (e) {
      if (mounted) {
        // Check if the widget is still mounted before showing a snackbar.
        setSnackbar(e.message, context);
      }
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
              //context.read<HomeProvider>().setCatLoading(true);
              // context.read<HomeProvider>().setSecLoading(true);
              //context.read<HomeProvider>().setSliderLoading(true);
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
}
