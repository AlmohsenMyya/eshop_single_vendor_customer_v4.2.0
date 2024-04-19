import 'dart:async';

import 'package:collection/src/iterable_extensions.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/SqliteData.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/FavoriteProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/app/routes.dart';
import 'package:eshop/cubits/fetch_featured_sections_cubit.dart';
import 'package:eshop/ui/widgets/Slideanimation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/SimBtn.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class SectionListScreen extends StatefulWidget {
  final int? index;
  SectionModel? section_model;
  List<Product>? productList;
  final int from;
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SectionListScreen(
          index: arguments?['index'],
          section_model: arguments?['section_model'],
          from: arguments?['from'],
          productList: arguments?['productList'],
        );
      },
    );
  }

  SectionListScreen(
      {Key? key,
      this.index,
      this.section_model,
      required this.from,
      this.productList})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateSection();
}

class StateSection extends State<SectionListScreen>
    with TickerProviderStateMixin {
  bool isLoadingmore = true, _isLoading = true, _isNetworkAvail = true;
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  RangeValues? _currentRangeValues;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String sortBy = 'p.id', orderBy = "DESC";

  late List<String> attsubList;
  late List<String> attListId;
  String? filter = "", selId = "";
  bool listType = true, _isProgress = false;
  int? total = 0, offset;
  final List<TextEditingController> _controller = [];
  late UserProvider userProvidser;
  String minPrice = "0", maxPrice = "0";
  ChoiceChip? choiceChip;
  var db = DatabaseHelper();
  AnimationController? _animationController;
  AnimationController? _animationController1;
  bool isFilterClear = false;

  @override
  void initState() {
    super.initState();
    widget.section_model!.productList!.clear();
    widget.section_model!.offset = widget.section_model!.productList!.length;

    widget.section_model!.selectedId = [];
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _animationController1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    if (widget.from == 1) {
      getSection("0");
      controller.addListener(_scrollListener);
    } else {
      _isLoading = false;
    }

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
    buttonController!.dispose();
    _animationController1!.dispose();
    _animationController!.dispose();
    for (int i = 0; i < _controller.length; i++) {
      _controller[i].dispose();
    }
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  void getAvailVarient(List<Product> productList) {
    for (int j = 0; j < productList.length; j++) {
      if (productList[j].stockType == "2") {
        for (int i = 0; i < productList[j].prVarientList!.length; i++) {
          if (productList[j].prVarientList![i].availability == "1") {
            productList[j].selVarient = i;

            break;
          }
        }
      }
    }
    widget.section_model!.productList!.addAll(productList);
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

  Future<void> _refresh() {
    if (widget.from == 1) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          isLoadingmore = true;
          widget.section_model!.offset = 0;
          widget.section_model!.totalItem = 0;
          widget.section_model!.selectedId = [];
          selId = '';
        });
      }

      total = 0;
      offset = 0;
      widget.section_model!.productList!.clear();
      return getSection("0");
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    }
    return Future.delayed(
      const Duration(seconds: 1),
      () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    userProvidser = Provider.of<UserProvider>(context);
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    List<SectionModel> featuredSectionList =
        context.watch<FetchFeaturedSectionsCubit>().getFeaturedSections();
    return Scaffold(
      // key: scaffoldKey,
      appBar: getAppBar(
        widget.from == 1
            ? featuredSectionList[widget.index!].title!
            : "You might also like",
        context,
      ),
      body: _isNetworkAvail
          ? RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: _isLoading
                  ? shimmer(context)
                  : Column(
                      children: [
                        if (widget.from == 1) filterOptions(),
                        Expanded(
                          child: Stack(
                            children: <Widget>[
                              widget.from == 1
                                  ? listType
                                      ? ListView.builder(
                                          controller: controller,
                                          itemCount:
                                              (widget.section_model!.offset! <
                                                      widget.section_model!
                                                          .totalItem!)
                                                  ? widget.section_model!
                                                          .productList!.length +
                                                      1
                                                  : widget.section_model!
                                                      .productList!.length,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return (index ==
                                                        widget
                                                            .section_model!
                                                            .productList!
                                                            .length &&
                                                    isLoadingmore)
                                                ? singleItemSimmer(context)
                                                : listItem(
                                                    index,
                                                    widget.section_model!
                                                        .productList!.length);
                                          },
                                        )
                                      : GridView.count(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                            top: 5,
                                          ),
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.6,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          controller: controller,
                                          children: List.generate(
                                            (widget.section_model!.offset! <
                                                    widget.section_model!
                                                        .totalItem!)
                                                ? widget.section_model!
                                                        .productList!.length +
                                                    1
                                                : widget.section_model!
                                                    .productList!.length,
                                            (index) {
                                              return (index ==
                                                          widget
                                                              .section_model!
                                                              .productList!
                                                              .length &&
                                                      isLoadingmore)
                                                  ? simmerSingleProduct(context)
                                                  : productItem(index);
                                            },
                                          ))
                                  : ListView.builder(
                                      controller: controller,
                                      itemCount: widget.productList!.length,
                                      shrinkWrap: true,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return listItem(
                                            index, widget.productList!.length);
                                      },
                                    ),
                              showCircularProgress(_isProgress, colors.primary),
                            ],
                          ),
                        ),
                      ],
                    ))
          : noInternet(context),
    );
  }

  filterOptions() {
    return Container(
        color: Theme.of(context).colorScheme.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          color: Theme.of(context).colorScheme.gray,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                  onPressed: filterDialog,
                  icon: const Icon(
                    Icons.filter_list,
                    color: colors.primary,
                  ),
                  label: Text(
                    getTranslated(context, 'FILTER')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                  )),
              TextButton.icon(
                  onPressed: sortDialog,
                  icon: const Icon(
                    Icons.swap_vert,
                    color: colors.primary,
                  ),
                  label: Text(
                    getTranslated(context, 'SORT_BY')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                  )),
              InkWell(
                child: Icon(
                  listType ? Icons.grid_view : Icons.list,
                  color: colors.primary,
                ),
                onTap: () {
                  context
                          .read<FetchFeaturedSectionsCubit>()
                          .getFeaturedSections()
                          .isNotEmpty
                      ? setState(() {
                          _animationController!.reverse();
                          _animationController1!.reverse();
                          listType = !listType;
                        })
                      : null;
                },
              ),
            ],
          ),
        ));
  }

  Widget listItem(int index, int len) {
    if (index < len) {
      Product model;
      if (widget.from == 1) {
        model = widget.section_model!.productList![index];
      } else {
        model = widget.productList![index];
      }

      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }

      double off = (double.parse(
                  model.prVarientList![model.selVarient!].price!) -
              double.parse(model.prVarientList![model.selVarient!].disPrice!))
          .toDouble();
      off = off *
          100 /
          double.parse(model.prVarientList![model.selVarient!].price!);

      List att = [], val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }
      if (_controller.length < index + 1) {
        _controller.add(TextEditingController());
      }

      return SlideAnimation(
        position: index,
        itemCount: len,
        slideDirection: SlideDirection.fromBottom,
        animationController: _animationController,
        child: Consumer<CartProvider>(
          builder: (context, data, child) {
            SectionModel? tempId = data.cartList.firstWhereOrNull((cp) =>
                cp.id == model.id &&
                cp.varientId == model.prVarientList![model.selVarient!].id!);
            if (tempId != null) {
              _controller[index].text = tempId.qty!;
            } else {
              _controller[index].text = "0";
            }

            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Card(
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Hero(
                                tag: "$secHero$index${model.id}${widget.index}",
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomLeft: Radius.circular(10)),
                                    child: Stack(
                                      children: [
                                        networkImageCommon(
                                            model.image!, 125, false,
                                            height: 125, width: 110),
                                        /*CachedNetworkImage(
                                            imageUrl: model.image!,
                                            height: 125.0,
                                            width: 110.0,
                                            placeholder: (context, url) {
                                              return placeHolder(125);
                                            },
                                            fit: extendImg
                                                ? BoxFit.fill
                                                : BoxFit.contain,
                                            errorWidget:
                                                (context, error, stackTrace) =>
                                                    erroWidget(125),
                                          ),*/
                                        model.availability == "0"
                                            ? Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .white70,
                                                width: 110,
                                                padding:
                                                    const EdgeInsets.all(2),
                                                height: 125,
                                                child: Center(
                                                  child: Text(
                                                      getTranslated(context,
                                                          'OUT_OF_STOCK_LBL')!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall!
                                                          .copyWith(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        off != 0 &&
                                                model
                                                        .prVarientList![
                                                            model.selVarient!]
                                                        .disPrice! !=
                                                    "0"
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  color: colors.red,
                                                ),
                                                margin: const EdgeInsets.all(5),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: Text(
                                                    model.isSalesOn == "1"
                                                        ? double.parse(
                                                                model.saleDis!)
                                                            .toStringAsFixed(2)
                                                        : "${off.toStringAsFixed(2)}%",
                                                    style: const TextStyle(
                                                        color: colors.whiteTemp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 9),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ],
                                    )),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        model.name!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      model.prVarientList![model.selVarient!]
                                                      .attr_name !=
                                                  null &&
                                              model
                                                  .prVarientList![
                                                      model.selVarient!]
                                                  .attr_name!
                                                  .isNotEmpty
                                          ? ListView.builder(
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              shrinkWrap: true,
                                              itemCount: att.length >= 2
                                                  ? 2
                                                  : att.length,
                                              itemBuilder: (context, index) {
                                                return Row(children: [
                                                  Flexible(
                                                    child: Text(
                                                      att[index].trim() + ":",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall!
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .lightBlack),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .only(start: 5.0),
                                                    child: Text(
                                                      val[index],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall!
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .lightBlack,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                  )
                                                ]);
                                              })
                                          : const SizedBox.shrink(),
                                      model.noOfRating! != "0"
                                          ? Row(
                                              children: [
                                                RatingBarIndicator(
                                                  rating: double.parse(
                                                      model.rating!),
                                                  itemBuilder:
                                                      (context, index) =>
                                                          const Icon(
                                                    Icons.star_rate_rounded,
                                                    color: Colors.amber,
                                                  ),
                                                  unratedColor: Colors.grey
                                                      .withOpacity(0.5),
                                                  itemCount: 5,
                                                  itemSize: 18.0,
                                                  direction: Axis.horizontal,
                                                ),
                                                Text(
                                                  " (${model.noOfRating!})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                )
                                              ],
                                            )
                                          : const SizedBox.shrink(),
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
                                                  .titleSmall!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          Text(
                                            double.parse(model
                                                        .prVarientList![
                                                            model.selVarient!]
                                                        .disPrice!) !=
                                                    0
                                                ? getPriceFormat(
                                                    context,
                                                    double.parse(model
                                                        .prVarientList![
                                                            model.selVarient!]
                                                        .price!))!
                                                : "",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall!
                                                .copyWith(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    letterSpacing: 0),
                                          ),
                                        ],
                                      ),
                                      _controller[index].text != "0"
                                          ? Row(
                                              children: [
                                                model.availability == "0"
                                                    ? const SizedBox.shrink()
                                                    : cartBtnList
                                                        ? Row(
                                                            children: <Widget>[
                                                              Row(
                                                                children: <Widget>[
                                                                  InkWell(
                                                                    child: Card(
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(50),
                                                                      ),
                                                                      child:
                                                                          const Padding(
                                                                        padding:
                                                                            EdgeInsets.all(8.0),
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .remove,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    onTap: () {
                                                                      if (_isProgress ==
                                                                              false &&
                                                                          (int.parse(_controller[index].text)) >
                                                                              0) {
                                                                        removeFromCart(
                                                                            index);
                                                                      }
                                                                    },
                                                                  ),
                                                                  SizedBox(
                                                                    width: 37,
                                                                    height: 20,
                                                                    child:
                                                                        Stack(
                                                                      children: [
                                                                        TextField(
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          readOnly:
                                                                              true,
                                                                          style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: Theme.of(context).colorScheme.fontColor),
                                                                          controller:
                                                                              _controller[index],
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            border:
                                                                                InputBorder.none,
                                                                          ),
                                                                        ),
                                                                        PopupMenuButton<
                                                                            String>(
                                                                          tooltip:
                                                                              '',
                                                                          icon:
                                                                              const Icon(
                                                                            Icons.arrow_drop_down,
                                                                            size:
                                                                                0,
                                                                          ),
                                                                          onSelected:
                                                                              (String value) {
                                                                            if (_isProgress ==
                                                                                false) {
                                                                              addToCart(index, value, 2);
                                                                            }
                                                                          },
                                                                          itemBuilder:
                                                                              (BuildContext context) {
                                                                            return model.itemsCounter!.map<PopupMenuItem<String>>((String
                                                                                value) {
                                                                              return PopupMenuItem(value: value, child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.fontColor)));
                                                                            }).toList();
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    child: Card(
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(50),
                                                                      ),
                                                                      child:
                                                                          const Padding(
                                                                        padding:
                                                                            EdgeInsets.all(8.0),
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .add,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    onTap: () {
                                                                      if (_isProgress ==
                                                                          false) {
                                                                        addToCart(
                                                                            index,
                                                                            (int.parse(_controller[index].text) + int.parse(model.qtyStepSize!)).toString(),
                                                                            2);
                                                                      }
                                                                    },
                                                                  )
                                                                ],
                                                              ),
                                                            ],
                                                          )
                                                        : const SizedBox
                                                            .shrink(),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        currentHero = secHero;

                        Navigator.pushNamed(context, Routers.productDetails,
                            arguments: {
                              "id": model.id!,
                              "secPos": widget.index,
                              "index": index,
                              "list": true,
                            });

                        // Navigator.push(
                        //   context,
                        //   PageRouteBuilder(
                        //       pageBuilder: (_, __, ___) => ProductDetail(
                        //
                        //           )),
                        // );
                      },
                    ),
                  ),
                  if (cartBtnList)
                    model.availability == "0"
                        ? const SizedBox.shrink()
                        : _controller[index].text == "0"
                            ? Positioned(
                                bottom: -15,
                                right: 45,
                                child: InkWell(
                                  onTap: () {
                                    if (_isProgress == false) {
                                      addToCart(
                                          index,
                                          (int.parse(_controller[index].text) +
                                                  int.parse(model.qtyStepSize!))
                                              .toString(),
                                          1);
                                    }
                                  },
                                  child: Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                  Positioned(
                      bottom: -15,
                      right: 0,
                      child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: model.isFavLoading!
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: colors.primary,
                                        strokeWidth: 0.7,
                                      )),
                                )
                              : Selector<FavoriteProvider, List<String?>>(
                                  builder: (context, data, child) {
                                    return InkWell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          !data.contains(model.id)
                                              ? Icons.favorite_border
                                              : Icons.favorite,
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () {
                                        if (context
                                                .read<UserProvider>()
                                                .userId !=
                                            "") {
                                          !data.contains(model.id)
                                              ? _setFav(index)
                                              : _removeFav(index);
                                        } else {
                                          if (!data.contains(model.id)) {
                                            model.isFavLoading = true;
                                            model.isFav = "1";
                                            context
                                                .read<FavoriteProvider>()
                                                .addFavItem(model);
                                            db.addAndRemoveFav(model.id!, true);
                                            model.isFavLoading = false;
                                          } else {
                                            model.isFavLoading = true;
                                            model.isFav = "0";
                                            context
                                                .read<FavoriteProvider>()
                                                .removeFavItem(model
                                                    .prVarientList![0].id!);
                                            db.addAndRemoveFav(
                                                model.id!, false);
                                            model.isFavLoading = false;
                                          }
                                          setState(() {});
                                        }
                                      },
                                    );
                                  },
                                  selector: (_, provider) => provider.favIdList,
                                )))
                ],
              ),
            );
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<void> addToCart(int index, String qty, int from) async {
    Product model;
    if (widget.from == 1) {
      model = widget.section_model!.productList![index];
    } else {
      model = widget.productList![index];
    }
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (context.read<UserProvider>().userId != "") {
        try {
          if (mounted) {
            setState(() {
              _isProgress = true;
            });
          }

          if (int.parse(qty) < model.minOrderQuntity!) {
            qty = model.minOrderQuntity.toString();

            setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
          }

          var parameter = {
            USER_ID: context.read<UserProvider>().userId,
            PRODUCT_VARIENT_ID: model.prVarientList![model.selVarient!].id,
            QTY: qty
          };

          apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];

              userProvidser.setCartCount(data['cart_count']);
              model.prVarientList![model.selVarient!].cartCount =
                  qty.toString();

              var cart = getdata["cart"];

              List<SectionModel> cartList = (cart as List)
                  .map((cart) => SectionModel.fromCart(cart))
                  .toList();
              context.read<CartProvider>().setCartlist(cartList);
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
      } else {
        setState(() {
          _isProgress = true;
        });

        if (from == 1) {
          int cartCount = await db.getTotalCartCount(context);
          if (int.parse(MAX_ITEMS!) > cartCount) {
            bool add = await db.insertCart(
                model.id!,
                model.prVarientList![model.selVarient!].id!,
                qty,
                model.productType!,
                context);
            if (add) {
              List<Product>? prList = [];
              prList.add(model);
              context.read<CartProvider>().addCartItem(SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: model.prVarientList![model.selVarient!].id!,
                    id: model.id,
                  ));
            }
          } else {
            setSnackbar(
                "In Cart maximum ${int.parse(MAX_ITEMS!)} product allowed",
                context);
          }
        } else {
          if (int.parse(qty) > int.parse(model.itemsCounter!.last)) {
            setSnackbar(
                "${getTranslated(context, 'MAXQTY')!} ${int.parse(model.itemsCounter!.last)}",
                context);
          } else {
            context.read<CartProvider>().updateCartItem(model.id!, qty,
                model.selVarient!, model.prVarientList![model.selVarient!].id!);
            db.updateCart(
                model.id!, model.prVarientList![model.selVarient!].id!, qty);
          }
        }
        setState(() {
          _isProgress = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  removeFromCart(int index) async {
    Product model;
    if (widget.from == 1) {
      model = widget.section_model!.productList![index];
    } else {
      model = widget.productList![index];
    }
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

          qty = (int.parse(_controller[index].text) -
              int.parse(model.qtyStepSize!));

          if (qty < model.minOrderQuntity!) {
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

              String? qty = data['total_quantity'];

              userProvidser.setCartCount(data['cart_count']);
              model.prVarientList![model.selVarient!].cartCount =
                  qty.toString();

              var cart = getdata["cart"];
              List<SectionModel> cartList = (cart as List)
                  .map((cart) => SectionModel.fromCart(cart))
                  .toList();
              context.read<CartProvider>().setCartlist(cartList);
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
      } else {
        setState(() {
          _isProgress = true;
        });

        int qty;

        qty = (int.parse(_controller[index].text) -
            int.parse(model.qtyStepSize!));

        if (qty < model.minOrderQuntity!) {
          qty = 0;
          context
              .read<CartProvider>()
              .removeCartItem(model.prVarientList![model.selVarient!].id!);
          db.removeCart(
              model.prVarientList![model.selVarient!].id!, model.id!, context);
        } else {
          context.read<CartProvider>().updateCartItem(model.id!, qty.toString(),
              model.selVarient!, model.prVarientList![model.selVarient!].id!);
          db.updateCart(model.id!, model.prVarientList![model.selVarient!].id!,
              qty.toString());
        }
        setState(() {
          _isProgress = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  void sortDialog() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.white,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: 19.0, bottom: 16.0),
                        child: Text(
                          getTranslated(context, 'SORT_BY')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                        )),
                  ),
                  InkWell(
                    onTap: () {
                      sortBy = '';
                      orderBy = 'DESC';

                      clearList("1");
                      Navigator.pop(context, 'option 1');
                    },
                    child: Container(
                      width: deviceWidth,
                      color: sortBy == ''
                          ? colors.primary
                          : Theme.of(context).colorScheme.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: Text(getTranslated(context, 'TOP_RATED')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color: sortBy == ''
                                      ? Theme.of(context).colorScheme.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .fontColor)),
                    ),
                  ),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'p.date_added' && orderBy == 'DESC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(getTranslated(context, 'F_NEWEST')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: sortBy == 'p.date_added' &&
                                              orderBy == 'DESC'
                                          ? Theme.of(context).colorScheme.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .fontColor))),
                      onTap: () {
                        sortBy = 'p.date_added';
                        orderBy = 'DESC';

                        clearList("0");
                        Navigator.pop(context, 'option 1');
                      }),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'p.date_added' && orderBy == 'ASC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(
                            getTranslated(context, 'F_OLDEST')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: sortBy == 'p.date_added' &&
                                            orderBy == 'ASC'
                                        ? Theme.of(context).colorScheme.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                          )),
                      onTap: () {
                        sortBy = 'p.date_added';
                        orderBy = 'ASC';

                        clearList("0");
                        Navigator.pop(context, 'option 2');
                      }),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'pv.price' && orderBy == 'ASC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(
                            getTranslated(context, 'F_LOW')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: sortBy == 'pv.price' &&
                                            orderBy == 'ASC'
                                        ? Theme.of(context).colorScheme.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                          )),
                      onTap: () {
                        sortBy = 'pv.price';
                        orderBy = 'ASC';

                        clearList("0");
                        Navigator.pop(context, 'option 3');
                      }),
                  InkWell(
                      child: Container(
                          width: deviceWidth,
                          color: sortBy == 'pv.price' && orderBy == 'DESC'
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(
                            getTranslated(context, 'F_HIGH')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: sortBy == 'pv.price' &&
                                            orderBy == 'DESC'
                                        ? Theme.of(context).colorScheme.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                          )),
                      onTap: () {
                        sortBy = 'pv.price';
                        orderBy = 'DESC';

                        clearList("0");
                        Navigator.pop(context, 'option 4');
                      }),
                ]),
          );
        });
      },
    );
  }

  void filterDialog() {
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsetsDirectional.only(top: 30.0),
                child: AppBar(
                  title: Text(
                    getTranslated(context, 'FILTER')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                  ),
                  centerTitle: true,
                  elevation: 5,
                  backgroundColor: Theme.of(context).colorScheme.white,
                  leading: Builder(builder: (BuildContext context) {
                    return Container(
                      margin: const EdgeInsets.all(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsetsDirectional.only(end: 4.0),
                          child: Icon(Icons.arrow_back_ios_rounded,
                              color: colors.primary),
                        ),
                      ),
                    );
                  }),
                )),
            Expanded(
                child: Container(
              color: Theme.of(context).colorScheme.lightWhite,
              padding: const EdgeInsetsDirectional.only(
                  start: 7.0, end: 7.0, top: 7.0),
              child: widget.section_model!.filterList != null
                  ? ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsetsDirectional.only(top: 10.0),
                      itemCount: widget.section_model!.filterList!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              SizedBox(
                                  width: deviceWidth,
                                  child: Card(
                                      elevation: 0,
                                      child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Price Range',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .lightBlack,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                              Text(
                                                '${getPriceFormat(context, _currentRangeValues!.start.roundToDouble())!} - ${getPriceFormat(context, _currentRangeValues!.end.roundToDouble())!}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .lightBlack,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ],
                                          )))),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  showValueIndicator: ShowValueIndicator.never,
                                ),
                                child: RangeSlider(
                                  values: _currentRangeValues!,
                                  min: double.parse(minPrice),
                                  max: double.parse(maxPrice),
                                  divisions: 10,
                                  labels: RangeLabels(
                                    _currentRangeValues!.start
                                        .round()
                                        .toString(),
                                    _currentRangeValues!.end.round().toString(),
                                  ),
                                  onChanged: (RangeValues values) {
                                    setState(() {
                                      _currentRangeValues = values;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          index = index - 1;

                          attsubList = widget.section_model!.filterList![index]
                              .attributeValues!
                              .split(',');

                          attListId = widget
                              .section_model!.filterList![index].attributeValId!
                              .split(',');

                          List<Widget?> chips = [];
                          List<String> att = widget.section_model!
                              .filterList![index].attributeValues!
                              .split(',');

                          List<String> attSType = widget
                              .section_model!.filterList![index].swatchType!
                              .split(',');

                          List<String> attSValue = widget
                              .section_model!.filterList![index].swatchValue!
                              .split(',');

                          for (int i = 0; i < att.length; i++) {
                            Widget itemLabel;
                            if (attSType[i] == "1") {
                              String clr = (attSValue[i].substring(1));

                              String color = "0xff$clr";

                              itemLabel = Container(
                                width: 25,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(int.parse(color))),
                              );
                            } else if (attSType[i] == "2") {
                              itemLabel = ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.network(attSValue[i],
                                      width: 80,
                                      height: 80,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              erroWidget(80)));
                            } else {
                              itemLabel = Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(att[i],
                                    style: TextStyle(
                                        color: widget.section_model!.selectedId!
                                                .contains(attListId[i])
                                            ? Theme.of(context)
                                                .colorScheme
                                                .white
                                            : Theme.of(context)
                                                .colorScheme
                                                .fontColor)),
                              );
                            }

                            choiceChip = ChoiceChip(
                              selected: widget.section_model!.selectedId!
                                  .contains(attListId[i]),
                              label: itemLabel,
                              labelPadding: const EdgeInsets.all(0),
                              selectedColor: colors.primary,
                              backgroundColor:
                                  Theme.of(context).colorScheme.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    attSType[i] == "1" ? 100 : 10),
                                side: BorderSide(
                                    color: widget.section_model!.selectedId!
                                            .contains(attListId[i])
                                        ? colors.primary
                                        : colors.black12,
                                    width: 1.5),
                              ),
                              onSelected: (bool selected) {
                                attListId = widget.section_model!
                                    .filterList![index].attributeValId!
                                    .split(',');

                                if (mounted) {
                                  setState(() {
                                    if (selected == true) {
                                      widget.section_model!.selectedId!
                                          .add(attListId[i]);
                                    } else {
                                      widget.section_model!.selectedId!
                                          .remove(attListId[i]);
                                    }
                                  });
                                }
                              },
                            );

                            chips.add(choiceChip);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: deviceWidth,
                                child: Card(
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      widget.section_model!.filterList![index]
                                          .name!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                              ),
                              chips.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Wrap(
                                        children:
                                            chips.map<Widget>((Widget? chip) {
                                          return Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: chip,
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : const SizedBox.shrink()
                            ],
                          );
                        }
                      })
                  : const SizedBox.shrink(),
            )),
            Container(
              color: Theme.of(context).colorScheme.white,
              child: Row(children: <Widget>[
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 20),
                  width: deviceWidth! * 0.4,
                  child: OutlinedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          widget.section_model!.selectedId!.clear();
                          isFilterClear = true;
                        });
                      }
                    },
                    child: Text(getTranslated(context, 'FILTER_CLEAR_LBL')!),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 20),
                  child: SimBtn(
                      width: 0.4,
                      height: 35,
                      title: getTranslated(context, 'APPLY'),
                      onBtnSelected: () {
                        if (!isFilterClear) {
                          if (widget.section_model!.selectedId!.isEmpty) {
                            selId = '';
                          } else {
                            selId = widget.section_model!.selectedId!.join(',');
                          }
                          clearList("0");
                        } else {
                          if (mounted) {
                            setState(() {
                              selId = "";
                              sortBy = 'p.id';
                              orderBy = "DESC";
                            });
                          }
                          clearList("0", clear: true);
                        }

                        Navigator.pop(context, 'Product Filter');
                      }),
                ),
              ]),
            )
          ]);
        });
      },
    );
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;
            if (widget.section_model!.offset! <
                widget.section_model!.totalItem!) getSection("0");
          });
        }
      }
    }
  }

  clearList(String top, {bool? clear}) {
    if (mounted) {
      setState(() {
        _isLoading = true;
        total = 0;
        offset = 0;
        widget.section_model!.totalItem = 0;
        widget.section_model!.offset = 0;
        widget.section_model!.productList = [];

        getSection(top, clear: clear);
      });
    }
  }

  productItem(int index) {
    if (index < widget.section_model!.productList!.length) {
      Product model = widget.section_model!.productList![index];

      double width = deviceWidth! * 0.5 - 20;
      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      List att = [], val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }

      if (_controller.length < index + 1) {
        _controller.add(TextEditingController());
      }

      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }

      double off = (double.parse(
                  model.prVarientList![model.selVarient!].price!) -
              double.parse(model.prVarientList![model.selVarient!].disPrice!))
          .toDouble();
      off = off *
          100 /
          double.parse(model.prVarientList![model.selVarient!].price!);
      return SlideAnimation(
          position: index,
          itemCount: widget.section_model!.productList!.length,
          slideDirection: SlideDirection.fromBottom,
          animationController: _animationController1,
          child: Selector<CartProvider, List<SectionModel>>(
              builder: (context, data, child) {
                SectionModel? tempId = data.firstWhereOrNull((cp) =>
                    cp.id == model.id &&
                    cp.varientId ==
                        model.prVarientList![model.selVarient!].id!);
                if (tempId != null) {
                  _controller[index].text = tempId.qty!;
                } else {
                  if (context.read<UserProvider>().userId != "") {
                    _controller[index].text =
                        model.prVarientList![model.selVarient!].cartCount!;
                  } else {
                    _controller[index].text = "0";
                  }
                }

                return Card(
                  elevation: 0,
                  child: InkWell(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                            child: Stack(
                          alignment: Alignment.bottomRight,
                          clipBehavior: Clip.none,
                          children: [
                            Hero(
                              tag:
                                  "$secHero$index${context.watch<FetchFeaturedSectionsCubit>().getFeaturedSections()[widget.index!].productList![index].id}${widget.index}",
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5)),
                                child: networkImageCommon(
                                    model.image!, width, false,
                                    height: double.maxFinite,
                                    width: double
                                        .maxFinite), /*CachedNetworkImage(
                                  imageUrl: model.image!,
                                  height: double.maxFinite,
                                  width: double.maxFinite,
                                  fadeInDuration:
                                      const Duration(milliseconds: 150),
                                  fit: extendImg ? BoxFit.fill : BoxFit.contain,
                                  errorWidget: (context, error, stackTrace) =>
                                      erroWidget(width),
                                  placeholder: (context, url) {
                                    return placeHolder(width);
                                  },
                                ),*/
                              ),
                            ),
                            model.availability == "0"
                                ? Container(
                                    constraints: const BoxConstraints.expand(),
                                    color:
                                        Theme.of(context).colorScheme.white70,
                                    width: double.maxFinite,
                                    padding: const EdgeInsets.all(2),
                                    child: Center(
                                      child: Text(
                                        getTranslated(
                                            context, 'OUT_OF_STOCK_LBL')!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            off != 0 &&
                                    model.prVarientList![model.selVarient!]
                                            .disPrice! !=
                                        "0"
                                ? Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: colors.red,
                                      ),
                                      margin: const EdgeInsets.all(5),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          model.isSalesOn == "1"
                                              ? double.parse(model.saleDis!)
                                                  .toStringAsFixed(2)
                                              : "${off.toStringAsFixed(2)}%",
                                          style: const TextStyle(
                                              color: colors.whiteTemp,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            const Divider(
                              height: 1,
                            ),
                            Positioned(
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (cartBtnList)
                                    _controller[index].text == "0"
                                        ? InkWell(
                                            onTap: () {
                                              if (_isProgress == false) {
                                                addToCart(
                                                    index,
                                                    (int.parse(_controller[
                                                                    index]
                                                                .text) +
                                                            int.parse(model
                                                                .qtyStepSize!))
                                                        .toString(),
                                                    1);
                                              }
                                            },
                                            child: Card(
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.shopping_cart_outlined,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(
                                                start: 3.0, bottom: 5, top: 3),
                                            child: model.availability == "0"
                                                ? const SizedBox.shrink()
                                                : cartBtnList
                                                    ? Row(
                                                        children: <Widget>[
                                                          InkWell(
                                                            child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child:
                                                                  const Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child: Icon(
                                                                  Icons.remove,
                                                                  size: 15,
                                                                ),
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              if (_isProgress ==
                                                                      false &&
                                                                  (int.parse(_controller[
                                                                              index]
                                                                          .text)) >
                                                                      0) {
                                                                removeFromCart(
                                                                    index);
                                                              }
                                                            },
                                                          ),
                                                          Container(
                                                            width: 37,
                                                            height: 20,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .white70,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                            ),
                                                            child: Stack(
                                                              children: [
                                                                TextField(
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  readOnly:
                                                                      true,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .fontColor),
                                                                  controller:
                                                                      _controller[
                                                                          index],
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                  ),
                                                                ),
                                                                PopupMenuButton<
                                                                    String>(
                                                                  tooltip: '',
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    size: 0,
                                                                  ),
                                                                  onSelected:
                                                                      (String
                                                                          value) {
                                                                    if (_isProgress ==
                                                                        false) {
                                                                      addToCart(
                                                                          index,
                                                                          value,
                                                                          2);
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
                                                                          value:
                                                                              value,
                                                                          child: Text(
                                                                              value,
                                                                              style: TextStyle(color: Theme.of(context).colorScheme.fontColor)));
                                                                    }).toList();
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          InkWell(
                                                            child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child:
                                                                  const Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child: Icon(
                                                                  Icons.add,
                                                                  size: 15,
                                                                ),
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              if (_isProgress ==
                                                                  false) {
                                                                addToCart(
                                                                    index,
                                                                    (int.parse(_controller[index].text) +
                                                                            int.parse(model.qtyStepSize!))
                                                                        .toString(),
                                                                    2);
                                                              }
                                                            },
                                                          )
                                                        ],
                                                      )
                                                    : const SizedBox.shrink(),
                                          ),
                                  Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: model.isFavLoading!
                                          ? const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                  height: 15,
                                                  width: 15,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: colors.primary,
                                                    strokeWidth: 0.7,
                                                  )),
                                            )
                                          : Selector<FavoriteProvider,
                                              List<String?>>(
                                              builder: (context, data, child) {
                                                return InkWell(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Icon(
                                                      !data.contains(model.id)
                                                          ? Icons
                                                              .favorite_border
                                                          : Icons.favorite,
                                                      size: 15,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    if (context
                                                            .read<
                                                                UserProvider>()
                                                            .userId !=
                                                        "") {
                                                      !data.contains(model.id)
                                                          ? _setFav(index)
                                                          : _removeFav(index);
                                                    } else {
                                                      if (!data
                                                          .contains(model.id)) {
                                                        model.isFavLoading =
                                                            true;
                                                        model.isFav = "1";
                                                        context
                                                            .read<
                                                                FavoriteProvider>()
                                                            .addFavItem(model);
                                                        db.addAndRemoveFav(
                                                            model.id!, true);
                                                        model.isFavLoading =
                                                            false;
                                                      } else {
                                                        model.isFavLoading =
                                                            true;
                                                        model.isFav = "0";
                                                        context
                                                            .read<
                                                                FavoriteProvider>()
                                                            .removeFavItem(model
                                                                .prVarientList![
                                                                    0]
                                                                .id!);
                                                        db.addAndRemoveFav(
                                                            model.id!, false);
                                                        model.isFavLoading =
                                                            false;
                                                      }
                                                      setState(() {});
                                                    }
                                                  },
                                                );
                                              },
                                              selector: (_, provider) =>
                                                  provider.favIdList,
                                            )),
                                ],
                              ),
                            ),
                          ],
                        )),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              RatingBarIndicator(
                                rating: double.parse(model.rating!),
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star_rate_rounded,
                                  color: Colors.amber,
                                ),
                                unratedColor: Colors.grey.withOpacity(0.5),
                                itemCount: 5,
                                itemSize: 12.0,
                                direction: Axis.horizontal,
                                itemPadding: const EdgeInsets.all(0),
                              ),
                              Text(
                                " (${model.noOfRating!})",
                                style: Theme.of(context).textTheme.labelSmall,
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                                model.isSalesOn == "1"
                                    ? getPriceFormat(
                                        context,
                                        double.parse(model
                                            .prVarientList![model.selVarient!]
                                            .saleFinalPrice!))!
                                    : '${getPriceFormat(context, price)!} ',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold)),
                            double.parse(model.prVarientList![model.selVarient!]
                                        .disPrice!) !=
                                    0
                                ? Flexible(
                                    child: Row(
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            double.parse(model
                                                        .prVarientList![
                                                            model.selVarient!]
                                                        .disPrice!) !=
                                                    0
                                                ? getPriceFormat(
                                                    context,
                                                    double.parse(model
                                                        .prVarientList![
                                                            model.selVarient!]
                                                        .price!))!
                                                : "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall!
                                                .copyWith(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    letterSpacing: 0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: model.prVarientList![model.selVarient!]
                                                .attr_name !=
                                            null &&
                                        model.prVarientList![model.selVarient!]
                                            .attr_name!.isNotEmpty
                                    ? ListView.builder(
                                        padding:
                                            const EdgeInsets.only(bottom: 5.0),
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount:
                                            att.length >= 2 ? 2 : att.length,
                                        itemBuilder: (context, index) {
                                          return Row(children: [
                                            Flexible(
                                              child: Text(
                                                att[index].trim() + ":",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .lightBlack),
                                              ),
                                            ),
                                            Flexible(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .only(start: 5.0),
                                                child: Text(
                                                  val[index],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .lightBlack,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          ]);
                                        })
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 5.0, bottom: 5),
                          child: Text(
                            model.name!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .lightBlack),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Product model = widget.section_model!.productList![index];
                      currentHero = secHero;

                      Navigator.pushNamed(context, Routers.productDetails,
                          arguments: {
                            "id": model.id!,
                            "secPos": widget.index,
                            "index": index,
                            "list": false,
                          });
                    },
                  ),
                );
              },
              selector: (_, provider) => provider.cartList));
    } else {
      return const SizedBox.shrink();
    }
  }

  updateSectionList() {
    if (mounted) setState(() {});
  }

  Future<void> getSection(String top, {bool? clear}) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          PRODUCT_LIMIT: perPage.toString(),
          PRODUCT_OFFSET: widget.section_model!.productList!.length.toString(),
          SEC_ID: widget.section_model!.id,
          TOP_RETAED: top,
          PSORT: sortBy,
          PORDER: orderBy,
        };
        if (context.read<UserProvider>().userId != "") {
          parameter[USER_ID] = context.read<UserProvider>().userId;
        }
        if (selId != null && selId != "") {
          parameter[ATTRIBUTE_VALUE_ID] = selId;
        }
        if (clear == null) {
          if (_currentRangeValues != null &&
              _currentRangeValues!.start.round().toString() != "0") {
            parameter[MINPRICE] = _currentRangeValues!.start.round().toString();
          }

          if (_currentRangeValues != null &&
              _currentRangeValues!.end.round().toString() != "0") {
            parameter[MAXPRICE] = _currentRangeValues!.end.round().toString();
          }
        }

        apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            minPrice = getdata[MINPRICE];
            maxPrice = getdata[MAXPRICE];
            _currentRangeValues =
                RangeValues(double.parse(minPrice), double.parse(maxPrice));

            offset = widget.section_model!.productList!.length;

            total = int.parse(data[0]["total"]);

            if (offset! < total!) {
              List<SectionModel> temp = (data as List)
                  .map((data) => SectionModel.fromJson(data))
                  .toList();

              getAvailVarient(temp[0].productList!);

              offset = widget.section_model!.offset! + perPage;

              widget.section_model!.offset = offset;
              widget.section_model!.totalItem = total;
            }
          } else {
            isLoadingmore = false;
            if (msg != 'Sections not found') setSnackbar(msg!, context);
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
              isFilterClear = false;
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

    return;
  }

  _setFav(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            widget.section_model!.productList![index].isFavLoading = true;
          });
        }

        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PRODUCT_ID: widget.section_model!.productList![index].id
        };

        apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            widget.section_model!.productList![index].isFav = "1";
            context
                .read<FavoriteProvider>()
                .addFavItem(widget.section_model!.productList![index]);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted) {
            setState(() {
              widget.section_model!.productList![index].isFavLoading = false;
            });
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

  _removeFav(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            widget.section_model!.productList![index].isFavLoading = true;
          });
        }

        var parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PRODUCT_ID: widget.section_model!.productList![index].id
        };
        apiBaseHelper.postAPICall(removeFavApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            widget.section_model!.productList![index].isFav = "0";

            context.read<FavoriteProvider>().removeFavItem(widget
                .section_model!.productList![index].prVarientList![0].id!);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted) {
            setState(() {
              widget.section_model!.productList![index].isFavLoading = false;
            });
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
}
